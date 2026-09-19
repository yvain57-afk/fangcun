import Foundation
import Observation
import SwiftData
import SwiftUI
import InnerBalanceCore

private struct PhoneSyncKey: EnvironmentKey { static let defaultValue: PhoneSyncCoordinator? = nil }
extension EnvironmentValues {
  var phoneSync: PhoneSyncCoordinator? { get { self[PhoneSyncKey.self] } set { self[PhoneSyncKey.self] = newValue } }
}
@MainActor @Observable final class PhoneSyncCoordinator {
  let service: SyncService?
  private(set) var queued = 0
  private(set) var errorKey: String?
  private var started = false
  private var readyForLocalEvents = false
  private var scanning = false
  private var rescan = false
  init(service: SyncService?) { self.service = service; if service == nil { errorKey = "sync.unavailable" } }
  static func make() -> PhoneSyncCoordinator {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return .init(service: nil) }
    #endif
    do {
      let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("FangcunSync")
      let group = Bundle.main.object(forInfoDictionaryKey: "FangcunAppGroupIdentifier") as? String
      let shared = group.flatMap { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) }
      return .init(service: SyncService(store: try SyncStore(directory: directory), transport: WatchConnectivityTransport(), role: "phone", localDirectory: directory, sharedDirectory: shared))
    } catch { return .init(service: nil) }
  }
  func start(diary: FangcunDiary, recovery: RecoveryCoordinator, readiness: ReadinessCoordinator, context: ModelContext) async {
    guard !started, let service else { return }; started = true
    service.onRecordsChanged = { archive in
      let remote = archive.entities.values.filter { $0.originInstallationID != archive.installationID }
      try diary.applySync(remote)
      guard let store = recovery.store else { throw SyncStore.Failure.corrupt }
      try await store.applySync(remote)
      await recovery.load()
      // Incoming records are application facts only. No HealthWriteCoordinator is called here.
      let deleted = Set(remote.filter { $0.deleted && $0.kind == .session }.map(\.entityID))
      for old in try context.fetch(FetchDescriptor<StoredPracticeCompletion>()) where deleted.contains(old.sessionID) { context.delete(old) }
      try context.save()
    }
    service.currentAssessment = { [weak readiness] in readiness?.current }
    readiness.onSummaryChange = { [weak service] assessment in await service?.publish(assessment) }
    await service.reconcile()
    await service.publish(readiness.current)
    readyForLocalEvents = true
    service.activate()
    await publishRecords(diary: diary, recovery: recovery)
  }
  func publishRecords(diary: FangcunDiary, recovery: RecoveryCoordinator) async {
    guard readyForLocalEvents, let service, diary.storageMessage == nil, recovery.errorKey == nil else { return }
    if scanning { rescan = true; return }; scanning = true
    defer { scanning = false }
    repeat {
      rescan = false
      do {
        for record in recovery.records { try await service.enqueue(record) }
        for drink in diary.allEntries { try await service.enqueue(drink.syncValue) }
        let present = Set(diary.allEntries.map { $0.id.uuidString })
        let archive = await service.store.snapshot()
        for event in archive.entities.values where event.kind == .drink && !event.deleted && !present.contains(event.entityID) {
          try await service.delete(kind: .drink, id: event.entityID)
        }
        await service.flush()
        queued = await service.store.snapshot().outbox.count; errorKey = nil
      } catch { errorKey = "sync.queueError" }
    } while rescan
  }
  func retry() async {
    guard let service else { return }
    await service.handshake(); await service.flush(manual: true)
    queued = await service.store.snapshot().outbox.count
    errorKey = service.lastError == nil ? nil : "sync.pending"
  }
}
struct PhoneSyncStatusView: View {
  let owner: PhoneSyncCoordinator
  var body: some View {
    List {
      Text(FangcunCopy.text("sync.queued", owner.queued))
      Text(FangcunCopy.text("sync.explanation"))
      if let error = owner.errorKey { Text(FangcunCopy.text(error)) }
      if owner.service?.sharedCache.file == nil { Text(FangcunCopy.text("sync.groupUnavailable")) }
      Button(FangcunCopy.text("sync.retry")) { Task { await owner.retry() } }
    }.navigationTitle(FangcunCopy.text("sync.title"))
  }
}
