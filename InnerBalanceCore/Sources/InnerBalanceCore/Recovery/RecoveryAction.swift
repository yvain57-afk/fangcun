import Foundation

public enum RecoveryActionKind: Codable, Equatable, Hashable, Sendable {
  case practice(PracticeKind)
  case movementBreak, seatedReset, quietRest
  public var id: String {
    switch self {
    case .practice(let kind): return "practice." + kind.rawValue
    case .movementBreak: return "movementBreak"
    case .seatedReset: return "seatedReset"
    case .quietRest: return "quietRest"
    }
  }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer(); try container.encode(id)
  }
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let id = try container.decode(String.self)
    if let local = Self.localActions.first(where: { $0.id == id }) { self = local; return }
    if id.hasPrefix("practice."), let kind = PracticeKind(rawValue: String(id.dropFirst(9))) { self = .practice(kind); return }
    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported recovery action")
  }
  public static let localActions: [Self] = [.movementBreak, .seatedReset, .quietRest]
}
public struct RecoveryProtocol: Equatable, Sendable {
  public var action: RecoveryActionKind
  public var version: Int = 1
  public var duration: TimeInterval
  public var preparationKey: String
  public var stageKeys: [String]
  public var safetyKey: String
  public static func local(_ action: RecoveryActionKind) -> Self? {
    guard RecoveryActionKind.localActions.contains(action) else { return nil }
    return .init(action: action, duration: action == .seatedReset ? 60 : 120,
      preparationKey: "recovery." + action.id + ".prepare",
      stageKeys: ["recovery." + action.id + ".stage1", "recovery." + action.id + ".stage2"],
      safetyKey: "recovery.safety")
  }
}
public enum RecoveryGoal: String, Codable, CaseIterable, Sendable { case rest, calm, tired, workBreak }
public enum RecoveryEnvironment: String, Codable, CaseIterable, Sendable { case seated, canMove, driving, unavailable }
public struct RecoveryRecommendation: Equatable, Sendable {
  public var action: RecoveryActionKind
  public var duration: TimeInterval
  public var reasonCodes: [String]
  public var preparationKey: String
  public var safetyKey = "recovery.safety"
}
public enum RecoveryRecommendationEngine {
  public static func recommend(assessment: ReadinessAssessment?, goal: RecoveryGoal? = nil,
    seconds: TimeInterval = 120, environment: RecoveryEnvironment = .seated,
    favorites: [RecoveryActionKind] = [], uncomfortable: Set<RecoveryActionKind> = []) -> RecoveryRecommendation? {
    guard environment != .driving, environment != .unavailable, seconds >= 60 else { return nil }
    var choices: [RecoveryActionKind]
    switch goal {
    case .workBreak: choices = environment == .canMove ? [.movementBreak, .seatedReset, .quietRest] : [.seatedReset, .quietRest]
    case .calm: choices = [.practice(.physiologicalSigh), .quietRest]
    case .tired: choices = [.quietRest, .seatedReset]
    case .rest, nil: choices = favorites + [.quietRest, .seatedReset]
    }
    // Explicit discomfort takes precedence over habits and recovery state. No psychological inference.
    for action in choices where !uncomfortable.contains(action) {
      if action == .movementBreak && environment != .canMove { continue }
      let duration = RecoveryProtocol.local(action)?.duration ?? 60
      guard duration <= seconds else { continue }
      return .init(action: action, duration: duration,
        reasonCodes: [goal?.rawValue ?? "neutral"],
        preparationKey: RecoveryProtocol.local(action)?.preparationKey ?? "recovery.breath.prepare")
    }
    return nil
  }
}
public enum RecoveryHelpfulness: String, Codable, CaseIterable, Sendable { case helpful, unchanged, uncomfortable }
public struct RecoveryFeedback: Codable, Equatable, Sendable {
  public var helpfulness: RecoveryHelpfulness?
  public var skipped: Bool
  public var revision: Int
  public var updatedAt: Date
  public var localNote: String?
  public init(helpfulness: RecoveryHelpfulness?, revision: Int, updatedAt: Date, localNote: String? = nil) {
    self.helpfulness = helpfulness; skipped = helpfulness == nil
    self.revision = revision; self.updatedAt = updatedAt; self.localNote = localNote
  }
}
public enum RecoveryEndReason: String, Codable, Sendable { case completed, endedEarly, interrupted, legacyUnknown }
public struct RecoverySession: Codable, Equatable, Sendable {
  public var sessionID: String
  public var action: RecoveryActionKind
  public var protocolVersion: Int
  public var plannedDuration: TimeInterval
  public var activeDuration: TimeInterval
  public var startedAt: Date
  public var endedAt: Date?
  public var endReason: RecoveryEndReason?
  public var originDevice: String
  public var revision: Int
  public var feedback: RecoveryFeedback?
  public var feedbackHistory: [RecoveryFeedback]
  public init(sessionID: String = UUID().uuidString, action: RecoveryActionKind, plannedDuration: TimeInterval,
    startedAt: Date, originDevice: String, protocolVersion: Int = 1) {
    self.sessionID = sessionID; self.action = action; self.plannedDuration = plannedDuration
    self.startedAt = startedAt; self.originDevice = originDevice; self.protocolVersion = protocolVersion
    activeDuration = 0; revision = 1; feedbackHistory = []
  }
}
/// Wall time is only counted while running in this process. A reopened checkpoint is interrupted.
public struct RecoverySessionClock: Sendable {
  public private(set) var session: RecoverySession
  private var runningSince: Date?
  public init(session: RecoverySession) { self.session = session }
  public var isRunning: Bool { runningSince != nil }
  public mutating func resume(at date: Date) {
    guard session.endedAt == nil, runningSince == nil else { return }
    runningSince = date
  }
  public mutating func pause(at date: Date) {
    guard let start = runningSince else { return }
    session.activeDuration = min(session.plannedDuration, session.activeDuration + max(0, date.timeIntervalSince(start)))
    runningSince = nil
  }
  public func elapsed(at date: Date) -> TimeInterval {
    min(session.plannedDuration, session.activeDuration + (runningSince.map { max(0, date.timeIntervalSince($0)) } ?? 0))
  }
  public mutating func finish(at date: Date, interrupted: Bool = false) -> RecoverySession {
    guard session.endedAt == nil else { return session }
    pause(at: date)
    session.endedAt = date
    session.endReason = interrupted ? .interrupted : session.activeDuration >= session.plannedDuration ? .completed : .endedEarly
    session.revision += 1
    return session
  }
  public mutating func checkpoint(at date: Date) -> RecoverySession {
    let running = isRunning; pause(at: date)
    session.revision += 1
    if running { resume(at: date) }
    return session
  }
}
public enum RecoveryFeedbackSummary {
  public static func counts(_ records: [RecoverySession], action: RecoveryActionKind) -> [RecoveryHelpfulness: Int]? {
    let responses = records.filter { $0.action == action }.compactMap { $0.feedback?.helpfulness }
    guard responses.count >= 5 else { return nil }
    return Dictionary(grouping: responses, by: { $0 }).mapValues(\.count)
  }
}
