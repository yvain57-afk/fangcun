import Foundation
import InnerBalanceCore

enum PracticeStageKind: Equatable {
  case breathing
  case settling
  case bodyScan
  case pelvicFloor

  static func `for`(_ kind: PracticeKind) -> Self {
    switch kind {
    case .physiologicalSigh, .pacedBreathing, .balancedBreathing, .boxBreathing, .alternateNostrilBreathing: .breathing
    case .diaphragmaticBreathing: .settling
    case .meditation: .settling
    case .nsdr: .bodyScan
    case .kegel: .pelvicFloor
    }
  }
}

enum PracticeScreenIdentity: Equatable {
  case ready
  case active
  case comparison
  case saved

  static func `for`(_ phase: PracticeSessionPhase) -> Self {
    switch phase {
    case .ready: .ready
    case .running, .paused: .active
    case .comparison: .comparison
    case .saved: .saved
    }
  }
}

enum PracticeCompletionMode: Equatable {
  case subjectiveComparison
  case completionOnly

  static func `for`(_ kind: PracticeKind) -> Self {
    kind == .kegel ? .completionOnly : .subjectiveComparison
  }
}

enum PracticeFeedbackPolicy {
  static func canSave(
    beforeRating: Int?,
    changeChoice: PracticeChangeChoice?,
    hasPostPosition: Bool
  ) -> Bool {
    hasPostPosition && (beforeRating == nil || changeChoice != nil)
  }
}

struct PracticeBodyScanState: Equatable {
  let id: Int
  let cue: PracticeAudioCue
  let progress: Double

  var isReturning: Bool { cue == .nsdrReturn }

  var focusIndex: Int? {
    switch cue {
    case .nsdrFace: 0
    case .nsdrShoulders: 1
    case .nsdrBelly: 2
    case .nsdrLegs: 3
    default: nil
    }
  }

  static func make(elapsed: TimeInterval, duration: TimeInterval? = nil) -> Self {
    let snapshot = PracticeTimeline.snapshot(kind: .nsdr, elapsed: max(0, elapsed), duration: duration ?? 600)
    let cue: PracticeAudioCue
    switch snapshot.segment?.focus {
    case "face": cue = .nsdrFace
    case "shoulders", "arms", "hands": cue = .nsdrShoulders
    case "belly", "hips": cue = .nsdrBelly
    case "legs", "feet": cue = .nsdrLegs
    case "return": cue = .nsdrReturn
    default: cue = .nsdrBreath
    }
    return Self(id: snapshot.cueID, cue: cue, progress: snapshot.phaseProgress)
  }
}

enum PracticeHapticTimeline {
  static func cueID(
    for kind: PracticeKind,
    elapsed: TimeInterval,
    duration: TimeInterval
  ) -> Int {
    if kind == .nsdr {
      return PracticeBodyScanState.make(elapsed: elapsed, duration: duration).id
    }
    return PracticeHapticCadence.cueID(for: kind, elapsed: elapsed)
  }
}

enum PracticeTimelineCadence {
  static func interval(
    kind: PracticeKind,
    phase: PracticeSessionPhase,
    reduceMotion: Bool
  ) -> TimeInterval {
    if phase == .paused || reduceMotion { return 1 }
    return kind == .nsdr ? 1 : 1.0 / 30
  }
}

/// UI-only scheduling. Phase labels and artwork always read the current VM snapshot.
enum PracticeRenderCadence {
  static func interval(snapshot: PracticeTimelineSnapshot, reduceMotion: Bool, kind: PracticeKind? = nil) -> TimeInterval {
    let frame = 1.0 / 30
    // Align the low-frequency display to the real next cue, instead of delaying it by a second.
    let untilCue = max(frame, snapshot.phaseDuration - snapshot.elapsedInPhase)
    if reduceMotion { return min(1, untilCue) }
    if kind == .diaphragmaticBreathing { return frame }
    switch snapshot.timelineMode {
    case .pacedBreath, .pelvicFloor:
      return frame
    case .guidedNatural, .bodyScan:
      // The director's short gesture finishes after 2.4 s; the remaining segment is quiet.
      return snapshot.segmentElapsed < 2.4 ? frame : min(1, untilCue)
    }
  }
}

enum PracticeSavedCopy {
  static func detail(
    kind: PracticeKind,
    healthNeedsAttention: Bool,
    hasSubjectiveComparison: Bool = true
  ) -> String {
    if PracticeCompletionMode.for(kind) == .completionOnly {
      return "本次练习已保存在本机。"
    }
    if !hasSubjectiveComparison {
      return healthNeedsAttention
        ? "此刻的感受已经保存在本机，Apple 健康稍后再试。"
        : "此刻的感受已经保存在本机，回到首页就能看到。"
    }
    return healthNeedsAttention
      ? "这次变化已经保存在本机，Apple 健康稍后再试。"
      : "这次变化已经保留，回到首页就能看到。"
  }
}

enum PracticeStartingRating {
  static func value(kind: PracticeKind, selected: Double) -> Int {
    PracticeCompletionMode.for(kind) == .completionOnly ? 0 : Int(selected.rounded())
  }
}

enum PracticeChangeChoice: CaseIterable, Equatable {
  case lighter
  case same
  case heavier

  var title: String {
    switch self {
    case .lighter: "更舒服"
    case .same: "差不多"
    case .heavier: "不舒服"
    }
  }

  func afterRating(before: Int) -> Int {
    let delta =
      switch self {
      case .lighter: -3
      case .same: 0
      case .heavier: 2
      }
    return min(max(before + delta, 0), 10)
  }
}

enum PracticeStartingChoice: CaseIterable, Equatable {
  case okay
  case some
  case strong

  var rating: Int {
    switch self {
    case .okay: 2
    case .some: 5
    case .strong: 8
    }
  }

  var title: String {
    switch self {
    case .okay: "还好"
    case .some: "有点需要"
    case .strong: "很需要"
    }
  }
}

struct PracticeStageState: Equatable {
  let stage: PracticeStageKind
  let focusIndex: Int
  let intensity: Double

  static func make(
    kind: PracticeKind,
    elapsed: TimeInterval,
    duration: TimeInterval? = nil
  ) -> Self {
    let elapsed = max(0, elapsed)
    switch kind {
    case .physiologicalSigh, .pacedBreathing, .balancedBreathing, .boxBreathing, .alternateNostrilBreathing:
      return Self(stage: .breathing, focusIndex: 0, intensity: 0)
    case .meditation, .diaphragmaticBreathing:
      let wave = (sin(elapsed * 0.55) + 1) / 2
      return Self(stage: .settling, focusIndex: (Int(elapsed) / 30) % 3, intensity: wave)
    case .nsdr:
      let state = PracticeBodyScanState.make(elapsed: elapsed, duration: duration)
      return Self(
        stage: .bodyScan,
        focusIndex: state.focusIndex ?? -1,
        intensity: state.progress
      )
    case .kegel:
      let position = elapsed.truncatingRemainder(dividingBy: 12)
      let intensity = position < 4 ? position / 4 : 1 - (position - 4) / 8
      return Self(stage: .pelvicFloor, focusIndex: position < 4 ? 0 : 1, intensity: intensity)
    }
  }
}

extension PracticeKind {
  var outcomeTitle: String {
    switch self {
    case .physiologicalSigh: "舒缓紧张"
    case .pacedBreathing: "睡前放松"
    case .balancedBreathing: "稳住节奏"
    case .boxBreathing: "进入专注"
    case .diaphragmaticBreathing: "轻松呼吸"
    case .alternateNostrilBreathing: "静心收神"
    case .meditation: "减少分心"
    case .nsdr: "恢复精力"
    case .kegel: "盆底控制"
    }
  }
  var title: String {
    switch self {
    case .physiologicalSigh: "生理性叹息"
    case .pacedBreathing: "节律呼吸"
    case .balancedBreathing: "均衡慢呼吸"
    case .boxBreathing: "方块呼吸"
    case .diaphragmaticBreathing: "膈肌呼吸"
    case .alternateNostrilBreathing: "交替鼻孔呼吸"
    case .meditation: "冥想"
    case .nsdr: "NSDR"
    case .kegel: "凯格尔"
    }
  }
  var summary: String {
    switch self {
    case .physiologicalSigh: "用两次轻吸和一次长呼，放慢急促的呼吸，松开紧绷感。"
    case .pacedBreathing: "把呼气放长，让身体慢下来，为休息和入睡做准备。"
    case .balancedBreathing: "用均匀的吸气和呼气，练习稳定、从容的呼吸节奏。"
    case .boxBreathing: "跟随吸、停、呼、停四段节拍，把注意力收回到眼前。"
    case .diaphragmaticBreathing: "学会用腹部和下肋轻柔呼吸，减少肩颈带着用力。"
    case .alternateNostrilBreathing: "在左右鼻孔交替中集中注意，暂时放下纷乱的思绪。"
    case .meditation: "练习发现走神、放下念头，再把注意力带回当下。"
    case .nsdr: "通过躺式放松和身体扫描缓解疲惫，让身心获得一段深度休息。"
    case .kegel: "练习盆底肌的收紧、保持与放松，逐步增强盆底控制。"
    }
  }
  var bestFor: String {
    switch self {
    case .physiologicalSigh: "突然紧张、忙碌间隙，或想先缓一缓。"
    case .pacedBreathing: "睡前、一天结束后，或需要安静下来的时刻。"
    case .balancedBreathing: "日常固定练习、工作间隙，或喜欢简单节拍的时候。"
    case .boxBreathing: "工作、阅读、演讲准备之前。"
    case .diaphragmaticBreathing: "想学会不费力的呼吸，或先熟悉身体动作。"
    case .alternateNostrilBreathing: "可以空出一只手，想做一段专注的静心练习。"
    case .meditation: "思绪很多、难以停下，或想练习注意力。"
    case .nsdr: "午间、工作之后，或需要躺下歇一会儿。"
    case .kegel: "主动选择盆底肌训练，且已经了解正确动作。"
    }
  }
  var steps: String {
    switch self {
    case .physiologicalSigh: "轻轻鼻吸 → 再补一小口 → 用嘴慢慢呼出。"
    case .pacedBreathing: "轻轻吸气 4 秒 → 慢慢呼气 6 秒，全程不屏息。"
    case .balancedBreathing: "吸气与呼气一样长；默认各 5 秒，也可选各 4 秒。"
    case .boxBreathing: "吸气 3 秒 → 停留 3 秒 → 呼气 3 秒 → 停留 3 秒。"
    case .diaphragmaticBreathing: "手轻放腹部或下肋，感受吸气时轻轻展开、呼气时回落；按自己的节奏。"
    case .alternateNostrilBreathing: "左侧吸 → 右侧呼 → 右侧吸 → 左侧呼；轻轻换边，不屏息。"
    case .meditation: "感受身体被托住 → 留意自然呼吸 → 走神后温和地回来。"
    case .nsdr: "躺稳 → 跟随声音扫描身体 → 安静休息 → 缓缓回来。"
    case .kegel: "轻收 4 秒 → 完全放松 8 秒，始终自然呼吸。"
    }
  }
  var preparation: String {
    switch self {
    case .physiologicalSigh: "轻柔呼吸，不必吸满；头晕或不舒服时停止，恢复自然呼吸。"
    case .pacedBreathing: "不追求深吸或用力呼尽；节奏吃力时停止，恢复自然呼吸。"
    case .balancedBreathing: "轻柔呼吸，不必吸满；不舒服时停止。"
    case .boxBreathing: "含短暂停留。无需忍耐憋气；不舒服时恢复自然呼吸，可换均衡慢呼吸。"
    case .diaphragmaticBreathing: "不故意鼓大肚子，不压腹部，不强行深吸；不适时停止。"
    case .alternateNostrilBreathing: "鼻塞或鼻部不舒服时换其他方法；手指轻放，不压迫鼻子。"
    case .meditation: "可以睁眼练习；不舒服时看看周围并结束。"
    case .nsdr: "在安全、能休息的地方使用；不在驾驶或操作设备时练习，不能代替正常睡眠。"
    case .kegel: "不在排尿时练习；腹部、臀部和大腿保持放松。盆底持续紧张、疼痛、排尿排便异常或产后术后恢复中，先咨询专业人员。"
    }
  }
  var completionReview: String {
    switch self {
    case .physiologicalSigh: "完成了一段舒缓呼吸练习。"
    case .pacedBreathing: "完成了一段睡前放松练习。"
    case .balancedBreathing: "完成了一段均衡呼吸练习。"
    case .boxBreathing: "完成了一段专注呼吸练习。"
    case .diaphragmaticBreathing: "完成了一段呼吸动作练习。"
    case .alternateNostrilBreathing: "完成了一段交替鼻孔呼吸。"
    case .meditation: "完成了一段注意力练习。"
    case .nsdr: "完成了一段 NSDR 深度休息。"
    case .kegel: "完成了一段盆底控制练习。"
    }
  }
  var outcomeDetail: String { summary }
  var purpose: String { summary }
  var systemImage: String { self == .nsdr ? "bed.double" : self == .kegel ? "figure.core.training" : "wind" }
  var v4DefaultDuration: TimeInterval {
    switch self {
    case .physiologicalSigh: 300
    case .pacedBreathing: 300
    case .balancedBreathing: 300
    case .boxBreathing: 180
    case .diaphragmaticBreathing: 180
    case .alternateNostrilBreathing: 180
    case .meditation: 300
    case .nsdr: 600
    case .kegel: 180
    }
  }
  var v4Tags: [String] {
    switch self {
    case .physiologicalSigh: ["放松"]
    case .pacedBreathing: ["放松", "休息"]
    case .balancedBreathing: ["放松"]
    case .boxBreathing: ["专注"]
    case .diaphragmaticBreathing: ["放松", "身体训练"]
    case .alternateNostrilBreathing: ["专注"]
    case .meditation: ["专注"]
    case .nsdr: ["休息"]
    case .kegel: ["身体训练"]
    }
  }
  func cue(elapsed: TimeInterval, duration: TimeInterval? = nil) -> String {
    let snapshot = PracticeTimeline.snapshot(kind: self, elapsed: elapsed, duration: duration ?? v4DefaultDuration)
    return snapshot.phase?.title ?? snapshot.segment?.text ?? steps
  }
}

enum PracticeDurationFormatter {
  static func text(_ duration: TimeInterval) -> String {
    let minutes = max(1, Int(duration / 60))
    return "\(minutes) 分钟"
  }

  static func clock(_ duration: TimeInterval) -> String {
    let seconds = max(0, Int(duration.rounded(.up)))
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
  }
}
