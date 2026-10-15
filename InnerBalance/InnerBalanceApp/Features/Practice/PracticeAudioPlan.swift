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
    case .guided: "语音引导"
    case .rhythmOnly: "仅节奏"
    case .silent: "静音"
    }
  }

  var detail: String {
    switch self {
    case .guided: "关键时刻听到简短指引"
    case .rhythmOnly: "用高低音跟随动作"
    case .silent: "只保留视觉与触觉"
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
    case .sighInhale: "用鼻子，轻轻吸气。"
    case .sighTopUp: "再补一小口。"
    case .sighExhale: "慢慢呼出去。"
    case .pacedInhale: "慢慢吸气。"
    case .pacedExhale: "把呼气放长。"
    case .meditationSupport: "感觉身体，被稳稳托住。"
    case .meditationBreath: "留意这一口，自然的呼吸。"
    case .meditationReturn: "走神也没关系，回来就好。"
    case .nsdrFace: "松开眼周，也松开下颌。"
    case .nsdrShoulders: "让肩膀，把重量交出去。"
    case .nsdrBreath: "轻轻吸气。慢慢呼气，把重量交出去。"
    case .nsdrBelly: "腹部不用用力，让呼吸自己来。"
    case .nsdrLegs: "双腿沉下来，脚也松开。"
    case .nsdrReturn: "动动手指和脚趾。准备好时，慢慢睁开眼睛。"
    case .kegelContract: "轻轻收紧，呼吸照常。"
    case .kegelRelease: "完全放松。"
    case .hold: "轻松停留。"
    case .leftInhale: "左侧吸气。"
    case .rightExhale: "右侧呼气。"
    case .rightInhale: "右侧吸气。"
    case .leftExhale: "左侧呼气。"
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
  static let selectedPackID = "zhixingnv"

  static func isAvailable(for kind: PracticeKind, bundle: Bundle = .main) -> Bool {
    requiredResourceNames(for: kind).allSatisfy { url(named: $0, bundle: bundle) != nil }
  }

  static func url(for cue: PracticeAudioCue, bundle: Bundle = .main) -> URL? {
    url(named: cue.voiceResourceName, bundle: bundle)
  }

  static func url(named name: String, bundle: Bundle = .main) -> URL? {
    ["m4a", "mp3", "wav"].lazy.compactMap { ext in
      bundle.url(forResource: name, withExtension: ext, subdirectory: "PracticeVoice")
        ?? bundle.url(forResource: name, withExtension: ext)
    }.first
  }

  static func resourceName(for segment: PracticeGuidedSegment) -> String {
    "practice_v4_" + segment.id
  }

  static func requiredResourceNames(for kind: PracticeKind) -> [String] {
    switch kind {
    case .physiologicalSigh: return [.sighInhale, .sighTopUp, .sighExhale].map { (cue: PracticeAudioCue) in cue.voiceResourceName }
    case .pacedBreathing, .balancedBreathing: return [PracticeAudioCue.pacedInhale, .pacedExhale].map(\.voiceResourceName)
    case .boxBreathing: return [PracticeAudioCue.pacedInhale, .hold, .pacedExhale].map(\.voiceResourceName)
    case .alternateNostrilBreathing: return [PracticeAudioCue.leftInhale, .rightExhale, .rightInhale, .leftExhale].map(\.voiceResourceName)
    case .kegel: return [PracticeAudioCue.kegelContract, .kegelRelease].map(\.voiceResourceName)
    case .meditation, .nsdr, .diaphragmaticBreathing:
      let durations: [Double] = kind == .nsdr ? [600, 1200] : kind == .meditation ? [300, 600] : [180, 300]
      return durations.flatMap { PracticeTimeline.segments(for: kind, duration: $0).map(resourceName) }
    }
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
    case .nsdr:
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
      shouldSpeak: snapshot.segment != nil || kind == .alternateNostrilBreathing || snapshot.cycleIndex < 2,
      voiceResourceName: snapshot.segment.map(PracticeVoiceAssets.resourceName) ?? cue.voiceResourceName,
      offset: snapshot.elapsedInPhase, remainingWindow: max(0, snapshot.phaseDuration - snapshot.elapsedInPhase),
      isSegment: snapshot.segment != nil)
  }

  static func cue(for kind: PracticeKind, elapsed: TimeInterval, duration: TimeInterval? = nil) -> PracticeAudioCue {
    moment(for: kind, elapsed: elapsed, duration: duration).cue
  }

  private static func cue(for kind: PracticeKind, snapshot: PracticeTimelineSnapshot) -> PracticeAudioCue {
    if let segment = snapshot.segment {
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
