import Foundation

public struct CareNotificationRequest: Codable, Equatable, Sendable {
  public var id: String
  public var category: CareCategory
  public var fireAt: Date
  public var expiresAt: Date
  public var titleKey = "care.notification.title"
  public var bodyKey: String
  public var basisIDs: [String]
}
public enum CareNotificationPlanner {
  public static let prefix = "fangcun.care."
  public static func plan(events: [BeverageEvent], preferences p: CarePreferences, ledger: CareLedger,
    now: Date, calendar: Calendar) -> [CareNotificationRequest] {
    guard p.inAppEnabled else { return [] }
    let start = calendar.startOfDay(for: now)
    let cycles = p.sleepCycles(now: now, calendar: calendar)
    let horizon = calendar.date(byAdding: .day, value: 3, to: start)!
    let live = events.filter { !$0.deleted && $0.consumedAt <= now }
    let latestFluid = live.filter { $0.alcoholPresence == .no }.map(\.consumedAt).max()
    let total = BeverageTotals(live.filter { calendar.isDate($0.consumedAt, inSameDayAs: now) })
    let todayMet = p.referenceAccepted && total.nonAlcoholBeverageML >= p.referenceML
    var proposals: [(CareCategory, Date)] = []
    for offset in 0..<3 {
      let date = calendar.date(byAdding: .day, value: offset, to: start)!
      if p.waterPush && p.volumePromptsAllowed && !(offset == 0 && todayMet) {
        for minute in [11*60+30, 16*60] {
          if let at = calendar.date(bySettingHour: minute/60, minute: minute%60, second: 0, of: date) { proposals.append((.water, at)) }
        }
      }
      if p.caffeinePush {
        if p.sleepPlanConfirmed {
          for cycle in cycles where calendar.isDate(cycle.start, inSameDayAs: date) {
            proposals.append((.caffeine, cycle.start.addingTimeInterval(-min(12,max(6,p.lateWindowHours))*3600-15*60)))
          }
        } else if let minute = p.cutoffMinute,
          let cutoff = calendar.date(bySettingHour: minute/60, minute: minute%60, second: 0, of: date) {
          proposals.append((.caffeine, cutoff.addingTimeInterval(-15*60)))
        }
      }
    }
    if p.alcoholPush, let at = ledger.requestedAlcoholReminderAt { proposals.append((.alcohol, at)) }
    // Future old reservations are replaced atomically by the caller. Past exposure remains budgeted.
    var reserved = ledger.entries.filter { $0.channel == "push" && $0.state != "cancelled"
      && $0.scheduledAt.map { $0 <= now && $0 > now.addingTimeInterval(-24*3600) } == true }.compactMap(\.scheduledAt)
    var planned: [CareNotificationRequest] = []
    for (category, at) in proposals.sorted(by: { $0.1 == $1.1 ? $0.0.rawValue < $1.0.rawValue : $0.1 < $1.1 }) {
      guard at > now, at < horizon, !(ledger.mutedUntil.map { at < $0 } ?? false),
        !(ledger.dismissedUntil.map { at < $0 } ?? false), !isQuiet(at, preferences: p, calendar: calendar),
        !cycles.contains(where: { $0.start <= at && at < $0.end }) else { continue }
      if category == .water {
        guard !(latestFluid.map { at < $0.addingTimeInterval(2*3600) } ?? false),
          !(ledger.waterAcknowledgedUntil.map { at < $0 } ?? false),
          !(ledger.waterSnoozedUntil.map { at < $0 } ?? false),
          !(ledger.waterTargetMetUntil.map { at < $0 } ?? false) else { continue }
      }
      guard reserved.filter({ calendar.isDate($0, inSameDayAs: at) }).count < 2,
        reserved.filter({ at.timeIntervalSince($0) >= 0 && at.timeIntervalSince($0) < 24*3600 }).count < 2,
        reserved.allSatisfy({ abs(at.timeIntervalSince($0)) >= 4*3600 }) else { continue }
      reserved.append(at)
      let id = prefix + StableDigest.data(Data((category.rawValue + ":" + String(Int(at.timeIntervalSince1970))).utf8))
      planned.append(.init(id: id, category: category, fireAt: at, expiresAt: at.addingTimeInterval(3600),
        bodyKey: p.detailedLockScreen ? "care.notification." + category.rawValue : "care.notification.generic", basisIDs: []))
    }
    return planned
  }
  public static func isQuiet(_ date: Date, preferences: CarePreferences, calendar: Calendar) -> Bool {
    let minute = calendar.component(.hour, from: date)*60 + calendar.component(.minute, from: date)
    func inside(_ start: Int, _ end: Int) -> Bool { start > end ? minute >= start || minute < end : minute >= start && minute < end }
    return inside(21*60+30, 9*60) || inside(preferences.quietStartMinute, preferences.quietEndMinute)
  }
}
