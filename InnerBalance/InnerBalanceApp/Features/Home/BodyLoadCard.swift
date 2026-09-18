import InnerBalanceCore
import SwiftUI

enum BodyLoadCardPresentation {
  static let emptyTrainingMessage = "近 24 小时未读到训练记录"

  static func trainingHeadline(_ summary: HomeTrainingSummary) -> String {
    let minutes = max(1, Int(summary.totalDuration / 60))
    let duration = minutes < 60 ? "\(minutes) 分" : "\(minutes / 60) 小时 \(minutes % 60) 分"
    return "近 24 小时 · \(summary.count) 次 · \(duration)"
  }

  static func hasReliableEvidence(_ evidence: [HomeHealthEvidence]) -> Bool {
    evidence.contains { $0.reliability == .reliable }
  }

  static func inferredStressSource(
    evidence: [HomeHealthEvidence],
    recentWorkoutProtection: Bool
  ) -> CurrentStressSource? {
    let elevated = evidence.filter {
      $0.reliability == .reliable && $0.deviation == .elevated
    }
    if elevated.contains(where: { $0.kind == .sleep }) {
      return .sleep
    }
    if recentWorkoutProtection,
      elevated.contains(where: {
        $0.kind == .heartRateVariability || $0.kind == .restingHeartRate
      })
    {
      return .training
    }
    return elevated.isEmpty ? nil : .bodySignals
  }

  static func isWorkoutProtected(
    level: BodyLoadLevel,
    recentWorkoutProtection: Bool,
    evidence: [HomeHealthEvidence]
  ) -> Bool {
    guard level == .steady, recentWorkoutProtection else { return false }
    return evidence.contains {
      $0.reliability == .reliable && $0.deviation == .elevated
        && ($0.kind == .heartRateVariability || $0.kind == .restingHeartRate)
    }
  }

  static func actionTitle(
    for level: BodyLoadLevel,
    evidence: [HomeHealthEvidence],
    recentWorkoutProtection: Bool = false
  ) -> String {
    if isWorkoutProtected(
      level: level,
      recentWorkoutProtection: recentWorkoutProtection,
      evidence: evidence
    ) {
      return "训练后先恢复"
    }
    return switch level {
    case .buildingBaseline: "照常安排"
    case .steady: hasReliableEvidence(evidence) ? "可以推进" : "照常安排"
    case .watch: "今天收着一点"
    case .elevated: "优先恢复"
    }
  }

  static func actionDetail(
    for level: BodyLoadLevel,
    evidence: [HomeHealthEvidence],
    recentWorkoutProtection: Bool
  ) -> String {
    if isWorkoutProtected(
      level: level,
      recentWorkoutProtection: recentWorkoutProtection,
      evidence: evidence
    ) {
      return "近期训练正在扰动训练敏感指标。今天先恢复，晚些再看。"
    }
    return switch level {
    case .buildingBaseline:
      evidence.isEmpty ? "目前没有足够证据改变今天的安排。" : "现有读数先用于建立个人参考；今天按原计划进行。"
    case .steady:
      hasReliableEvidence(evidence)
        ? "近期可靠指标在个人参考范围内，今天的安排可以照常推进。"
        : "目前没有足够证据改变今天的安排。"
    case .watch: "有一项可靠指标偏离近期参考。降低今天的强度，留出恢复时间。"
    case .elevated: "至少两项独立可靠指标偏离个人参考。今天先减量，再安排恢复。"
    }
  }
}

struct BodyLoadCard: View {
  @State private var isShowingEvidence = false

  let viewModel: HomeViewModel
  let today: TodayViewState
  let onReviewSleep: () -> Void
  let onCheckIn: () -> Void
  let onStartPractice: (PracticeKind) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(4)) {
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
        VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
          Text("当前压力")
            .font(.caption2.weight(.bold))
            .tracking(1.1)
            .foregroundStyle(InnerBalanceTheme.emphasis)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

          Text(today.stressLevelTitle)
            .fangcunActionStyle()
            .foregroundStyle(InnerBalanceTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("home.stressConclusion")

          if today.isStressIdentified {
            HStack(alignment: .firstTextBaseline, spacing: FangcunLayout.spacing(2)) {
              Text(today.stressSourceRoleTitle)
                .foregroundStyle(InnerBalanceTheme.mutedInk)
              Text(today.stressSourceTitle)
                .fontWeight(.semibold)
                .foregroundStyle(InnerBalanceTheme.ink)
            }
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("home.stressSource")
          }

          if let currentStateTitle = today.currentStateTitle {
            HStack(spacing: FangcunLayout.spacing(2)) {
              Text("当前感受")
                .foregroundStyle(InnerBalanceTheme.mutedInk)
              Text(currentStateTitle)
                .fontWeight(.semibold)
                .accessibilityIdentifier("home.currentState")
            }
            .font(.caption)
          }

          Text(today.explanation)
            .fangcunBodyStyle()
            .foregroundStyle(InnerBalanceTheme.mutedInk)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("home.responseExplanation")
        }

        Divider().overlay(InnerBalanceTheme.hairline)

        RecoveryRecommendationCard(
          action: today.recoveryAction,
          onCheckIn: onCheckIn,
          onStartPractice: onStartPractice,
          onStrongSurface: false
        )
      }
      .padding(FangcunLayout.spacing(5.5))
      .background(
        InnerBalanceTheme.elevatedSurface,
        in: RoundedRectangle(
          cornerRadius: FangcunSurface.editorialResponseCornerRadius,
          style: .continuous
        )
      )
      .overlay {
        RoundedRectangle(
          cornerRadius: FangcunSurface.editorialResponseCornerRadius,
          style: .continuous
        )
        .strokeBorder(InnerBalanceTheme.emphasis.opacity(0.24), lineWidth: 1)
      }
      .overlay(alignment: .leading) {
        Capsule()
          .fill(InnerBalanceTheme.emphasis)
          .frame(width: 3)
          .padding(.vertical, FangcunLayout.spacing(5))
      }

      if let latestPractice = today.latestPractice {
        RecentPracticeRow(practice: latestPractice)
      }

      BodyEvidenceDisclosure(
        isExpanded: $isShowingEvidence,
        viewModel: viewModel,
        onReviewSleep: onReviewSleep
      )
    }
    .accessibilityElement(children: .contain)
  }

}
