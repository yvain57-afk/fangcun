import HealthKit
import Testing

@testable import InnerBalance

@Suite("Health sync cursor")
struct HealthSyncCursorStoreTests {
  @Test("An anchored-query cursor can be restored and cleared")
  func cursorRoundTrip() throws {
    let suiteName = "HealthSyncCursorStoreTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = HealthSyncCursorStore(userDefaults: defaults)

    try store.save(HKQueryAnchor(fromValue: 17), for: .stateOfMind)

    #expect(try store.load(for: .stateOfMind) != nil)
    store.clear(for: .stateOfMind)
    #expect(try store.load(for: .stateOfMind) == nil)
  }
}
