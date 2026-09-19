import Foundation
import InnerBalanceCore
import Observation
import SwiftUI
import UserNotifications

private struct CareOwnerKey: EnvironmentKey { static let defaultValue: BeverageCareCoordinator? = nil }
extension EnvironmentValues {
  var careOwner: BeverageCareCoordinator? { get { self[CareOwnerKey.self] } set { self[CareOwnerKey.self] = newValue } }
}
struct CareArchive: Codable {
  var version = 1
  var preferences = CarePreferences()
  var ledger = CareLedger()
}
@MainActor @Observable final class BeverageCareCoordinator {
  private(set) var archive = CareArchive()
  private(set) var selection: CareSelection?
  private(set) var errorKey: String?
  private(set) var authorization = "unknown"
  private(set) var scheduledThrough: Date?
  var pendingRoute: String?
  private let file: URL
  private let notificationsEnabled: Bool
  private let client: any CareNotificationClient
  private var delegate: CareNotificationDelegate?
  private var events: [BeverageEvent] = []
  private var sessionDismissed = false
  private var generation = 0
  private var planning = false
  private var needsReplan = false
  var preferences: CarePreferences { archive.preferences }
  var ledger: CareLedger { archive.ledger }
  init(directory: URL, notificationsEnabled: Bool = true, client: (any CareNotificationClient)? = nil) {
    self.client = client ?? SystemCareNotificationClient()
    file = directory.appendingPathComponent("care-v2.json"); self.notificationsEnabled = notificationsEnabled
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      if FileManager.default.fileExists(atPath: file.path) {
        archive = try JSONDecoder().decode(CareArchive.self, from: Data(contentsOf: file))
        guard archive.version == 1 else { throw CocoaError(.coderReadCorrupt) }
      }
    } catch { errorKey = "care.storageError" }
    if notificationsEnabled && client == nil {
      let handler = CareNotificationDelegate(owner: self); delegate = handler
      UNUserNotificationCenter.current().delegate = handler
      Task { await registerCategories() }
    }
  }
  static func make() -> BeverageCareCoordinator {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
      return .init(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), notificationsEnabled: false)
    }
    #endif
    let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FangcunCare")
    return .init(directory: directory)
  }
  @discardableResult private func persist(_ value: CareArchive) -> Bool {
    guard errorKey == nil else { return false }
    do {
      try JSONEncoder().encode(value).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
      archive = value; return true
    } catch { errorKey = "care.storageError"; return false }
  }
  func update(_ value: CarePreferences) {
    guard (500...3500).contains(value.referenceML), value.referenceML % 250 == 0,
      (10...3000).contains(value.cupML), (6...12).contains(value.lateWindowHours),
      (1...400).contains(value.caffeineReferenceMG), (0..<1440).contains(value.sleepMinute),
      (0..<1440).contains(value.wakeMinute), value.cutoffMinute.map({ (0..<1440).contains($0) }) ?? true else { return }
    var next = archive; next.preferences = value
    guard persist(next) else { return }; refresh(events: events)
  }
  func refresh(events: [BeverageEvent], now: Date = .now, calendar: Calendar = .current) {
    generation += 1
    self.events = events
    var next = archive
    let totals = BeverageTotals(events.filter { calendar.isDate($0.consumedAt, inSameDayAs: now) })
    if preferences.referenceAccepted && preferences.volumePromptsAllowed && totals.nonAlcoholBeverageML >= preferences.referenceML {
      next.ledger.waterTargetMetUntil = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
    }
    let candidates = BeverageCareEngine.evaluate(events: events, preferences: preferences, ledger: next.ledger, now: now, calendar: calendar)
    let result = CareAttentionPolicy.select(candidates, ledger: next.ledger, now: now, sessionDismissed: sessionDismissed)
    if let result, result.noticeable {
      next.ledger.entries.append(.init(candidateID: result.candidate.id, basisIDs: result.candidate.basisIDs,
        expiresAt: result.candidate.expiresAt, category: result.candidate.category))
      next.ledger.entries[next.ledger.entries.count - 1].attentionKey = result.candidate.attentionKey
    }
    if next.ledger != archive.ledger, !persist(next) { selection = nil; return }
    selection = result
    Task { await replan(now: now, calendar: calendar) }
  }
  func action(_ key: String, now: Date = .now, calendar: Calendar = .current) {
    if key == "care.record" || key == "care.view" { pendingRoute = "record"; return }
    var next = archive
    switch key {
    case "care.ack": next.ledger.waterAcknowledgedUntil = now.addingTimeInterval(3*3600)
    case "care.snooze": next.ledger.waterSnoozedUntil = now.addingTimeInterval(3600)
    case "care.mute": next.ledger.muteToday(now: now, calendar: calendar)
    case "care.dismiss": next.ledger.dismissedUntil = now.addingTimeInterval(4*3600); sessionDismissed = true
    case "care.tooMuch": next.ledger.drankTooMuchAt = now
    case "care.severe": next.ledger.severeSymptomsAt = now
    case "care.safetyResolved": next.ledger.severeSymptomsAt = nil
    case "care.laterAlcohol": next.ledger.requestedAlcoholReminderAt = now.addingTimeInterval(30*60)
    default: return
    }
    guard persist(next) else { return }
    // Acknowledgement is care state only. This owner cannot write the diary.
    refresh(events: events, now: now, calendar: calendar)
  }
  func enablePush(_ category: CareCategory, enabled: Bool) async {
    guard notificationsEnabled else { authorization = "unavailable"; return }
    var allowed = false
    if enabled {
      let status = await client.access()
      if status == .notAsked { allowed = await client.requestPermission() }
      else { allowed = status == .allowed }
      authorization = allowed ? "enabled" : "denied"
    }
    var p = preferences
    switch category { case .water: p.waterPush = enabled && allowed; case .caffeine: p.caffeinePush = enabled && allowed
    case .alcohol: p.alcoholPush = enabled && allowed; case .danger: return }
    update(p)
  }
  func foreground() { sessionDismissed = false; refresh(events: events) }
  func clearPrivateCare() async {
    generation += 1; needsReplan = true
    let pending = await client.pendingIDs()
    client.removePending(pending.filter { $0.hasPrefix(CareNotificationPlanner.prefix) })
    let delivered = await client.deliveredIDs()
    client.removeDelivered(delivered.filter { $0.hasPrefix(CareNotificationPlanner.prefix) })
    if persist(CareArchive()) { selection = nil; scheduledThrough = nil }
  }
  private func registerCategories() async {
    let center = UNUserNotificationCenter.current()
    var categories = await center.notificationCategories()
    categories = categories.filter { !$0.identifier.hasPrefix(CareNotificationPlanner.prefix) }
    let actions = [UNNotificationAction(identifier: "care.record", title: FangcunCopy.text("care.record"), options: [.foreground]),
      UNNotificationAction(identifier: "care.snooze", title: FangcunCopy.text("care.snooze")),
      UNNotificationAction(identifier: "care.mute", title: FangcunCopy.text("care.mute"))]
    categories.insert(UNNotificationCategory(identifier: CareNotificationPlanner.prefix + "actions", actions: actions, intentIdentifiers: []))
    center.setNotificationCategories(categories)
  }
  func replan(now: Date = .now, calendar: Calendar = .current) async {
    guard notificationsEnabled, errorKey == nil else { return }
    if planning { needsReplan = true; return }; planning = true
    defer { planning = false }
    repeat {
      needsReplan = false
      let revision = generation
      let status = await client.access()
      authorization = status == .denied ? "denied" : status == .notAsked ? "notAsked" : "enabled"
      let pending = await client.pendingIDs()
      let delivered = await client.deliveredIDs()
      guard revision == generation else { needsReplan = true; continue }
      var next = archive
      for notification in delivered where notification.hasPrefix(CareNotificationPlanner.prefix) {
        if let index = next.ledger.entries.firstIndex(where: { $0.requestID == notification }) {
          next.ledger.entries[index].state = "systemConfirmedDelivered"
        }
      }
      let proposed = status == .allowed
        ? CareNotificationPlanner.plan(events: events, preferences: preferences, ledger: next.ledger, now: now, calendar: calendar) : []
      let plans = proposed.filter { plan in !next.ledger.entries.contains { $0.requestID == plan.id && !$0.handledActionIDs.isEmpty } }
      let own = pending.filter { $0.hasPrefix(CareNotificationPlanner.prefix) }
      client.removePending(own)
      for index in next.ledger.entries.indices where next.ledger.entries[index].channel == "push"
        && (next.ledger.entries[index].scheduledAt ?? .distantPast) > now && next.ledger.entries[index].handledActionIDs.isEmpty { next.ledger.entries[index].state = "cancelled" }
      for plan in plans {
        next.ledger.entries.removeAll { $0.requestID == plan.id && $0.state == "cancelled" }
        next.ledger.entries.append(.init(candidateID: plan.id, channel: "push", scheduledAt: plan.fireAt,
          expiresAt: plan.expiresAt, requestID: plan.id, state: "reserved", category: plan.category,
          privacy: preferences.detailedLockScreen ? "detail" : "generic"))
      }
      guard persist(next) else { return }
      for plan in plans {
        guard revision == generation else { needsReplan = true; break }
        do {
          try await client.add(plan, calendar: calendar)
          guard revision == generation else {
            client.removePending(plans.map(\.id)); needsReplan = true; break
          }
          var saved = archive
          if let index = saved.ledger.entries.firstIndex(where: { $0.requestID == plan.id }) { saved.ledger.entries[index].state = "scheduled" }
          guard persist(saved) else { client.removePending(plans.map(\.id)); return }
        } catch { errorKey = "care.notificationError"; break }
      }
      scheduledThrough = plans.map(\.fireAt).max()
      // Stale delivered cards may be removed; their exposure receipts remain in the budget ledger.
      let valid = Set(plans.map(\.id))
      client.removeDelivered(delivered.filter { $0.hasPrefix(CareNotificationPlanner.prefix) && !valid.contains($0) })
    } while needsReplan
  }
  func handleResponse(requestID: String, action: String) async {
    guard requestID.hasPrefix(CareNotificationPlanner.prefix) else { return }
    var next = archive
    guard let index = next.ledger.entries.firstIndex(where: { $0.requestID == requestID }) else { return }
    let receipt = requestID + ":" + action
    guard !next.ledger.entries[index].handledActionIDs.contains(receipt) else { return }
    next.ledger.entries[index].handledActionIDs.insert(receipt); next.ledger.entries[index].state = "responseReceived"
    if action == "care.snooze" { next.ledger.waterSnoozedUntil = Date.now.addingTimeInterval(3600) }
    if action == "care.mute" { next.ledger.muteToday(now: .now, calendar: .current) }
    guard persist(next) else { return }
    if action == "care.record" || action == UNNotificationDefaultActionIdentifier { pendingRoute = "record" }
    await replan()
  }
}

final class CareNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
  @MainActor weak var owner: BeverageCareCoordinator?
  @MainActor init(owner: BeverageCareCoordinator) { self.owner = owner; super.init() }
  nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    SystemCareNotificationClient.foregroundOptions(requestID: notification.request.identifier)
  }
  nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    let id = response.notification.request.identifier, action = response.actionIdentifier
    await owner?.handleResponse(requestID: id, action: action)
  }
}
