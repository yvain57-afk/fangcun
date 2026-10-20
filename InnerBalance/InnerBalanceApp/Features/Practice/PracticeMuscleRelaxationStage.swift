import InnerBalanceCore
import SwiftUI

struct PracticeMuscleRelaxationState: Equatable {
  enum Action: Equatable { case settle, prepare, tense, release, rest, returning, sleep }
  let action: Action
  let muscleIndex: Int?
  static let muscles = ["双手", "上臂", "额头", "嘴唇与面颊", "肩膀", "大腿", "小腿", "双脚与脚趾"]
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
    case .tense: "轻轻收紧"
    case .release: "现在松开"
    case .prepare: "先听动作说明"
    case .returning: "慢慢回到此刻"
    case .sleep: "继续安静休息"
    case .rest: "不用再做动作"
    case .settle: "先让身体安顿下来"
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
    PracticeStageScaffold(eyebrow: "渐进式肌肉放松 · 自然呼吸",
      title: isPaused ? "已暂停，先松开" : muscle.title,
      instruction: isPaused ? "保持舒服的姿势，不需要继续收紧" : state.segment?.text ?? "呼吸照自己的节奏。",
      remaining: remaining, accessibilityIdentifier: "practice.muscleRelaxationStage", showsStageCard: false) {
        VStack(spacing: 18) {
          HStack {
            if let index = muscle.muscleIndex {
              Text("\(index + 1) / 8 · " + PracticeMuscleRelaxationState.muscles[index])
                .font(.headline).accessibilityIdentifier("practice.pmr.muscle")
            } else { Text("给身体一点休息的时间").font(.subheadline) }
            Spacer()
            if muscle.action == .tense || muscle.action == .release {
              Text("\(max(1, Int(ceil(state.phaseDuration - state.elapsedInPhase)))) 秒")
                .font(.title3.monospacedDigit().weight(.semibold))
                .accessibilityIdentifier("practice.pmr.phaseRemaining")
            }
          }
          PracticeCompanionV4(kind: .progressiveMuscleRelaxation, elapsed: elapsed, duration: duration,
            variantID: variantID, isActive: false, reduceMotionOverride: reduceMotion)
            .frame(height: 185).frame(maxWidth: 300)
          if muscle.muscleIndex != nil {
            HStack(spacing: 10) {
              phase("听说明", action: .prepare)
              phase("轻收 5 秒", action: .tense)
              phase("松开 25 秒", action: .release)
            }.accessibilityIdentifier("practice.pmr.actions")
            ProgressView(value: state.phaseProgress, total: 1)
              .tint(muscle.action == .tense ? InnerBalanceTheme.emphasis : Color("FangcunExhale"))
              .accessibilityLabel("当前动作进度")
          }
          Text("随时可以松开或跳过用力 · 不要屏住呼吸")
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
