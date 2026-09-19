import Foundation
import Testing
@testable import InnerBalanceCore

struct RecoveryActionTests {
  @Test(arguments: RecoveryActionKind.localActions)
  func pauseEndRetryAndRestart(_ action: RecoveryActionKind) async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try RecoveryStore(directory: directory)
    let protocolValue = try #require(RecoveryProtocol.local(action))
    let start = Date(timeIntervalSince1970: 10000)
    var clock = RecoverySessionClock(session: .init(sessionID: "stable", action: action, plannedDuration: protocolValue.duration, startedAt: start, originDevice: "synthetic"))
    clock.resume(at: start)
    clock.pause(at: start.addingTimeInterval(10))
    clock.resume(at: start.addingTimeInterval(100))
    let record = clock.finish(at: start.addingTimeInterval(105))
    #expect(record.activeDuration == 15)
    #expect(record.endReason == .endedEarly)
    #expect(clock.finish(at: start.addingTimeInterval(500)) == record)
    await store.injectWriteFailure()
    await #expect(throws: RecoveryStore.Failure.self) { try await store.save(record) }
    #expect(await store.records().isEmpty)
    try await store.save(record); try await store.save(record)
    #expect(await store.records().count == 1)
    var interrupted = RecoverySessionClock(session: .init(sessionID: "restart", action: action, plannedDuration: 120, startedAt: start, originDevice: "synthetic"))
    interrupted.resume(at: start)
    try await store.save(interrupted.checkpoint(at: start.addingTimeInterval(4)))
    let reopened = try RecoveryStore(directory: directory)
    try await reopened.recoverInterrupted(now: start.addingTimeInterval(600))
    let restored = try #require(await reopened.records().first { $0.sessionID == "restart" })
    #expect(restored.activeDuration == 4)
    #expect(restored.endReason == .interrupted)
  }
  @Test func optionalFeedbackRevisionsAndDenominator() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try RecoveryStore(directory: directory)
    for n in 0..<6 {
      var record = RecoverySession(sessionID: "s\(n)", action: .quietRest, plannedDuration: 120, startedAt: .now, originDevice: "synthetic")
      record.endedAt = .now; record.endReason = .endedEarly
      try await store.save(record)
      try await store.feedback(sessionID: record.sessionID, helpfulness: n == 0 ? nil : .helpful, now: .now)
      if n == 4 { #expect(RecoveryFeedbackSummary.counts(await store.records(), action: .quietRest) == nil) }
    }
    #expect(RecoveryFeedbackSummary.counts(await store.records(), action: .quietRest)?[.helpful] == 5)
    try await store.feedback(sessionID: "s1", helpfulness: .uncomfortable, now: .now)
    let edited = try #require(await store.records().first { $0.sessionID == "s1" })
    #expect(edited.feedback?.revision == 2)
    #expect(edited.feedbackHistory.first?.helpfulness == .helpful)
    let skipped = try #require(await store.records().first { $0.sessionID == "s0" })
    #expect(skipped.feedback?.helpfulness == nil && skipped.feedback?.skipped == true)
  }
  @Test func recommendationsRespectExplicitSafetyAndDiscomfortFirst() {
    #expect(RecoveryRecommendationEngine.recommend(assessment: nil, environment: .driving) == nil)
    #expect(RecoveryRecommendationEngine.recommend(assessment: nil, environment: .unavailable) == nil)
    #expect(RecoveryRecommendationEngine.recommend(assessment: nil, goal: .workBreak, environment: .canMove)?.action == .movementBreak)
    #expect(RecoveryRecommendationEngine.recommend(assessment: nil, goal: .workBreak, environment: .seated)?.action == .seatedReset)
    #expect(RecoveryRecommendationEngine.recommend(assessment: nil, favorites: [.quietRest], uncomfortable: [.quietRest])?.action == .seatedReset)
    #expect(RecoveryRecommendationEngine.recommend(assessment: nil, goal: .calm, uncomfortable: [.practice(.physiologicalSigh)])?.action == .quietRest)
  }
}
