import HealthKit

enum HealthSyncCursorKind: String, Sendable {
  case stateOfMind
  case mindfulSession
}

struct HealthSyncCursorStore {
  private let userDefaults: UserDefaults
  private let keyPrefix = "com.yvainair.innerbalance.healthCursor."

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  func load(for kind: HealthSyncCursorKind) throws -> HKQueryAnchor? {
    guard let data = userDefaults.data(forKey: key(for: kind)) else { return nil }
    return try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
  }

  func save(_ anchor: HKQueryAnchor, for kind: HealthSyncCursorKind) throws {
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: anchor,
      requiringSecureCoding: true
    )
    userDefaults.set(data, forKey: key(for: kind))
  }

  func clear(for kind: HealthSyncCursorKind) {
    userDefaults.removeObject(forKey: key(for: kind))
  }

  private func key(for kind: HealthSyncCursorKind) -> String {
    keyPrefix + kind.rawValue
  }
}
