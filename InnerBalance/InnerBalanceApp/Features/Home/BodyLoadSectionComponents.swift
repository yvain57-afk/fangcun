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
        Text("You don't need an extra practice to keep going.")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(primaryInk)
          .fixedSize(horizontal: false, vertical: true)
        adjustmentButton

      case .needsInput:
        Text("Take a moment to note what you're feeling and what may be on your mind.")
          .font(.subheadline)
          .foregroundStyle(secondaryInk)
          .fixedSize(horizontal: false, vertical: true)
        Button("Check in with yourself", action: onCheckIn)
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
    Button("Update your check-in", action: onCheckIn)
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(secondaryInk)
      .frame(minHeight: 44)
      .buttonStyle(FangcunPressButtonStyle())
      .accessibilityIdentifier("home.checkIn")
  }

  private var sectionTitle: String {
    switch action {
    case .practice: "Try this now"
    case .continueNormally: "What might help now?"
    case .needsInput: "Next"
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
      .accessibilityLabel("Begin · \(practice.title)")
      .accessibilityIdentifier("home.startRecommendation")
  }

  private func actionTitle(for practice: PracticeKind) -> String {
    switch practice {
    case .physiologicalSigh: "Take one minute"
    case .pacedBreathing: "Breathe for 3 minutes"
    case .balancedBreathing: "Breathe for 5 minutes"
    case .boxBreathing, .diaphragmaticBreathing, .alternateNostrilBreathing: "Begin · 3 min"
    case .meditation: "A quiet 5 minutes"
    case .nsdr: "Rest for 10 minutes"
    case .kegel: "Begin · 3 min"
    case .progressiveMuscleRelaxation: "Unwind for 10 minutes"
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
    case .physiologicalSigh: "1 min · Two gentle breaths in, one slow breath out"
    case .pacedBreathing: "3 or 5 min · A gentle breathing rhythm"
    case .balancedBreathing: "3 or 5 min · Equal time in and out"
    case .boxBreathing: "3 or 5 min · In, pause, out, pause"
    case .diaphragmaticBreathing: "3 or 5 min · Notice movement at your lower ribs"
    case .alternateNostrilBreathing: "3 or 5 min · Alternate sides, without holds"
    case .meditation: "5 or 10 min · Room for a quiet moment"
    case .nsdr: "10 or 20 min · Lie down for guided rest"
    case .kegel: "3 min · Pelvic floor lift and release"
    case .progressiveMuscleRelaxation: "10 min · Gently tense and release"
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
        Text("Today, you made time")
          .font(.caption.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.strongFill)
        Text(practice.practiceKind.title)
          .font(.headline)
        Text(changeText)
          .font(.subheadline.weight(.medium))
        Text("\(PracticeDurationFormatter.clock(practice.actualDuration)) of practice")
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
    guard practice.hasSubjectiveComparison else { return "Complete" }
    let change = practice.subjectiveChange
    if change == 0 { return "You felt about the same" }
    return "Reported need for a pause \(change < 0 ? "decreased" : "increased") by \(abs(change))"
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
          Label("Recent longer workouts are accounted for separately in HRV and resting heart rate assessment", systemImage: "figure.run")
            .font(.caption)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        if viewModel.sleepNeedsReview {
          Button(action: onReviewSleep) {
            Label("Review sleep data", systemImage: "exclamationmark.bubble")
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
        Text("These are everyday wellbeing suggestions, not a medical diagnosis.")
          .font(.caption2)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
      .padding(.top, FangcunLayout.spacing(5))
    } label: {
      Label("What this is based on", systemImage: "waveform.path.ecg")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.strongFill)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
    .accessibilityHint("View exercise context, data sources, timestamps, and reliability")
    .accessibilityIdentifier("home.trainingSummary")
  }
}

private struct TrainingContextSummary: View {
  let viewModel: HomeViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
      Text("Exercise context").font(.subheadline.weight(.semibold))
      if let summary = viewModel.trainingSummary {
        Text(BodyLoadCardPresentation.trainingHeadline(summary)).font(.subheadline)
        Text(
          "Latest: \(summary.latestActivityName) · "
            + "\(PracticeDurationFormatter.text(summary.latestDuration)) · "
            + "\(summary.latestEndDate.formatted(.relative(presentation: .named).locale(Locale(identifier: "en")))) · "
            + summary.latestSourceName
        )
        .font(.caption)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
      } else {
        Text(
          viewModel.unavailableKinds.contains(.workout)
            ? "Exercise data isn't available yet" : BodyLoadCardPresentation.emptyTrainingMessage
        )
        .font(.caption)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}
