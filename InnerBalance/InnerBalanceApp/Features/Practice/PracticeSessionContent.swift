import InnerBalanceCore
import SwiftUI

struct PracticeSessionContent: View {
  @Bindable var viewModel: PracticeSessionViewModel
  @Binding var beforeRating: Double
  @Binding var hapticCadenceEnabled: Bool
  @Binding var soundMode: PracticeSoundMode
  @Binding var ambienceEnabled: Bool
  @Binding var afterRating: Double
  @Binding var changeChoice: PracticeChangeChoice?
  @Binding var postValence: Double
  @Binding var postArousal: Double
  @Binding var hasPostPosition: Bool
  let reduceMotion: Bool
  let isSaving: Bool
  let savedDetail: String
  let onStart: () -> Void
  let onFinish: () -> Void
  let onSave: () -> Void
  let onDone: () -> Void

  @ViewBuilder var body: some View {
    switch viewModel.phase {
    case .ready:
      PracticePreparationScreen(
        viewModel: viewModel,
        beforeRating: $beforeRating,
        hapticCadenceEnabled: $hapticCadenceEnabled,
        soundMode: $soundMode,
        ambienceEnabled: $ambienceEnabled,
        onStart: onStart
      )
    case .running, .paused:
      PracticePlayerScreen(
        viewModel: viewModel,
        reduceMotion: reduceMotion,
        onFinish: onFinish
      )
    case .comparison:
      if viewModel.plan.kind == .progressiveMuscleRelaxation && viewModel.variantID == "pmr_sleep" {
        VStack(spacing: 20) {
          Text("Nothing more to do").font(.title2.weight(.semibold))
          Text("You can keep resting. No need to check the screen.")
            .font(.body).foregroundStyle(InnerBalanceTheme.mutedInk)
          if isSaving { ProgressView("Saving this moment") }
        }.accessibilityIdentifier("practice.pmr.sleepFinish")
      } else {
      PracticeComparisonScreen(
        viewModel: viewModel,
        afterRating: $afterRating,
        changeChoice: $changeChoice,
        postValence: $postValence,
        postArousal: $postArousal,
        hasPostPosition: $hasPostPosition,
        isSaving: isSaving,
        onSave: onSave
      )
      }
    case .saved:
      PracticeSavedScreen(detail: savedDetail, kind: viewModel.plan.kind, actualDuration: viewModel.actualDuration ?? 0,
        scene: (viewModel.actualDuration ?? 0) >= viewModel.duration - 1 ? .complete : .rest,
        onDone: onDone)
    }
  }
}
