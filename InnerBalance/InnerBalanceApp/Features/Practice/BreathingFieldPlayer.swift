import InnerBalanceCore
import SwiftUI

enum BreathingFieldPresentation {
  static func targetExpansion(for phase: PracticeBreathPhase, kind: PracticeKind) -> Double {
    switch phase {
    case .inhale: kind == .physiologicalSigh ? 0.82 : 1
    case .topUp: 1
    case .exhale: 0.28
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
    case .inhale: 0.28
    case .topUp: 0.82
    case .exhale: 1
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

  private var state: PracticeBreathState {
    PracticeBreathGuide.state(for: kind, elapsed: elapsed)
  }

  var body: some View {
    PracticeStageScaffold(
      eyebrow: kind == .physiologicalSigh ? "双吸一呼" : "舒缓呼吸",
      title: isPaused ? "已暂停" : state.phase.title,
      instruction: isPaused ? "准备好后，从这里接着来" : instruction,
      remaining: sessionRemaining,
      accessibilityIdentifier: "practice.breathGuide",
      titleAccessibilityIdentifier: "practice.breathPhase",
      showsStageCard: false
    ) {
      ZStack {
        ForEach([0.82, 1.0, 1.18], id: \.self) { scale in
          Circle().stroke(InnerBalanceTheme.strongFill.opacity(0.09), lineWidth: 1)
            .scaleEffect(scale * (0.86 + (reduceMotion ? 0.12 : BreathingFieldPresentation.currentExpansion(for: state, kind: kind) * 0.14)))
        }
        FangcunCompanion(scene: .breathe,
          breath: reduceMotion ? 0 : BreathingFieldPresentation.currentExpansion(for: state, kind: kind),
          paused: isPaused)
          .frame(width: 210, height: 210)
          .clipShape(Circle())
      }.frame(width: 260, height: 260)

    }
  }

  private var instruction: String {
    switch (kind, state.phase) {
    case (.physiologicalSigh, .inhale): "用鼻子轻轻吸气"
    case (.physiologicalSigh, .topUp): "再补一小口"
    case (.physiologicalSigh, .exhale): "松开嘴唇，慢慢呼尽"
    case (.pacedBreathing, .inhale): "轻轻吸气，不必吸满"
    case (.pacedBreathing, .exhale): "让呼气比吸气更长"
    default: "跟着场域的开合呼吸"
    }
  }
}

private struct BreathingOrbField: View {
  let expansion: Double
  let phase: PracticeBreathPhase
  let reduceMotion: Bool

  var body: some View {
    ZStack {
      ForEach(Array([0.72, 0.90, 1.08].enumerated()), id: \.offset) { index, scale in
        Circle()
          .stroke(
            InnerBalanceTheme.hairline.opacity(0.72 + Double(index) * 0.12),
            lineWidth: 1
          )
          .scaleEffect(scale * (0.82 + expansion * 0.16))
      }
      Circle()
        .fill(InnerBalanceTheme.subtleFill.opacity(0.82))
        .frame(width: 184, height: 184)
        .scaleEffect(0.68 + expansion * 0.30)
      Circle()
        .stroke(
          InnerBalanceTheme.emphasis.opacity(phaseStrokeOpacity),
          lineWidth: phaseLineWidth
        )
        .frame(width: 142, height: 142)
        .scaleEffect(0.72 + expansion * 0.26)
      Circle()
        .fill(InnerBalanceTheme.strongFill.opacity(phaseCoreOpacity))
        .frame(width: 54, height: 54)
        .scaleEffect(0.82 + expansion * 0.22)
      Circle()
        .fill(InnerBalanceTheme.elevatedSurface)
        .frame(width: 16, height: 16)
        .overlay { Circle().stroke(InnerBalanceTheme.hairline, lineWidth: 1) }
    }
    .frame(width: 260, height: 260)
    .opacity(reduceMotion ? phaseOpacity : 1)
    .animation(
      .timingCurve(0.23, 1, 0.32, 1, duration: 0.20),
      value: phase
    )
    .accessibilityHidden(true)
  }

  private var phaseLineWidth: CGFloat {
    switch phase {
    case .inhale: 2
    case .topUp: 4
    case .exhale: 1
    }
  }

  private var phaseStrokeOpacity: Double {
    switch phase {
    case .inhale: 0.72
    case .topUp: 1
    case .exhale: 0.52
    }
  }

  private var phaseCoreOpacity: Double {
    switch phase {
    case .inhale: 0.78
    case .topUp: 1
    case .exhale: 0.58
    }
  }

  private var phaseOpacity: Double {
    switch phase {
    case .inhale: 0.72
    case .topUp: 1
    case .exhale: 0.48
    }
  }
}
