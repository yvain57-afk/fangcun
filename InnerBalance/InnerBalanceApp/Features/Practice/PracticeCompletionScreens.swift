import InnerBalanceCore
import SwiftUI

struct PracticeComparisonScreen: View {
  let viewModel: PracticeSessionViewModel
  @Binding var afterRating: Double
  @Binding var changeChoice: PracticeChangeChoice?
  @Binding var postValence: Double
  @Binding var postArousal: Double
  @Binding var hasPostPosition: Bool
  let isSaving: Bool
  let onSave: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        PracticeCompanionV4(kind: viewModel.plan.kind, elapsed: viewModel.phaseElapsed,
          duration: viewModel.duration, variantID: viewModel.variantID, isActive: false)
          .frame(height: 190).frame(maxWidth: .infinity)
        Text((viewModel.actualDuration ?? 0) >= viewModel.duration - 1 ? "You made a little space" : "A good place to stop")
          .font(.caption.weight(.semibold)).foregroundStyle(InnerBalanceTheme.emphasis)
        Text(viewModel.plan.kind.title + " · " + PracticeDurationFormatter.clock(viewModel.actualDuration ?? 0))
          .font(.title.weight(.semibold)).accessibilityIdentifier("practice.actualSummary")
        if !PracticeTimeline.steps(for: viewModel.plan.kind, variantID: viewModel.variantID).isEmpty {
          HStack {
            Label("\(viewModel.completedCycles) rounds completed", systemImage: "checkmark.circle")
            Spacer()
            Text("Saved with the time you actually practiced").font(.caption)
          }.font(.subheadline.monospacedDigit()).foregroundStyle(Color("FangcunExhale")).fangcunPaperCard()
        }
        Text(viewModel.plan.kind.completionReview).font(.body).foregroundStyle(InnerBalanceTheme.mutedInk)
        Text(PracticeGuidanceContent.completion(for: viewModel.plan.kind))
          .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk).lineSpacing(5)
        Text("How are you feeling now?").font(.headline)
        VStack(spacing: 10) {
          ForEach(PracticeChangeChoice.allCases, id: \.self) { choice in
            Button { changeChoice = choice } label: {
              HStack { Text(choice.title); Spacer(); Image(systemName: changeChoice == choice ? "checkmark.circle.fill" : "circle") }
                .padding(16).frame(minHeight: 52)
                .background(changeChoice == choice ? InnerBalanceTheme.subtleFill : InnerBalanceTheme.surface,
                  in: RoundedRectangle(cornerRadius: 16))
            }.buttonStyle(.plain).accessibilityIdentifier("practice.feedback." + choice.title)
              .accessibilityAddTraits(changeChoice == choice ? .isSelected : [])
          }
        }
        Button(isSaving ? "Saving…" : "Save this feeling", action: onSave)
          .buttonStyle(InnerBalancePrimaryButtonStyle()).disabled(isSaving || changeChoice == nil)
          .accessibilityIdentifier("practice.feedback.save")
        Button(isSaving ? "Saving…" : "Skip and finish") {
          changeChoice = nil
          hasPostPosition = false
          onSave()
        }.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
          .disabled(isSaving).accessibilityIdentifier("practice.feedback.skip")
      }.padding(.vertical, 16).padding(.bottom, 32)
    }.accessibilityIdentifier("practice.comparison.scroll")
  }
}

struct PracticeSavedScreen: View {
  @Environment(\.fangcunReduceMotion) private var reduceMotion
  @State private var appeared = false
  @State private var completionStartedAt = Date.now
  @State private var completionFinished = false
  let detail: String
  var kind: PracticeKind? = nil
  var actualDuration: TimeInterval = 0
  var scene: FangcunCompanionScene = .complete
  let onDone: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: FangcunLayout.spacing(5)) {
        Text("Your moment")
          .fangcunSectionLabelStyle()
        if let kind {
          TimelineView(.animation(minimumInterval: 1.0 / 30, paused: completionFinished || kind == .nsdr || kind == .pacedBreathing || kind == .progressiveMuscleRelaxation || scene != .complete)) { context in
            let celebrates = kind != .nsdr && kind != .pacedBreathing && kind != .progressiveMuscleRelaxation && scene == .complete
            let progress = min(1, max(0, context.date.timeIntervalSince(completionStartedAt) / 1.6))
            PracticeCompanionV4(kind: kind, elapsed: actualDuration, duration: max(1, actualDuration),
              variantID: nil, isActive: celebrates && !completionFinished,
              completionProgress: celebrates ? progress : 0)
              .frame(height: 185)
              .frame(maxWidth: kind == .progressiveMuscleRelaxation ? 300 : .infinity)
              .opacity(appeared ? 1 : 0)
          }
        } else {
          FangcunCompanion(scene: scene, event: scene == .complete ? .completed : .endedEarly).frame(height: 185)
        }
        Text("Your practice is saved")
          .font(.title.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.ink)
          .multilineTextAlignment(.center)
        HStack(spacing: 8) {
          FangcunBrandMark(size: 24)
          Text("Little Exhale · A moment for you").font(.caption)
        }
        .foregroundStyle(InnerBalanceTheme.mutedInk)
        Text(detail)
          .font(.subheadline)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
          .multilineTextAlignment(.center)
          .padding(FangcunLayout.spacing(4))
          .frame(maxWidth: .infinity)
          .fangcunLevelOneSurface(cornerRadius: FangcunSurface.compactCornerRadius)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, FangcunLayout.spacing(8))
      .padding(.bottom, FangcunLayout.spacing(8))
    }
    .accessibilityIdentifier("practice.saved.scroll")
    .safeAreaInset(edge: .bottom) {
      Button("Back to Breathe", action: onDone)
        .buttonStyle(InnerBalancePrimaryButtonStyle())
        .accessibilityIdentifier("practice.saved.done")
        .padding(.vertical, FangcunLayout.spacing(3))
        .background(InnerBalanceTheme.canvas)
    }
    .task {
      completionStartedAt = .now
      withAnimation(
        reduceMotion ? .easeOut(duration: 0.18) : .spring(duration: 0.48, bounce: 0.12)
      ) {
        appeared = true
      }
      do { try await Task.sleep(for: .seconds(1.6)) } catch { return }
      completionFinished = true
    }
  }
}
