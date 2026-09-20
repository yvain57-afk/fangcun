import Foundation
import Testing
@testable import InnerBalanceCore

@MainActor @Suite struct ScoreV3SyncTests {
  final class Transport: SyncTransport {
    var onReceive: (@MainActor @Sendable (Data) async -> Data?)?
    var onOpportunity: (@MainActor @Sendable () async -> Void)?
    var contexts: [Data] = []
    func activate() {}
    func deliver(_ data:Data) async throws -> Data? { nil }
    func updateContext(_ data:Data) throws { contexts.append(data) }
  }
  @Test func legacyPeerGetsRevocationNewPeerGetsMinimalScoreAndStaleReplayIsRejected() async throws {
    let f = StatusScoreDataV3Tests(), rows = [StatusScoreDataV3Tests().row(.sleep)]
    var state = f.state(rows); try state.recordStatus(f.features(rows),configuration:.init(),now:f.now)
    let score = try #require(state.currentStatus)
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:dir) }
    let store = try SyncStore(directory:dir), transport = Transport()
    let service = SyncService(store:store,transport:transport,role:"phone",localDirectory:dir)
    var oldHello = SyncPacket(origin:"synthetic-watch",role:"watch",hello:true); oldHello.capabilities = ["beverage-v2"]
    _ = await service.receive(try JSONEncoder().encode(oldHello))
    await service.publishStatus(score,now:f.now)
    let oldPacket = try JSONDecoder().decode(SyncPacket.self,from:try #require(transport.contexts.last))
    #expect(oldPacket.statusSummary == nil && oldPacket.summary?.revoked == true && oldPacket.summary?.level == nil)
    oldHello.capabilities = ["beverage-v2","score-v3"]
    _ = await service.receive(try JSONEncoder().encode(oldHello))
    await service.publishStatus(score,now:f.now)
    let newPacket = try JSONDecoder().decode(SyncPacket.self,from:try #require(transport.contexts.last))
    let summary = try #require(newPacket.statusSummary)
    #expect(summary.score == 78 && summary.band == .fair)
    let receiver = try SyncStore(directory:dir.appendingPathComponent("receiver"))
    try await receiver.acceptPeer(summary.originInstallationID)
    try await receiver.receiveStatusSummary(summary)
    var stale = summary; stale.sequence -= 1; stale.score = 79
    try await receiver.receiveStatusSummary(stale)
    #expect(await receiver.snapshot().statusSummary?.score == 78)
    var bad = summary; bad.schemaVersion = 99
    await #expect(throws:SyncStore.Failure.self) { try await receiver.receiveStatusSummary(bad) }
    await service.publishStatus(nil,now:f.now)
    #expect(await store.snapshot().statusSummary?.revoked == true)
    #expect(service.statusCache.read(now:f.now,peer:summary.originInstallationID) == nil)
  }
}
