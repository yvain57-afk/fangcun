import Foundation
import InnerBalanceCore

/// One optional resumable draft; completed records continue through PracticeCompletionStore.
/// Failed/unknown decoding never deletes the original bytes or touches existing user data.
enum PracticeSessionDraftStore {
  private static let runtimeDefaults: UserDefaults = {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
      let defaults = UserDefaults(suiteName: "fangcun.practice.v4.ui-testing")!
      if !ProcessInfo.processInfo.arguments.contains("--ui-testing-preserve-practice-draft") {
        defaults.removeObject(forKey: key)
      }
      return defaults
    }
    #endif
    return .standard
  }()
  static let key = "fangcun.practice.v4.confirmed-checkpoint"
  static let quarantinePrefix = key + ".unreadable."
  static func load(defaults: UserDefaults? = nil) -> PracticeSessionCheckpoint? {
    let defaults = defaults ?? runtimeDefaults
    guard let data = defaults.data(forKey: key),
      let value = try? JSONDecoder().decode(PracticeSessionCheckpoint.self, from: data), value.isValid else { return nil }
    return value
  }
  @discardableResult static func save(_ value: PracticeSessionCheckpoint, defaults: UserDefaults? = nil) -> Bool {
    let defaults = defaults ?? runtimeDefaults
    guard value.isValid, let data = try? JSONEncoder().encode(value) else { return false }
    if let original = defaults.data(forKey: key), load(defaults: defaults) == nil {
      // A new session may proceed, but a malformed/future draft remains recoverable.
      let quarantineKey = quarantinePrefix + UUID().uuidString
      defaults.set(original, forKey: quarantineKey)
      guard defaults.data(forKey: quarantineKey) == original else { return false }
    }
    defaults.set(data, forKey: key)
    return defaults.data(forKey: key) == data
  }
  static func clear(sessionID: String, defaults: UserDefaults? = nil) {
    let defaults = defaults ?? runtimeDefaults
    guard load(defaults: defaults)?.sessionID == sessionID else { return }
    defaults.removeObject(forKey: key)
  }
}
