import Foundation
import InnerBalanceCore

enum PracticeStageKind: Equatable {
  case breathing
  case settling
  case bodyScan
  case pelvicFloor

  static func `for`(_ kind: PracticeKind) -> Self {
    switch kind {
    case .physiologicalSigh, .pacedBreathing: .breathing
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
    let elapsed = max(0, elapsed)
    if let duration, duration - elapsed <= 30 {
      return Self(
        id: Int(ceil(duration / 25)) + 1,
        cue: .nsdrReturn,
        progress: min(max((elapsed - max(0, duration - 30)) / 30, 0), 1)
      )
    }

    let cues: [PracticeAudioCue] = [
      .nsdrFace, .nsdrShoulders, .nsdrBreath, .nsdrBelly, .nsdrLegs, .nsdrBreath,
    ]
    let id = Int(elapsed / 25)
    return Self(
      id: id,
      cue: cues[id % cues.count],
      progress: elapsed.truncatingRemainder(dividingBy: 25) / 25
    )
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
    case .lighter: "松了一些"
    case .same: "差不多"
    case .heavier: "更需要缓缓"
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
    case .physiologicalSigh, .pacedBreathing:
      return Self(stage: .breathing, focusIndex: 0, intensity: 0)
    case .meditation:
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
    case .physiologicalSigh: "压力突然升高"
    case .pacedBreathing: "压力中等，节奏偏快"
    case .meditation: "压力较低，思绪占满"
    case .nsdr: "睡眠或训练透支"
    case .kegel: "专项训练，不用于即时减压"
    }
  }

  var outcomeDetail: String {
    summary
  }

  var title: String {
    switch self {
    case .physiologicalSigh: "生理性叹息"
    case .pacedBreathing: "延长呼气"
    case .meditation: "冥想"
    case .nsdr: "NSDR 躺式休息"
    case .kegel: "凯格尔练习"
    }
  }

  var summary: String {
    switch self {
    case .physiologicalSigh: "两次鼻吸、一次长呼，用 1 分钟把呼气慢下来。"
    case .pacedBreathing: "按 4 秒吸、6 秒呼的节奏练习，不屏息。"
    case .meditation: "留意身体的支撑感和自然呼吸，走神了再回来。"
    case .nsdr: "躺着完成一段身体扫描，不要求睡着。"
    case .kegel: "轻收 4 秒、完全放松 8 秒，同时保持自然呼吸。"
    }
  }

  var purpose: String {
    switch self {
    case .physiologicalSigh: "把短促的呼吸拉回更慢的节奏。"
    case .pacedBreathing: "给呼吸一个固定节拍，也给注意力一个跟随点。"
    case .meditation: "练习发现走神，再把注意力放回来；不是清空大脑。"
    case .nsdr: "把注意力依次带过身体，减少主动用力，留出一段安静休息。"
    case .kegel: "练习找到盆底肌，并协调收紧、放松与呼吸。"
    }
  }

  var bestFor: String {
    switch self {
    case .physiologicalSigh: "突然紧绷、呼吸变浅，或只想先快速缓一下。"
    case .pacedBreathing: "心里有点乱，但还能安静坐 3 到 5 分钟。"
    case .meditation: "思绪很多，想暂时从手头的事里退开几分钟。"
    case .nsdr: "睡眠不足、训练后疲惫，或午间想躺一会儿。"
    case .kegel: "想做日常盆底肌训练，并且当前没有疼痛或异常。"
    }
  }

  var steps: String {
    switch self {
    case .physiologicalSigh: "鼻吸一口 → 再补一小口 → 用嘴慢慢呼尽。"
    case .pacedBreathing: "慢慢吸气 4 秒 → 再用 6 秒呼出。"
    case .meditation: "感受身体被托住 → 留意一口自然呼吸 → 走神后再回来。"
    case .nsdr: "放松脸和下颌 → 肩膀 → 腹部 → 双腿，再慢慢回来。"
    case .kegel: "轻轻收紧 4 秒 → 完全放松 8 秒 → 重复下一轮。"
    }
  }

  var systemImage: String {
    switch self {
    case .physiologicalSigh: "wind"
    case .pacedBreathing: "circle.dotted.circle"
    case .meditation: "figure.mind.and.body"
    case .nsdr: "bed.double.fill"
    case .kegel: "figure.core.training"
    }
  }

  var preparation: String {
    switch self {
    case .physiologicalSigh:
      "坐稳或站稳，不用吸到满。头晕、胸闷或不舒服就停下，恢复自然呼吸。"
    case .pacedBreathing:
      "找个不费力的姿势，不要追求深呼吸；气短或头晕时，先恢复自然呼吸。"
    case .meditation:
      "可以坐着或躺着，不需要控制呼吸。不舒服时，可以睁眼、看看周围并结束练习。"
    case .nsdr:
      "不要在驾驶、操作设备或需要保持警觉时开始；它不能代替正常睡眠。"
    case .kegel:
      "保持自然呼吸，不在排尿时练习。盆底持续紧张、排尿排便异常、产后或术后恢复中，请先咨询专业人员；如有疼痛或不适立即停止。"
    }
  }

  func cue(elapsed: TimeInterval, duration: TimeInterval? = nil) -> String {
    switch self {
    case .physiologicalSigh:
      return switch Int(elapsed) % 12 {
      case 0..<3: "用鼻子轻吸一口"
      case 3..<5: "再轻轻补一小口"
      default: "用嘴缓慢、完全呼出"
      }
    case .pacedBreathing:
      return Int(elapsed) % 10 < 4 ? "慢慢吸气" : "更慢地呼气"
    case .meditation:
      let cues = ["感受身体与支撑面接触", "注意一次自然呼吸", "走神了，只需温和地回来"]
      return cues[(Int(elapsed) / 30) % cues.count]
    case .nsdr:
      return PracticeBodyScanState.make(elapsed: elapsed, duration: duration).cue.spokenText
    case .kegel:
      return Int(elapsed) % 12 < 4 ? "轻轻收紧，保持呼吸" : "完全放松"
    }
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
