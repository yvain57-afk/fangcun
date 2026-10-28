import Foundation
import InnerBalanceCore

enum PracticeStageKind: Equatable {
  case breathing
  case settling
  case bodyScan
  case pelvicFloor
  case muscleRelaxation

  static func `for`(_ kind: PracticeKind) -> Self {
    switch kind {
    case .physiologicalSigh, .pacedBreathing, .balancedBreathing, .boxBreathing, .alternateNostrilBreathing: .breathing
    case .diaphragmaticBreathing: .settling
    case .meditation: .settling
    case .nsdr: .bodyScan
    case .kegel: .pelvicFloor
    case .progressiveMuscleRelaxation: .muscleRelaxation
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
      return "Saved on this device."
    }
    if !hasSubjectiveComparison {
      return healthNeedsAttention
        ? "Your feeling is saved here. We'll retry Apple Health later."
        : "Your feeling is saved. You'll find it in Daily."
    }
    return healthNeedsAttention
      ? "Your reflection is saved here. We'll retry Apple Health later."
      : "Your reflection is saved. You'll find it in Daily."
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
    case .lighter: "A little easier"
    case .same: "About the same"
    case .heavier: "Less comfortable"
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
    case .okay: "Doing okay"
    case .some: "Could use a pause"
    case .strong: "Really need a pause"
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
    case .progressiveMuscleRelaxation:
      let snapshot = PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: duration ?? 600)
      let state = PracticeMuscleRelaxationState(snapshot: snapshot)
      return Self(stage: .muscleRelaxation, focusIndex: state.muscleIndex ?? -1, intensity: snapshot.phaseProgress)
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
    case .physiologicalSigh: "Let the tension ease"
    case .pacedBreathing: "Wind down"
    case .balancedBreathing: "Find your rhythm"
    case .boxBreathing: "Gather your attention"
    case .diaphragmaticBreathing: "Breathe with less effort"
    case .alternateNostrilBreathing: "One side at a time"
    case .meditation: "Make room for your thoughts"
    case .nsdr: "A place to rest"
    case .kegel: "Build gentle control"
    case .progressiveMuscleRelaxation: "Let your body soften"
    }
  }
  var title: String {
    switch self {
    case .physiologicalSigh: "A little sigh"
    case .pacedBreathing: "Longer exhale"
    case .balancedBreathing: "Even breathing"
    case .boxBreathing: "Box breathing"
    case .diaphragmaticBreathing: "Belly breathing"
    case .alternateNostrilBreathing: "Alternate nostril"
    case .meditation: "A quiet moment"
    case .nsdr: "NSDR"
    case .kegel: "Pelvic floor"
    case .progressiveMuscleRelaxation: "Muscle relaxation"
    }
  }
  var summary: String {
    switch self {
    case .physiologicalSigh: "Two gentle breaths in, one slow breath out. A small pause when things feel like a lot."
    case .pacedBreathing: "A little more time on the out-breath, for winding down at the end of a busy day."
    case .balancedBreathing: "Equal time breathing in and out. A simple rhythm to return to."
    case .boxBreathing: "In, pause, out, pause. Four gentle steps to gather your attention."
    case .diaphragmaticBreathing: "Notice your belly and lower ribs move, without asking your shoulders to work harder."
    case .alternateNostrilBreathing: "Follow one side, then the other. Give your attention a simple place to land."
    case .meditation: "Notice when your mind wanders, and gently come back. No empty mind required."
    case .nsdr: "Lie down for a guided body scan and some quiet rest. You don't have to fall asleep."
    case .kegel: "Practice a gentle pelvic floor lift, with plenty of time to release."
    case .progressiveMuscleRelaxation: "Gently tense and release eight muscle groups. Notice what changes when you let go."
    }
  }
  var bestFor: String {
    switch self {
    case .physiologicalSigh: "When you're feeling tense, between tasks, or whenever you'd like a pause."
    case .pacedBreathing: "Before bed, after a long day, or when you'd like to slow down."
    case .balancedBreathing: "For a daily pause, a work break, or when a simple rhythm feels right."
    case .boxBreathing: "Before work, reading, or a conversation that needs your attention."
    case .diaphragmaticBreathing: "When you'd like to explore easier breathing at your own pace."
    case .alternateNostrilBreathing: "When you have a free hand and a quiet moment to focus."
    case .meditation: "When your mind feels busy, or you'd like to practice coming back."
    case .nsdr: "At midday, after work, or when you have time to lie down and rest."
    case .kegel: "When you've chosen pelvic floor training and know the correct movement."
    case .progressiveMuscleRelaxation: "For a daytime reset or a quieter way to settle before bed."
    }
  }
  var steps: String {
    switch self {
    case .physiologicalSigh: "Gently in through your nose → one small top-up → slowly out through your mouth."
    case .pacedBreathing: "Breathe in for 4 seconds → out for 6. No holds."
    case .balancedBreathing: "Equal time in and out: 5 seconds each, or choose 4."
    case .boxBreathing: "In for 3 → pause for 3 → out for 3 → pause for 3."
    case .diaphragmaticBreathing: "Rest your hand on your belly or lower ribs. Notice a little expansion and release, at your own pace."
    case .alternateNostrilBreathing: "Left in → right out → right in → left out. Switch gently, without holding your breath."
    case .meditation: "Feel your support → notice a natural breath → gently return when your mind wanders."
    case .nsdr: "Lie down → follow the body scan → rest quietly → gently return."
    case .kegel: "Gently lift for 4 seconds → fully release for 8. Keep breathing naturally."
    case .progressiveMuscleRelaxation: "Eight muscle groups, once each. Hear the guidance, gently tense for 5 seconds, then release for 25. Keep breathing naturally."
    }
  }
  var preparation: String {
    switch self {
    case .physiologicalSigh: "Keep it gentle. Stop if you feel dizzy or uncomfortable, and breathe normally."
    case .pacedBreathing: "Don't force a deep breath or empty your lungs. If the pace feels difficult, stop and breathe normally."
    case .balancedBreathing: "Keep each breath gentle. Stop if you feel uncomfortable."
    case .boxBreathing: "Includes short holds. Don't push through discomfort. Breathe normally and try Even breathing instead."
    case .diaphragmaticBreathing: "Don't push your belly out, press inward, or force a deep breath. Stop if uncomfortable."
    case .alternateNostrilBreathing: "Choose another practice if your nose is blocked or uncomfortable. Cover lightly, without squeezing."
    case .meditation: "You can keep your eyes open. If uncomfortable, look around and stop."
    case .nsdr: "Use only where you can rest safely. Never while driving or operating equipment. This doesn't replace sleep."
    case .kegel: "Don't practice while urinating. Keep your belly, bottom, and thighs relaxed. For ongoing pelvic tension or pain, bladder or bowel symptoms, or recovery after childbirth or surgery, follow your clinician's advice."
    case .progressiveMuscleRelaxation: "Skip tightening any painful, injured, or cramp-prone area. Release immediately if uncomfortable; don't wait for 5 seconds. Follow professional advice after surgery or when exertion is restricted."
    }
  }
  var completionReview: String {
    switch self {
    case .physiologicalSigh: "You took a moment for a little sigh."
    case .pacedBreathing: "You made time to wind down."
    case .balancedBreathing: "You spent a little time with an even rhythm."
    case .boxBreathing: "You made a little room for focus."
    case .diaphragmaticBreathing: "You explored easier breathing."
    case .alternateNostrilBreathing: "You finished an alternate nostril practice."
    case .meditation: "You made room for a quiet moment."
    case .nsdr: "You gave yourself time to rest."
    case .kegel: "You finished a pelvic floor practice."
    case .progressiveMuscleRelaxation: "You gave your muscles time to let go."
    }
  }
  var outcomeDetail: String { summary }
  var purpose: String { summary }
  var systemImage: String { self == .progressiveMuscleRelaxation ? "figure.cooldown" : self == .nsdr ? "bed.double" : self == .kegel ? "figure.core.training" : "wind" }
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
    case .progressiveMuscleRelaxation: 600
    }
  }
  var v4Tags: [String] {
    switch self {
    case .physiologicalSigh: ["Unwind"]
    case .pacedBreathing: ["Unwind", "Rest"]
    case .balancedBreathing: ["Unwind"]
    case .boxBreathing: ["Focus"]
    case .diaphragmaticBreathing: ["Unwind", "Body"]
    case .alternateNostrilBreathing: ["Focus"]
    case .meditation: ["Focus"]
    case .nsdr: ["Rest"]
    case .kegel: ["Body"]
    case .progressiveMuscleRelaxation: ["Unwind", "Rest", "Body"]
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
    return "\(minutes) min"
  }

  static func clock(_ duration: TimeInterval) -> String {
    let seconds = max(0, Int(duration.rounded(.up)))
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
  }
}
