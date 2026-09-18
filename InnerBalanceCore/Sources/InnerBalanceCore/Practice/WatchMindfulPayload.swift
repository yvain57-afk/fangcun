import Foundation

public struct WatchMindfulPayload: Codable, Equatable, Sendable {
  public let syncIdentifier: String
  public let sessionID: String
  public let practiceKindRawValue: String
  public let startDate: Date
  public let endDate: Date
  public let heartRateEvidenceRequested: Bool?
  public let heartRateEvidence: HeartRateEvidence?

  public init(
    syncIdentifier: String,
    sessionID: String,
    practiceKind: PracticeKind,
    startDate: Date,
    endDate: Date,
    heartRateEvidenceRequested: Bool = false,
    heartRateEvidence: HeartRateEvidence? = nil
  ) {
    self.syncIdentifier = syncIdentifier
    self.sessionID = sessionID
    practiceKindRawValue = practiceKind.rawValue
    self.startDate = startDate
    self.endDate = endDate
    self.heartRateEvidenceRequested = heartRateEvidenceRequested
    self.heartRateEvidence = heartRateEvidence
  }
}
