import InnerBalanceCore
import SwiftUI

enum BreathingFieldPresentation {
  static func targetExpansion(for phase: PracticeBreathPhase, kind: PracticeKind) -> Double {
    switch phase {
    case .inhale, .leftInhale, .rightInhale: kind == .physiologicalSigh ? 0.82 : 1
    case .topUp: 1
    case .exhale, .leftExhale, .rightExhale, .holdAfterExhale, .release: 0.28
    case .holdAfterInhale, .contract: 1
    case .natural: 0.5
    }
  }

  static func usesPhysicalTranslation(reduceMotion: Bool) -> Bool { !reduceMotion }

  static func currentExpansion(for state: PracticeBreathState, kind: PracticeKind) -> Double {
    let start = startExpansion(for: state.phase, kind: kind)
    let target = targetExpansion(for: state.phase, kind: kind)
    return start + (target - start) * timingCurveProgress(state.progress)
  }

  static func remainingAnimationDuration(for state: PracticeBreathState) -> TimeInterval {
    max(0, state.phaseDuration - state.elapsedInPhase)
  }

  static func startExpansion(for phase: PracticeBreathPhase, kind _: PracticeKind) -> Double {
    switch phase {
    case .inhale, .leftInhale, .rightInhale, .holdAfterExhale, .release: 0.28
    case .topUp: 0.82
    case .exhale, .leftExhale, .rightExhale, .holdAfterInhale, .contract: 1
    case .natural: 0.5
    }
  }

  static func timingCurveProgress(_ progress: Double) -> Double {
    let progress = min(max(progress, 0), 1)
    var parameter = progress
    for _ in 0..<8 {
      let error = cubicBezier(parameter, control1: 0.4, control2: 0.2) - progress
      let slope = cubicBezierDerivative(parameter, control1: 0.4, control2: 0.2)
      guard abs(slope) > 0.000_001 else { break }
      parameter = min(max(parameter - error / slope, 0), 1)
    }
    return cubicBezier(parameter, control1: 0, control2: 1)
  }

  private static func cubicBezier(_ value: Double, control1: Double, control2: Double) -> Double {
    let inverse = 1 - value
    return 3 * inverse * inverse * value * control1
      + 3 * inverse * value * value * control2
      + value * value * value
  }

  private static func cubicBezierDerivative(
    _ value: Double,
    control1: Double,
    control2: Double
  ) -> Double {
    let inverse = 1 - value
    return 3 * inverse * inverse * control1
      + 6 * inverse * value * (control2 - control1)
      + 3 * value * value * (1 - control2)
  }
}

struct BreathingFieldPlayer: View {
  let kind: PracticeKind
  let elapsed: TimeInterval
  let sessionRemaining: TimeInterval
  let isPaused: Bool
  let reduceMotion: Bool
  var variantID: String? = nil
  private var snapshot: PracticeTimelineSnapshot {
    PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: elapsed + sessionRemaining, variantID: variantID)
  }
  var body: some View {
    PracticeStageScaffold(eyebrow: kind.outcomeTitle,
      title: isPaused ? "已暂停" : snapshot.phase?.title ?? "自然呼吸",
      instruction: isPaused ? "先自然呼吸，准备好再继续" : instruction,
      remaining: sessionRemaining, accessibilityIdentifier: "practice.breathGuide",
      titleAccessibilityIdentifier: "practice.breathPhase", showsStageCard: false) {
        PracticeCompanionV4(kind: kind, elapsed: elapsed, duration: elapsed + sessionRemaining,
          variantID: variantID, isActive: !isPaused)
          .frame(maxWidth: 320).frame(height: 280)
    }
  }
  private var instruction: String {
    switch snapshot.phase {
    case .inhale, .rightInhale, .leftInhale: "轻轻吸气，不必吸满"
    case .topUp: "再补一小口，比刚才更轻"
    case .exhale, .rightExhale, .leftExhale: kind == .pacedBreathing ? "让呼气比吸气更长" : "轻柔、慢慢地呼出"
    case .holdAfterInhale, .holdAfterExhale: "轻松停留，不用忍耐憋气；不舒服就自然呼吸"
    default: "跟随自己的舒适节奏"
    }
  }
}
