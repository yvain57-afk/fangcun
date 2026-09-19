import Foundation
import InnerBalanceCore
import SwiftData

/// Minimal transport lifecycle only; existing Watch screens, clocks and HealthKit writes stay owned by their source.
@MainActor final class WatchSyncLifecycle {
  static let shared = WatchSyncLifecycle()
  private var service: SyncService?
  private var started = false
  private(set) var unavailable = false
  func start(context: ModelContext) async {
    guard !started else { return }; started = true
    do {
      let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("FangcunWatchSync")
      let group = Bundle.main.object(forInfoDictionaryKey: "FangcunAppGroupIdentifier") as? String
      let shared = group.flatMap { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) }
      let value = SyncService(store: try SyncStore(directory: directory), transport: WatchConnectivityTransport(), role: "watch", localDirectory: directory, sharedDirectory: shared)
      // Remote session/feedback/drink facts are durably applied in SyncStore before ACK.
      // No call to the Watch health-writing queue and no second readiness engine.
      value.onRecordsChanged = { archive in
        for event in archive.entities.values where event.originInstallationID != archive.installationID && event.kind == .session {
          let id = event.entityID
          let descriptor = FetchDescriptor<WatchPracticeCompletion>(predicate: #Predicate { $0.sessionID == id })
          let existing = try context.fetch(descriptor).first
          if event.deleted { if let existing { context.delete(existing) }; continue }
          let record = try JSONDecoder().decode(RecoverySession.self, from: event.payload)
          guard case .practice(let kind) = record.action, let end = record.endedAt else { continue }
          if let existing {
            existing.activeDuration = record.activeDuration; existing.endedAt = end
            existing.startedAt = record.startedAt; existing.plannedDuration = record.plannedDuration
          } else {
            let imported = WatchPracticeCompletion(sessionID: id, practiceKind: kind,
              activeDuration: record.activeDuration, endedAt: end, healthWriteStatus: "imported_no_health_write")
            imported.startedAt = record.startedAt; imported.plannedDuration = record.plannedDuration
            context.insert(imported)
          }
        }
        try context.save()
      }
      service = value
      await value.reconcile()
      value.activate()
      for record in try context.fetch(FetchDescriptor<WatchPracticeCompletion>()) {
        guard let kind = PracticeKind(rawValue: record.practiceKindRawValue) else { continue }
        let archived = await value.store.snapshot().entities["session:" + record.sessionID]
        guard archived == nil else { continue }
        var session = RecoverySession(sessionID: record.sessionID, action: .practice(kind),
          plannedDuration: record.plannedDuration ?? record.activeDuration,
          startedAt: record.startedAt ?? record.endedAt.addingTimeInterval(-record.activeDuration), originDevice: "watch")
        session.plannedDurationKnown = record.plannedDuration != nil
        session.activeDuration = record.activeDuration; session.endedAt = record.endedAt
        session.endReason = record.startedAt == nil ? .legacyUnknown : record.activeDuration >= session.plannedDuration ? .completed : .endedEarly
        try await value.enqueue(session)
      }
      await value.flush()
    } catch { unavailable = true; started = false }
  }
  func completed(sessionID: String, kind: PracticeKind, planned: TimeInterval, active: TimeInterval, started: Date, ended: Date) async {
    guard let service else { return } // SwiftData local completion is replayed on the next launch.
    var value = RecoverySession(sessionID: sessionID, action: .practice(kind), plannedDuration: planned, startedAt: started, originDevice: "watch")
    value.activeDuration = active; value.endedAt = ended
    value.endReason = active >= planned ? .completed : .endedEarly
    do { try await service.enqueue(value); await service.flush() } catch { unavailable = true }
  }
}
