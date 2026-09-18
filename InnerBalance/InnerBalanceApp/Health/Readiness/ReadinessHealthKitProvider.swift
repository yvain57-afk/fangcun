import Foundation
import HealthKit
import InnerBalanceCore

typealias ReadinessHealthDataProviding = ReadinessDataProviding

/// Separate from the legacy Home provider. M3 will connect the evaluated result to the UI.
/// No authorization requests, background delivery entitlement changes, or new read types here.
@MainActor
final class ReadinessHealthKitProvider: ReadinessHealthDataProviding {
  static let permittedMetrics: [ReadinessMetric] = [.hrvSDNN, .restingHeartRate, .sleep, .workout]
  private let store: HKHealthStore
  private var observers: [HKObserverQuery] = []
  private(set) var lastObserverOutcome: ReadinessObserverOutcome?
  var observerNeedsRefresh: Bool { lastObserverOutcome.map { $0 != .processed } ?? false }
  private let pageSize = 500
  init(store: HKHealthStore = HKHealthStore()) { self.store = store }

  func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch {
    guard HKHealthStore.isHealthDataAvailable() else { throw ReadinessReadFailure.healthDataUnavailable }
    let type = try Self.type(for: metric)
    let cursor = cursor ?? HealthReadCursor(windowStart: now.addingTimeInterval(-35 * 86_400))
    let anchor: HKQueryAnchor?
    do {
      anchor = try cursor.anchor.map {
        guard let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: $0) else {
          throw ReadinessReadFailure.invalidAnchor
        }
        return decoded
      }
    } catch { throw ReadinessReadFailure.invalidAnchor }
    // Keep the predicate stable for the lifetime of this anchor. Prune the local cache separately.
    let predicate = HKQuery.predicateForSamples(withStart: cursor.windowStart, end: nil)
    let pageSize = pageSize
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKAnchoredObjectQuery(type: type, predicate: predicate, anchor: anchor, limit: pageSize) {
        _, added, deleted, newAnchor, error in
        if let error {
          let hk = error as NSError
          let failure: ReadinessReadFailure = hk.domain == HKErrorDomain && hk.code == HKError.Code.errorDatabaseInaccessible.rawValue
            ? .protectedDataUnavailable : .queryFailed
          continuation.resume(throwing: failure); return
        }
        do {
          guard let newAnchor else { throw ReadinessReadFailure.invalidAnchor }
          let data = try NSKeyedArchiver.archivedData(withRootObject: newAnchor, requiringSecureCoding: true)
          let additions = (added ?? []).compactMap { Self.normalize($0, metric: metric, queriedAt: now) }
          continuation.resume(returning: ReadinessChangeBatch(metric: metric, samples: additions,
            deletedIDs: (deleted ?? []).map(\.uuid),
            cursor: HealthReadCursor(anchor: data, windowStart: cursor.windowStart),
            hasMore: (added?.count ?? 0) + (deleted?.count ?? 0) >= pageSize))
        } catch { continuation.resume(throwing: ReadinessReadFailure.invalidAnchor) }
      }
      store.execute(query)
    }
  }

  /// Explicit opt-in by a future lifecycle owner; no background delivery/authorization is enabled here.
  func startObserving(pipeline: ReadinessPipeline,
    context: @escaping @MainActor @Sendable () -> ReadinessObservationContext,
    onSnapshot: @escaping @MainActor @Sendable (InsightsSnapshot) -> Void = { _ in }) throws {
    try startObserving(onChange: {
      let value = context()
      let snapshot = try await pipeline.refresh(now: value.now, calendar: value.calendar,
        configuration: value.configuration, interventions: value.interventions, healthDataChanged: true)
      onSnapshot(snapshot)
    })
  }

  private func startObserving(onChange: @escaping @MainActor @Sendable () async throws -> Void) throws {
    guard observers.isEmpty else { return }
    for metric in Self.permittedMetrics {
      let query = HKObserverQuery(sampleType: try Self.type(for: metric), predicate: nil) { [weak self] _, completion, error in
        _ = Self.handleObserverUpdate(error: error, completion: completion, onChange: onChange,
          onOutcome: { [weak self] outcome in self?.lastObserverOutcome = outcome })
      }
      observers.append(query); store.execute(query)
    }
  }

  /// The real HK callback and tests share this owner. Every path finishes processing before one ACK.
  nonisolated static func handleObserverUpdate(error: Error?, completion: @escaping () -> Void,
    onChange: @escaping @MainActor @Sendable () async throws -> Void,
    onOutcome: @escaping @MainActor @Sendable (ReadinessObserverOutcome) -> Void = { _ in }) -> Task<Void, Never> {
    let acknowledgement = ReadinessObserverCompletion(completion)
    return Task { @MainActor in
      defer { acknowledgement.call() }
      guard error == nil else { onOutcome(.queryFailed); return }
      do {
        try await onChange()
        onOutcome(.processed)
      } catch is CancellationError { onOutcome(.cancelled) }
      catch { onOutcome(.processingFailed) }
    }
  }

  func stopObserving() { observers.forEach(store.stop); observers.removeAll() }

  nonisolated private static func type(for metric: ReadinessMetric) throws -> HKSampleType {
    switch metric {
    case .hrvSDNN: HKQuantityType(.heartRateVariabilitySDNN)
    case .restingHeartRate: HKQuantityType(.restingHeartRate)
    case .sleep: HKCategoryType(.sleepAnalysis)
    case .workout: HKObjectType.workoutType()
    default: throw ReadinessReadFailure.unsupportedMetric
    }
  }

  nonisolated static func normalize(_ sample: HKSample, metric: ReadinessMetric, queriedAt: Date) -> ReadinessSample? {
    let revision = sample.sourceRevision
    let os = revision.operatingSystemVersion
    let device = sample.device
    let source = ReadinessSource(bundleID: revision.source.bundleIdentifier,
      name: revision.source.name, productType: revision.productType, deviceModel: device?.model,
      deviceIdentity: device?.localIdentifier.map(StableDigest.text),
      revision: "\(revision.version ?? "")|\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)|\(device?.hardwareVersion ?? "")|\(device?.softwareVersion ?? "")",
      samplingMethod: metric.rawValue, isOriginalDeviceRecord: device != nil)
    var value: Double?, unit = "", stage: SleepStage?, activity: UInt?
    switch metric {
    case .hrvSDNN, .restingHeartRate:
      guard let quantity = sample as? HKQuantitySample,
        quantity.quantityType == (metric == .hrvSDNN ? HKQuantityType(.heartRateVariabilitySDNN) : HKQuantityType(.restingHeartRate)) else { return nil }
      value = quantity.quantity.doubleValue(for: metric == .hrvSDNN ? .secondUnit(with: .milli) : .count().unitDivided(by: .minute()))
      unit = metric == .hrvSDNN ? "ms" : "count/min"
    case .sleep:
      guard let category = sample as? HKCategorySample, category.categoryType == HKCategoryType(.sleepAnalysis) else { return nil }
      unit = "category"
      switch HKCategoryValueSleepAnalysis(rawValue: category.value) {
      case .asleepUnspecified: stage = .asleep
      case .asleepCore: stage = .core
      case .asleepDeep: stage = .deep
      case .asleepREM: stage = .rem
      case .awake: stage = .awake
      case .inBed: stage = .inBed
      default: stage = .unknown
      }
    case .workout:
      guard let workout = sample as? HKWorkout else { return nil }
      value = workout.duration; unit = "s"; activity = workout.workoutActivityType.rawValue
    default: return nil
    }
    var metadata: [String: String] = [:]
    if let context = sample.metadata?[HKMetadataKeyHeartRateMotionContext] as? NSNumber {
      metadata[HKMetadataKeyHeartRateMotionContext] = context.stringValue
    }
    return ReadinessSample(id: sample.uuid, metric: metric, value: value, unit: unit, stage: stage,
      start: sample.startDate, end: sample.endDate, source: source,
      manuallyEntered: (sample.metadata?[HKMetadataKeyWasUserEntered] as? NSNumber)?.boolValue ?? false,
      syncIdentifier: sample.metadata?[HKMetadataKeySyncIdentifier] as? String,
      syncVersion: (sample.metadata?[HKMetadataKeySyncVersion] as? NSNumber)?.intValue ?? 0,
      activityType: activity, metadata: metadata, queriedAt: queriedAt)
  }
}


nonisolated enum ReadinessObserverOutcome: Sendable { case processed, queryFailed, processingFailed, cancelled }

struct ReadinessObservationContext: Sendable {
  var now: Date
  var calendar: Calendar
  var configuration: ReadinessConfiguration = .init()
  var interventions: [ReadinessInterval] = []
}
