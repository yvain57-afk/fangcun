import Foundation
import Observation

@MainActor
@Observable
final class PracticeSoundPreferences {
  private enum Key {
    static let mode = "practice.sound.mode"
    static let ambience = "practice.sound.ambience"
    static let voicePack = "practice.voice.pack"
  }

  private let defaults: UserDefaults

  var preferredMode: PracticeSoundMode {
    didSet { defaults.set(preferredMode.rawValue, forKey: Key.mode) }
  }

  var ambienceEnabled: Bool {
    didSet { defaults.set(ambienceEnabled, forKey: Key.ambience) }
  }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if defaults.string(forKey: Key.voicePack) != PracticeVoiceAssets.selectedPackID {
      preferredMode = .guided
      defaults.set(PracticeSoundMode.guided.rawValue, forKey: Key.mode)
      defaults.set(PracticeVoiceAssets.selectedPackID, forKey: Key.voicePack)
    } else {
      preferredMode =
        defaults.string(forKey: Key.mode).flatMap(PracticeSoundMode.init(rawValue:)) ?? .guided
    }
    ambienceEnabled =
      defaults.object(forKey: Key.ambience) == nil
      ? true
      : defaults.bool(forKey: Key.ambience)
  }

  func mode(hasVoiceAssets: Bool) -> PracticeSoundMode {
    PracticeSoundMode.resolved(preferredMode, hasVoiceAssets: hasVoiceAssets)
  }
}
