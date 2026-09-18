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

  var voiceResourceName: String {
    switch self {
    case .sighInhale: "practice_sigh_inhale"
    case .sighTopUp: "practice_sigh_top_up"
    case .sighExhale: "practice_sigh_exhale"
    case .pacedInhale: "practice_paced_inhale"
    case .pacedExhale: "practice_paced_exhale"
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
    case .kegelRelease: "practice_kegel_release"
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
    case .kegelRelease: "慢慢放松，不要急。"
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
    cues(for: kind).allSatisfy { url(for: $0, bundle: bundle) != nil }
  }

  static func url(for cue: PracticeAudioCue, bundle: Bundle = .main) -> URL? {
    ["m4a", "mp3", "wav"].lazy.compactMap { fileExtension in
      bundle.url(
        forResource: cue.voiceResourceName,
        withExtension: fileExtension,
        subdirectory: "PracticeVoice"
      )
        ?? bundle.url(
          forResource: cue.voiceResourceName,
          withExtension: fileExtension
        )
    }.first
  }

  private static func cues(for kind: PracticeKind) -> [PracticeAudioCue] {
    switch kind {
    case .physiologicalSigh: [.sighInhale, .sighTopUp, .sighExhale]
    case .pacedBreathing: [.pacedInhale, .pacedExhale]
    case .meditation: [.meditationSupport, .meditationBreath, .meditationReturn]
    case .nsdr:
      [.nsdrFace, .nsdrShoulders, .nsdrBreath, .nsdrBelly, .nsdrLegs, .nsdrReturn]
    case .kegel: [.kegelContract, .kegelRelease]
    }
  }
}

struct PracticeCueToneSpec: Equatable {
  let startFrequency: Double
  let endFrequency: Double
  let duration: TimeInterval

  static func `for`(_ cue: PracticeAudioCue) -> Self {
    switch cue {
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
    case .pacedBreathing:
      Self(frequencies: [65.5, 98.25, 131], duration: 8, volume: 0.028)
    case .meditation:
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
}

enum PracticeAudioTimeline {
  static func moment(
    for kind: PracticeKind,
    elapsed: TimeInterval,
    duration: TimeInterval? = nil
  ) -> PracticeAudioMoment {
    let elapsed = max(0, elapsed)
    let id = momentID(for: kind, elapsed: elapsed, duration: duration)
    return PracticeAudioMoment(
      id: id,
      cue: cue(for: kind, elapsed: elapsed, duration: duration),
      shouldSpeak: shouldSpeak(kind: kind, momentID: id)
    )
  }

  static func cue(
    for kind: PracticeKind,
    elapsed: TimeInterval,
    duration: TimeInterval? = nil
  ) -> PracticeAudioCue {
    let elapsed = max(0, elapsed)
    switch kind {
    case .physiologicalSigh:
      return switch elapsed.truncatingRemainder(dividingBy: 12) {
      case 0..<3: .sighInhale
      case 3..<5: .sighTopUp
      default: .sighExhale
      }
    case .pacedBreathing:
      return elapsed.truncatingRemainder(dividingBy: 10) < 4 ? .pacedInhale : .pacedExhale
    case .meditation:
      let cues = [
        PracticeAudioCue.meditationSupport,
        .meditationBreath,
        .meditationReturn,
      ]
      return cues[(Int(elapsed) / 30) % cues.count]
    case .nsdr:
      return PracticeBodyScanState.make(elapsed: elapsed, duration: duration).cue
    case .kegel:
      return elapsed.truncatingRemainder(dividingBy: 12) < 4 ? .kegelContract : .kegelRelease
    }
  }

  private static func momentID(
    for kind: PracticeKind,
    elapsed: TimeInterval,
    duration: TimeInterval?
  ) -> Int {
    switch kind {
    case .physiologicalSigh:
      let cycle = Int(elapsed / 12)
      let position = elapsed.truncatingRemainder(dividingBy: 12)
      let phase = position < 3 ? 0 : position < 5 ? 1 : 2
      return cycle * 3 + phase
    case .pacedBreathing:
      let cycle = Int(elapsed / 10)
      let phase = elapsed.truncatingRemainder(dividingBy: 10) < 4 ? 0 : 1
      return cycle * 2 + phase
    case .meditation:
      return Int(elapsed / 30)
    case .nsdr:
      return PracticeBodyScanState.make(elapsed: elapsed, duration: duration).id
    case .kegel:
      let cycle = Int(elapsed / 12)
      let phase = elapsed.truncatingRemainder(dividingBy: 12) < 4 ? 0 : 1
      return cycle * 2 + phase
    }
  }

  private static func shouldSpeak(kind: PracticeKind, momentID: Int) -> Bool {
    switch kind {
    case .physiologicalSigh:
      return momentID < 6
    case .pacedBreathing, .kegel:
      return momentID < 4
    case .meditation, .nsdr:
      return true
    }
  }
}
