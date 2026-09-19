import Foundation
import InnerBalanceCore
import UserNotifications

enum CareNotificationAccess { case notAsked, denied, allowed }
@MainActor protocol CareNotificationClient: AnyObject {
  func access() async -> CareNotificationAccess
  func requestPermission() async -> Bool
  func pendingIDs() async -> [String]
  func deliveredIDs() async -> [String]
  func removePending(_ ids: [String])
  func removeDelivered(_ ids: [String])
  func add(_ request: CareNotificationRequest, calendar: Calendar) async throws
}
@MainActor final class SystemCareNotificationClient: CareNotificationClient {
  private let center = UNUserNotificationCenter.current()
  func access() async -> CareNotificationAccess {
    switch await center.notificationSettings().authorizationStatus {
    case .authorized, .provisional, .ephemeral: .allowed
    case .notDetermined: .notAsked
    default: .denied
    }
  }
  func requestPermission() async -> Bool { (try? await center.requestAuthorization(options: [.alert])) ?? false }
  func pendingIDs() async -> [String] { await center.pendingNotificationRequests().map(\.identifier) }
  func deliveredIDs() async -> [String] { await center.deliveredNotifications().map { $0.request.identifier } }
  func removePending(_ ids: [String]) { center.removePendingNotificationRequests(withIdentifiers: ids) }
  func removeDelivered(_ ids: [String]) { center.removeDeliveredNotifications(withIdentifiers: ids) }
  func add(_ request: CareNotificationRequest, calendar: Calendar) async throws {
    let content = UNMutableNotificationContent()
    content.title = FangcunCopy.text(request.titleKey); content.body = FangcunCopy.text(request.bodyKey)
    content.sound = nil; content.badge = nil; content.interruptionLevel = .passive
    content.categoryIdentifier = CareNotificationPlanner.prefix + "actions"
    content.userInfo = ["careCategory": request.category.rawValue]
    var components = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second], from: request.fireAt)
    components.timeZone = calendar.timeZone
    try await center.add(UNNotificationRequest(identifier: request.id, content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)))
  }
  nonisolated static func foregroundOptions(requestID: String) -> UNNotificationPresentationOptions {
    requestID.hasPrefix(CareNotificationPlanner.prefix) ? [] : [.banner]
  }
}
