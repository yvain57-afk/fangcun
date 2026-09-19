import Foundation
import Testing
import InnerBalanceCore
@testable import InnerBalance
@Suite @MainActor struct BeverageCareCoordinatorTests {
  @Test func acknowledgeAndMuteNeverWriteDiaryAndSurviveRestart() {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let owner = BeverageCareCoordinator(directory: root, notificationsEnabled: false)
    owner.refresh(events: [])
    let now = Date.now; owner.action("care.ack", now: now)
    #expect(owner.ledger.waterAcknowledgedUntil == now.addingTimeInterval(3*3600))
    owner.action("care.mute", now: now)
    let restarted = BeverageCareCoordinator(directory: root, notificationsEnabled: false)
    #expect(restarted.ledger == owner.ledger)
    #expect(restarted.preferences.waterPush == false && restarted.preferences.referenceAccepted == false)
  }
}
