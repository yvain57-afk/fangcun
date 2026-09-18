import Foundation
import InnerBalanceCore
import Testing
@testable import InnerBalance

@Suite("M1 current evidence pipeline") @MainActor
struct HomeEvidencePipelineTests {
  @Test("Raw provider input drives current-evidence qualification", arguments: HomeHealthFixture.allCases)
  func rawInput(_ fixture: HomeHealthFixture) async {
    let provider = FixtureProvider(snapshot: fixture.snapshot())
    let model = HomeViewModel(provider: provider, clock: { HomeHealthFixture.now })
    await model.refresh()
    let expected: FangcunDayState = switch fixture {
    case .noCurrentHistory, .stale, .failed, .previousSleep: .insufficient
    case .sleepOnly, .oneCardio, .baselineBuilding, .workoutProtected, .unreliablePair: .limited
    case .steady: .steady
    case .watch: .watch
    case .elevated: .elevated
    }
    #expect(provider.fetchCount == 1)
    #expect(FangcunDayState.resolve(model) == expected)
    #expect(model.fetchedAt == HomeHealthFixture.now.addingTimeInterval(-60))
    #expect(model.computedAt == HomeHealthFixture.now)
    if expected == .steady {
      #expect(model.assessment.availability == .available)
    } else {
      #expect(model.assessment.level != .steady)
    }
    if fixture == .workoutProtected {
      #expect(model.recentWorkoutProtection)
      #expect(model.assessment.workoutExcludedEvidenceIDs == ["hrv", "rhr"])
      #expect(model.evidence.filter { $0.deviation == .elevated }.count == 2)
    }
    if fixture == .failed {
      #expect(model.evidence.isEmpty)
      #expect(model.latestMeasuredAt == nil)
      #expect(model.unavailableKinds.count == 4)
    }
    if fixture == .previousSleep {
      #expect(model.evidence.first { $0.kind == .sleep }?.reliability == .stale)
    }
  }

  @Test("Fresh queries never advance measurement timestamps")
  func timeSeparation() async throws {
    let old = HomeHealthFixture.stale.snapshot()
    let provider = FixtureProvider(snapshot: old)
    var clock = HomeHealthFixture.now
    let model = HomeViewModel(provider: provider, clock: { clock })
    await model.refresh()
    let measured = try #require(model.latestMeasuredAt)
    clock = clock.addingTimeInterval(300)
    provider.snapshot = BodyHealthDataSnapshot(heartRateVariability: old.heartRateVariability,
      restingHeartRate: old.restingHeartRate, sleep: old.sleep, workouts: old.workouts,
      unavailableKinds: [], fetchedAt: clock)
    await model.refresh()
    #expect(model.latestMeasuredAt == measured)
    #expect(model.fetchedAt == clock)
    #expect(model.computedAt == clock)
    #expect(FangcunDayState.resolve(model) == .insufficient)
  }

  @Test("Old baseline days and future values cannot qualify current evidence")
  func invalidDates() async {
    let original = HomeHealthFixture.steady.snapshot()
    let source = original.heartRateVariability[0].source
    let old = (20...26).map { HealthQuantityRecord(value: 50,
      date: HomeHealthFixture.now.addingTimeInterval(-Double($0) * 86_400), source: source) }
    let future = HealthQuantityRecord(value: 50, date: HomeHealthFixture.now.addingTimeInterval(60), source: source)
    let provider = FixtureProvider(snapshot: BodyHealthDataSnapshot(heartRateVariability: old + [future],
      restingHeartRate: [], sleep: [], workouts: [], unavailableKinds: [], fetchedAt: HomeHealthFixture.now))
    let model = HomeViewModel(provider: provider, clock: { HomeHealthFixture.now })
    await model.refresh()
    #expect(model.baselineDays == 0)
    #expect(model.latestMeasuredAt == nil)
    #expect(FangcunDayState.resolve(model) == .insufficient)
  }
}

@MainActor private final class FixtureProvider: BodyHealthDataProviding {
  var snapshot: BodyHealthDataSnapshot
  var fetchCount = 0
  init(snapshot: BodyHealthDataSnapshot) { self.snapshot = snapshot }
  func fetchBodyHealthData(now: Date) async -> BodyHealthDataSnapshot {
    fetchCount += 1
    return snapshot
  }
}
