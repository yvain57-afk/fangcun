import InnerBalanceCore
import SwiftUI

struct SettlingStagePlayer: View {
  let kind: PracticeKind
  let duration: TimeInterval
  let elapsed: TimeInterval
  let remaining: TimeInterval
  let isPaused: Bool
  let reduceMotion: Bool
  var variantID: String? = nil
  private var state: PracticeTimelineSnapshot { PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: duration) }
  var body: some View {
    PracticeStageScaffold(eyebrow: kind.outcomeTitle,
      title: isPaused ? "Paused" : kind == .diaphragmaticBreathing ? "Breathe at your own pace" : "Let your attention settle",
      instruction: isPaused ? "Breathe naturally. Continue when you're ready." : state.segment?.text ?? kind.steps,
      remaining: remaining, accessibilityIdentifier: "practice.settlingStage", showsStageCard: false) {
        VStack(spacing: 16) {
          PracticeCompanionV4(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID,
            isActive: !isPaused, reduceMotionOverride: reduceMotion).frame(maxWidth: 320).frame(height: 250)
          PracticeGuidedProgress(kind: kind, elapsed: elapsed, duration: duration)
          if kind == .diaphragmaticBreathing {
            Text("A movement guide · Follow your own breath")
              .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
          }
        }
    }
  }
}

struct BodyScanStagePlayer: View {
  let kind: PracticeKind
  let duration: TimeInterval
  let elapsed: TimeInterval
  let remaining: TimeInterval
  let isPaused: Bool
  let reduceMotion: Bool
  var variantID: String? = nil
  private var state: PracticeTimelineSnapshot { PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: duration) }
  var body: some View {
    PracticeStageScaffold(eyebrow: kind.outcomeTitle,
      title: isPaused ? "Paused" : state.segment?.focus == "return" ? "Gently return" : "Let the support take your weight",
      instruction: isPaused ? "Breathe naturally. Continue when you're ready." : state.segment?.text ?? kind.steps,
      remaining: remaining, accessibilityIdentifier: "practice.bodyScanStage", showsStageCard: false) {
        VStack(spacing: 16) {
          PracticeCompanionV4(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID,
            isActive: !isPaused, reduceMotionOverride: reduceMotion).frame(maxWidth: 320).frame(height: 260)
          PracticeGuidedProgress(kind: kind, elapsed: elapsed, duration: duration)
        }
    }
  }
}

struct PelvicFloorStagePlayer: View {
  let kind: PracticeKind
  let duration: TimeInterval
  let elapsed: TimeInterval
  let remaining: TimeInterval
  let isPaused: Bool
  let reduceMotion: Bool
  var variantID: String? = nil
  private var state: PracticeTimelineSnapshot { PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: duration) }
  var body: some View {
    PracticeStageScaffold(eyebrow: kind.outcomeTitle,
      title: isPaused ? "Paused" : state.phase?.title ?? "Release fully",
      instruction: isPaused ? "Release fully. Breathe naturally." : "Keep breathing. Your shoulders, belly, and thighs can rest.",
      remaining: remaining, accessibilityIdentifier: "practice.pelvicFloorStage", showsStageCard: false) {
        PracticeVisualGuide(kind: kind, elapsed: elapsed, duration: duration,
          variantID: variantID, isPaused: isPaused, reduceMotion: reduceMotion)
    }
  }
}
