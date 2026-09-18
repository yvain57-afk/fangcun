import HealthKit
import InnerBalanceCore

enum BodyHealthDataKind: String, Hashable, Sendable {
  case heartRateVariability
  case restingHeartRate
  case sleep
  case workout
}

struct HealthSourceDescriptor: Equatable, Sendable {
  let name: String
  let bundleIdentifier: String
  let isAppleWatch: Bool
}

struct HealthQuantityRecord: Equatable, Sendable {
  let value: Double
  let date: Date
  let source: HealthSourceDescriptor

  var coreSample: HealthMetricSample {
    HealthMetricSample(value: value, date: date, isAppleWatch: source.isAppleWatch)
  }
}

struct HealthSleepRecord: Equatable, Sendable {
  let startDate: Date
  let endDate: Date
  let source: HealthSourceDescriptor

  var coreSample: SleepSampleInterval {
    SleepSampleInterval(
      start: startDate,
      end: endDate,
      sourceName: source.name,
      isAppleWatch: source.isAppleWatch
    )
  }
}

struct HealthWorkoutRecord: Equatable, Sendable {
  let startDate: Date
  let endDate: Date
  let duration: TimeInterval
  let source: HealthSourceDescriptor
  let activityName: String

  init(
    startDate: Date,
    endDate: Date,
    duration: TimeInterval,
    source: HealthSourceDescriptor,
    activityName: String = "训练"
  ) {
    self.startDate = startDate
    self.endDate = endDate
    self.duration = duration
    self.source = source
    self.activityName = activityName
  }
}

struct WatchHeartRateDiagnosticCounts: Equatable, Sendable {
  let eligible: Int
  let available: Int

  static let zero = WatchHeartRateDiagnosticCounts(eligible: 0, available: 0)
}

struct BodyHealthDataSnapshot: Equatable, Sendable {
  let heartRateVariability: [HealthQuantityRecord]
  let restingHeartRate: [HealthQuantityRecord]
  let sleep: [HealthSleepRecord]
  let workouts: [HealthWorkoutRecord]
  let unavailableKinds: Set<BodyHealthDataKind>
  let fetchedAt: Date

  static func empty(at date: Date) -> BodyHealthDataSnapshot {
    BodyHealthDataSnapshot(
      heartRateVariability: [],
      restingHeartRate: [],
      sleep: [],
      workouts: [],
      unavailableKinds: [],
      fetchedAt: date
    )
  }
}

struct OwnStateOfMindRecordChange {
  let record: StateOfMindRecord
  let healthKitObjectUUID: UUID
}

struct OwnStateOfMindChangeBatch {
  let additions: [OwnStateOfMindRecordChange]
  let deletedObjectUUIDs: [UUID]
  fileprivate let anchor: HKQueryAnchor?
}

@MainActor
protocol BodyHealthDataProviding {
  func fetchBodyHealthData(now: Date) async -> BodyHealthDataSnapshot
}

enum HealthKitRepositoryError: Error, Equatable {
  case invalidMindfulSession
  case unsupportedPracticeType
}

@MainActor
final class HealthKitRepository: HealthWriting, BodyHealthDataProviding {
  private let healthStore: HKHealthStore
  private let cursorStore: HealthSyncCursorStore

  init(
    healthStore: HKHealthStore = HKHealthStore(),
    cursorStore: HealthSyncCursorStore = HealthSyncCursorStore()
  ) {
    self.healthStore = healthStore
    self.cursorStore = cursorStore
  }

  func saveStateOfMind(_ record: StateOfMindRecord) async throws {
    try await healthStore.save(StateOfMindMapper.sample(from: record))
  }

  func saveMindfulSession(_ record: MindfulSessionRecord) async throws {
    guard record.endDate > record.startDate else {
      throw HealthKitRepositoryError.invalidMindfulSession
    }
    guard record.practiceType != "kegel" else {
      throw HealthKitRepositoryError.unsupportedPracticeType
    }

    let sample = HKCategorySample(
      type: HKCategoryType(.mindfulSession),
      value: HKCategoryValue.notApplicable.rawValue,
      start: record.startDate,
      end: record.endDate,
      metadata: HealthMetadataKeys.mindfulSession(
        syncIdentifier: record.syncIdentifier,
        syncVersion: record.syncVersion,
        sessionID: record.sessionID,
        practiceType: record.practiceType,
        protocolVersion: record.protocolVersion,
        origin: record.origin,
        evidenceMode: record.evidenceMode,
        heartRateEvidence: record.heartRateEvidence
      )
    )
    try await healthStore.save(sample)
  }

  func fetchBodyHealthData(now: Date) async -> BodyHealthDataSnapshot {
    let baselineStart =
      Calendar.current.date(byAdding: .day, value: -14, to: now)
      ?? now.addingTimeInterval(-14 * 86_400)
    let sleepStart = now.addingTimeInterval(-48 * 3_600)

    let hrv = await quantityRecords(
      type: HKQuantityType(.heartRateVariabilitySDNN),
      unit: .secondUnit(with: .milli),
      start: baselineStart,
      end: now,
      kind: .heartRateVariability
    )
    let resting = await quantityRecords(
      type: HKQuantityType(.restingHeartRate),
      unit: .count().unitDivided(by: .minute()),
      start: baselineStart,
      end: now,
      kind: .restingHeartRate
    )
    let sleep = await sleepRecords(start: sleepStart, end: now)
    let workouts = await workoutRecords(start: sleepStart, end: now)

    return BodyHealthDataSnapshot(
      heartRateVariability: hrv.values,
      restingHeartRate: resting.values,
      sleep: sleep.values,
      workouts: workouts.values,
      unavailableKinds: [hrv.issue, resting.issue, sleep.issue, workouts.issue].compactSet,
      fetchedAt: now
    )
  }

  func ownStateOfMindChanges() async throws -> OwnStateOfMindChangeBatch {
    let anchor = try cursorStore.load(for: .stateOfMind)
    let descriptor = HKAnchoredObjectQueryDescriptor<HKStateOfMind>(
      predicates: [.stateOfMind(Self.ownedStateOfMindMetadataPredicate())],
      anchor: anchor
    )
    let result = try await descriptor.result(for: healthStore)
    let additions = Self.deduplicateOwnStateOfMindSamples(result.addedSamples)
      .compactMap { sample in
        StateOfMindMapper.record(from: sample).map {
          OwnStateOfMindRecordChange(record: $0, healthKitObjectUUID: sample.uuid)
        }
      }
    return OwnStateOfMindChangeBatch(
      additions: additions,
      deletedObjectUUIDs: result.deletedObjects.map(\.uuid),
      anchor: result.newAnchor
    )
  }

  func watchHeartRateDiagnosticCounts() async -> WatchHeartRateDiagnosticCounts {
    let type = HKCategoryType(.mindfulSession)
    let predicate = HKQuery.predicateForObjects(
      withMetadataKey: HealthMetadataKeys.origin,
      allowedValues: [HealthRecordOrigin.watch.rawValue]
    )
    let descriptor = HKSampleQueryDescriptor<HKCategorySample>(
      predicates: [.categorySample(type: type, predicate: predicate)],
      sortDescriptors: []
    )
    guard let samples = try? await descriptor.result(for: healthStore) else { return .zero }
    let ownedSamples = samples.filter {
      Self.isOwnedBundleIdentifier($0.sourceRevision.source.bundleIdentifier)
        && Self.isOwnedSyncIdentifier($0.metadata?[HKMetadataKeySyncIdentifier] as? String)
    }
    let eligible = ownedSamples.filter {
      ($0.metadata?[HealthMetadataKeys.heartRateEvidenceRequested] as? NSNumber)?.boolValue
        == true
    }
    let available = eligible.filter {
      $0.metadata?[HealthMetadataKeys.evidenceQuality] as? String
        == HeartRateEvidenceQuality.sufficient.rawValue
    }
    return WatchHeartRateDiagnosticCounts(eligible: eligible.count, available: available.count)
  }

  func commit(_ batch: OwnStateOfMindChangeBatch) throws {
    guard let anchor = batch.anchor else { return }
    try cursorStore.save(anchor, for: .stateOfMind)
  }

  static func deduplicateOwnStateOfMindSamples(
    _ samples: [HKStateOfMind]
  ) -> [HKStateOfMind] {
    deduplicateStateOfMindSamples(
      samples.filter {
        isOwnedBundleIdentifier($0.sourceRevision.source.bundleIdentifier)
          && isOwnedSyncIdentifier($0.metadata?[HKMetadataKeySyncIdentifier] as? String)
      }
    )
  }

  static func deduplicateStateOfMindSamples(
    _ samples: [HKStateOfMind]
  ) -> [HKStateOfMind] {
    var samplesByIdentifier: [String: HKStateOfMind] = [:]
    for sample in samples {
      guard let identifier = sample.metadata?[HKMetadataKeySyncIdentifier] as? String,
        identifier.isEmpty == false
      else { continue }

      let version = syncVersion(of: sample)
      if let existing = samplesByIdentifier[identifier], syncVersion(of: existing) > version {
        continue
      }
      samplesByIdentifier[identifier] = sample
    }
    return samplesByIdentifier.values.sorted { $0.startDate < $1.startDate }
  }

  static func isOwnedBundleIdentifier(_ bundleIdentifier: String) -> Bool {
    bundleIdentifier == "com.yvainair.InnerBalance"
      || bundleIdentifier == "com.yvainair.InnerBalance.watchkitapp"
  }

  static func isOwnedSyncIdentifier(_ syncIdentifier: String?) -> Bool {
    syncIdentifier?.hasPrefix("com.yvainair.innerbalance.") == true
  }

  static func ownedStateOfMindMetadataPredicate() -> NSPredicate {
    HKQuery.predicateForObjects(
      withMetadataKey: HealthMetadataKeys.origin,
      allowedValues: [HealthRecordOrigin.iPhone.rawValue, HealthRecordOrigin.watch.rawValue]
    )
  }

  private static func syncVersion(of sample: HKStateOfMind) -> Int {
    (sample.metadata?[HKMetadataKeySyncVersion] as? NSNumber)?.intValue ?? 0
  }

  private func quantityRecords(
    type: HKQuantityType,
    unit: HKUnit,
    start: Date,
    end: Date,
    kind: BodyHealthDataKind
  ) async -> HealthQueryResult<HealthQuantityRecord> {
    let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
    let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
      predicates: [.quantitySample(type: type, predicate: predicate)],
      sortDescriptors: []
    )
    do {
      let samples = try await descriptor.result(for: healthStore)
      return HealthQueryResult(
        values: samples.map {
          HealthQuantityRecord(
            value: $0.quantity.doubleValue(for: unit),
            date: $0.endDate,
            source: Self.sourceDescriptor(for: $0)
          )
        },
        issue: nil
      )
    } catch {
      return HealthQueryResult(values: [], issue: kind)
    }
  }

  private func sleepRecords(start: Date, end: Date) async -> HealthQueryResult<HealthSleepRecord> {
    let type = HKCategoryType(.sleepAnalysis)
    let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end)
    let asleepPredicate = HKCategoryValueSleepAnalysis.predicateForSamples(
      equalTo: HKCategoryValueSleepAnalysis.allAsleepValues
    )
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      datePredicate, asleepPredicate,
    ])
    let descriptor = HKSampleQueryDescriptor<HKCategorySample>(
      predicates: [.categorySample(type: type, predicate: predicate)],
      sortDescriptors: []
    )
    do {
      let samples = try await descriptor.result(for: healthStore)
      return HealthQueryResult(
        values: samples.map {
          HealthSleepRecord(
            startDate: $0.startDate,
            endDate: $0.endDate,
            source: Self.sourceDescriptor(for: $0)
          )
        },
        issue: nil
      )
    } catch {
      return HealthQueryResult(values: [], issue: .sleep)
    }
  }

  private func workoutRecords(
    start: Date,
    end: Date
  ) async -> HealthQueryResult<HealthWorkoutRecord> {
    let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
    let descriptor = HKSampleQueryDescriptor<HKWorkout>(
      predicates: [.workout(predicate)],
      sortDescriptors: []
    )
    do {
      let samples = try await descriptor.result(for: healthStore)
      return HealthQueryResult(
        values: samples.map {
          HealthWorkoutRecord(
            startDate: $0.startDate,
            endDate: $0.endDate,
            duration: $0.duration,
            source: Self.sourceDescriptor(for: $0),
            activityName: Self.activityName(for: $0.workoutActivityType)
          )
        },
        issue: nil
      )
    } catch {
      return HealthQueryResult(values: [], issue: .workout)
    }
  }

  private static func sourceDescriptor(for sample: HKSample) -> HealthSourceDescriptor {
    let source = sample.sourceRevision.source
    let productType = sample.sourceRevision.productType ?? ""
    return HealthSourceDescriptor(
      name: source.name,
      bundleIdentifier: source.bundleIdentifier,
      isAppleWatch: productType.hasPrefix("Watch")
    )
  }

  static func activityName(for type: HKWorkoutActivityType) -> String {
    switch type {
    case .running: "跑步"
    case .walking: "步行"
    case .cycling: "骑行"
    case .hiking: "徒步"
    case .swimming: "游泳"
    case .traditionalStrengthTraining, .functionalStrengthTraining: "力量训练"
    case .highIntensityIntervalTraining: "间歇训练"
    case .yoga: "瑜伽"
    case .mindAndBody: "身心训练"
    case .coreTraining: "核心训练"
    case .rowing: "划船"
    case .elliptical: "椭圆机"
    case .pilates: "普拉提"
    case .cardioDance, .socialDance: "舞蹈"
    case .tennis: "网球"
    case .basketball: "篮球"
    case .badminton: "羽毛球"
    case .tableTennis: "乒乓球"
    case .soccer: "足球"
    case .volleyball: "排球"
    case .golf: "高尔夫"
    case .stairClimbing, .stairs, .stepTraining: "爬楼"
    case .jumpRope: "跳绳"
    case .boxing, .kickboxing: "拳击"
    case .martialArts: "武术"
    case .climbing: "攀岩"
    case .crossCountrySkiing, .downhillSkiing: "滑雪"
    case .snowboarding: "单板滑雪"
    case .skatingSports: "滑冰"
    case .surfingSports: "冲浪"
    case .paddleSports: "桨板"
    case .waterFitness: "水中健身"
    case .taiChi: "太极"
    case .flexibility: "拉伸"
    case .mixedCardio: "综合有氧"
    default: "训练"
    }
  }
}

private struct HealthQueryResult<Value> {
  let values: [Value]
  let issue: BodyHealthDataKind?
}

extension Array where Element == BodyHealthDataKind? {
  fileprivate var compactSet: Set<BodyHealthDataKind> {
    Set(compactMap { $0 })
  }
}
