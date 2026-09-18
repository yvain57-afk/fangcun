import InnerBalanceCore
import SwiftUI

struct RecoveryRecommendationCard: View {
  let action: TodayRecoveryAction
  let onCheckIn: () -> Void
  let onStartPractice: (PracticeKind) -> Void
  let onStrongSurface: Bool

  init(
    action: TodayRecoveryAction,
    onCheckIn: @escaping () -> Void,
    onStartPractice: @escaping (PracticeKind) -> Void,
    onStrongSurface: Bool = false
  ) {
    self.action = action
    self.onCheckIn = onCheckIn
    self.onStartPractice = onStartPractice
    self.onStrongSurface = onStrongSurface
  }

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
      Text(sectionTitle)
        .font(.caption.weight(.semibold))
        .tracking(1.1)
        .foregroundStyle(secondaryInk)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

      switch action {
      case .practice(let practice):
        ViewThatFits(in: .horizontal) {
          HStack(alignment: .center, spacing: FangcunLayout.spacing(3)) {
            practiceSummary(practice)
              .layoutPriority(1)
            Spacer(minLength: FangcunLayout.spacing(2))
            startButton(practice)
              .frame(width: 144)
          }

          VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
            practiceSummary(practice)
            startButton(practice)
          }
        }

        adjustmentButton

      case .continueNormally:
        Text("照常进行，不需要额外练习。")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(primaryInk)
          .fixedSize(horizontal: false, vertical: true)
        adjustmentButton

      case .needsInput:
        Text("想直接弄清压力和来源，用十秒做一次判断。")
          .font(.subheadline)
          .foregroundStyle(secondaryInk)
          .fixedSize(horizontal: false, vertical: true)
        Button("判断压力与来源", action: onCheckIn)
          .buttonStyle(
            InnerBalancePrimaryButtonStyle(
              onStrongSurface: onStrongSurface,
              cornerRadius: FangcunSurface.editorialActionCornerRadius
            )
          )
          .accessibilityIdentifier("home.checkIn")
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var adjustmentButton: some View {
    Button("调整状态与来源", action: onCheckIn)
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(secondaryInk)
      .frame(minHeight: 44)
      .buttonStyle(FangcunPressButtonStyle())
      .accessibilityIdentifier("home.checkIn")
  }

  private var sectionTitle: String {
    switch action {
    case .practice: "现在做这个"
    case .continueNormally: "现在怎么做"
    case .needsInput: "下一步"
    }
  }

  private func practiceSummary(_ practice: PracticeKind) -> some View {
    Label {
      VStack(alignment: .leading, spacing: 4) {
        Text(practice.title)
          .font(.headline)
        Text(recommendationDetail(for: practice))
          .font(.caption)
          .foregroundStyle(secondaryInk)
          .fixedSize(horizontal: false, vertical: true)
      }
    } icon: {
      Image(systemName: practice.systemImage)
        .font(.title3)
        .foregroundStyle(primaryInk)
        .frame(width: 44, height: 44)
        .background(iconFill, in: Circle())
    }
    .foregroundStyle(primaryInk)
  }

  private func startButton(_ practice: PracticeKind) -> some View {
    Button(actionTitle(for: practice)) { onStartPractice(practice) }
      .buttonStyle(
        InnerBalancePrimaryButtonStyle(
          onStrongSurface: onStrongSurface,
          cornerRadius: FangcunSurface.editorialActionCornerRadius
        )
      )
      .accessibilityLabel("开始 · \(practice.title)")
      .accessibilityIdentifier("home.startRecommendation")
  }

  private func actionTitle(for practice: PracticeKind) -> String {
    switch practice {
    case .physiologicalSigh: "先缓 1 分钟"
    case .pacedBreathing: "呼吸 3 分钟"
    case .meditation: "安静 5 分钟"
    case .nsdr: "躺下休息 10 分钟"
    case .kegel: "开始 3 分钟"
    }
  }

  private var primaryInk: Color {
    onStrongSurface ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink
  }

  private var secondaryInk: Color {
    onStrongSurface
      ? InnerBalanceTheme.inverseInk.opacity(0.70) : InnerBalanceTheme.mutedInk
  }

  private var iconFill: Color {
    onStrongSurface
      ? InnerBalanceTheme.inverseInk.opacity(0.14) : InnerBalanceTheme.subtleFill
  }

  private func recommendationDetail(for practice: PracticeKind) -> String {
    switch practice {
    case .physiologicalSigh: "1 分钟 · 双重吸气后延长呼气"
    case .pacedBreathing: "3 或 5 分钟 · 跟随节奏呼吸"
    case .meditation: "5 或 10 分钟 · 安静地放松注意力"
    case .nsdr: "10 或 20 分钟 · 躺下完成深度休息"
    case .kegel: "3 分钟 · 盆底肌收紧与放松"
    }
  }
}

struct RecentPracticeRow: View {
  let practice: PracticeCompletionRecord

  var body: some View {
    HStack(alignment: .top, spacing: FangcunLayout.spacing(3)) {
      Image(systemName: "checkmark")
        .font(.title3)
        .foregroundStyle(InnerBalanceTheme.strongFill)
        .frame(width: 36, height: 44)
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
        Text("今日完成")
          .font(.caption.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.strongFill)
        Text(practice.practiceKind.title)
          .font(.headline)
        Text(changeText)
          .font(.subheadline.weight(.medium))
        Text("练习了 \(PracticeDurationFormatter.clock(practice.actualDuration))")
          .font(.caption2.monospacedDigit())
          .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, FangcunLayout.spacing(4))
    .overlay(alignment: .top) {
      FangcunEditorialRule()
        .frame(height: 1)
    }
    .overlay(alignment: .bottom) {
      FangcunEditorialRule()
        .frame(height: 1)
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("home.latestPractice")
  }

  private var changeText: String {
    guard practice.hasSubjectiveComparison else { return "已完成" }
    let change = practice.subjectiveChange
    if change == 0 { return "主观感受持平" }
    return "需要调节程度\(change < 0 ? "下降" : "上升") \(abs(change))"
  }
}

struct BodyEvidenceDisclosure: View {
  @Binding var isExpanded: Bool
  let viewModel: HomeViewModel
  let onReviewSleep: () -> Void

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(5)) {
        if viewModel.baselineDays < 5 {
          BaselineProgressView(completedDays: viewModel.baselineDays)
        }
        TrainingContextSummary(viewModel: viewModel)
        ForEach(Array(viewModel.evidence.prefix(3))) { item in
          HealthEvidenceView(evidence: item)
        }
        if viewModel.recentWorkoutProtection {
          Label("近期较长训练已从 HRV 与静息心率判断中单独处理", systemImage: "figure.run")
            .font(.caption)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        if viewModel.sleepNeedsReview {
          Button(action: onReviewSleep) {
            Label("核对睡眠数据", systemImage: "exclamationmark.bubble")
              .font(.subheadline.weight(.semibold))
          }
          .buttonStyle(.plain)
          .foregroundStyle(InnerBalanceTheme.emphasis)
          .frame(minHeight: 44, alignment: .leading)
        }
        if let lastUpdated = viewModel.lastUpdated {
          Text(
            FangcunCopy.text("body.time.fetched", FangcunCopy.timestamp(lastUpdated))
          )
          .font(.caption2)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        Text("方寸给出的是当下调节建议，不是医疗诊断。")
          .font(.caption2)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
      .padding(.top, FangcunLayout.spacing(5))
    } label: {
      Label("为什么这样判断", systemImage: "waveform.path.ecg")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.strongFill)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
    .accessibilityHint("展开查看训练、数据来源、时间和可靠性")
    .accessibilityIdentifier("home.trainingSummary")
  }
}

private struct TrainingContextSummary: View {
  let viewModel: HomeViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
      Text("训练背景").font(.subheadline.weight(.semibold))
      if let summary = viewModel.trainingSummary {
        Text(BodyLoadCardPresentation.trainingHeadline(summary)).font(.subheadline)
        Text(
          "最近一次 \(summary.latestActivityName) · "
            + "\(PracticeDurationFormatter.text(summary.latestDuration)) · "
            + "\(summary.latestEndDate.formatted(.relative(presentation: .named))) · "
            + summary.latestSourceName
        )
        .font(.caption)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
      } else {
        Text(
          viewModel.unavailableKinds.contains(.workout)
            ? "训练数据尚未可用" : BodyLoadCardPresentation.emptyTrainingMessage
        )
        .font(.caption)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}
