import Foundation
import Testing
@testable import InnerBalanceCore

@Suite("M2-R01 dependency invalidation")
struct M2ReviewR01Tests {
  let f = ReadinessFixture()
  @Test func historicalSleepDeletionInvalidatesThenRecomputesAndCannotRecoverOldCache() async throws {
    let dir = try InsightsStoreTests().directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = SyntheticReadinessProvider(f.records(), now: f.now)
    let pipeline = ReadinessPipeline(provider: provider, store: store)
    let first = try await pipeline.refresh(now: f.now, calendar: f.calendar)
    let original = try #require(first.current)
    try await store.deleteSamples([f.id(101)])
    let removed = await store.snapshot()
    #expect(removed.current == nil)
    #expect(!removed.assessments.contains { $0.assessmentID == original.assessmentID })
    #expect(removed.deletionAudit.contains { $0.assessmentID == original.assessmentID })
    let revised = try await pipeline.refresh(now: f.now+60, calendar: f.calendar)
    let next = try #require(revised.current)
    #expect(next.level == .usual && next.evidence.first?.baseline?.validDays == 19)
    #expect(next.revision == original.revision+1 && next.supersedesID == original.assessmentID)
    let restarted = try InsightsStore(directory: dir)
    #expect(await restarted.snapshot().assessments.allSatisfy { $0.assessmentID != original.assessmentID })
    try Data("corrupt".utf8).write(to: dir.appendingPathComponent("insights-v1.json"))
    let recovered = try InsightsStore(directory: dir)
    await provider.setFailure(.queryFailed)
    let failed = try await ReadinessPipeline(provider: provider, store: recovered).refresh(now: f.now+120, calendar: f.calendar)
    #expect(failed.current?.level == nil)
    #expect(!failed.assessments.contains { $0.assessmentID == original.assessmentID })
    #expect(failed.ledger.samples[f.id(101).uuidString] == nil)
  }
  @Test(arguments: [true,false]) func rejectedSamplesAndSleepConflictAreDependencies(conflict: Bool) async throws {
    let dir = try InsightsStoreTests().directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let rejected = conflict ? f.sleep(start: 8,end: 7,seed: 9000,stage: .awake)
      : f.quantity(.hrvSDNN,value: .nan,hoursAgo: 6,seed: 9000)
    let store = try InsightsStore(directory: dir)
    let provider = SyntheticReadinessProvider(f.records()+[rejected], now: f.now)
    let pipeline = ReadinessPipeline(provider: provider, store: store)
    let before = try await pipeline.refresh(now: f.now, calendar: f.calendar)
    #expect(before.current?.availability == .limited)
    try await store.deleteSamples([rejected.id])
    #expect(await store.snapshot().current == nil)
    let after = try await pipeline.refresh(now: f.now+60, calendar: f.calendar)
    #expect(after.current?.level == .usual)
    #expect(after.current?.supersedesID == before.current?.assessmentID)
  }
  @Test func legacyAssessmentWithoutDependencyMetadataLoadsButDeletionFailsClosed() async throws {
    let dir = try InsightsStoreTests().directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir)
    let initial = try await store.commit(InsightsStoreTests().candidate(), expectedGeneration: 0)
    let url = dir.appendingPathComponent("insights-v1.json")
    var envelope = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    let encoded = try #require(envelope["payload"] as? String)
    let payload = try #require(Data(base64Encoded: encoded))
    var value = try #require(JSONSerialization.jsonObject(with: payload) as? [String: Any])
    var assessments = try #require(value["assessments"] as? [[String: Any]])
    for i in assessments.indices { assessments[i].removeValue(forKey: "dependencyVersion") }
    value["assessments"] = assessments
    let changed = try JSONSerialization.data(withJSONObject: value)
    envelope["payload"] = changed.base64EncodedString(); envelope["checksum"] = StableDigest.data(changed)
    try JSONSerialization.data(withJSONObject: envelope).write(to: url)
    let legacy = try InsightsStore(directory: dir)
    #expect(await legacy.snapshot().current?.assessmentID == initial.current?.assessmentID)
    try await legacy.deleteSamples([f.id(101)])
    #expect(await legacy.snapshot().current == nil)
    #expect(await legacy.snapshot().ledger.samples[f.id(1).uuidString] != nil)
  }
}
