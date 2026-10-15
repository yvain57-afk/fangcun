import Foundation

public enum PracticeTimelineMode: String, Codable, Sendable {
  case pacedBreath, guidedNatural, bodyScan, pelvicFloor
}
public struct PracticePhaseStep: Equatable, Sendable {
  public let phase: PracticeBreathPhase
  public let duration: TimeInterval
}
public struct PracticeGuidedSegment: Equatable, Sendable {
  public let id: String
  public let start: TimeInterval
  public let end: TimeInterval
  public let focus: String
  public let text: String
}
public struct PracticeTimelineSnapshot: Equatable, Sendable {
  public let timelineMode: PracticeTimelineMode
  public let phase: PracticeBreathPhase?
  public let phaseDuration: TimeInterval
  public let elapsedInPhase: TimeInterval
  public let phaseProgress: Double
  public let cycleIndex: Int
  public let cueID: Int
  public let segment: PracticeGuidedSegment?
  public let variantID: String?
  public var segmentElapsed: TimeInterval { elapsedInPhase }
}
public enum PracticeTimeline {
  public static let protocolVersion = "fangcun-practice-v4.0"
  public static func mode(for kind: PracticeKind) -> PracticeTimelineMode {
    switch kind {
    case .meditation, .diaphragmaticBreathing: .guidedNatural
    case .nsdr: .bodyScan
    case .kegel: .pelvicFloor
    default: .pacedBreath
    }
  }
  public static func sceneID(for kind: PracticeKind) -> String {
    switch kind {
    case .physiologicalSigh: "cat_flower_sigh"
    case .pacedBreathing: "dog_pillow_exhale"
    case .balancedBreathing: "duo_settled_breath"
    case .boxBreathing: "cat_four_corners"
    case .diaphragmaticBreathing: "dog_soft_belly"
    case .alternateNostrilBreathing: "dog_two_leaves"
    case .meditation: "cat_leaf_attention"
    case .nsdr: "dog_blanket_rest"
    case .kegel: "dog_gentle_coach"
    }
  }
  public static func variantID(for kind: PracticeKind, requested: String? = nil) -> String? {
    switch kind {
    case .physiologicalSigh: "legacy_3_2_7"
    case .pacedBreathing: "legacy_4_6"
    case .balancedBreathing: requested == "easy_4_4" ? "easy_4_4" : "equal_5_5"
    case .boxBreathing: "box_3"
    case .diaphragmaticBreathing: nil
    case .alternateNostrilBreathing: "alternate_3"
    case .meditation: nil
    case .nsdr: nil
    case .kegel: "legacy_4_8"
    }
  }
  public static func steps(for kind: PracticeKind, variantID: String? = nil) -> [PracticePhaseStep] {
    switch kind {
    case .physiologicalSigh: [.init(phase: .inhale, duration: 3), .init(phase: .topUp, duration: 2), .init(phase: .exhale, duration: 7)]
    case .pacedBreathing: [.init(phase: .inhale, duration: 4), .init(phase: .exhale, duration: 6)]
    case .balancedBreathing: variantID == "easy_4_4" ? [.init(phase: .inhale, duration: 4), .init(phase: .exhale, duration: 4)] : [.init(phase: .inhale, duration: 5), .init(phase: .exhale, duration: 5)]
    case .boxBreathing: [.init(phase: .inhale, duration: 3), .init(phase: .holdAfterInhale, duration: 3), .init(phase: .exhale, duration: 3), .init(phase: .holdAfterExhale, duration: 3)]
    case .diaphragmaticBreathing: []
    case .alternateNostrilBreathing: [.init(phase: .leftInhale, duration: 3), .init(phase: .rightExhale, duration: 3), .init(phase: .rightInhale, duration: 3), .init(phase: .leftExhale, duration: 3)]
    case .meditation: []
    case .nsdr: []
    case .kegel: [.init(phase: .contract, duration: 4), .init(phase: .release, duration: 8)]
    }
  }
  public static func segments(for kind: PracticeKind, duration: TimeInterval) -> [PracticeGuidedSegment] {
    switch (kind, duration) {
    case (.nsdr, 600): [
      .init(id: "nsdr_600_0", start: 0, end: 30, focus: "settle", text: "找个可以躺稳的位置，把身体交给床面或垫子。接下来，跟着声音休息。"),
      .init(id: "nsdr_600_1", start: 30, end: 60, focus: "settle", text: "轻轻闭眼，或把视线放低。你不用一直看屏幕。"),
      .init(id: "nsdr_600_2", start: 60, end: 90, focus: "face", text: "松开眼周，让下颌和舌头都轻松一点。"),
      .init(id: "nsdr_600_3", start: 90, end: 130, focus: "shoulders", text: "让两侧肩膀落下来。背部的重量，交给下面的支撑。"),
      .init(id: "nsdr_600_4", start: 130, end: 170, focus: "arms", text: "注意上臂、前臂，再到双手。让手指自然弯着。"),
      .init(id: "nsdr_600_5", start: 170, end: 210, focus: "hands", text: "感受手掌的重量。现在不用抓住任何东西。"),
      .init(id: "nsdr_600_6", start: 210, end: 250, focus: "breath", text: "留意一口自然呼吸。让空气自己进来，再出去。"),
      .init(id: "nsdr_600_7", start: 250, end: 290, focus: "belly", text: "腹部不用收紧。让腰腹得到支撑，随着自然呼吸轻轻移动。"),
      .init(id: "nsdr_600_8", start: 290, end: 330, focus: "hips", text: "感受骨盆与垫子接触的位置，把重量放下。"),
      .init(id: "nsdr_600_9", start: 330, end: 370, focus: "legs", text: "注意大腿和小腿。让双腿休息，不用主动绷直。"),
      .init(id: "nsdr_600_10", start: 370, end: 415, focus: "feet", text: "脚踝放松，脚趾松开。感受双脚也被托住。"),
      .init(id: "nsdr_600_11", start: 415, end: 460, focus: "whole", text: "从头到脚感受整个身体。让支撑面接住你的重量。"),
      .init(id: "nsdr_600_12", start: 460, end: 510, focus: "breath", text: "注意再一口自然的呼吸。不需要调整它。"),
      .init(id: "nsdr_600_13", start: 510, end: 570, focus: "quiet", text: "接下来安静待一会儿。听到声音，再慢慢回来。"),
      .init(id: "nsdr_600_14", start: 570, end: 600, focus: "return", text: "轻轻动动手指和脚趾。感受身边的空间，准备好时慢慢睁开眼睛。"),
    ]
    case (.nsdr, 1200): [
      .init(id: "nsdr_1200_0", start: 0, end: 45, focus: "settle", text: "找个可以躺稳的位置，把身体交给床面或垫子。这二十分钟，留给安静的休息。"),
      .init(id: "nsdr_1200_1", start: 45, end: 90, focus: "settle", text: "轻轻闭眼，或把视线放低。接下来不用看屏幕，听见声音时再跟随。"),
      .init(id: "nsdr_1200_2", start: 90, end: 150, focus: "face", text: "松开眼周，让下颌和舌头都轻松一点。"),
      .init(id: "nsdr_1200_3", start: 150, end: 230, focus: "shoulders", text: "让两侧肩膀落下来。背部的重量，交给下面的支撑。"),
      .init(id: "nsdr_1200_4", start: 230, end: 310, focus: "arms", text: "注意上臂、前臂，再到双手。让手指自然弯着。"),
      .init(id: "nsdr_1200_5", start: 310, end: 390, focus: "hands", text: "感受手掌的重量。现在不用抓住任何东西。"),
      .init(id: "nsdr_1200_6", start: 390, end: 470, focus: "breath", text: "留意一口自然呼吸。让空气自己进来，再出去。"),
      .init(id: "nsdr_1200_7", start: 470, end: 550, focus: "belly", text: "腹部不用收紧。让腰腹得到支撑，随着自然呼吸轻轻移动。"),
      .init(id: "nsdr_1200_8", start: 550, end: 640, focus: "hips", text: "感受骨盆与垫子接触的位置，把重量放下。"),
      .init(id: "nsdr_1200_9", start: 640, end: 720, focus: "legs", text: "注意大腿和小腿。让双腿休息，不用主动绷直。"),
      .init(id: "nsdr_1200_10", start: 720, end: 810, focus: "feet", text: "脚踝放松，脚趾松开。感受双脚也被托住。"),
      .init(id: "nsdr_1200_11", start: 810, end: 900, focus: "whole", text: "从头到脚感受整个身体。让支撑面接住你的重量。"),
      .init(id: "nsdr_1200_12", start: 900, end: 1000, focus: "breath", text: "留意呼吸，也留意身体与垫子的接触。现在不用做更多事情。"),
      .init(id: "nsdr_1200_13", start: 1000, end: 1100, focus: "quiet", text: "接下来安静待一会儿。念头出现，就让它过去。"),
      .init(id: "nsdr_1200_14", start: 1100, end: 1170, focus: "whole", text: "再感受一次整个身体。保持舒服的姿势，先不用起身。"),
      .init(id: "nsdr_1200_15", start: 1170, end: 1200, focus: "return", text: "轻轻动动手指和脚趾。感受身边的空间，准备好时慢慢睁开眼睛。"),
    ]
    case (.meditation, 300): [
      .init(id: "meditation_300_0", start: 0, end: 25, focus: "settle", text: "找一个舒服、能坐稳的姿势。把手自然放好。"),
      .init(id: "meditation_300_1", start: 25, end: 55, focus: "support", text: "感觉身体与椅子或垫子接触，先在这里停一下。"),
      .init(id: "meditation_300_2", start: 55, end: 100, focus: "breath", text: "留意一口自然的呼吸。让呼吸按自己的节奏发生。"),
      .init(id: "meditation_300_3", start: 100, end: 145, focus: "return", text: "发现走神，就把注意力轻轻带回这一口呼吸。"),
      .init(id: "meditation_300_4", start: 145, end: 200, focus: "allow", text: "念头可以来，也可以走。暂时不用跟着它继续想。"),
      .init(id: "meditation_300_5", start: 200, end: 260, focus: "return", text: "再感觉一次身体被托住。把注意力带回此刻。"),
      .init(id: "meditation_300_6", start: 260, end: 285, focus: "breath", text: "留意接下来的几口自然呼吸。"),
      .init(id: "meditation_300_7", start: 285, end: 300, focus: "finish", text: "感受身边的声音，轻轻动动手。准备好后，带着这份注意继续今天。"),
    ]
    case (.meditation, 600): [
      .init(id: "meditation_600_0", start: 0, end: 30, focus: "settle", text: "找一个舒服、能坐稳的姿势。把手自然放好。"),
      .init(id: "meditation_600_1", start: 30, end: 70, focus: "support", text: "感觉身体与椅子或垫子接触，先在这里停一下。"),
      .init(id: "meditation_600_2", start: 70, end: 140, focus: "breath", text: "留意一口自然的呼吸。让呼吸按自己的节奏发生。"),
      .init(id: "meditation_600_3", start: 140, end: 220, focus: "return", text: "发现走神，就把注意力轻轻带回这一口呼吸。"),
      .init(id: "meditation_600_4", start: 220, end: 300, focus: "allow", text: "念头可以来，也可以走。暂时不用跟着它继续想。"),
      .init(id: "meditation_600_5", start: 300, end: 400, focus: "support", text: "再感觉一次身体被托住。肩膀、下颌和双手都可以放松。"),
      .init(id: "meditation_600_6", start: 400, end: 500, focus: "return", text: "你注意到自己在想别的事，就已经有了回来的机会。再回到呼吸。"),
      .init(id: "meditation_600_7", start: 500, end: 565, focus: "breath", text: "接下来留意几口自然呼吸，安静地待一会儿。"),
      .init(id: "meditation_600_8", start: 565, end: 600, focus: "finish", text: "感受身边的声音，轻轻动动手。准备好后，带着这份注意继续今天。"),
    ]
    case (.diaphragmaticBreathing, 180): [
      .init(id: "diaphragmaticBreathing_180_0", start: 0, end: 25, focus: "settle", text: "坐稳或舒适地躺好，一只手轻放腹部或下肋。"),
      .init(id: "diaphragmaticBreathing_180_1", start: 25, end: 50, focus: "lowerRibs", text: "吸气时，感觉下肋和腹部轻轻展开。肩膀不需要抬起来。"),
      .init(id: "diaphragmaticBreathing_180_2", start: 50, end: 85, focus: "release", text: "呼气时，让腹部自然回落，不要向里用力挤。"),
      .init(id: "diaphragmaticBreathing_180_3", start: 85, end: 120, focus: "natural", text: "现在按自己的节奏呼吸，手只用来感受。"),
      .init(id: "diaphragmaticBreathing_180_4", start: 120, end: 155, focus: "relax", text: "松开下颌和肩膀，继续轻柔呼吸。"),
      .init(id: "diaphragmaticBreathing_180_5", start: 155, end: 175, focus: "independent", text: "把手放回舒服的位置，继续几口自然呼吸。"),
      .init(id: "diaphragmaticBreathing_180_6", start: 175, end: 180, focus: "finish", text: "记住这份不费力的动作，慢慢结束练习。"),
    ]
    case (.diaphragmaticBreathing, 300): [
      .init(id: "diaphragmaticBreathing_300_0", start: 0, end: 30, focus: "settle", text: "坐稳或舒适地躺好，一只手轻放腹部或下肋。"),
      .init(id: "diaphragmaticBreathing_300_1", start: 30, end: 60, focus: "lowerRibs", text: "吸气时，感觉下肋和腹部轻轻展开。肩膀不需要抬起来。"),
      .init(id: "diaphragmaticBreathing_300_2", start: 60, end: 120, focus: "release", text: "呼气时，让腹部自然回落，不要向里用力挤。"),
      .init(id: "diaphragmaticBreathing_300_3", start: 120, end: 185, focus: "natural", text: "现在按自己的节奏呼吸，手只用来感受。"),
      .init(id: "diaphragmaticBreathing_300_4", start: 185, end: 245, focus: "relax", text: "松开下颌和肩膀，继续轻柔呼吸。"),
      .init(id: "diaphragmaticBreathing_300_5", start: 245, end: 285, focus: "independent", text: "把手放回舒服的位置，继续几口自然呼吸。"),
      .init(id: "diaphragmaticBreathing_300_6", start: 285, end: 300, focus: "finish", text: "记住这份不费力的动作，慢慢结束练习。"),
    ]
    default: []
    }
  }
  public static func snapshot(kind: PracticeKind, elapsed: TimeInterval, duration: TimeInterval, variantID: String? = nil) -> PracticeTimelineSnapshot {
    let elapsed = max(0, elapsed.isFinite ? elapsed : 0)
    let mode = mode(for: kind)
    let variant = self.variantID(for: kind, requested: variantID)
    let steps = steps(for: kind, variantID: variant)
    if !steps.isEmpty {
      let cycleDuration = steps.reduce(0) { $0 + $1.duration }
      let cycle = Int(elapsed / cycleDuration)
      var position = elapsed.truncatingRemainder(dividingBy: cycleDuration)
      for (index, step) in steps.enumerated() {
        if position < step.duration {
          return .init(timelineMode: mode, phase: step.phase, phaseDuration: step.duration, elapsedInPhase: position, phaseProgress: position / step.duration, cycleIndex: cycle, cueID: cycle * steps.count + index, segment: nil, variantID: variant)
        }
        position -= step.duration
      }
    }
    let segments = segments(for: kind, duration: duration)
    let index = segments.lastIndex(where: { elapsed >= $0.start }) ?? 0
    let segment = segments.indices.contains(index) ? segments[index] : nil
    let position = min(max(0, elapsed - (segment?.start ?? 0)), (segment?.end ?? duration) - (segment?.start ?? 0))
    let length = max(1, (segment?.end ?? duration) - (segment?.start ?? 0))
    return .init(timelineMode: mode, phase: nil, phaseDuration: length, elapsedInPhase: position, phaseProgress: position / length, cycleIndex: 0, cueID: index, segment: segment, variantID: nil)
  }
}
