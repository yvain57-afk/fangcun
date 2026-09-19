import Foundation
import Testing
import InnerBalanceCore
@testable import InnerBalance

@MainActor struct RecoverySessionTests {
  @Test(arguments: RecoveryActionKind.localActions)
  func localSaveFailureRetryAndPauseHaveOneIdentity(_ action: RecoveryActionKind) async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try RecoveryStore(directory: directory)
    let owner = RecoveryCoordinator(store: store)
    var now = Date.now
    let model = RecoverySessionModel(plan: try #require(RecoveryProtocol.local(action)), now: { now })
    model.start(environment: .driving)
    #expect(model.phase == .ready && model.clock == nil)
    model.start(environment: .canMove)
    let id = try #require(model.clock?.session.sessionID)
    now = now.addingTimeInterval(10); model.pause()
    now = now.addingTimeInterval(100); model.resume()
    now = now.addingTimeInterval(5)
    await store.injectWriteFailure()
    await model.finish(owner: owner)
    #expect(model.phase == .saving && model.failed)
    #expect(owner.records.isEmpty)
    now = now.addingTimeInterval(200)
    await model.finish(owner: owner); await model.finish(owner: owner)
    #expect(model.phase == .feedback)
    #expect(owner.records.count == 1)
    #expect(owner.records.first?.sessionID == id)
    #expect(owner.records.first?.activeDuration == 15)
    await model.feedback(owner: owner, value: nil)
    #expect(owner.records.first?.feedback?.helpfulness == nil)
    #expect(owner.records.first?.feedback?.skipped == true)
    _ = await owner.feedback(id, .uncomfortable)
    #expect(owner.uncomfortable.contains(action))
    #expect(owner.records.first?.feedback?.revision == 2)
  }
  @Test func legacyPracticeIdentitySurvivesReconciliationAndFeedbackEdit() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let owner = RecoveryCoordinator(store: try RecoveryStore(directory: directory))
    let record = PracticeCompletionRecord(sessionID: "original", practiceKind: .physiologicalSigh,
      plannedDuration: 300, actualDuration: 30, startedAt: .now.addingTimeInterval(-30), endedAt: .now, beforeRating: nil, afterRating: nil)
    await owner.importPractice(record); await owner.importPractice(record)
    _ = await owner.feedback("original", .uncomfortable)
    await owner.importPractice(record)
    #expect(owner.records.count == 1)
    #expect(owner.records.first?.feedback?.helpfulness == .uncomfortable)
    #expect(owner.records.first?.endReason == .legacyUnknown)
  }
}
