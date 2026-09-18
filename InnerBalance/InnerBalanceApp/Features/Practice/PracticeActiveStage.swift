import InnerBalanceCore
import SwiftUI

struct PracticeActiveStage: View {
  let kind: PracticeKind
  let duration: TimeInterval
  let elapsed: TimeInterval
  let remaining: TimeInterval
  let isPaused: Bool
  let reduceMotion: Bool

  var body: some View {
    switch PracticeStageKind.for(kind) {
    case .breathing:
      BreathingFieldPlayer(
        kind: kind,
        elapsed: elapsed,
        sessionRemaining: remaining,
        isPaused: isPaused,
        reduceMotion: reduceMotion
      )
    case .settling:
      SettlingStagePlayer(
        kind: kind,
        elapsed: elapsed,
        remaining: remaining,
        isPaused: isPaused,
        reduceMotion: reduceMotion
      )
    case .bodyScan:
      BodyScanStagePlayer(
        kind: kind,
        duration: duration,
        elapsed: elapsed,
        remaining: remaining,
        isPaused: isPaused,
        reduceMotion: reduceMotion
      )
    case .pelvicFloor:
      PelvicFloorStagePlayer(
        kind: kind,
        elapsed: elapsed,
        remaining: remaining,
        isPaused: isPaused,
        reduceMotion: reduceMotion
      )
    }
  }
}

struct PracticeStageScaffold<Stage: View>: View {
  let eyebrow: String
  let title: String
  let instruction: String
  let remaining: TimeInterval
  let accessibilityIdentifier: String
  var titleAccessibilityIdentifier = "practice.stageTitle"
  var showsStageCard = true
  @ViewBuilder let stage: () -> Stage

  var body: some View {
    ScrollView {
      VStack(spacing: FangcunLayout.spacing(6)) {
        VStack(spacing: FangcunLayout.spacing(2)) {
          Text(eyebrow)
            .font(.caption.weight(.bold))
            .foregroundStyle(InnerBalanceTheme.emphasis)
          Text(title)
            .font(.system(.largeTitle, design: .default, weight: .bold))
            .foregroundStyle(InnerBalanceTheme.ink)
            .multilineTextAlignment(.center)
            .contentTransition(.opacity)
            .animation(
              .timingCurve(0.23, 1, 0.32, 1, duration: 0.18),
              value: title
            )
            .accessibilityIdentifier(titleAccessibilityIdentifier)
          Text(instruction)
            .font(.title3.weight(.medium))
            .foregroundStyle(InnerBalanceTheme.mutedInk)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        stage()
          .frame(minHeight: 272)
          .frame(maxWidth: .infinity)
          .background(
            showsStageCard ? InnerBalanceTheme.surface : .clear,
            in: RoundedRectangle(
              cornerRadius: FangcunSurface.responseCornerRadius,
              style: .continuous
            )
          )
          .overlay {
            RoundedRectangle(
              cornerRadius: FangcunSurface.responseCornerRadius,
              style: .continuous
            )
            .strokeBorder(showsStageCard ? InnerBalanceTheme.hairline : .clear, lineWidth: 1)
          }
        Text(PracticeDurationFormatter.clock(remaining))
          .font(.footnote.monospacedDigit().weight(.medium))
          .foregroundStyle(InnerBalanceTheme.mutedInk)
          .accessibilityLabel("剩余 \(PracticeDurationFormatter.clock(remaining))")
      }
      .frame(maxWidth: .infinity)
      .padding(.top, FangcunLayout.spacing(6))
      .padding(.bottom, FangcunLayout.spacing(4))
    }
    .accessibilityIdentifier(accessibilityIdentifier)
  }
}
