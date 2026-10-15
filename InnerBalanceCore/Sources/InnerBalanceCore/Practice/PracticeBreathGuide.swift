import Foundation

public enum PracticeBreathPhase: Equatable, Sendable {
  case inhale
  case topUp
  case exhale
  case holdAfterInhale, holdAfterExhale
  case leftInhale, rightExhale, rightInhale, leftExhale
  case contract, release, natural

  public var title: String {
    switch self {
    case .inhale: "吸气"
    case .topUp: "再轻吸一口"
    case .exhale: "呼气"
    case .holdAfterInhale, .holdAfterExhale: "轻松停留"
    case .leftInhale: "左侧吸气"
    case .rightInhale: "右侧吸气"
    case .leftExhale: "左侧呼气"
    case .rightExhale: "右侧呼气"
    case .contract: "轻轻收紧"
    case .release: "完全放松"
    case .natural: "自然呼吸"
    }
  }
}

public struct PracticeBreathState: Equatable, Sendable {
  public let phase: PracticeBreathPhase
  public let phaseDuration: TimeInterval
  public let elapsedInPhase: TimeInterval

  public var progress: Double {
    guard phaseDuration > 0 else { return 0 }
    return min(max(elapsedInPhase / phaseDuration, 0), 1)
  }

  public var remainingWholeSeconds: Int {
    max(1, Int((phaseDuration - elapsedInPhase).rounded(.up)))
  }
}

public enum PracticeBreathGuide {
  public static func state(
    for kind: PracticeKind,
    elapsed: TimeInterval
  ) -> PracticeBreathState {
    let snapshot = PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: PracticeCatalog.protocol(for: kind)?.defaultDuration ?? 300)
    return PracticeBreathState(phase: snapshot.phase ?? .natural, phaseDuration: snapshot.phaseDuration, elapsedInPhase: snapshot.elapsedInPhase)
  }
}
