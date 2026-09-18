import Foundation
import InnerBalanceCore
import Observation

enum HomeEvidenceReliability: Equatable, Sendable {
  case reliable
  case buildingBaseline
  case needsReview
  case stale
}

enum HomeEvidenceDeviation: Equatable, Sendable {
  case withinRange
  case elevated
}

struct HomeHealthEvidence: Equatable, Identifiable, Sendable {
  let kind: BodyLoadEvidenceKind
  let valueText: String
  let sourceName: String
  let measuredAt: Date
  let reliability: HomeEvidenceReliability
  let deviation: HomeEvidenceDeviation
  let assessmentValueText: String?
  let assessmentMeasuredAt: Date?

  init(
    kind: BodyLoadEvidenceKind,
    valueText: String,
    sourceName: String,
    measuredAt: Date,
    reliability: HomeEvidenceReliability,
    deviation: HomeEvidenceDeviation,
    assessmentValueText: String? = nil,
    assessmentMeasuredAt: Date? = nil
  ) {
    self.kind = kind
    self.valueText = valueText
    self.sourceName = sourceName
    self.measuredAt = measuredAt
    self.reliability = reliability
    self.deviation = deviation
    self.assessmentValueText = assessmentValueText
    self.assessmentMeasuredAt = assessmentMeasuredAt
  }

  var isAggregatedAssessment: Bool {
    kind == .heartRateVariability || kind == .restingHeartRate
  }

  var id: BodyLoadEvidenceKind { kind }
}

struct SleepReviewDetails: Equatable, Sendable {
  let startDate: Date
  let endDate: Date
  let asleepDuration: TimeInterval
  let sampleCount: Int
  let sourceNames: [String]
  let includesAppleWatch: Bool
}

struct HomeTrainingSummary: Equatable, Sendable {
  let count: Int
  let totalDuration: TimeInterval
  let latestActivityName: String
  let latestDuration: TimeInterval
  let latestEndDate: Date
  let latestSourceName: String
}

@MainActor
@Observable
final class HomeViewModel {
  private let provider: any BodyHealthDataProviding
  private let clock: () -> Date
  @ObservationIgnored private var currentRefreshID: UUID?

  private(set) var assessment = BodyLoadEngine.assess(evidence: [], baselineDays: 0)
  private(set) var baselineDays = 0
  private(set) var evidence: [HomeHealthEvidence] = []
  private(set) var unavailableKinds: Set<BodyHealthDataKind> = []
  private(set) var recentWorkoutProtection = false
  private(set) var sleepNeedsReview = false
  private(set) var sleepReviewDetails: SleepReviewDetails?
  private(set) var trainingSummary: HomeTrainingSummary?
  private(set) var fetchedAt: Date?
  private(set) var computedAt: Date?
  /// Compatibility for older diagnostics; this has always been a query timestamp.
  var lastUpdated: Date? { fetchedAt }
  var latestMeasuredAt: Date? {
    evidence.flatMap { [$0.measuredAt, $0.assessmentMeasuredAt].compactMap { $0 } }.max()
  }
  private(set) var isLoading = false

  init(provider: any BodyHealthDataProviding, clock: @escaping () -> Date = { .now }) {
    self.provider = provider
    self.clock = clock
  }

  func refresh(now: Date? = nil) async {
    let now = now ?? clock()
    let refreshID = UUID()
    currentRefreshID = refreshID
    isLoading = true
    defer {
      if currentRefreshID == refreshID {
        isLoading = false
      }
    }

    let received = await provider.fetchBodyHealthData(now: now)
    guard currentRefreshID == refreshID else { return }
    // A failed query cannot validate any cached values delivered alongside it.
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: received.unavailableKinds.contains(.heartRateVariability) ? [] : received.heartRateVariability,
      restingHeartRate: received.unavailableKinds.contains(.restingHeartRate) ? [] : received.restingHeartRate,
      sleep: received.unavailableKinds.contains(.sleep) ? [] : received.sleep,
      workouts: received.unavailableKinds.contains(.workout) ? [] : received.workouts,
      unavailableKinds: received.unavailableKinds, fetchedAt: received.fetchedAt)
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: now)
    let baselineCutoff = calendar.date(byAdding: .day, value: -14, to: now) ?? now
    let historicalHRV = snapshot.heartRateVariability.filter { $0.date < today && $0.date >= baselineCutoff }
    let historicalResting = snapshot.restingHeartRate.filter { $0.date < today && $0.date >= baselineCutoff }
    let currentHRV = assessmentRecords(
      from: snapshot.heartRateVariability,
      now: now
    )
    let currentResting = assessmentRecords(
      from: snapshot.restingHeartRate,
      now: now
    )
    let hrvBaselineRecords = compatibleBaselineRecords(
      from: historicalHRV,
      assessmentUsesWatch: currentHRV.first?.source.isAppleWatch
    )
    let restingBaselineRecords = compatibleBaselineRecords(
      from: historicalResting,
      assessmentUsesWatch: currentResting.first?.source.isAppleWatch
    )
    baselineDays = min(
      5,
      max(
        validDayCount(in: hrvBaselineRecords, calendar: calendar),
        validDayCount(in: restingBaselineRecords, calendar: calendar)
      )
    )
    let hrvBaseline = BodyLoadEngine.dailyMedianBaseline(
      from: hrvBaselineRecords.map(\.coreSample),
      now: now
    )
    let restingBaseline = BodyLoadEngine.dailyMedianBaseline(
      from: restingBaselineRecords.map(\.coreSample),
      now: now
    )
    let provisionalHRVBaseline = BodyLoadEngine.dailyMedianBaseline(
      from: hrvBaselineRecords.map(\.coreSample),
      now: now,
      minimumDays: 1
    )
    let provisionalRestingBaseline = BodyLoadEngine.dailyMedianBaseline(
      from: restingBaselineRecords.map(\.coreSample),
      now: now,
      minimumDays: 1
    )
    let recentHRV = BodyLoadEngine.recentSummary(
      from: currentHRV.map(\.coreSample),
      now: now,
      window: 36 * 3_600
    )
    let latestHRV = latestRecord(
      from: snapshot.heartRateVariability,
      now: now,
      window: 14 * 86_400
    )
    let recentResting = BodyLoadEngine.recentSummary(
      from: currentResting.map(\.coreSample),
      now: now,
      window: 36 * 3_600
    )
    let latestResting = latestRecord(
      from: snapshot.restingHeartRate,
      now: now,
      window: 14 * 86_400
    )

    var items: [HomeHealthEvidence] = []
    var coreEvidence: [BodyLoadEvidence] = []
    if let latestHRV {
      let comparison = hrvBaseline ?? provisionalHRVBaseline
      let isElevated =
        recentHRV.flatMap { recent in
          comparison.map { recent.value < $0 * 0.90 }
        } ?? false
      items.append(
        HomeHealthEvidence(
          kind: .heartRateVariability,
          valueText: "\(latestHRV.value.formatted(.number.precision(.fractionLength(0)))) ms",
          sourceName: latestHRV.source.name,
          measuredAt: latestHRV.date,
          reliability: reliability(for: recentHRV, baseline: hrvBaseline),
          deviation: isElevated ? .elevated : .withinRange,
          assessmentValueText: recentHRV.map {
            "近 36 小时中位数 "
              + "\($0.value.formatted(.number.precision(.fractionLength(0)))) ms"
              + " · 来源 \(assessmentSourceName(from: currentHRV))"
          },
          assessmentMeasuredAt: recentHRV?.latestDate
        )
      )
      if recentHRV != nil {
        coreEvidence.append(
          BodyLoadEvidence(
            kind: .heartRateVariability,
            state: isElevated ? .elevated : .withinRange,
            isReliable: hrvBaseline != nil
          )
        )
      }
    }
    if let latestResting {
      let comparison = restingBaseline ?? provisionalRestingBaseline
      let isElevated =
        recentResting.flatMap { recent in
          comparison.map { recent.value > $0 * 1.08 }
        } ?? false
      items.append(
        HomeHealthEvidence(
          kind: .restingHeartRate,
          valueText: "\(latestResting.value.formatted(.number.precision(.fractionLength(0)))) 次/分",
          sourceName: latestResting.source.name,
          measuredAt: latestResting.date,
          reliability: reliability(for: recentResting, baseline: restingBaseline),
          deviation: isElevated ? .elevated : .withinRange,
          assessmentValueText: recentResting.map {
            "近 36 小时中位数 "
              + "\($0.value.formatted(.number.precision(.fractionLength(0)))) 次/分"
              + " · 来源 \(assessmentSourceName(from: currentResting))"
          },
          assessmentMeasuredAt: recentResting?.latestDate
        )
      )
      if recentResting != nil {
        coreEvidence.append(
          BodyLoadEvidence(
            kind: .restingHeartRate,
            state: isElevated ? .elevated : .withinRange,
            isReliable: restingBaseline != nil
          )
        )
      }
    }

    let primarySleep = SleepEpisodeAnalyzer.primarySleep(
      from: snapshot.sleep.map(\.coreSample),
      now: now
    )
    sleepNeedsReview = primarySleep?.quality == .needsReview
    sleepReviewDetails = primarySleep.map {
      SleepReviewDetails(
        startDate: $0.start,
        endDate: $0.end,
        asleepDuration: $0.asleepDuration,
        sampleCount: $0.sampleCount,
        sourceNames: $0.sourceNames,
        includesAppleWatch: $0.usesAppleWatch
      )
    }
    if let primarySleep {
      let isCurrent = primarySleep.end >= now.addingTimeInterval(-36 * 3_600)
      let isElevated = primarySleep.isUsableForBodyLoad && primarySleep.asleepDuration < 6.5 * 3_600
      items.append(
        HomeHealthEvidence(
          kind: .sleep,
          valueText: Self.durationText(primarySleep.asleepDuration),
          sourceName: primarySleep.sourceNames.joined(separator: "、"),
          measuredAt: primarySleep.end,
          reliability: !isCurrent ? .stale : primarySleep.isUsableForBodyLoad ? .reliable : .needsReview,
          deviation: isElevated ? .elevated : .withinRange
        )
      )
      if isCurrent { coreEvidence.append(
        BodyLoadEvidence(
          kind: .sleep,
          state: isElevated ? .elevated : .withinRange,
          isReliable: primarySleep.isUsableForBodyLoad
        )
      ) }
    }

    recentWorkoutProtection = snapshot.workouts.contains {
      $0.duration >= 45 * 60
        && $0.endDate <= now
        && $0.endDate >= now.addingTimeInterval(-18 * 3_600)
    }
    let recentWorkouts = deduplicatedWorkouts(
      snapshot.workouts.filter {
        $0.duration > 0
          && $0.endDate <= now
          && $0.endDate >= now.addingTimeInterval(-24 * 3_600)
      }
    )
    if let latestWorkout = recentWorkouts.max(by: { $0.endDate < $1.endDate }) {
      trainingSummary = HomeTrainingSummary(
        count: recentWorkouts.count,
        totalDuration: recentWorkouts.reduce(0) { $0 + $1.duration },
        latestActivityName: latestWorkout.activityName,
        latestDuration: latestWorkout.duration,
        latestEndDate: latestWorkout.endDate,
        latestSourceName: latestWorkout.source.name
      )
    } else {
      trainingSummary = nil
    }
    evidence = items
    unavailableKinds = snapshot.unavailableKinds
    assessment = BodyLoadEngine.assess(
      evidence: coreEvidence,
      baselineDays: baselineDays,
      recentWorkout: recentWorkoutProtection
    )
    fetchedAt = snapshot.fetchedAt
    computedAt = clock()
  }

  private func validDayCount(
    in records: [HealthQuantityRecord],
    calendar: Calendar
  ) -> Int {
    let valid = records.filter { $0.value.isFinite && $0.value > 0 }
    let watch = valid.filter(\.source.isAppleWatch)
    let selected = Set(watch.map { calendar.startOfDay(for: $0.date) }).count >= 5 ? watch : valid
    return Set(selected.map { calendar.startOfDay(for: $0.date) }).count
  }

  private func deduplicatedWorkouts(
    _ workouts: [HealthWorkoutRecord]
  ) -> [HealthWorkoutRecord] {
    let preferred = workouts.sorted { lhs, rhs in
      if lhs.source.isAppleWatch != rhs.source.isAppleWatch {
        return lhs.source.isAppleWatch
      }
      return lhs.endDate > rhs.endDate
    }
    var result: [HealthWorkoutRecord] = []
    for workout in preferred where !result.contains(where: { isMirror($0, of: workout) }) {
      result.append(workout)
    }
    return result
  }

  private func isMirror(
    _ lhs: HealthWorkoutRecord,
    of rhs: HealthWorkoutRecord
  ) -> Bool {
    guard lhs.activityName == rhs.activityName else { return false }
    let overlap = min(lhs.endDate, rhs.endDate).timeIntervalSince(
      max(lhs.startDate, rhs.startDate)
    )
    guard overlap > 0 else { return false }
    let lhsSpan = max(1, lhs.endDate.timeIntervalSince(lhs.startDate))
    let rhsSpan = max(1, rhs.endDate.timeIntervalSince(rhs.startDate))
    return overlap / min(lhsSpan, rhsSpan) >= 0.8
  }

  private func latestRecord(
    from records: [HealthQuantityRecord],
    now: Date,
    window: TimeInterval
  ) -> HealthQuantityRecord? {
    let valid = records.filter {
      $0.value.isFinite
        && $0.value > 0
        && $0.date <= now
        && $0.date >= now.addingTimeInterval(-window)
    }
    let watch = valid.filter(\.source.isAppleWatch)
    return (watch.isEmpty ? valid : watch).max { lhs, rhs in
      if lhs.date == rhs.date {
        return !lhs.source.isAppleWatch && rhs.source.isAppleWatch
      }
      return lhs.date < rhs.date
    }
  }

  private func assessmentRecords(
    from records: [HealthQuantityRecord],
    now: Date
  ) -> [HealthQuantityRecord] {
    let cutoff = now.addingTimeInterval(-36 * 3_600)
    let valid = records.filter {
      $0.value.isFinite && $0.value > 0 && $0.date >= cutoff && $0.date <= now
    }
    let watch = valid.filter(\.source.isAppleWatch)
    return watch.isEmpty ? valid.filter { !$0.source.isAppleWatch } : watch
  }

  private func compatibleBaselineRecords(
    from records: [HealthQuantityRecord],
    assessmentUsesWatch: Bool?
  ) -> [HealthQuantityRecord] {
    guard let assessmentUsesWatch else { return records }
    return records.filter { $0.source.isAppleWatch == assessmentUsesWatch }
  }

  private func assessmentSourceName(from records: [HealthQuantityRecord]) -> String {
    Array(Set(records.map(\.source.name))).sorted().joined(separator: "、")
  }

  private func reliability(
    for recent: HealthMetricSummary?,
    baseline: Double?
  ) -> HomeEvidenceReliability {
    guard recent != nil else { return .stale }
    return baseline == nil ? .buildingBaseline : .reliable
  }

  static func durationText(_ duration: TimeInterval) -> String {
    let totalMinutes = Int(duration / 60)
    return "\(totalMinutes / 60) 小时 \(totalMinutes % 60) 分"
  }
}
