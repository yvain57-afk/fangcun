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
}
