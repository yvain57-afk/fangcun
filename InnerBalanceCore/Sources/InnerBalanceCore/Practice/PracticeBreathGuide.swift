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
    case .inhale: "Breathe in"
    case .topUp: "A little more"
    case .exhale: "Breathe out"
    case .holdAfterInhale, .holdAfterExhale: "Gently pause"
    case .leftInhale: "Left, breathe in"
    case .rightInhale: "Right, breathe in"
    case .leftExhale: "Left, breathe out"
    case .rightExhale: "Right, breathe out"
    case .contract: "Gently lift"
    case .release: "Release fully"
    case .natural: "Breathe naturally"
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
