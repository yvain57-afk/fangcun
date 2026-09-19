import Foundation
import HealthKit
import InnerBalanceCore
import SwiftData
import Testing
@testable import InnerBalance

@MainActor struct PhoneSyncIntegrationTests {
  final class Transport: SyncTransport {
    var onReceive: (@MainActor @Sendable (Data) async -> Data?)?
    var onOpportunity: (@MainActor @Sendable () async -> Void)?
    func activate() {}
    func deliver(_ data: Data) async throws -> Data? { nil }
    func updateContext(_ data: Data) throws {}
  }
  @Test func receiverProjectsUnknownDrinkValuesAndDeduplicatesHealthSession() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let recoveryStore = try RecoveryStore(directory: directory.appendingPathComponent("recovery"))
    let recovery = RecoveryCoordinator(store: recoveryStore)
    let diary = FangcunDiary(defaults: UserDefaults(suiteName: UUID().uuidString)!, storage: try FangcunDiaryStorage(directory: directory.appendingPathComponent("diary")))
    let insights = try InsightsStore(directory: directory.appendingPathComponent("insights"))
    let readiness = ReadinessCoordinator(store: insights, provider: ReadinessDemoProvider(scenario: "assessable"), defaults: UserDefaults(suiteName: UUID().uuidString)!)
    let store = try SyncStore(directory: directory.appendingPathComponent("sync"))
    let service = SyncService(store: store, transport: Transport(), role: "phone", localDirectory: directory.appendingPathComponent("cache"))
    let owner = PhoneSyncCoordinator(service: service)
    let schema = Schema([StoredPracticeCompletion.self])
    let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    await owner.start(diary: diary, recovery: recovery, readiness: readiness, context: container.mainContext)
    await readiness.refresh()
    #expect(await store.snapshot().summary?.assessmentID == readiness.current?.assessmentID)
    await readiness.stop(clear: true)
    #expect(await store.snapshot().summary?.revoked == true)
    #expect(service.localCache.read(now: .now, peer: (await store.snapshot()).installationID) == .neutral)
    let start = Date.now.addingTimeInterval(-60)
    let hk = HKCategorySample(type: HKCategoryType(.mindfulSession), value: HKCategoryValue.notApplicable.rawValue, start: start, end: .now,
      metadata: [HealthMetadataKeys.sessionID: "same-session", HealthMetadataKeys.practiceType: "physiologicalSigh"])
    let imported = try #require(HealthKitRepository.recoverySession(hk))
    #expect(imported.plannedDurationKnown == false)
    try await recoveryStore.mergeHealthSession(imported)
    var wc = RecoverySession(sessionID: "same-session", action: .practice(.physiologicalSigh), plannedDuration: 300, startedAt: start, originDevice: "watch")
    wc.endedAt = .now; wc.activeDuration = 60; wc.endReason = .endedEarly
    let encoder = JSONEncoder()
    let event = SyncEvent(entityID: wc.sessionID, kind: .session, revision: 1, originInstallationID: "synthetic-watch", payload: try encoder.encode(wc))
    let packet = try encoder.encode(SyncPacket(origin: "synthetic-watch", role: "watch", event: event))
    #expect(await service.receive(packet) != nil)
    #expect(await service.receive(packet) != nil)
    try await recoveryStore.mergeHealthSession(imported)
    #expect(await recoveryStore.records().count == 1)
    #expect(await recoveryStore.records().first?.plannedDuration == 300)
    #expect(try container.mainContext.fetch(FetchDescriptor<StoredPracticeCompletion>()).isEmpty)
    let id = UUID().uuidString
    let drink = SyncedDrink(id: id, kind: "beer", consumedAt: start, recordedAt: nil, volumeML: 330,
      caffeineMG: 0, alcoholGrams: nil, sugarServings: 0, sugarGrams: nil, estimateMethod: "legacyFixedCupEstimate", estimateVersion: 1)
    let drinkEvent = SyncEvent(entityID: id, kind: .drink, revision: 1, originInstallationID: "synthetic-watch", payload: try encoder.encode(drink))
    #expect(await service.receive(try encoder.encode(SyncPacket(origin: "synthetic-watch", role: "watch", event: drinkEvent))) != nil)
    #expect(diary.allEntries.first?.alcoholGrams == nil && diary.allEntries.first?.recordedAt == nil)
    var deleted = event; deleted.eventID = "delete"; deleted.deleted = true; deleted.payload = Data(); deleted.revision = 2
    #expect(await service.receive(try encoder.encode(SyncPacket(origin: "synthetic-watch", role: "watch", event: deleted))) != nil)
    try await recoveryStore.mergeHealthSession(imported)
    #expect(await recoveryStore.records().isEmpty)
    #expect(await service.receive(packet) != nil)
    #expect(await recoveryStore.records().isEmpty)
  }
  @Test func undoUsesNewTransportRevisionAndArchiveCompatibility() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let diary = FangcunDiary(defaults: UserDefaults(suiteName: UUID().uuidString)!, storage: try FangcunDiaryStorage(directory: directory.appendingPathComponent("diary")))
    let store = try SyncStore(directory: directory.appendingPathComponent("sync"))
    let service = SyncService(store: store, transport: Transport(), role: "phone", localDirectory: directory)
    diary.add(.water)
    let first = try #require(diary.allEntries.first)
    try await service.enqueue(first.syncValue)
    diary.edit(first.id, consumedAt: first.date, volumeML: 500)
    try await service.enqueue(try #require(diary.allEntries.first).syncValue)
    diary.undo()
    try await service.enqueue(try #require(diary.allEntries.first).syncValue)
    #expect(await store.snapshot().entities["drink:" + first.id.uuidString]?.revision == 3)
    #expect(diary.allEntries.first?.volumeML == 250)
    diary.remove(.water); try await service.delete(kind: .drink, id: first.id.uuidString)
    diary.undo(); try await service.enqueue(try #require(diary.allEntries.first).syncValue)
    #expect(await store.snapshot().entities["drink:" + first.id.uuidString]?.explicitRestore == true)
    #expect(await store.snapshot().entities["drink:" + first.id.uuidString]?.revision == 5)
  }
}
