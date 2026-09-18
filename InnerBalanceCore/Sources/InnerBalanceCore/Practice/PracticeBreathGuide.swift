import Foundation

public enum PracticeBreathPhase: Equatable, Sendable {
  case inhale
  case topUp
  case exhale

  public var title: String {
    switch self {
    case .inhale: "吸气"
    case .topUp: "再轻吸一口"
    case .exhale: "呼气"
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
    let elapsed = max(0, elapsed)
    switch kind {
    case .physiologicalSigh:
      let position = elapsed.truncatingRemainder(dividingBy: 12)
      if position < 3 {
        return PracticeBreathState(
          phase: .inhale,
          phaseDuration: 3,
          elapsedInPhase: position
        )
      }
      if position < 5 {
        return PracticeBreathState(
          phase: .topUp,
          phaseDuration: 2,
          elapsedInPhase: position - 3
        )
      }
      return PracticeBreathState(
        phase: .exhale,
        phaseDuration: 7,
        elapsedInPhase: position - 5
      )
    case .pacedBreathing:
      let position = elapsed.truncatingRemainder(dividingBy: 10)
      if position < 4 {
        return PracticeBreathState(
          phase: .inhale,
          phaseDuration: 4,
          elapsedInPhase: position
        )
      }
      return PracticeBreathState(
        phase: .exhale,
        phaseDuration: 6,
        elapsedInPhase: position - 4
      )
    case .meditation, .nsdr, .kegel:
      return PracticeBreathState(
        phase: .inhale,
        phaseDuration: 1,
        elapsedInPhase: 0
      )
    }
  }
}
