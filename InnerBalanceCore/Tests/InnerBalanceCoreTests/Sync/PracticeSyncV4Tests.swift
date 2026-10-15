import Foundation
import Testing
@testable import InnerBalanceCore

@Suite @MainActor struct PracticeSyncV4Tests {
  @Test func unknownPeerPreservesNewMethodUntilRecordCapabilityArrives() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let store = try SyncStore(directory: root), transport = BeverageSyncV2Tests.Transport()
    let service = SyncService(store: store, transport: transport, role: "phone", localDirectory: root)
    var record = RecoverySession(sessionID: "v4-balanced", action: .practice(.balancedBreathing), plannedDuration: 180, startedAt: Date(timeIntervalSince1970: 1000), originDevice: "iPhone", protocolVersion: 4)
    record.activeDuration = 70; record.endedAt = record.startedAt.addingTimeInterval(70); record.endReason = .endedEarly
    try await service.enqueue(record)
    await service.flush(manual: true)
    #expect(transport.delivered.isEmpty)
    #expect(await store.snapshot().outbox.count == 1)
    var hello = SyncPacket(origin: "watch-test", role: "watch", hello: true)
    hello.capabilities = ["beverage-v2", "score-v3"]
    _ = await service.receive(try JSONEncoder().encode(hello))
    await service.flush(manual: true)
    #expect(transport.delivered.isEmpty)
    #expect(service.lastError == "peer_practice_upgrade_required")
    hello.capabilities?.append("practice-record-v4")
    _ = await service.receive(try JSONEncoder().encode(hello))
    await service.flush(manual: true)
    let event = try #require(transport.delivered.first?.event)
    let decoded = try JSONDecoder().decode(RecoverySession.self, from: event.payload)
    #expect(decoded.action == .practice(.balancedBreathing))
    #expect(decoded.protocolVersion == 4)
    #expect(await store.snapshot().outbox.count == 1)
    #expect(!PracticeKind.balancedBreathing.isLegacyWatchExecutable)
    hello.capabilities = nil // Same installation ID, but now an older app build.
    _ = await service.receive(try JSONEncoder().encode(hello))
    await service.flush(manual: true)
    #expect(transport.delivered.count == 1)
    #expect(service.lastError == "peer_practice_upgrade_required")
  }
}
