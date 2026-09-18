import InnerBalanceCore
import SwiftUI

struct SettlingStagePlayer: View {
  let kind: PracticeKind
  let elapsed: TimeInterval
  let remaining: TimeInterval
  let isPaused: Bool
  let reduceMotion: Bool

  private var state: PracticeStageState { .make(kind: kind, elapsed: elapsed) }

  var body: some View {
    PracticeStageScaffold(
      eyebrow: kind.outcomeTitle,
      title: isPaused ? "已暂停" : "让注意力落下来",
      instruction: isPaused ? "准备好后继续" : kind.cue(elapsed: elapsed),
      remaining: remaining,
      accessibilityIdentifier: "practice.settlingStage"
    ) {
      ZStack {
        ForEach(0..<4) { index in
          Circle()
            .stroke(
              InnerBalanceTheme.emphasis.opacity(0.22 + Double(index) * 0.10),
              lineWidth: index == state.focusIndex ? 3 : 1
            )
            .frame(width: 112 + CGFloat(index) * 40, height: 112 + CGFloat(index) * 40)
            .scaleEffect(reduceMotion ? 1 : 0.96 + state.intensity * 0.05)
            .opacity(1 - Double(index) * 0.12)
        }
        Circle()
          .fill(InnerBalanceTheme.strongFill.opacity(0.78))
          .frame(width: 28, height: 28)
          .scaleEffect(reduceMotion ? 1 : 0.82 + state.intensity * 0.24)
      }
      .accessibilityHidden(true)
    }
  }
}

struct BodyScanStagePlayer: View {
  let kind: PracticeKind
  let duration: TimeInterval
  let elapsed: TimeInterval
  let remaining: TimeInterval
  let isPaused: Bool
  let reduceMotion: Bool

  private var state: PracticeBodyScanState {
    .make(elapsed: elapsed, duration: duration)
  }

  var body: some View {
    PracticeStageScaffold(
      eyebrow: kind.outcomeTitle,
      title: isPaused ? "已暂停" : state.isReturning ? "慢慢回到此刻" : "把重量交给支撑面",
      instruction: isPaused ? "准备好后继续" : state.cue.spokenText,
      remaining: remaining,
      accessibilityIdentifier: "practice.bodyScanStage"
    ) {
      VStack(spacing: FangcunLayout.spacing(3)) {
        ForEach(0..<4) { index in
          ZStack {
            Capsule()
              .fill(InnerBalanceTheme.subtleFill)
            Capsule()
              .fill(InnerBalanceTheme.strongFill)
              .scaleEffect(
                x: reduceMotion ? 1 : index == state.focusIndex ? 1.04 : 0.96,
                y: reduceMotion ? 1 : index == state.focusIndex ? 1.34 : 1
              )
              .opacity(state.focusIndex == nil ? 0.36 : index == state.focusIndex ? 0.92 : 0)
          }
          .frame(width: 112 + CGFloat(index) * 28, height: 12)
          .animation(
            reduceMotion
              ? .easeOut(duration: 0.18)
              : .timingCurve(0.23, 1, 0.32, 1, duration: 0.22),
            value: state.focusIndex
          )
        }
      }
      .frame(maxHeight: .infinity)
      .accessibilityHidden(true)
    }
  }
}

struct PelvicFloorStagePlayer: View {
  let kind: PracticeKind
  let elapsed: TimeInterval
  let remaining: TimeInterval
  let isPaused: Bool
  let reduceMotion: Bool

  private var state: PracticeStageState { .make(kind: kind, elapsed: elapsed) }

  var body: some View {
    PracticeStageScaffold(
      eyebrow: kind.outcomeTitle,
      title: isPaused ? "已暂停" : state.focusIndex == 0 ? "轻轻收紧" : "完全放松",
      instruction: isPaused ? "保持自然呼吸，准备好再继续" : "肩膀和腹部不用帮忙",
      remaining: remaining,
      accessibilityIdentifier: "practice.pelvicFloorStage"
    ) {
      ZStack {
        ForEach([1.0, 0.78, 0.56], id: \.self) { scale in
          Capsule()
            .stroke(
              InnerBalanceTheme.emphasis.opacity(0.28 + scale * 0.24),
              lineWidth: scale == 0.56 ? 2 : 1
            )
            .frame(width: 152 * scale, height: 228 * scale)
        }
        Capsule()
          .fill(state.focusIndex == 0 ? InnerBalanceTheme.strongFill : InnerBalanceTheme.subtleFill)
          .frame(width: 56, height: 112)
          .overlay {
            Capsule()
              .stroke(InnerBalanceTheme.emphasis.opacity(0.72), lineWidth: 2)
          }
          .scaleEffect(
            x: reduceMotion ? 0.82 : 0.72 + state.intensity * 0.22,
            y: reduceMotion ? 0.82 : 0.68 + state.intensity * 0.28
          )
          .offset(y: reduceMotion ? 0 : -state.intensity * 12)
          .opacity(reduceMotion ? (state.focusIndex == 0 ? 0.9 : 0.62) : 0.86)
      }
      .accessibilityHidden(true)
    }
  }
}
