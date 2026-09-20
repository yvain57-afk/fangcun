import Foundation
import Testing
import InnerBalanceCore
@testable import InnerBalance

@MainActor struct StatusScoreCoordinatorV3Tests {
  @Test func rawSleepScoreColdReloadFailureAndTargetRevision() async throws {
    var now = ISO8601DateFormatter().date(from:"2026-09-20T04:00:00Z")!
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:dir) }
    let store = try InsightsStore(directory:dir), provider = ReadinessDemoProvider(scenario:"scoreSleep375",now:now)
    let defaults = UserDefaults(suiteName:UUID().uuidString)!
    let owner = ReadinessCoordinator(store:store,provider:provider,defaults:defaults,clock:{ now })
    await owner.refresh()
    let first = try #require(owner.statusScore)
    #expect(first.displayScore == 78 && first.band == .fair)
    now = now.addingTimeInterval(3600)
    await provider.setFailure(true)
    let restored = ReadinessCoordinator(store:try InsightsStore(directory:dir),provider:provider,defaults:defaults,clock:{ now })
    await restored.refresh()
    #expect(restored.statusScore?.scoreID == first.scoreID && restored.statusScore?.asOf == first.asOf)
    #expect(restored.errorKey != nil)
    await provider.setFailure(false)
    await owner.setTarget(9)
    #expect(owner.statusScore?.displayScore == 69 && owner.statusScore?.revision == 2)
    #expect(owner.snapshot.statusScores?.first?.displayScore == 78)
    now = first.validUntil; owner.tick()
    #expect(owner.statusScore == nil)
  }
  @Test func nightAndConstraintsChangeOnlyAction() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:dir) }
    let now = ISO8601DateFormatter().date(from:"2026-09-20T04:00:00Z")!
    let owner = ReadinessCoordinator(store:try InsightsStore(directory:dir),provider:ReadinessDemoProvider(scenario:"scoreSleep375",now:now),defaults:UserDefaults(suiteName:UUID().uuidString)!,clock:{ now })
    await owner.refresh(); let score = try #require(owner.statusScore)
    #expect(StatusPresentationPolicy.action(score:score,night:false) == .quietRest)
    #expect(StatusPresentationPolicy.action(score:score,night:true) == .shortBreathing)
    #expect(StatusPresentationPolicy.action(score:score,night:true,driving:true) == .unavailable)
    #expect(StatusPresentationPolicy.action(score:score,night:true,avoidBreathing:true) == .quietRest)
    #expect(StatusPresentationPolicy.action(score:score,night:true,severe:true) == .safety)
    #expect(owner.statusScore?.scoreID == score.scoreID && owner.statusScore?.displayScore == 78)
  }
  actor Gate: ReadinessDataProviding {
    var entered = false
    private var continuation: CheckedContinuation<Void,Never>?
    private var released = false
    func release() { released = true; continuation?.resume(); continuation = nil }
    func changes(for metric:ReadinessMetric,cursor:HealthReadCursor?,now:Date) async throws -> ReadinessChangeBatch {
      if !released { entered = true; await withCheckedContinuation { continuation = $0 } }
      return .init(metric:metric,samples:[],cursor:cursor ?? .init(anchor:Data([1]),windowStart:now.addingTimeInterval(-35*86400)))
    }
  }
  @Test func simultaneousTargetAndSourceChangeRejectsOldScoreIntent() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:dir) }
    let now = ISO8601DateFormatter().date(from:"2026-09-20T04:00:00Z")!
    let store = try InsightsStore(directory:dir)
    let seed = ReadinessPipeline(provider:ReadinessDemoProvider(scenario:"assessable",now:now),store:store)
    _ = try await seed.refresh(now:now,calendar:.current,scoreConfiguration:.init())
    let gate = Gate()
    // Use one explicit provider owner for all coalesced requests.
    let currentOwner = ReadinessCoordinator(store:store,provider:gate,defaults:UserDefaults(suiteName:UUID().uuidString)!,clock:{ now })
    let first = Task { await currentOwner.refresh() }
    while !(await gate.entered) { await Task.yield() }
    let target = Task { await currentOwner.setTarget(9) }
    while currentOwner.scoreConfiguration.sleepGoalMinutes != 540 { await Task.yield() }
    let source = Task { await currentOwner.selectSource("missing-v3-selected-source",metric:.hrvSDNN) }
    while await store.snapshot().sources[ReadinessMetric.hrvSDNN.rawValue]?.sourceKey != "missing-v3-selected-source" { await Task.yield() }
    await gate.release(); await first.value; await target.value; await source.value
    let score = try #require(currentOwner.statusScore)
    #expect(score.configuration.sleepGoalMinutes == 540)
    #expect(!score.components.contains { $0.name == "hrv" })
    #expect(currentOwner.snapshot.sources[ReadinessMetric.hrvSDNN.rawValue]?.sourceKey == "missing-v3-selected-source")
    #expect(await store.snapshot().currentStatus?.scoreID == score.scoreID)
  }

}
