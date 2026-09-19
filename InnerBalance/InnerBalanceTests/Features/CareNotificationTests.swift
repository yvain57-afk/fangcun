import Foundation
import Testing
import UserNotifications
import InnerBalanceCore
@testable import InnerBalance

@Suite @MainActor struct CareNotificationTests {
  final class Client: CareNotificationClient {
    var status = CareNotificationAccess.allowed
    var permissionRequests = 0
    var pending = ["another.feature.reminder"]
    var delivered = ["another.feature.delivered"]
    var plans: [CareNotificationRequest] = []
    var fail = false
    func access() async -> CareNotificationAccess { status }
    func requestPermission() async -> Bool { permissionRequests += 1; status = .allowed; return true }
    func pendingIDs() async -> [String] { pending }
    func deliveredIDs() async -> [String] { delivered }
    func removePending(_ ids: [String]) { pending.removeAll { ids.contains($0) }; plans.removeAll { ids.contains($0.id) } }
    func removeDelivered(_ ids: [String]) { delivered.removeAll { ids.contains($0) } }
    func add(_ request: CareNotificationRequest, calendar: Calendar) async throws {
      if fail { throw CocoaError(.fileWriteUnknown) }
      pending.append(request.id); plans.append(request)
    }
  }
  func setup(_ client: Client) -> (BeverageCareCoordinator, URL) {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    return (.init(directory: root, client: client), root)
  }
  @Test func noPromptAtStartupAndDeniedNeverRequestsAgain() async {
    let client = Client(); client.status = .notAsked
    let (owner, root) = setup(client); defer { try? FileManager.default.removeItem(at: root) }
    await owner.replan()
    #expect(client.permissionRequests == 0 && client.plans.isEmpty)
    client.status = .denied
    await owner.enablePush(.water, enabled: true)
    #expect(client.permissionRequests == 0 && !owner.preferences.waterPush && owner.authorization == "denied")
    client.status = .notAsked
    await owner.enablePush(.water, enabled: true)
    #expect(client.permissionRequests == 1 && owner.preferences.waterPush)
  }
  @Test func plansCancelOnlyOwnedRequestsAndClearRetainsOtherFeatures() async {
    let client = Client(); let (owner, root) = setup(client)
    defer { try? FileManager.default.removeItem(at: root) }
    var p = owner.preferences; p.waterPush = true; owner.update(p)
    await owner.replan()
    #expect(!client.plans.isEmpty)
    #expect(client.plans.allSatisfy { $0.bodyKey == "care.notification.generic" })
    client.delivered.append(client.plans[0].id)
    await owner.clearPrivateCare()
    await owner.replan()
    #expect(client.pending == ["another.feature.reminder"] && client.delivered == ["another.feature.delivered"])
    #expect(client.plans.isEmpty && !owner.preferences.waterPush)
  }
  @Test func foregroundCareIsSilentAndSchedulingIsNotDelivery() async {
    #expect(SystemCareNotificationClient.foregroundOptions(requestID: "fangcun.care.test").isEmpty)
    #expect(SystemCareNotificationClient.foregroundOptions(requestID: "another.feature").contains(.banner))
    let client = Client(); let (owner, root) = setup(client)
    defer { try? FileManager.default.removeItem(at: root) }
    var p = owner.preferences; p.waterPush = true; owner.update(p)
    await owner.replan()
    #expect(owner.ledger.entries.contains { $0.state == "scheduled" })
    #expect(!owner.ledger.entries.contains { $0.state == "systemConfirmedDelivered" })
  }
  @Test func coldStartActionIsPersistedAndDuplicateDoesNotNavigateTwice() async throws {
    let client = Client(); let (owner, root) = setup(client)
    defer { try? FileManager.default.removeItem(at: root) }
    var p = owner.preferences; p.waterPush = true; owner.update(p); await owner.replan()
    let requestID = try #require(owner.ledger.entries.first { $0.channel == "push" }?.requestID)
    let restarted = BeverageCareCoordinator(directory: root, client: client)
    await restarted.handleResponse(requestID: requestID, action: "care.record")
    #expect(restarted.pendingRoute == "record")
    restarted.pendingRoute = nil
    await restarted.handleResponse(requestID: requestID, action: "care.record")
    #expect(restarted.pendingRoute == nil)
    #expect(restarted.ledger.entries.contains { $0.handledActionIDs.contains(requestID + ":care.record") })
  }
}
