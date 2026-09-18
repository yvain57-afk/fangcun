import Foundation

public struct WatchPracticeCompletionSnapshot: Equatable, Sendable {
  public let sessionID: String
  public let endedAt: Date
  public let activeDuration: TimeInterval
  public let heartRateEvidenceRequested: Bool
  public let heartRateEvidence: HeartRateEvidence?
  public let heartRateEvidenceCaptureCompleted: Bool

  fileprivate init(
    sessionID: String,
    endedAt: Date,
    activeDuration: TimeInterval,
    heartRateEvidenceRequested: Bool,
    heartRateEvidence: HeartRateEvidence?,
    heartRateEvidenceCaptureCompleted: Bool
  ) {
    self.sessionID = sessionID
    self.endedAt = endedAt
    self.activeDuration = activeDuration
    self.heartRateEvidenceRequested = heartRateEvidenceRequested
    self.heartRateEvidence = heartRateEvidence
    self.heartRateEvidenceCaptureCompleted = heartRateEvidenceCaptureCompleted
  }
}

public struct WatchPracticeCompletionFreezer: Equatable, Sendable {
  public private(set) var snapshot: WatchPracticeCompletionSnapshot?

  public init() {}

  public mutating func freeze(
    sessionID: String,
    endedAt: Date,
    activeDuration: TimeInterval,
    heartRateEvidenceRequested: Bool
  ) -> WatchPracticeCompletionSnapshot {
    if let snapshot {
      return snapshot
    }
    let frozen = WatchPracticeCompletionSnapshot(
      sessionID: sessionID,
      endedAt: endedAt,
      activeDuration: activeDuration,
      heartRateEvidenceRequested: heartRateEvidenceRequested,
      heartRateEvidence: nil,
      heartRateEvidenceCaptureCompleted: !heartRateEvidenceRequested
    )
    snapshot = frozen
    return frozen
  }

  public mutating func completeHeartRateEvidenceCapture(
    _ evidence: HeartRateEvidence?
  ) -> WatchPracticeCompletionSnapshot? {
    guard let snapshot else { return nil }
    guard !snapshot.heartRateEvidenceCaptureCompleted else { return snapshot }
    let completed = WatchPracticeCompletionSnapshot(
      sessionID: snapshot.sessionID,
      endedAt: snapshot.endedAt,
      activeDuration: snapshot.activeDuration,
      heartRateEvidenceRequested: snapshot.heartRateEvidenceRequested,
      heartRateEvidence: evidence,
      heartRateEvidenceCaptureCompleted: true
    )
    self.snapshot = completed
    return completed
  }
}

public enum HeartRateEvidenceRequestCompatibility {
  public static func resolved(
    explicitRequest: Bool?,
    evidence: HeartRateEvidence?
  ) -> Bool {
    explicitRequest ?? (evidence != nil)
  }
}
