#if DEBUG
import Foundation

/// Synthetic raw records only. Every result still runs through HomeViewModel and Core.
/// Release builds contain neither this source nor the launch-argument entry point.
enum HomeHealthFixture: String, CaseIterable {
  case noCurrentHistory, stale, failed, sleepOnly, oneCardio, baselineBuilding
  case steady, watch, elevated, workoutProtected, previousSleep, unreliablePair

  static let now = Date(timeIntervalSince1970: 1_789_704_000) // 2026-09-18 04:00 UTC

  func snapshot(now: Date = Self.now) -> BodyHealthDataSnapshot {
    let source = HealthSourceDescriptor(name: "Synthetic Watch", bundleIdentifier: "org.example.fixture", isAppleWatch: true)
    func quantity(_ value: Double, _ hoursAgo: Double) -> HealthQuantityRecord {
      HealthQuantityRecord(value: value, date: now.addingTimeInterval(-hoursAgo * 3_600), source: source)
    }
    let days = self == .baselineBuilding ? 3...5 : 3...9
    var hrv = days.map { quantity(50, Double($0 * 24)) }
    var resting = days.map { quantity(60, Double($0 * 24)) }
    var sleep: [HealthSleepRecord] = []
    var workouts: [HealthWorkoutRecord] = []
    var unavailable: Set<BodyHealthDataKind> = []
    switch self {
    case .noCurrentHistory: break
    case .stale:
      hrv.append(quantity(50, 37)); resting.append(quantity(60, 37))
    case .sleepOnly, .previousSleep:
      // History may be sufficient; sleep alone still cannot determine overall load.
      let end = now.addingTimeInterval(self == .previousSleep ? -40 * 3_600 : -3 * 3_600)
      sleep = [HealthSleepRecord(startDate: end.addingTimeInterval(-7 * 3_600), endDate: end, source: source)]
    case .oneCardio:
      hrv.append(quantity(50, 2))
    case .steady, .baselineBuilding:
      hrv.append(quantity(50, 2)); resting.append(quantity(60, 2))
    case .watch:
      hrv.append(quantity(30, 2)); resting.append(quantity(60, 2))
    case .elevated, .workoutProtected:
      hrv.append(quantity(30, 2)); resting.append(quantity(78, 2))
      if self == .workoutProtected {
        workouts = [HealthWorkoutRecord(startDate: now.addingTimeInterval(-7_200),
          endDate: now.addingTimeInterval(-3_600), duration: 3_600, source: source, activityName: "Synthetic exercise")]
      }
    case .failed:
      // Deliberately includes cached-looking values: failure must take precedence.
      hrv.append(quantity(50, 2)); resting.append(quantity(60, 2))
      unavailable = [.heartRateVariability, .restingHeartRate, .sleep, .workout]
    case .unreliablePair:
      hrv.append(quantity(50, 2)); resting = [quantity(60, 2)]
    }
    return BodyHealthDataSnapshot(heartRateVariability: hrv, restingHeartRate: resting,
      sleep: sleep, workouts: workouts, unavailableKinds: unavailable,
      fetchedAt: now.addingTimeInterval(-60))
  }
}
#endif
