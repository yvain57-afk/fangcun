import InnerBalanceCore
import SwiftUI

struct PracticePreparationScreen: View {
  let viewModel: PracticeSessionViewModel
  @Binding var beforeRating: Double
  @Binding var hapticCadenceEnabled: Bool
  @Binding var soundMode: PracticeSoundMode
  @Binding var ambienceEnabled: Bool
  let onStart: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(7)) {
        PracticePreparationHero(kind: viewModel.plan.kind, duration: viewModel.duration)
        PracticeIntroductionCard(kind: viewModel.plan.kind)
        preparationInput
        Text("引导设置")
          .font(.title3.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.ink)
        PracticeSoundControls(
          mode: $soundMode,
          ambienceEnabled: $ambienceEnabled,
          voiceAvailable: PracticeVoiceAssets.isAvailable(for: viewModel.plan.kind)
        )
        PracticeHapticToggle(isOn: $hapticCadenceEnabled)
      }
      .padding(.vertical, FangcunLayout.spacing(3))
      .padding(.bottom, FangcunLayout.spacing(24))
    }
    .safeAreaInset(edge: .bottom) {
      Button("开始 · \(PracticeDurationFormatter.text(viewModel.duration))", action: onStart)
        .buttonStyle(InnerBalancePrimaryButtonStyle())
        .accessibilityLabel("开始 \(PracticeDurationFormatter.text(viewModel.duration))练习")
        .padding(.vertical, FangcunLayout.spacing(3))
        .background(InnerBalanceTheme.canvas)
    }
    .accessibilityIdentifier("practice.preparation")
  }

  @ViewBuilder private var preparationInput: some View {
    if PracticeCompletionMode.for(viewModel.plan.kind) == .completionOnly {
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
        Text("练习前先确认")
          .font(.caption.weight(.bold))
          .foregroundStyle(InnerBalanceTheme.emphasis)
        Text("这次只记录完成，不需要评估感受变化。")
          .font(.title3.weight(.semibold))
      }
    } else {
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
        Text("先记一下")
          .font(.caption.weight(.bold))
          .foregroundStyle(InnerBalanceTheme.emphasis)
        Text("此刻有多需要缓一缓？")
          .font(.title2.weight(.semibold))
        PracticeStartingPicker(value: $beforeRating)
      }
    }
  }
}

struct PracticePlayerScreen: View {
  @Bindable var viewModel: PracticeSessionViewModel
  let reduceMotion: Bool
  let onFinish: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      TimelineView(.periodic(from: .now, by: timelineInterval)) { _ in
        PracticeActiveStage(
          kind: viewModel.plan.kind,
          duration: viewModel.duration,
          elapsed: elapsed,
          remaining: viewModel.remainingTime,
          isPaused: viewModel.phase == .paused,
          reduceMotion: reduceMotion
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      PracticeTransportControls(
        isPaused: viewModel.phase == .paused,
        onTogglePause: togglePause,
        onFinish: onFinish
      )
    }
  }

  private var elapsed: TimeInterval {
    viewModel.duration - viewModel.remainingTime
  }

  private var timelineInterval: TimeInterval {
    PracticeTimelineCadence.interval(
      kind: viewModel.plan.kind,
      phase: viewModel.phase,
      reduceMotion: reduceMotion
    )
  }

  private func togglePause() {
    viewModel.phase == .paused ? viewModel.resume() : viewModel.pause()
  }
}
