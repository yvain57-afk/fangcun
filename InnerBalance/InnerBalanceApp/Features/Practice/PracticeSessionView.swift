import InnerBalanceCore
import SwiftUI

struct PracticeSessionView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.fangcunReduceMotion) private var reduceMotion
  @State private var viewModel: PracticeSessionViewModel
  @State private var beforeRating = -1.0
  @State private var afterRating = 5.0
  @State private var changeChoice: PracticeChangeChoice?
  @State private var showFinishConfirmation = false
  @State private var showExitConfirmation = false
  @State private var cadence = PracticeCadenceController()
  @State private var audio = PracticeAudioController()
  @State private var sound = PracticeSoundPreferences()
  @State private var saving: PracticeCompletionSaveController
  @State private var postValence = 0.0
  @State private var postArousal = 0.0
  @State private var hasPostPosition = false

  private let diagnostics: any LocalDiagnosticsRecording
  private let startsImmediately: Bool
  private let wasRecommended: Bool
  private let onReturnToHome: () -> Void

  init(
    launch: PracticeLaunch,
    coordinator: PracticeCompletionCoordinator,
    diagnostics: any LocalDiagnosticsRecording,
    wasRecommended: Bool,
    onReturnToHome: @escaping () -> Void = {},
    onSaved: @escaping (PracticeCompletionRecord, StateOfMindRecord?) -> Void
  ) {
    let plan = PracticeCatalog.protocol(for: launch.kind)!
    _viewModel = State(
      initialValue: PracticeSessionViewModel(plan: plan, duration: launch.duration))
    _saving = State(
      initialValue: PracticeCompletionSaveController(
        coordinator: coordinator,
        diagnostics: diagnostics,
        onSaved: onSaved
      ))
    self.startsImmediately = launch.startsImmediately
    self.diagnostics = diagnostics
    self.wasRecommended = wasRecommended
    self.onReturnToHome = onReturnToHome
  }

  var body: some View {
    NavigationStack {
      ZStack {
        PracticeSessionAtmosphere(kind: viewModel.plan.kind)
        PracticeSessionContent(
          viewModel: viewModel,
          beforeRating: $beforeRating,
          hapticCadenceEnabled: Binding(
            get: { cadence.isEnabled },
            set: { cadence.isEnabled = $0 }
          ),
          soundMode: Binding(
            get: { sound.mode(hasVoiceAssets: voiceAvailable) },
            set: { sound.preferredMode = $0 }
          ),
          ambienceEnabled: Binding(
            get: { sound.ambienceEnabled },
            set: { sound.ambienceEnabled = $0 }
          ),
          afterRating: $afterRating,
          changeChoice: $changeChoice,
          postValence: $postValence,
          postArousal: $postArousal,
          hasPostPosition: $hasPostPosition,
          reduceMotion: reduceMotion,
          isSaving: saving.isSaving,
          savedDetail: savedDetail,
          onStart: startPractice,
          onFinish: { showFinishConfirmation = true },
          onSave: { Task { await saveCompletion() } },
          onDone: {
            onReturnToHome()
            dismiss()
          }
        )
        .id(PracticeScreenIdentity.for(viewModel.phase))
        .transition(
          reduceMotion
            ? .opacity
            : .asymmetric(
              insertion: .opacity.combined(with: .scale(scale: 0.98)),
              removal: .opacity
            )
        )
        .padding(FangcunLayout.pageHorizontalPadding)
      }
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(InnerBalanceTheme.canvas, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        PracticeCloseToolbar(
          isActive: viewModel.phase == .running || viewModel.phase == .paused,
          showExitConfirmation: $showExitConfirmation,
          onDismiss: { dismiss() }
        )
      }
    }
    .interactiveDismissDisabled(viewModel.phase == .running)
    .animation(
      .timingCurve(0.23, 1, 0.32, 1, duration: 0.22),
      value: PracticeScreenIdentity.for(viewModel.phase)
    )
    .onAppear { if startsImmediately && viewModel.phase == .ready { startPractice() } }
    .task(id: viewModel.phase) { await runSessionPhase() }
    .modifier(
      PracticeAudioLifecycle(
        viewModel: viewModel,
        audio: audio,
        mode: sound.mode(hasVoiceAssets: voiceAvailable),
        ambienceEnabled: sound.ambienceEnabled
      )
    )
    .practiceSessionDialogs(
      showFinish: $showFinishConfirmation,
      showExit: $showExitConfirmation,
      saveErrorMessage: Binding(
        get: { saving.saveErrorMessage },
        set: { saving.saveErrorMessage = $0 }
      ),
      onFinish: viewModel.finish,
      onRetry: { Task { await saveCompletion() } },
      onDiscard: { dismiss() }
    )
    .sensoryFeedback(.impact(weight: .light), trigger: cadence.trigger)
  }

  private func startPractice() {
    diagnostics.record(.practiceStarted)
    if wasRecommended { diagnostics.record(.recommendationAccepted) }
    let selectedRating =
      beforeRating >= 0
      ? PracticeStartingRating.value(kind: viewModel.plan.kind, selected: beforeRating)
      : nil
    viewModel.start(beforeRating: selectedRating)
  }

  private var voiceAvailable: Bool {
    PracticeVoiceAssets.isAvailable(for: viewModel.plan.kind)
  }

  private func saveCompletion() async {
    if PracticeFeedbackPolicy.canSave(
      beforeRating: viewModel.beforeRating,
      changeChoice: changeChoice,
      hasPostPosition: hasPostPosition
    ) {
      await saving.save(
        viewModel: viewModel,
        afterRating: afterRating,
        postValence: postValence,
        postArousal: postArousal,
        hasPostPosition: hasPostPosition
      )
    } else {
      await saving.skipFeedback(viewModel: viewModel)
    }
  }

  private func runSessionPhase() async {
    if viewModel.phase == .comparison {
      await saving.saveCompletion(viewModel: viewModel)
    } else {
      await cadence.run(viewModel)
      if viewModel.phase == .comparison {
        await saving.saveCompletion(viewModel: viewModel)
      }
    }
  }

  private var savedDetail: String {
    guard saving.hasSavedFeedback else {
      return saving.healthWriteNeedsAttention
        ? "本次练习已经保存在本机，Apple 健康稍后再试。"
        : "本次练习已经保存在本机。"
    }
    return PracticeSavedCopy.detail(
      kind: viewModel.plan.kind,
      healthNeedsAttention: saving.healthWriteNeedsAttention,
      hasSubjectiveComparison: viewModel.beforeRating != nil
    )
  }
}
