import InnerBalanceCore
import SwiftUI

enum BodyLoadCardPresentation {
  static let emptyTrainingMessage = "No workouts found in the past 24 hours"

  static func trainingHeadline(_ summary: HomeTrainingSummary) -> String {
    let minutes = max(1, Int(summary.totalDuration / 60))
    let duration = minutes < 60 ? "\(minutes) min" : "\(minutes / 60) hr \(minutes % 60) min"
    return "Past 24 hours · \(summary.count) workouts · \(duration)"
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
      return "Room to recover"
    }
    return switch level {
    case .buildingBaseline: "Keep your usual plans"
    case .steady: hasReliableEvidence(evidence) ? "Within your usual range" : "Keep your usual plans"
    case .watch: "Take it a little easier"
    case .elevated: "Make room for recovery"
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
      return "Recent exercise may affect these readings. Give yourself time to recover and check again later."
    }
    return switch level {
    case .buildingBaseline:
      evidence.isEmpty ? "There isn't enough information here to suggest a change to your plans." : "These readings are helping build your personal baseline. They don't yet support a personalized assessment."
    case .steady:
      hasReliableEvidence(evidence)
        ? "The recent reliable readings are within your personal reference range."
        : "There isn't enough information here to suggest a change to your plans."
    case .watch: "One reliable measure differs from your recent baseline. Consider an easier day with time to recover."
    case .elevated: "At least two independent reliable measures differ from your baseline. Consider reducing effort and making time to recover."
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
          Text("Reported pressure")
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
              Text("How you feel")
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
