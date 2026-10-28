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
  /// After interruption, the remainder of a PMR tension slot becomes rest without
  /// changing its boundaries or adding a compensating contraction.
  public func recoveringMuscleRelease() -> Self {
    guard let segment, segment.focus.hasPrefix("pmr_"), segment.focus.hasSuffix("gentle_tension") else { return self }
    let release = PracticeGuidedSegment(id: segment.id + "_resume_release", start: segment.start,
      end: segment.end, focus: segment.focus.replacingOccurrences(of: "gentle_tension", with: "release"),
      text: "Let go and breathe naturally. You don't need to repeat the last contraction.")
    return .init(timelineMode: timelineMode, phase: nil, phaseDuration: phaseDuration,
      elapsedInPhase: elapsedInPhase, phaseProgress: phaseProgress, cycleIndex: cycleIndex,
      cueID: cueID, segment: release, variantID: variantID)
  }
}
public enum PracticeTimeline {
  public static let protocolVersion = "fangcun-practice-v4.0"
  public static func mode(for kind: PracticeKind) -> PracticeTimelineMode {
    switch kind {
    case .meditation, .diaphragmaticBreathing: .guidedNatural
    case .nsdr, .progressiveMuscleRelaxation: .bodyScan
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
    case .progressiveMuscleRelaxation: "dog_gentle_release"
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
    case .progressiveMuscleRelaxation: requested == "pmr_sleep" ? "pmr_sleep" : "pmr_day"
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
    case .nsdr, .progressiveMuscleRelaxation: []
    case .kegel: [.init(phase: .contract, duration: 4), .init(phase: .release, duration: 8)]
    }
  }
  public static func segments(for kind: PracticeKind, duration: TimeInterval, variantID: String? = nil) -> [PracticeGuidedSegment] {
    PracticeGuidanceContent.segments(for: kind, duration: duration, variantID: variantID)
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
    let segments = segments(for: kind, duration: duration, variantID: variant)
    let index = segments.lastIndex(where: { elapsed >= $0.start }) ?? 0
    let segment = segments.indices.contains(index) ? segments[index] : nil
    let position = min(max(0, elapsed - (segment?.start ?? 0)), (segment?.end ?? duration) - (segment?.start ?? 0))
    let length = max(1, (segment?.end ?? duration) - (segment?.start ?? 0))
    return .init(timelineMode: mode, phase: nil, phaseDuration: length, elapsedInPhase: position, phaseProgress: position / length, cycleIndex: 0, cueID: index, segment: segment, variantID: variant)
  }
}
