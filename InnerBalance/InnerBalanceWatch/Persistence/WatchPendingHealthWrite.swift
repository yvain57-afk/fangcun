import Foundation
import HealthKit
import InnerBalanceCore
import SwiftData

@Model
final class WatchPendingHealthWrite {
  @Attribute(.unique) var syncIdentifier: String
  var payload: Data
  var createdAt: Date
  var attemptCount: Int
  var nextRetryAt: Date = Date.distantPast
  var lastErrorCode: String = ""
  var isTerminal: Bool = false

  init(
    syncIdentifier: String,
    payload: Data,
    createdAt: Date = .now,
    lastErrorCode: String
  ) {
    self.syncIdentifier = syncIdentifier
    self.payload = payload
    self.createdAt = createdAt
    attemptCount = 0
    nextRetryAt = createdAt
    self.lastErrorCode = lastErrorCode
    isTerminal = false
  }
}

struct WatchPendingSummary: Equatable, Sendable {
  let totalCount: Int
  let terminalCount: Int
  let authorizationRequiredCount: Int
}

@MainActor
final class WatchHealthWriteCoordinator {
  private let repository: WatchHealthRepository
  private let modelContext: ModelContext
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init(repository: WatchHealthRepository, modelContext: ModelContext) {
    self.repository = repository
    self.modelContext = modelContext
  }

  func save(_ payload: WatchHealthPayload) async -> Bool {
    guard await repository.requestBasicAuthorization() else {
      return enqueue(payload, errorCode: "authorization_required")
    }
    guard repository.hasWriteAuthorization(for: payload) else {
      return enqueue(payload, errorCode: "authorization_required")
    }
    do {
      try await repository.save(payload)
      return true
    } catch {
      return enqueue(payload, errorCode: Self.errorCode(for: error))
    }
  }

  func retryPending(now: Date = .now, force: Bool = false) async {
    let descriptor =
      if force {
        FetchDescriptor<WatchPendingHealthWrite>(
          predicate: #Predicate { !$0.isTerminal },
          sortBy: [SortDescriptor(\.createdAt)]
        )
      } else {
        FetchDescriptor<WatchPendingHealthWrite>(
          predicate: #Predicate { !$0.isTerminal && $0.nextRetryAt <= now },
          sortBy: [SortDescriptor(\.createdAt)]
        )
      }
    guard let writes = try? modelContext.fetch(descriptor) else {
      return
    }
    guard !writes.isEmpty else { return }
    guard await repository.requestBasicAuthorization() else {
      for write in writes {
        scheduleRetry(write, now: now, errorCode: "authorization_required")
      }
      try? modelContext.save()
      return
    }
    for write in writes {
      do {
        let payload = try decoder.decode(WatchHealthPayload.self, from: write.payload)
        guard repository.hasWriteAuthorization(for: payload) else {
          scheduleRetry(write, now: now, errorCode: "authorization_required")
          continue
        }
        try await repository.save(payload)
        modelContext.delete(write)
      } catch is DecodingError {
        write.lastErrorCode = "invalid_payload"
        write.isTerminal = true
      } catch {
        scheduleRetry(write, now: now, errorCode: Self.errorCode(for: error))
      }
    }
    try? modelContext.save()
  }

  var pendingCount: Int {
    pendingSummary.totalCount
  }

  var pendingSummary: WatchPendingSummary {
    let writes =
      (try? modelContext.fetch(FetchDescriptor<WatchPendingHealthWrite>())) ?? []
    return WatchPendingSummary(
      totalCount: writes.count,
      terminalCount: writes.filter(\.isTerminal).count,
      authorizationRequiredCount: writes.filter { $0.lastErrorCode == "authorization_required" }
        .count
    )
  }

  func discardTerminalWrites() {
    let descriptor = FetchDescriptor<WatchPendingHealthWrite>(
      predicate: #Predicate { $0.isTerminal }
    )
    guard let writes = try? modelContext.fetch(descriptor) else { return }
    for write in writes {
      modelContext.delete(write)
    }
    try? modelContext.save()
  }

  private func enqueue(_ payload: WatchHealthPayload, errorCode: String) -> Bool {
    do {
      let data = try encoder.encode(payload)
      let identifier = payload.syncIdentifier
      let descriptor = FetchDescriptor<WatchPendingHealthWrite>(
        predicate: #Predicate { $0.syncIdentifier == identifier }
      )
      if let existing = try modelContext.fetch(descriptor).first {
        existing.payload = data
        existing.lastErrorCode = errorCode
        existing.nextRetryAt = .now
        existing.isTerminal = false
      } else {
        modelContext.insert(
          WatchPendingHealthWrite(
            syncIdentifier: identifier,
            payload: data,
            lastErrorCode: errorCode
          )
        )
      }
      try modelContext.save()
      return true
    } catch {
      return false
    }
  }

  private func scheduleRetry(
    _ write: WatchPendingHealthWrite,
    now: Date,
    errorCode: String
  ) {
    write.attemptCount += 1
    write.lastErrorCode = errorCode
    write.nextRetryAt = now.addingTimeInterval(
      PendingRetryPolicy.delay(afterAttempt: write.attemptCount)
    )
  }

  private static func errorCode(for error: any Error) -> String {
    let error = error as NSError
    guard error.domain == HKErrorDomain else { return "write_failed" }
    let authorizationCodes: Set<Int> = [
      HKError.Code.errorAuthorizationDenied.rawValue,
      HKError.Code.errorAuthorizationNotDetermined.rawValue,
      HKError.Code.errorHealthDataRestricted.rawValue,
      HKError.Code.errorRequiredAuthorizationDenied.rawValue,
    ]
    return authorizationCodes.contains(error.code) ? "authorization_required" : "write_failed"
  }
}

extension WatchHealthPayload {
  fileprivate var syncIdentifier: String {
    switch self {
    case .stateOfMind(let payload): payload.syncIdentifier
    case .mindful(let payload): payload.syncIdentifier
    }
  }
}
