import Foundation
import Testing
@testable import InnerBalanceCore

@Suite @MainActor struct BeverageSyncV2Tests {
  final class Transport: SyncTransport {
    var onReceive: (@MainActor @Sendable (Data) async -> Data?)?
    var onOpportunity: (@MainActor @Sendable () async -> Void)?
    var delivered: [SyncPacket] = []
    func activate() {}
    func deliver(_ data: Data) async throws -> Data? { delivered.append(try JSONDecoder().decode(SyncPacket.self, from: data)); return nil }
    func updateContext(_ data: Data) throws {}
  }
  @Test func unknownOldWatchKeepsNewBeverageQueuedThenCapabilityUnlocks() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let store = try SyncStore(directory: root), transport = Transport()
    let service = SyncService(store: store, transport: transport, role: "phone", localDirectory: root)
    let d = BeverageDetails(displayName: "Wine", alcoholPresence: .yes, abvPercent: 12)
    let drink = SyncedDrink(id: "wine", kind: "alcohol", consumedAt: .now, recordedAt: .now, volumeML: 150,
      caffeineMG: 0, alcoholGrams: 14.202, sugarServings: 0, sugarGrams: nil, estimateMethod: "perServing", estimateVersion: 2, beverageDetails: d)
    try await service.enqueue(drink)
    await service.flush(manual: true)
    #expect(transport.delivered.isEmpty)
    #expect(await store.snapshot().outbox.count == 1)
    var oldHello = SyncPacket(origin: "old-watch", role: "watch", hello: true); oldHello.capabilities = nil
    _ = await service.receive(try JSONEncoder().encode(oldHello)); await service.flush(manual: true)
    #expect(transport.delivered.isEmpty)
    #expect(await store.snapshot().outbox.count == 1)
    oldHello.capabilities = ["beverage-v2"]
    _ = await service.receive(try JSONEncoder().encode(oldHello)); await service.flush(manual: true)
    let event = try #require(transport.delivered.first?.event)
    let decoded = try JSONDecoder().decode(SyncedDrink.self, from: event.payload)
    #expect(decoded.kind == "alcohol" && decoded.beverageDetails == d)
    #expect((await store.snapshot()).outbox.count == 1) // Sending alone is never an ACK.
  }
}
