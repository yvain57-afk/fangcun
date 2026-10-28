import InnerBalanceCore
import SwiftUI

struct PracticeMuscleRelaxationState: Equatable {
  enum Action: Equatable { case settle, prepare, tense, release, rest, returning, sleep }
  let action: Action
  let muscleIndex: Int?
  static let muscles = ["Hands", "Upper arms", "Forehead", "Lips and cheeks", "Shoulders", "Thighs", "Lower legs", "Feet and toes"]
  init(snapshot: PracticeTimelineSnapshot) {
    let focus = snapshot.segment?.focus ?? ""
    let pieces = focus.split(separator: "_")
    if pieces.count > 1, pieces[1].hasPrefix("m"), let n = Int(pieces[1].dropFirst()), (1...8).contains(n) {
      muscleIndex = n - 1
    } else { muscleIndex = nil }
    if focus.hasSuffix("gentle_tension") { action = .tense }
    else if focus.hasSuffix("release") { action = .release }
    else if focus.hasSuffix("prepare") { action = .prepare }
    else if focus == "return" { action = .returning }
    else if focus == "pmr_sleep" { action = .sleep }
    else if focus == "pmr_quiet" { action = .rest }
    else { action = .settle }
  }
  var title: String {
    switch action {
    case .tense: "Gently tense"
    case .release: "Let go now"
    case .prepare: "Listen before moving"
    case .returning: "Gently return"
    case .sleep: "Stay resting"
    case .rest: "Nothing more to do"
    case .settle: "Let yourself settle"
    }
  }
}

struct MuscleRelaxationStagePlayer: View {
  let duration: TimeInterval
  let elapsed: TimeInterval
  let remaining: TimeInterval
  let isPaused: Bool
  let reduceMotion: Bool
  var variantID: String?
  private var snapshot: PracticeTimelineSnapshot {
    PracticeTimeline.snapshot(kind: .progressiveMuscleRelaxation, elapsed: elapsed, duration: duration, variantID: variantID)
  }
  /// The VM can supply a release-only recovery cue after pausing during tension.
  var recoverySnapshot: PracticeTimelineSnapshot? = nil
  private var state: PracticeTimelineSnapshot { recoverySnapshot ?? snapshot }
  private var muscle: PracticeMuscleRelaxationState { .init(snapshot: state) }

  var body: some View {
    PracticeStageScaffold(eyebrow: "Muscle relaxation · Breathe naturally",
      title: isPaused ? "Paused. Let go for now." : muscle.title,
      instruction: isPaused ? "Stay comfortable. There's no need to hold the tension." : state.segment?.text ?? "Keep breathing at your own pace.",
      remaining: remaining, accessibilityIdentifier: "practice.muscleRelaxationStage", showsStageCard: false) {
        VStack(spacing: 18) {
          HStack {
            if let index = muscle.muscleIndex {
              Text("\(index + 1) / 8 · " + PracticeMuscleRelaxationState.muscles[index])
                .font(.headline).accessibilityIdentifier("practice.pmr.muscle")
            } else { Text("Give your body a little time to rest").font(.subheadline) }
            Spacer()
            if muscle.action == .tense || muscle.action == .release {
              Text("\(max(1, Int(ceil(state.phaseDuration - state.elapsedInPhase)))) sec")
                .font(.title3.monospacedDigit().weight(.semibold))
                .accessibilityIdentifier("practice.pmr.phaseRemaining")
            }
          }
          PracticeCompanionV4(kind: .progressiveMuscleRelaxation, elapsed: elapsed, duration: duration,
            variantID: variantID, isActive: false, reduceMotionOverride: reduceMotion)
            .frame(height: 185).frame(maxWidth: 300)
          if muscle.muscleIndex != nil {
            HStack(spacing: 10) {
              phase("Listen", action: .prepare)
              phase("Gently tense · 5 sec", action: .tense)
              phase("Release · 25 sec", action: .release)
            }.accessibilityIdentifier("practice.pmr.actions")
            ProgressView(value: state.phaseProgress, total: 1)
              .tint(muscle.action == .tense ? InnerBalanceTheme.emphasis : Color("FangcunExhale"))
              .accessibilityLabel("Current movement progress")
          }
          Text("Release or skip any time · Keep breathing")
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
          PracticeGuidedProgress(kind: .progressiveMuscleRelaxation, elapsed: elapsed, duration: duration, variantID: variantID)
        }.padding(.horizontal, 8)
    }
  }
  private func phase(_ title: String, action: PracticeMuscleRelaxationState.Action) -> some View {
    Text(title).font(.caption.weight(.medium)).multilineTextAlignment(.center)
      .frame(maxWidth: .infinity, minHeight: 44)
      .foregroundStyle(muscle.action == action ? InnerBalanceTheme.ink : InnerBalanceTheme.mutedInk)
      .background(muscle.action == action ? InnerBalanceTheme.subtleFill : .clear, in: RoundedRectangle(cornerRadius: 12))
  }
}
