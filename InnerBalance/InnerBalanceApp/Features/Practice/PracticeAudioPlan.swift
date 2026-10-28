import AVFAudio
import Foundation
import InnerBalanceCore

enum PracticeAudioSessionPolicy {
  static let category: AVAudioSession.Category = .playback
  static let mode: AVAudioSession.Mode = .default
  static let options: AVAudioSession.CategoryOptions = []
}

enum PracticeSoundMode: String, CaseIterable, Equatable {
  case guided
  case rhythmOnly
  case silent

  var title: String {
    switch self {
    case .guided: "Guided"
    case .rhythmOnly: "Cues only"
    case .silent: "Silent"
    }
  }

  var detail: String {
    switch self {
    case .guided: "A few words when you need them"
    case .rhythmOnly: "Follow gentle sound cues"
    case .silent: "Visual and haptic guidance only"
    }
  }

  var supportsAmbience: Bool {
    self != .silent
  }

  static func availableCases(hasVoiceAssets: Bool) -> [Self] {
    hasVoiceAssets ? allCases : [.rhythmOnly, .silent]
  }

  static func resolved(_ preferred: Self, hasVoiceAssets: Bool) -> Self {
    preferred == .guided && !hasVoiceAssets ? .rhythmOnly : preferred
  }
}

enum PracticeAudioLayer: Hashable {
  case voice
  case cue
  case ambience
}

struct PracticeAudioPlan: Equatable {
  let layers: Set<PracticeAudioLayer>

  static func make(mode: PracticeSoundMode, ambienceEnabled: Bool) -> Self {
    switch mode {
    case .guided:
      return Self(layers: ambienceEnabled ? [.voice, .cue, .ambience] : [.voice, .cue])
    case .rhythmOnly:
      return Self(layers: ambienceEnabled ? [.cue, .ambience] : [.cue])
    case .silent:
      return Self(layers: [])
    }
  }
}

enum PracticeAudioCue: String, CaseIterable, Equatable {
  case sighInhale
  case sighTopUp
  case sighExhale
  case pacedInhale
  case pacedExhale
  case meditationSupport
  case meditationBreath
  case meditationReturn
  case nsdrFace
  case nsdrShoulders
  case nsdrBreath
  case nsdrBelly
  case nsdrLegs
  case nsdrReturn
  case kegelContract
  case kegelRelease
  case hold
  case leftInhale, rightExhale, rightInhale, leftExhale

  var voiceResourceName: String {
    switch self {
    case .sighInhale: "practice_sigh_inhale"
    case .sighTopUp: "practice_sigh_top_up"
    case .sighExhale: "practice_sigh_exhale"
    case .pacedInhale: "practice_v4_paced_inhale"
    case .pacedExhale: "practice_v4_paced_exhale"
    case .meditationSupport: "practice_meditation_support"
    case .meditationBreath: "practice_meditation_breath"
    case .meditationReturn: "practice_meditation_return"
    case .nsdrFace: "practice_nsdr_face"
    case .nsdrShoulders: "practice_nsdr_shoulders"
    case .nsdrBreath: "practice_nsdr_breath"
    case .nsdrBelly: "practice_nsdr_belly"
    case .nsdrLegs: "practice_nsdr_legs"
    case .nsdrReturn: "practice_nsdr_return"
    case .kegelContract: "practice_kegel_contract"
    case .kegelRelease: "practice_v4_kegel_release"
    case .hold: "practice_v4_hold"
    case .leftInhale: "practice_v4_left_inhale"
    case .rightExhale: "practice_v4_right_exhale"
    case .rightInhale: "practice_v4_right_inhale"
    case .leftExhale: "practice_v4_left_exhale"
    }
  }

  var spokenText: String {
    switch self {
    case .sighInhale: "Gently breathe in through your nose."
    case .sighTopUp: "A little more."
    case .sighExhale: "Slowly breathe out."
    case .pacedInhale: "Gently breathe in."
    case .pacedExhale: "Let the out-breath be longer."
    case .meditationSupport: "Feel the support beneath you."
    case .meditationBreath: "Notice this ordinary breath."
    case .meditationReturn: "It's okay to wander. Gently come back."
    case .nsdrFace: "Soften your eyes and your jaw."
    case .nsdrShoulders: "Let your shoulders rest."
    case .nsdrBreath: "Gently in. Slowly out. Let your weight be supported."
    case .nsdrBelly: "Let your belly rest. Breathing can happen on its own."
    case .nsdrLegs: "Let your legs and feet rest."
    case .nsdrReturn: "Move your fingers and toes. Open your eyes when you're ready."
    case .kegelContract: "Gently lift. Keep breathing."
    case .kegelRelease: "Let go completely."
    case .hold: "Gently pause."
    case .leftInhale: "Left, breathe in."
    case .rightExhale: "Right, breathe out."
    case .rightInhale: "Right, breathe in."
    case .leftExhale: "Left, breathe out."
    }
  }
}

enum PracticeAudioBackgroundPolicy {
  static func shouldPauseWhenInactive(
    mode: PracticeSoundMode,
    ambienceEnabled: Bool,
    continuousAudioAvailable: Bool
  ) -> Bool {
    mode == .silent || !ambienceEnabled || !continuousAudioAvailable
  }

  static func shouldPauseForRouteChange(
    reason: AVAudioSession.RouteChangeReason
  ) -> Bool {
    reason == .oldDeviceUnavailable
  }
}

enum PracticeVoiceAssets {
  static let selectedPackID = "little-exhale-ava-en-20261028"

  static func isAvailable(for kind: PracticeKind, bundle: Bundle = .main) -> Bool {
    requiredResourceNames(for: kind).allSatisfy { url(named: $0, bundle: bundle) != nil }
  }

  static func url(for cue: PracticeAudioCue, bundle: Bundle = .main) -> URL? {
    url(named: cue.voiceResourceName, bundle: bundle)
  }

  static func url(named name: String, bundle: Bundle = .main) -> URL? {
    let name = "le2_" + name
    return ["m4a", "mp3", "wav"].lazy.compactMap { ext in
      bundle.url(forResource: name, withExtension: ext, subdirectory: "PracticeVoice")
        ?? bundle.url(forResource: name, withExtension: ext)
    }.first
  }

  static func resourceName(for segment: PracticeGuidedSegment) -> String {
    "guide20_" + segment.id
  }

  static func requiredResourceNames(for kind: PracticeKind) -> [String] {
    var resources: [String] = []
    let steps = PracticeTimeline.steps(for: kind)
    if !steps.isEmpty {
      resources = (0..<2).flatMap { cycle in
        steps.indices.map { PracticeGuidanceContent.phaseResource(for: kind, cycle: cycle, index: $0) }
      }
    } else {
      let variants: [String?] = kind == .progressiveMuscleRelaxation ? ["pmr_day", "pmr_sleep"] : [nil]
      resources = variants.flatMap { variant in
        (PracticeCatalog.protocol(for: kind)?.durationOptions ?? []).flatMap { duration in
          PracticeTimeline.segments(for: kind, duration: duration, variantID: variant).map(resourceName)
        }
      }
    }
    return Array(Set(resources)).sorted()
  }

}

struct PracticeCueToneSpec: Equatable {
  let startFrequency: Double
  let endFrequency: Double
  let duration: TimeInterval

  static func `for`(_ cue: PracticeAudioCue) -> Self {
    switch cue {
    case .hold: Self(startFrequency: 330, endFrequency: 330, duration: 0.3)
    case .leftInhale: Self(startFrequency: 320, endFrequency: 480, duration: 0.6)
    case .rightExhale: Self(startFrequency: 520, endFrequency: 320, duration: 0.6)
    case .rightInhale: Self(startFrequency: 400, endFrequency: 600, duration: 0.6)
    case .leftExhale: Self(startFrequency: 440, endFrequency: 260, duration: 0.6)
    case .sighInhale: Self(startFrequency: 392, endFrequency: 523, duration: 0.55)
    case .sighTopUp: Self(startFrequency: 523, endFrequency: 659, duration: 0.35)
    case .sighExhale: Self(startFrequency: 392, endFrequency: 220, duration: 1.2)
    case .pacedInhale: Self(startFrequency: 349, endFrequency: 523, duration: 0.9)
    case .pacedExhale: Self(startFrequency: 440, endFrequency: 261, duration: 1.2)
    case .meditationSupport: Self(startFrequency: 392, endFrequency: 494, duration: 0.8)
    case .meditationBreath: Self(startFrequency: 349, endFrequency: 440, duration: 0.8)
    case .meditationReturn: Self(startFrequency: 330, endFrequency: 415, duration: 0.8)
    case .nsdrFace: Self(startFrequency: 330, endFrequency: 294, duration: 1)
    case .nsdrShoulders: Self(startFrequency: 294, endFrequency: 261, duration: 1)
    case .nsdrBreath: Self(startFrequency: 294, endFrequency: 220, duration: 1.2)
    case .nsdrBelly: Self(startFrequency: 261, endFrequency: 247, duration: 1)
    case .nsdrLegs: Self(startFrequency: 247, endFrequency: 220, duration: 1)
    case .nsdrReturn: Self(startFrequency: 247, endFrequency: 330, duration: 1.2)
    case .kegelContract: Self(startFrequency: 330, endFrequency: 494, duration: 0.5)
    case .kegelRelease: Self(startFrequency: 392, endFrequency: 247, duration: 0.9)
    }
  }
}

struct PracticeAmbienceSpec: Equatable {
  let frequencies: [Double]
  let duration: TimeInterval
  let volume: Double

  static func `for`(_ kind: PracticeKind) -> Self {
    switch kind {
    case .physiologicalSigh:
      Self(frequencies: [98, 147, 196], duration: 8, volume: 0.025)
    case .pacedBreathing, .balancedBreathing, .boxBreathing, .alternateNostrilBreathing:
      Self(frequencies: [65.5, 98.25, 131], duration: 8, volume: 0.028)
    case .meditation, .diaphragmaticBreathing:
      Self(frequencies: [55, 82.5, 110], duration: 8, volume: 0.032)
    case .nsdr, .progressiveMuscleRelaxation:
      Self(frequencies: [44, 66, 88], duration: 8, volume: 0.035)
    case .kegel:
      Self(frequencies: [73.5, 110.25, 147], duration: 8, volume: 0.022)
    }
  }
}

struct PracticeAudioMoment: Equatable {
  let id: Int
  let cue: PracticeAudioCue
  let shouldSpeak: Bool
  var voiceResourceName: String? = nil
  var offset: TimeInterval = 0
  var remainingWindow: TimeInterval = .infinity
  var isSegment: Bool = false
}

enum PracticeAudioTimeline {
  static func moment(for kind: PracticeKind, elapsed: TimeInterval, duration: TimeInterval? = nil, variantID: String? = nil) -> PracticeAudioMoment {
    moment(for: kind, snapshot: PracticeTimeline.snapshot(kind: kind, elapsed: elapsed,
      duration: duration ?? PracticeCatalog.protocol(for: kind)?.defaultDuration ?? 300, variantID: variantID))
  }

  static func moment(for kind: PracticeKind, snapshot: PracticeTimelineSnapshot) -> PracticeAudioMoment {
    let cue = cue(for: kind, snapshot: snapshot)
    return PracticeAudioMoment(id: snapshot.cueID, cue: cue,
      shouldSpeak: !(snapshot.segment?.id.hasSuffix("_resume_release") ?? false) && (snapshot.segment != nil || kind == .alternateNostrilBreathing || snapshot.cycleIndex < 2),
      voiceResourceName: snapshot.segment.map(PracticeVoiceAssets.resourceName) ?? phaseResource(kind: kind, snapshot: snapshot),
      offset: snapshot.elapsedInPhase, remainingWindow: max(0, snapshot.phaseDuration - snapshot.elapsedInPhase),
      isSegment: snapshot.segment != nil)
  }

  private static func phaseResource(kind: PracticeKind, snapshot: PracticeTimelineSnapshot) -> String {
    let count = PracticeTimeline.steps(for: kind, variantID: snapshot.variantID).count
    guard count > 0 else { return PracticeAudioCue.meditationBreath.voiceResourceName }
    return PracticeGuidanceContent.phaseResource(for: kind, cycle: snapshot.cycleIndex, index: snapshot.cueID % count)
  }

  static func cue(for kind: PracticeKind, elapsed: TimeInterval, duration: TimeInterval? = nil) -> PracticeAudioCue {
    moment(for: kind, elapsed: elapsed, duration: duration).cue
  }

  private static func cue(for kind: PracticeKind, snapshot: PracticeTimelineSnapshot) -> PracticeAudioCue {
    if let segment = snapshot.segment {
      if kind == .progressiveMuscleRelaxation {
        if segment.focus.hasSuffix("gentle_tension") { return .kegelContract }
        if segment.focus.hasSuffix("release") { return .kegelRelease }
      }
      if kind == .meditation { return segment.focus == "return" ? .meditationReturn : segment.focus == "breath" ? .meditationBreath : .meditationSupport }
      switch segment.focus {
      case "face": return .nsdrFace
      case "shoulders", "arms", "hands": return .nsdrShoulders
      case "belly", "hips", "lowerRibs", "release": return .nsdrBelly
      case "legs", "feet": return .nsdrLegs
      case "return", "finish": return .nsdrReturn
      default: return .nsdrBreath
      }
    }
    switch snapshot.phase {
    case .inhale: return kind == .physiologicalSigh ? .sighInhale : .pacedInhale
    case .topUp: return .sighTopUp
    case .exhale: return kind == .physiologicalSigh ? .sighExhale : .pacedExhale
    case .holdAfterInhale, .holdAfterExhale: return .hold
    case .leftInhale: return .leftInhale
    case .rightExhale: return .rightExhale
    case .rightInhale: return .rightInhale
    case .leftExhale: return .leftExhale
    case .contract: return .kegelContract
    case .release: return .kegelRelease
    case .natural, nil: return .meditationBreath
    }
  }
}

/// Resuming seeks only inside the current cue. The phase boundary is a hard stop.
struct PracticeVoicePlaybackSlice: Equatable {
  let startFrame: AVAudioFramePosition
  let frameCount: AVAudioFrameCount

  static func make(frameLength: AVAudioFramePosition, sampleRate: Double,
    offset: TimeInterval, remainingWindow: TimeInterval) -> Self? {
    guard sampleRate.isFinite, sampleRate > 0, offset.isFinite,
      offset >= 0, remainingWindow > 0, frameLength > 0 else { return nil }
    guard offset < Double(frameLength) / sampleRate else { return nil }
    let start = AVAudioFramePosition((offset * sampleRate).rounded(.down))
    let available = frameLength - start
    let window = remainingWindow.isFinite ? min(Double(available), remainingWindow * sampleRate) : Double(available)
    let length = AVAudioFramePosition(window.rounded(.down))
    guard length > 0 else { return nil }
    return Self(startFrame: start, frameCount: AVAudioFrameCount(min(length, Int64(UInt32.max))))
  }
}
