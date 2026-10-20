import Foundation

/// Optional on historical records. Absence means legacy, never an inferred V4 protocol.
public struct PracticeSessionMetadata: Codable, Equatable, Sendable {
  public static let muscleRelaxationProtocolVersion = "fangcun-pmr-1.0"
  public let protocolVersion: String
  public let timelineVariantID: String?
  public let sceneID: String
  public let completionStatus: String
  public let completedCycles: Int
  public let activeIntervals: [PracticeActiveInterval]
  public var subjectiveFeedback: String?

  public init(protocolVersion: String = PracticeTimeline.protocolVersion, timelineVariantID: String?, sceneID: String, completionStatus: String, completedCycles: Int, activeIntervals: [PracticeActiveInterval], subjectiveFeedback: String? = nil) {
    self.protocolVersion = protocolVersion
    self.timelineVariantID = timelineVariantID
    self.sceneID = sceneID
    self.completionStatus = completionStatus
    self.completedCycles = completedCycles
    self.activeIntervals = activeIntervals
    self.subjectiveFeedback = subjectiveFeedback
  }
}

public struct PracticeActiveInterval: Codable, Equatable, Sendable {
  public let start: Date
  public let end: Date
  public var duration: TimeInterval { max(0, end.timeIntervalSince(start)) }
  public init(start: Date, end: Date) { self.start = start; self.end = max(start, end) }
}

/// A checkpoint contains only activity already observed by the running process.
/// Reopening it never extends an interval to the current wall clock.
public struct PracticeSessionCheckpoint: Codable, Equatable, Sendable {
  public var schemaVersion = 1
  public let sessionID: String
  public let kind: PracticeKind
  public let duration: TimeInterval
  public let variantID: String?
  public let startedAt: Date
  public let endedAt: Date?
  public let activeIntervals: [PracticeActiveInterval]
  public let completedCycles: Int
  public var actualDuration: TimeInterval { activeIntervals.reduce(0) { $0 + $1.duration } }

  public init(sessionID: String, kind: PracticeKind, duration: TimeInterval, variantID: String?, startedAt: Date, endedAt: Date?, activeIntervals: [PracticeActiveInterval], completedCycles: Int) {
    self.sessionID = sessionID; self.kind = kind; self.duration = duration; self.variantID = variantID
    self.startedAt = startedAt; self.endedAt = endedAt
    self.activeIntervals = activeIntervals; self.completedCycles = completedCycles
  }
  public var isValid: Bool {
    guard schemaVersion == 1, !sessionID.isEmpty, duration.isFinite, duration > 0,
      actualDuration.isFinite, actualDuration <= duration, completedCycles >= 0,
      startedAt.timeIntervalSinceReferenceDate.isFinite else { return false }
    var previousEnd = startedAt
    for interval in activeIntervals {
      guard interval.start.timeIntervalSinceReferenceDate.isFinite,
        interval.end.timeIntervalSinceReferenceDate.isFinite,
        interval.start >= previousEnd, interval.end >= interval.start else { return false }
      previousEnd = interval.end
    }
    return endedAt.map { $0.timeIntervalSinceReferenceDate.isFinite && $0 >= previousEnd } ?? true
  }
}
