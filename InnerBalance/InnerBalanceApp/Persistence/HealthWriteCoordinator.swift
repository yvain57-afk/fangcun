import Foundation
import SwiftData

enum HealthWriteResult: Equatable, Sendable {
  case saved
  case queued
  case failedToQueue
}

@MainActor
final class HealthWriteCoordinator {
  private let writer: any HealthWriting
  private let modelContext: ModelContext
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder

  init(writer: any HealthWriting, modelContext: ModelContext) {
    self.writer = writer
    self.modelContext = modelContext
    decoder = JSONDecoder()
    encoder = JSONEncoder()
  }

  func saveStateOfMind(_ record: StateOfMindRecord) async -> HealthWriteResult {
    do {
      try await writer.saveStateOfMind(record)
      return .saved
    } catch {
      recordSyncError("write_failed")
      return enqueue(
        record,
        kind: .stateOfMind,
        syncIdentifier: record.syncIdentifier,
        syncVersion: record.syncVersion
      )
    }
  }

  func saveMindfulSession(_ record: MindfulSessionRecord) async -> HealthWriteResult {
    do {
      try await writer.saveMindfulSession(record)
      return .saved
    } catch {
      recordSyncError("write_failed")
      return enqueue(
        record,
        kind: .mindfulSession,
        syncIdentifier: record.syncIdentifier,
        syncVersion: record.syncVersion
      )
    }
  }

  func retryPending(now: Date = .now) async {
    let descriptor = FetchDescriptor<PendingHealthWrite>(
      predicate: #Predicate { $0.nextRetryAt <= now },
      sortBy: [SortDescriptor(\.createdAt)]
    )
    guard let pendingWrites = try? modelContext.fetch(descriptor) else { return }

    for pendingWrite in pendingWrites {
      do {
        try await write(pendingWrite)
        modelContext.delete(pendingWrite)
      } catch is DecodingError {
        pendingWrite.lastErrorCode = "invalid_payload"
        recordSyncError("invalid_payload")
        scheduleRetry(for: pendingWrite, now: now)
      } catch {
        pendingWrite.lastErrorCode = "write_failed"
        recordSyncError("write_failed")
        scheduleRetry(for: pendingWrite, now: now)
      }
    }
    try? modelContext.save()
  }

  private func enqueue<Record: Encodable>(
    _ record: Record,
    kind: PendingHealthWriteKind,
    syncIdentifier: String,
    syncVersion: Int
  ) -> HealthWriteResult {
    do {
      let payload = try encoder.encode(record)
      let kindRawValue = kind.rawValue
      let descriptor = FetchDescriptor<PendingHealthWrite>(
        predicate: #Predicate {
          $0.syncIdentifier == syncIdentifier && $0.kindRawValue == kindRawValue
        }
      )
      if let existing = try modelContext.fetch(descriptor).first {
        guard syncVersion >= existing.syncVersion else { return .queued }
        existing.payload = payload
        existing.syncVersion = syncVersion
        existing.nextRetryAt = .now
        existing.lastErrorCode = "write_failed"
        try modelContext.save()
        return .queued
      }
      modelContext.insert(
        PendingHealthWrite(
          kind: kind,
          payload: payload,
          syncIdentifier: syncIdentifier,
          syncVersion: syncVersion,
          lastErrorCode: "write_failed"
        )
      )
      try modelContext.save()
      return .queued
    } catch {
      return .failedToQueue
    }
  }

  private func write(_ pendingWrite: PendingHealthWrite) async throws {
    switch pendingWrite.kind {
    case .stateOfMind:
      let record = try decoder.decode(StateOfMindRecord.self, from: pendingWrite.payload)
      try await writer.saveStateOfMind(record)
    case .mindfulSession:
      let record = try decoder.decode(MindfulSessionRecord.self, from: pendingWrite.payload)
      try await writer.saveMindfulSession(record)
    }
  }

  private func scheduleRetry(for pendingWrite: PendingHealthWrite, now: Date) {
    pendingWrite.attemptCount += 1
    let delay = min(pow(2, Double(pendingWrite.attemptCount - 1)) * 60, 24 * 60 * 60)
    pendingWrite.nextRetryAt = now.addingTimeInterval(delay)
  }

  private func recordSyncError(_ categoryCode: String) {
    modelContext.insert(
      LocalDiagnosticEvent(kind: .syncError, categoryCode: categoryCode)
    )
    try? modelContext.save()
  }
}
