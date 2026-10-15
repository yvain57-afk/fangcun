import InnerBalanceCore
import SwiftUI

/// Visible instruction, distinct from the mascot's small anatomically constrained motion.
/// All geometry is sampled from the same elapsed value as text, audio and haptics.
struct PracticeVisualGuide: View {
  let kind: PracticeKind
  let elapsed: TimeInterval
  let duration: TimeInterval
  var variantID: String? = nil
  var isPaused = false
  var reduceMotion = false
  @Environment(\.accessibilityReduceMotion) private var systemReduced
  @AppStorage("fangcun.motionMode") private var motionMode = "standard"
  @AppStorage("fangcun.reduceMotion") private var savedReduced = false

  private var state: PracticeTimelineSnapshot {
    PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID)
  }
  private var motion: PracticeVisualMotion { .init(kind: kind, snapshot: state) }
  private var reduced: Bool {
    reduceMotion || savedReduced || systemReduced || motionMode == "static"
      || ProcessInfo.processInfo.isLowPowerModeEnabled
  }
  private var expansion: Double {
    if reduced {
      // Still teach the phase when motion is disabled; no continuous zoom or drift.
      switch state.phase {
      case .inhale, .leftInhale, .rightInhale: return kind == .physiologicalSigh ? 0.82 : 1
      case .topUp, .holdAfterInhale: return 1
      default: return 0
      }
    }
    return motion.expansion
  }
  private var diameter: CGFloat { 174 + 100 * expansion }
  private var ink: Color { InnerBalanceTheme.strongFill }
  private var isKegel: Bool { kind == .kegel }

  var body: some View {
    VStack(spacing: 12) {
      ZStack {
        if isKegel { releaseField }
        else { breathingField }
        PracticeCompanionV4(kind: kind, elapsed: elapsed, duration: duration,
          variantID: variantID, isActive: !isPaused, reduceMotionOverride: reduced)
          .frame(width: kind == .balancedBreathing ? 278 : 250, height: 238)
      }
      .frame(maxWidth: .infinity).frame(height: 290)
      if kind == .alternateNostrilBreathing { nostrilLabels }
      HStack(spacing: 8) {
        Text(isPaused ? "先自然呼吸，准备好再继续" : cue)
          .font(.subheadline.weight(.medium))
          .fixedSize(horizontal: false, vertical: true)
        if !isPaused {
          Text("\(motion.phaseSeconds) 秒")
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .contentTransition(.identity)
            .accessibilityIdentifier("practice.phaseSeconds")
        }
      }
      .foregroundStyle(InnerBalanceTheme.ink)
      .multilineTextAlignment(.center)
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("practice.visualCue")
      phaseRail
    }
    .frame(maxWidth: 340)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("practice.visualGuide")
  }

  private var cue: String {
    if reduced { return state.phase?.title ?? "自然呼吸" }
    return motion.instruction
  }
  private var breathingField: some View {
    ZStack {
      Circle().stroke(ink.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 7]))
        .frame(width: 274, height: 274)
      Circle().fill(ink.opacity(0.055))
        .overlay { Circle().stroke(ink.opacity(isPaused ? 0.18 : 0.48), lineWidth: 2.5) }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("呼吸引导圈")
        .accessibilityValue(isPaused ? "暂停" : state.phase?.title ?? "自然呼吸")
        .accessibilityIdentifier("practice.breathEnvelope")
      // This arc is phase progress, while the inner circle is breath volume metaphor.
      Circle().trim(from: 0, to: isPaused ? 0 : state.phaseProgress)
        .stroke(ink.opacity(0.65), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .rotationEffect(.degrees(-90)).frame(width: 284, height: 284)
        .accessibilityHidden(true)
    }
  }

  private var releaseField: some View {
    let amount = isPaused ? 0 : reduced ? (state.phase == .contract ? 1.0 : 0) : motion.contraction
    return ZStack {
      RoundedRectangle(cornerRadius: 70).fill(ink.opacity(0.045)).frame(width: 285, height: 235)
      ForEach([-1, 1], id: \.self) { side in
        Image(systemName: side < 0 ? "chevron.right" : "chevron.left")
          .font(.system(size: 26, weight: .medium))
          .rotationEffect(.degrees(amount > 0.5 ? 0 : 180))
          .foregroundStyle(ink.opacity(0.65))
          .offset(x: CGFloat(side) * (137 - 28 * amount), y: 52 - 12 * amount)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(isPaused || state.phase == .release ? "舒展开来，完全放松" : "向内轻收，呼吸照常")
    .accessibilityIdentifier("practice.contractionGuide")
  }

  private var nostrilLabels: some View {
    HStack {
      sideLabel("你的左侧", active: motion.side == -1)
      Spacer(minLength: 16)
      sideLabel("你的右侧", active: motion.side == 1)
    }
    .padding(.horizontal, 12)
  }
  private func sideLabel(_ title: String, active: Bool) -> some View {
    Text(title).font(.caption.weight(active && !isPaused ? .bold : .regular))
      .foregroundStyle(active && !isPaused ? InnerBalanceTheme.ink : InnerBalanceTheme.mutedInk)
      .padding(.horizontal, 12).padding(.vertical, 6)
      .background(active && !isPaused ? ink.opacity(0.1) : .clear, in: Capsule())
  }

  private var phaseRail: some View {
    let steps = PracticeTimeline.steps(for: kind, variantID: variantID)
    return HStack(spacing: 5) {
      ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
        let active = !isPaused && index == state.cueID % max(1, steps.count)
        VStack(spacing: 5) {
          Capsule().fill(ink.opacity(active ? 0.8 : 0.12)).frame(height: 4)
          Text(shortTitle(step.phase)).font(.caption2.weight(active ? .semibold : .regular))
            .foregroundStyle(active ? InnerBalanceTheme.ink : InnerBalanceTheme.mutedInk)
        }.frame(maxWidth: .infinity)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("本轮顺序")
    .accessibilityValue(steps.map { shortTitle($0.phase) }.joined(separator: "，"))
    .padding(.horizontal, 12)
  }
  private func shortTitle(_ phase: PracticeBreathPhase) -> String {
    switch phase {
    case .topUp: "补吸"
    case .holdAfterInhale: "吸后停留"
    case .holdAfterExhale: "呼后停留"
    case .leftInhale: "左吸"
    case .rightInhale: "右吸"
    case .leftExhale: "左呼"
    case .rightExhale: "右呼"
    case .contract: "轻收"
    case .release: "放松"
    default: phase.title
    }
  }
}
