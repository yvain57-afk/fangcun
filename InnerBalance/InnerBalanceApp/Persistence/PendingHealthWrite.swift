import Foundation
import SwiftData

enum PendingHealthWriteKind: String, Codable, Sendable {
  case stateOfMind
  case mindfulSession
}

@Model
final class PendingHealthWrite {
  @Attribute(.unique) var id: UUID
  var kindRawValue: String
  var payload: Data
  var syncIdentifier: String
  var syncVersion: Int
  var createdAt: Date
  var attemptCount: Int
  var nextRetryAt: Date
  var lastErrorCode: String?

  var kind: PendingHealthWriteKind {
    get { PendingHealthWriteKind(rawValue: kindRawValue) ?? .stateOfMind }
    set { kindRawValue = newValue.rawValue }
  }

  init(
    id: UUID = UUID(),
    kind: PendingHealthWriteKind,
    payload: Data,
    syncIdentifier: String,
    syncVersion: Int,
    createdAt: Date = .now,
    attemptCount: Int = 0,
    nextRetryAt: Date = .now,
    lastErrorCode: String? = nil
  ) {
    self.id = id
    kindRawValue = kind.rawValue
    self.payload = payload
    self.syncIdentifier = syncIdentifier
    self.syncVersion = syncVersion
    self.createdAt = createdAt
    self.attemptCount = attemptCount
    self.nextRetryAt = nextRetryAt
    self.lastErrorCode = lastErrorCode
  }
}
