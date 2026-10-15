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
      title: isPaused ? "已暂停" : kind == .diaphragmaticBreathing ? "按自己的节奏呼吸" : "让注意力落下来",
      instruction: isPaused ? "先自然呼吸，准备好再继续" : state.segment?.text ?? kind.steps,
      remaining: remaining, accessibilityIdentifier: "practice.settlingStage", showsStageCard: false) {
        PracticeCompanionV4(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID,
          isActive: !isPaused).frame(maxWidth: 320).frame(height: 280)
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
      title: isPaused ? "已暂停" : state.segment?.focus == "return" ? "慢慢回到此刻" : "把重量交给支撑面",
      instruction: isPaused ? "先自然呼吸，准备好再继续" : state.segment?.text ?? kind.steps,
      remaining: remaining, accessibilityIdentifier: "practice.bodyScanStage", showsStageCard: false) {
        PracticeCompanionV4(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID,
          isActive: !isPaused).frame(maxWidth: 320).frame(height: 280)
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
      title: isPaused ? "已暂停" : state.phase?.title ?? "完全放松",
      instruction: isPaused ? "完全放松，先自然呼吸" : "始终自然呼吸，肩膀、腹部和大腿不用帮忙",
      remaining: remaining, accessibilityIdentifier: "practice.pelvicFloorStage", showsStageCard: false) {
        PracticeCompanionV4(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID,
          isActive: !isPaused).frame(maxWidth: 320).frame(height: 280)
    }
  }
}
