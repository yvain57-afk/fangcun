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
    // A new asset pack must not overwrite a person's existing mute/rhythm choice.
    preferredMode = defaults.string(forKey: Key.mode).flatMap(PracticeSoundMode.init(rawValue:)) ?? .guided
    defaults.set(PracticeVoiceAssets.selectedPackID, forKey: Key.voicePack)
    ambienceEnabled =
      defaults.object(forKey: Key.ambience) == nil
      ? true
      : defaults.bool(forKey: Key.ambience)
  }

  func mode(hasVoiceAssets: Bool) -> PracticeSoundMode {
    PracticeSoundMode.resolved(preferredMode, hasVoiceAssets: hasVoiceAssets)
  }
}

/// Independent layers retain zero as an intentional mute. No new key resets old preferences.
enum PracticeAudioLevels {
  static func read(_ layer: String, defaults: UserDefaults = .standard) -> Float {
    let key = "practice.sound.volume." + layer
    guard defaults.object(forKey: key) != nil else { return 1 }
    return Float(min(1, max(0, defaults.double(forKey: key))))
  }
}
