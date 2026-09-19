import Foundation
import Testing
@testable import InnerBalanceCore

@MainActor struct SyncReliabilityTests {
  final class Transport: SyncTransport {
    var onReceive: (@MainActor @Sendable (Data) async -> Data?)?
    var onOpportunity: (@MainActor @Sendable () async -> Void)?
    weak var peer: Transport?
    var offline = false
    var loseACK = false
    var context: Data?
    func activate() {}
    func deliver(_ data: Data) async throws -> Data? {
      guard !offline, let peer else { throw SyncStore.Failure.peer }
      let result = await peer.onReceive?(data); return loseACK ? nil : result
    }
    func updateContext(_ data: Data) throws { if offline { throw SyncStore.Failure.peer }; context = data }
  }
  func session(_ id: String = "s1") -> RecoverySession {
    var result = RecoverySession(sessionID: id, action: .quietRest, plannedDuration: 120, startedAt: .now, originDevice: "watch")
    result.endedAt = .now; result.endReason = .endedEarly; result.activeDuration = 15
    result.feedback = .init(helpfulness: nil, revision: 1, updatedAt: .now, localNote: "local-only-note")
    return result
  }
  @Test func durableACKLostOfflineRestartDuplicatesAndProjectionRetry() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let a = try SyncStore(directory: dir.appendingPathComponent("a")), b = try SyncStore(directory: dir.appendingPathComponent("b"))
    let ta = Transport(), tb = Transport(); ta.peer = tb; tb.peer = ta
    let phone = SyncService(store: a, transport: ta, role: "phone", localDirectory: dir.appendingPathComponent("ac"))
    let watch = SyncService(store: b, transport: tb, role: "watch", localDirectory: dir.appendingPathComponent("bc"))
    await phone.handshake(); await watch.handshake()
    try await watch.enqueue(session())
    tb.offline = true; await watch.flush()
    #expect(await b.snapshot().outbox.count == 1)
    let reopened = try SyncStore(directory: dir.appendingPathComponent("b"))
    let restarted = SyncService(store: reopened, transport: tb, role: "watch", localDirectory: dir.appendingPathComponent("bc"))
    tb.offline = false; tb.loseACK = true
    await restarted.flush(manual: true)
    #expect(await a.snapshot().entities.count == 1)
    #expect(await reopened.snapshot().outbox.count == 1)
    let record = try JSONDecoder().decode(RecoverySession.self, from: #require(await a.snapshot().entities["session:s1"]?.payload))
    #expect(record.feedback?.localNote == nil)
    tb.loseACK = false
    phone.onRecordsChanged = { _ in throw SyncStore.Failure.injected }
    await restarted.flush(manual: true)
    #expect(await reopened.snapshot().outbox.count == 1)
    phone.onRecordsChanged = nil
    await restarted.flush(manual: true)
    #expect(await reopened.snapshot().outbox.isEmpty)
    #expect(await a.snapshot().received.count == 1)
  }
  @Test func failedReceiverCannotACKAndDeletePrecedesStaleReplay() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let store = try SyncStore(directory: dir)
    try await store.acceptPeer("watch")
    let payload = try JSONEncoder().encode(session())
    let created = SyncEvent(entityID: "s1", kind: .session, revision: 1, originInstallationID: "watch", payload: payload)
    await store.injectWriteFailure()
    await #expect(throws: SyncStore.Failure.self) { try await store.receive(created) }
    #expect(await store.snapshot().received.isEmpty)
    let deleted = SyncEvent(entityID: "s1", kind: .session, revision: 3, originInstallationID: "watch", deleted: true, payload: Data())
    _ = try await store.receive(deleted); _ = try await store.receive(created)
    #expect(await store.snapshot().entities["session:s1"]?.deleted == true)
    var forged = created; forged.revision = 4; forged.eventID = "later-stale"
    _ = try await store.receive(forged)
    #expect(await store.snapshot().entities["session:s1"]?.deleted == true)
    var restore = forged; restore.eventID = "explicit-undo"; restore.explicitRestore = true
    _ = try await store.receive(restore)
    #expect(await store.snapshot().entities["session:s1"]?.deleted == false)
    var old = created; old.revision = 2; old.eventID = "out-of-order"
    _ = try await store.receive(old)
    #expect(await store.snapshot().entities["session:s1"]?.revision == 4)
  }
  @Test func epochUnknownProtocolSummaryAndCorruptionRemainNeutral() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let store = try SyncStore(directory: dir)
    let transport = Transport()
    let receiver = SyncService(store: store, transport: transport, role: "watch", localDirectory: dir)
    let encoder = JSONEncoder()
    _ = await receiver.receive(try encoder.encode(SyncPacket(origin: "old", role: "phone", hello: true)))
    _ = await receiver.receive(try encoder.encode(SyncPacket(origin: "new", role: "phone", hello: true)))
    _ = await receiver.receive(try encoder.encode(SyncPacket(origin: "old", role: "phone", hello: true)))
    #expect(await store.snapshot().peerInstallationID == "new")
    var unknown = SyncPacket(origin: "new", role: "phone"); unknown.schemaVersion = 99
    #expect(await receiver.receive(try encoder.encode(unknown)) == nil)
    #expect(await store.snapshot().quarantined.count == 2)
    #expect(receiver.sharedCache.read(now: .now, peer: "new") == .unavailable)
    var summary = ReadinessSummaryDTO(assessment: nil, installationID: "new", sequence: 2, now: .now)
    summary.revoked = false; summary.validUntil = .now.addingTimeInterval(60)
    try receiver.localCache.write(summary)
    #expect(receiver.localCache.read(now: .now, peer: "new") == .current(summary))
    #expect(receiver.localCache.read(now: .now.addingTimeInterval(61), peer: "new") == .neutral)
    #expect(receiver.localCache.read(now: .now, peer: "old") == .neutral)
    try Data("corrupt".utf8).write(to: #require(receiver.localCache.file))
    #expect(receiver.localCache.read(now: .now, peer: "new") == .neutral)
    try await store.receiveSummary(summary)
    summary.sequence = 1; summary.revoked = true
    try await store.receiveSummary(summary)
    #expect(await store.snapshot().summary?.sequence == 2)
  }
  @Test func revocationStillReplacesTransportContextWhenDiskWriteFails() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try SyncStore(directory: directory)
    let transport = Transport()
    let service = SyncService(store: store, transport: transport, role: "phone", localDirectory: directory)
    await store.injectWriteFailure()
    await service.publish(nil)
    let data = try #require(transport.context)
    let packet = try JSONDecoder().decode(SyncPacket.self, from: data)
    #expect(packet.summary?.revoked == true)
    #expect(service.localCache.read(now: .now, peer: (await store.snapshot()).installationID) == .neutral)
    #expect(service.lastError == "summary_unavailable")
  }

}
