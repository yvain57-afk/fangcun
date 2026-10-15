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
        PracticeHumanInstruction(kind: viewModel.plan.kind)
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
    .accessibilityIdentifier("practice.preparation")
    .safeAreaInset(edge: .bottom) {
      Button("开始 · \(PracticeDurationFormatter.text(viewModel.duration))", action: onStart)
        .buttonStyle(InnerBalancePrimaryButtonStyle())
        .accessibilityLabel("开始 \(PracticeDurationFormatter.text(viewModel.duration))练习")
        .accessibilityIdentifier("practice.prepare.start")
        .padding(.vertical, FangcunLayout.spacing(3))
        .background(InnerBalanceTheme.canvas)
    }
  }

}

struct PracticePlayerScreen: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @AppStorage("fangcun.motionMode") private var motionMode = "standard"
  @State private var renderRevision: UInt64 = 0
  @State private var isResuming = false
  @Bindable var viewModel: PracticeSessionViewModel
  let reduceMotion: Bool
  let onFinish: () -> Void

  var body: some View {
    // This token invalidates only the presentation; the VM remains the sole session clock.
    let _ = renderRevision
    return VStack(spacing: 0) {
        PracticeActiveStage(
          kind: viewModel.plan.kind,
          duration: viewModel.duration,
          elapsed: viewModel.phaseElapsed,
          remaining: viewModel.remainingTime,
          isPaused: viewModel.phase == .paused,
          reduceMotion: reduceMotion,
          variantID: viewModel.variantID
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      if isResuming { Text("准备好，先自然呼吸…").font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk).padding(.bottom, 12).accessibilityIdentifier("practice.resumePreparation") }
      PracticeTransportControls(
        isPaused: viewModel.phase == .paused,
        onTogglePause: togglePause,
        onFinish: { isResuming = false; onFinish() }
      )
    }
    .task(id: renderTaskID) { await refreshVisibleStage() }
    .task(id: isResuming) {
      guard isResuming else { return }
      do { try await Task.sleep(for: .seconds(2)) } catch { return }
      guard !Task.isCancelled, viewModel.phase == .paused else { return }
      isResuming = false
      viewModel.resume()
    }
    .onChange(of: viewModel.phase) { _, phase in if phase != .paused { isResuming = false } }
  }

  private var suppressAnimation: Bool {
    reduceMotion || systemReduceMotion || motionMode == "static" || ProcessInfo.processInfo.isLowPowerModeEnabled
  }

  private var renderTaskID: String {
    "\(scenePhase)-\(viewModel.phase)-\(viewModel.timelineGeneration)-\(suppressAnimation)"
  }

  @MainActor
  private func refreshVisibleStage() async {
    guard scenePhase == .active, viewModel.phase == .running else { return }
    while !Task.isCancelled, scenePhase == .active, viewModel.phase == .running {
      renderRevision &+= 1
      let interval = PracticeRenderCadence.interval(
        snapshot: viewModel.timelineSnapshot, reduceMotion: suppressAnimation
      )
      do { try await Task.sleep(for: .seconds(interval)) } catch { return }
    }
  }

  private func togglePause() {
    if isResuming { isResuming = false }
    else if viewModel.phase == .paused { isResuming = true } else { viewModel.pause() }
  }
}


struct PracticeEntryScreen: View {
  let kind: PracticeKind
  let duration: TimeInterval
  let variantID: String?
  let startedAt: Date
  let entryDuration: TimeInterval
  let onSkip: () -> Void
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text(kind.title).font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
        Text(kind == .nsdr ? "躺稳，把重量放下" : "找个舒服的姿势")
          .font(.title.weight(.semibold)).multilineTextAlignment(.center)
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
          let progress = min(1, max(0, context.date.timeIntervalSince(startedAt) / entryDuration))
          PracticeCompanionV4(kind: kind, elapsed: 0, duration: duration, variantID: variantID,
            isActive: true, entryProgress: progress)
            .frame(maxWidth: 320).frame(height: 280)
        }
        Text("先自然呼吸，准备时间不计入练习。").font(.subheadline)
          .foregroundStyle(InnerBalanceTheme.mutedInk).multilineTextAlignment(.center)
        Button("准备好了，开始", action: onSkip).buttonStyle(InnerBalancePrimaryButtonStyle())
          .accessibilityIdentifier("practice.entry.skip")
      }.padding(.vertical, 20).frame(maxWidth: .infinity)
    }.accessibilityIdentifier("practice.entry")
  }
}
