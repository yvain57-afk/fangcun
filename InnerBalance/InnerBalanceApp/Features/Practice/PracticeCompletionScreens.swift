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

  private var canSaveFeedback: Bool {
    PracticeFeedbackPolicy.canSave(
      beforeRating: viewModel.beforeRating,
      changeChoice: changeChoice,
      hasPostPosition: hasPostPosition
    )
  }

  var body: some View {
    if PracticeCompletionMode.for(viewModel.plan.kind) == .completionOnly {
      KegelCompletionPrompt(isSaving: isSaving, onSave: onSave)
    } else {
      ScrollView {
        VStack(alignment: .leading, spacing: FangcunLayout.spacing(7)) {
          FangcunCompanion(scene: viewModel.actualDuration ?? 0 >= viewModel.duration - 1 ? .complete : .rest, paused: true)
            .frame(height: 155).frame(maxWidth: .infinity)
          VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
            Text("已经为自己留了片刻")
              .font(.caption.weight(.bold))
              .foregroundStyle(InnerBalanceTheme.emphasis)
            Text("现在感觉怎么样？")
              .font(.title.weight(.semibold))
              .foregroundStyle(InnerBalanceTheme.ink)
              .fixedSize(horizontal: false, vertical: true)
          }
          if let beforeRating = viewModel.beforeRating {
            PracticeChangePicker(
              selection: $changeChoice,
              beforeRating: beforeRating,
              afterRating: $afterRating
            )
          }
          PostPracticeCompassPicker(
            valence: $postValence,
            arousal: $postArousal,
            hasSelection: $hasPostPosition
          )
          Button(
            isSaving
              ? "正在保存…"
              : viewModel.beforeRating == nil ? "保留现在的感受" : "保留这次变化",
            action: onSave
          )
          .buttonStyle(InnerBalancePrimaryButtonStyle())
          .disabled(isSaving || !canSaveFeedback)
          .opacity(canSaveFeedback ? 1 : 0.42)
          Button(isSaving ? "正在保存…" : "先完成") {
            changeChoice = nil
            hasPostPosition = false
            onSave()
          }
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.strongFill)
          .frame(maxWidth: .infinity, minHeight: 44)
          .disabled(isSaving)
        }
        .padding(.vertical, FangcunLayout.spacing(4))
        .padding(.bottom, FangcunLayout.spacing(10))
      }
      .accessibilityIdentifier("practice.comparison.scroll")
    }
  }
}

private struct KegelCompletionPrompt: View {
  let isSaving: Bool
  let onSave: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(5)) {
        Text("身体训练完成")
          .fangcunSectionLabelStyle()
        Text("已完成一轮收紧和放松")
          .font(.title.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.ink)
          .fixedSize(horizontal: false, vertical: true)
        Text("这里只记录本次完成，不要求评价感受变化。")
          .font(.body)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, FangcunLayout.spacing(8))
      .padding(.bottom, FangcunLayout.spacing(20))
    }
    .accessibilityIdentifier("practice.completionOnly.scroll")
    .safeAreaInset(edge: .bottom) {
      Button(isSaving ? "正在保存…" : "记录本次完成", action: onSave)
        .buttonStyle(InnerBalancePrimaryButtonStyle())
        .disabled(isSaving)
        .padding(.vertical, FangcunLayout.spacing(3))
        .background(InnerBalanceTheme.canvas)
    }
  }
}

struct PracticeSavedScreen: View {
  @Environment(\.fangcunReduceMotion) private var reduceMotion
  @State private var appeared = false
  let detail: String
  var scene: FangcunCompanionScene = .complete
  let onDone: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: FangcunLayout.spacing(5)) {
        Text("练习结果")
          .fangcunSectionLabelStyle()
        FangcunCompanion(scene: scene, event: scene == .complete ? .completed : .endedEarly)
          .frame(height: 185)
        .opacity(appeared ? 1 : 0)
        Text("本次练习已保存")
          .font(.title.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.ink)
          .multilineTextAlignment(.center)
        HStack(spacing: 8) {
          FangcunBrandMark(size: 24)
          Text("方寸 · 片刻").font(.caption)
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
      Button("回到今日", action: onDone)
        .buttonStyle(InnerBalancePrimaryButtonStyle())
        .accessibilityIdentifier("practice.saved.done")
        .padding(.vertical, FangcunLayout.spacing(3))
        .background(InnerBalanceTheme.canvas)
    }
    .task {
      withAnimation(
        reduceMotion ? .easeOut(duration: 0.18) : .spring(duration: 0.48, bounce: 0.12)
      ) {
        appeared = true
      }
    }
  }
}
