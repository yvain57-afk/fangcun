import Foundation
import InnerBalanceCore
import SwiftData

@Model
final class WatchPracticeCompletion {
  @Attribute(.unique) var sessionID: String
  var practiceKindRawValue: String
  var startedAt: Date?
  var plannedDuration: TimeInterval?
  var activeDuration: TimeInterval
  var endedAt: Date
  var healthWriteStatus: String

  init(
    sessionID: String,
    practiceKind: PracticeKind,
    activeDuration: TimeInterval,
    endedAt: Date,
    healthWriteStatus: String
  ) {
    self.sessionID = sessionID
    practiceKindRawValue = practiceKind.rawValue
    self.activeDuration = activeDuration
    self.endedAt = endedAt
    self.healthWriteStatus = healthWriteStatus
  }
}
