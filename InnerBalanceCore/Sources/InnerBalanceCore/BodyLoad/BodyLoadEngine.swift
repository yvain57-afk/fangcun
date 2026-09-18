import Foundation

public struct HealthMetricSample: Equatable, Sendable {
  public let value: Double
  public let date: Date
  public let isAppleWatch: Bool

  public init(value: Double, date: Date, isAppleWatch: Bool) {
    self.value = value
    self.date = date
    self.isAppleWatch = isAppleWatch
  }
}

public struct HealthMetricSummary: Equatable, Sendable {
  public let value: Double
  public let latestDate: Date
  public let sampleCount: Int
  public let usesAppleWatch: Bool
}

public enum BodyLoadEvidenceState: Equatable, Sendable {
  case withinRange
  case elevated
}

public enum BodyLoadEvidenceKind: String, Hashable, Sendable {
  case heartRateVariability = "hrv"
  case restingHeartRate = "rhr"
  case respiratoryRate = "respiratory_rate"
  case sleep

  fileprivate var isWorkoutSensitive: Bool {
    switch self {
    case .heartRateVariability, .restingHeartRate: true
    case .respiratoryRate, .sleep: false
    }
  }
}

public struct BodyLoadEvidence: Equatable, Sendable {
  public let kind: BodyLoadEvidenceKind
  public let state: BodyLoadEvidenceState
  public let isReliable: Bool

  public init(
    kind: BodyLoadEvidenceKind,
    state: BodyLoadEvidenceState,
    isReliable: Bool
  ) {
    self.kind = kind
    self.state = state
    self.isReliable = isReliable
  }
}

public enum BodyLoadLevel: Equatable, Sendable {
  case buildingBaseline
  case steady
  case watch
  case elevated
}

public struct BodyLoadAssessment: Equatable, Sendable {
  public let level: BodyLoadLevel
  public let elevatedEvidenceIDs: [String]
  public let availability: BodyLoadDataAvailability
  public let workoutExcludedEvidenceIDs: [String]
}

/// Eligibility for the legacy load estimate, separate from the estimate itself.
/// Callers pass current evidence only; historical baseline length is not current evidence.
public enum BodyLoadDataAvailability: String, Equatable, Sendable {
  case insufficient
  case limited
  case buildingBaseline
  case available
}

public enum BodyLoadEngine {
  public static func median(_ values: [Double]) -> Double? {
    let sorted = values.filter(\.isFinite).sorted()
    guard !sorted.isEmpty else { return nil }

    let middle = sorted.count / 2
    if sorted.count.isMultiple(of: 2) {
      return (sorted[middle - 1] + sorted[middle]) / 2
    }
    return sorted[middle]
  }

  public static func dailyMedianBaseline(
    from samples: [HealthMetricSample],
    now: Date,
    minimumDays: Int = 5,
    calendar: Calendar = .current
  ) -> Double? {
    guard let cutoff = calendar.date(byAdding: .day, value: -14, to: now) else {
      return nil
    }
    let valid = samples.filter {
      $0.value.isFinite
        && $0.value > 0
        && $0.date >= cutoff
        && $0.date <= now
    }
    let watchSamples = valid.filter(\.isAppleWatch)
    let selected =
      distinctDayCount(in: watchSamples, calendar: calendar) >= minimumDays
      ? watchSamples
      : valid

    let grouped = Dictionary(grouping: selected) { calendar.startOfDay(for: $0.date) }
    guard grouped.count >= minimumDays else { return nil }
    return median(grouped.values.compactMap { median($0.map(\.value)) })
  }

  public static func recentSummary(
    from samples: [HealthMetricSample],
    now: Date,
    window: TimeInterval
  ) -> HealthMetricSummary? {
    let valid = samples.filter {
      $0.value.isFinite
        && $0.value > 0
        && $0.date <= now
        && $0.date >= now.addingTimeInterval(-window)
    }
    let watchSamples = valid.filter(\.isAppleWatch)
    let selected = watchSamples.isEmpty ? valid : watchSamples
    guard let value = median(selected.map(\.value)),
      let latestDate = selected.map(\.date).max()
    else { return nil }

    return HealthMetricSummary(
      value: value,
      latestDate: latestDate,
      sampleCount: selected.count,
      usesAppleWatch: !watchSamples.isEmpty
    )
  }

  public static func latestSample(
    from samples: [HealthMetricSample],
    now: Date,
    window: TimeInterval
  ) -> HealthMetricSample? {
    let valid = samples.filter {
      $0.value.isFinite
        && $0.value > 0
        && $0.date <= now
        && $0.date >= now.addingTimeInterval(-window)
    }
    let watchSamples = valid.filter(\.isAppleWatch)
    return (watchSamples.isEmpty ? valid : watchSamples).max { $0.date < $1.date }
  }

  public static func assess(
    evidence: [BodyLoadEvidence],
    baselineDays: Int,
    recentWorkout: Bool = false
  ) -> BodyLoadAssessment {
    guard !evidence.isEmpty else {
      return unavailable(.insufficient)
    }
    guard baselineDays >= 5 else {
      return unavailable(evidence.contains { $0.kind.isWorkoutSensitive } ? .buildingBaseline : .limited)
    }
    let reliableKinds = Set(evidence.filter(\.isReliable).map(\.kind))
    guard reliableKinds.count >= 2, reliableKinds.contains(where: \.isWorkoutSensitive) else {
      return unavailable(.limited)
    }

    let workoutExcludedIDs = Set(evidence.filter {
      recentWorkout && $0.isReliable && $0.state == .elevated && $0.kind.isWorkoutSensitive
    }.map { $0.kind.rawValue }).sorted()
    let elevatedKinds = Set(
      evidence
        .filter {
          $0.isReliable
            && $0.state == .elevated
            && (!recentWorkout || !$0.kind.isWorkoutSensitive)
        }
        .map(\.kind)
    )
    let elevatedIDs = elevatedKinds.map(\.rawValue).sorted()
    let level: BodyLoadLevel
    level =
      switch elevatedKinds.count {
      case 2...: .elevated
      case 1: .watch
      default: .steady
      }

    // A workout explanation must not turn suppressed deviations into reassurance.
    if level == .steady && !workoutExcludedIDs.isEmpty {
      return BodyLoadAssessment(level: .buildingBaseline, elevatedEvidenceIDs: [],
        availability: .limited, workoutExcludedEvidenceIDs: workoutExcludedIDs)
    }
    return BodyLoadAssessment(level: level, elevatedEvidenceIDs: elevatedIDs,
      availability: .available, workoutExcludedEvidenceIDs: workoutExcludedIDs)
  }

  private static func unavailable(_ availability: BodyLoadDataAvailability) -> BodyLoadAssessment {
    BodyLoadAssessment(level: .buildingBaseline, elevatedEvidenceIDs: [],
      availability: availability, workoutExcludedEvidenceIDs: [])
  }

  private static func distinctDayCount(
    in samples: [HealthMetricSample],
    calendar: Calendar
  ) -> Int {
    Set(samples.map { calendar.startOfDay(for: $0.date) }).count
  }
}
