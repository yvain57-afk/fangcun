import Foundation

public struct CarePreferences: Codable, Equatable, Sendable {
  public var inAppEnabled = true
  public var waterPush = false
  public var caffeinePush = false
  public var alcoholPush = false
  public var detailedLockScreen = false
  public var referenceAccepted = false
  public var referenceML = 1500
  public var cupML = 250
  public var fluidRestricted = false
  public var adultReferenceApplies = true
  public var sleepPlanConfirmed = false
  public var sleepMinute = 23 * 60 + 30
  public var wakeMinute = 7 * 60 + 30
  public var sleepOverride: ReadinessInterval?
  public var cutoffMinute: Int?
  public var lateWindowHours = 8.0
  public var caffeineReferenceMG = 400.0
  public var quietStartMinute = 21 * 60 + 30
  public var quietEndMinute = 9 * 60
  public init() {}
  public var volumePromptsAllowed: Bool { !fluidRestricted && adultReferenceApplies }
  public func sleepCycles(now: Date, calendar: Calendar) -> [ReadinessInterval] {
    guard sleepPlanConfirmed else { return [] }
    if let sleepOverride, sleepOverride.end > now { return [sleepOverride] }
    let day = calendar.startOfDay(for: now)
    return (-2...3).compactMap { offset in
      guard let date = calendar.date(byAdding: .day, value: offset, to: day),
        let start = calendar.date(bySettingHour: sleepMinute / 60, minute: sleepMinute % 60, second: 0, of: date),
        let endDate = calendar.date(byAdding: .day, value: wakeMinute <= sleepMinute ? 1 : 0, to: date),
        let end = calendar.date(bySettingHour: wakeMinute / 60, minute: wakeMinute % 60, second: 0, of: endDate) else { return nil }
      return .init(start: start, end: end)
    }
  }
}
public enum CareCategory: String, Codable, Sendable { case danger, alcohol, caffeine, water }
public struct CareCandidate: Codable, Equatable, Sendable, Identifiable {
  public var id: String
  public var ruleID: String
  public var ruleVersion = "care-v2.0-engineering-20260919"
  public var category: CareCategory
  public var priority: Int
  public var titleKey: String
  public var bodyKey: String
  public var noteKey: String?
  public var actionKeys: [String]
  public var basisIDs: [String]
  public var expiresAt: Date
  public var origin: String
  public var noticeEligible: Bool
  public var attentionKey: String? = nil
}
public struct CareLedgerEntry: Codable, Equatable, Sendable {
  public var candidateID: String
  public var ruleVersion: String
  public var basisIDs: [String]
  public var channel: String
  public var scheduledAt: Date?
  public var expiresAt: Date
  public var requestID: String?
  public var state: String
  public var category: CareCategory
  public var origin: String
  public var privacy: String
  public var attentionKey: String? = nil
  public var handledActionIDs: Set<String> = []
  public init(candidateID: String, ruleVersion: String = "care-v2.0-engineering-20260919", basisIDs: [String] = [],
    channel: String = "inApp", scheduledAt: Date? = nil, expiresAt: Date, requestID: String? = nil,
    state: String = "shown", category: CareCategory, origin: String = "local", privacy: String = "generic") {
    self.candidateID = candidateID; self.ruleVersion = ruleVersion; self.basisIDs = basisIDs; self.channel = channel
    self.scheduledAt = scheduledAt; self.expiresAt = expiresAt; self.requestID = requestID; self.state = state
    self.category = category; self.origin = origin; self.privacy = privacy
  }
}
public struct CareLedger: Codable, Equatable, Sendable {
  public var entries: [CareLedgerEntry] = []
  public var mutedUntil: Date?
  public var dismissedUntil: Date?
  public var waterAcknowledgedUntil: Date?
  public var waterSnoozedUntil: Date?
  public var waterTargetMetUntil: Date?
  public var severeSymptomsAt: Date?
  public var drankTooMuchAt: Date?
  public var requestedAlcoholReminderAt: Date?
  public init() {}
  public mutating func muteToday(now: Date, calendar: Calendar) {
    let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
    mutedUntil = max(mutedUntil ?? .distantPast, end)
  }
}
public enum BeverageCareEngine {
  public static func evaluate(events: [BeverageEvent], preferences p: CarePreferences, ledger: CareLedger,
    now: Date, calendar: Calendar) -> [CareCandidate] {
    let rows = events.filter { !$0.deleted && $0.consumedAt <= now }
    let day = calendar.startOfDay(for: now), endDay = calendar.date(byAdding: .day, value: 1, to: day)!
    let today = rows.filter { $0.consumedAt >= day }
    let total = BeverageTotals(today)
    let cycles = p.sleepCycles(now: now, calendar: calendar)
    let asleep = cycles.contains { $0.start <= now && now < $0.end }
    var result: [CareCandidate] = []
    func add(_ rule: String, _ category: CareCategory, _ priority: Int, _ basis: [BeverageEvent], _ expires: Date,
      _ note: String? = nil, _ action: [String] = ["care.view"], notice: Bool = true) {
      let ids = basis.map(\.basisID).sorted()
      let salt = basis.isEmpty ? String(Int(day.timeIntervalSince1970)) : ids.joined(separator: "|")
      let isRecentLocal = basis.contains { $0.origin == "local" && now.timeIntervalSince($0.consumedAt) <= 15*60
        && $0.recordedAt.map { now.timeIntervalSince($0) < 120 } == true }
      result.append(.init(id: rule + ":" + StableDigest.data(Data(salt.utf8)), ruleID: rule, category: category,
        priority: priority, titleKey: "care." + rule + ".title", bodyKey: "care." + rule + ".body", noteKey: note,
        actionKeys: action, basisIDs: ids, expiresAt: expires, origin: isRecentLocal ? "local" : "passive",
        noticeEligible: notice && (basis.isEmpty || isRecentLocal), attentionKey: rule + ":" + StableDigest.data(Data(basis.map {
          $0.id + ":" + String($0.consumedAt.timeIntervalSince1970) + ":" + String($0.caffeineMG ?? -1) + ":" + String($0.alcoholGrams ?? -1)
        }.sorted().joined(separator: "|").utf8))))
    }
    if ledger.severeSymptomsAt != nil {
      add("A05", .danger, 100, [], .distantFuture, nil, ["care.emergency"])
      return result
    }
    guard p.inAppEnabled else { return [] }
    let alcohol = rows.filter { now.timeIntervalSince($0.consumedAt) < 6*3600 && $0.alcoholPresence != .no }
    let alcoholTotal = BeverageTotals(alcohol)
    let tooMuch = ledger.drankTooMuchAt.map { now.timeIntervalSince($0) < 6*3600 } == true
    if !alcohol.isEmpty || tooMuch {
      let expiry = max(alcohol.map(\.consumedAt).max() ?? .distantPast, tooMuch ? ledger.drankTooMuchAt! : .distantPast).addingTimeInterval(6*3600)
      let note = p.fluidRestricted ? "care.fluidRestricted" : "care.alcohol.boundary"
      if alcoholTotal.knownAlcoholGrams >= 30 || tooMuch { add("A02", .alcohol, 90, alcohol, expiry, note) }
      else if alcoholTotal.hasUnknownAlcohol { add("A03", .alcohol, 80, alcohol, expiry, note) }
      else if cycles.contains(where: { $0.end > now && $0.start.timeIntervalSince(now) <= 3*3600 }) {
        add("A01", .alcohol, 80, alcohol, expiry, note)
      }
    }
    if result.isEmpty, let previous = cycles.last(where: { $0.end <= now }) {
      let prior = rows.filter { $0.alcoholPresence != .no && $0.consumedAt >= previous.start.addingTimeInterval(-6*3600)
        && $0.consumedAt < previous.end && now.timeIntervalSince($0.consumedAt) < 18*3600 }
      if let latest = prior.map(\.consumedAt).max() {
        add("A04", .alcohol, 70, prior, latest.addingTimeInterval(18*3600),
          p.fluidRestricted ? "care.fluidRestricted" : "care.alcohol.boundary", notice: false)
      }
    }
    let caffeine = rows.filter { now.timeIntervalSince($0.consumedAt) < 24*3600 && $0.caffeinePresence != .no }
    let caffeineTotal = BeverageTotals(caffeine)
    let high = caffeineTotal.knownCaffeineMG >= min(400, max(1, p.caffeineReferenceMG))
    var late: [BeverageEvent] = []; var lateExpiry = endDay
    if let cycle = cycles.first(where: { $0.end > now }) {
      let cutoff = cycle.start.addingTimeInterval(-min(12, max(6, p.lateWindowHours))*3600)
      late = caffeine.filter { $0.consumedAt >= cutoff && $0.consumedAt < cycle.end && now.timeIntervalSince($0.consumedAt) < 12*3600
        && (($0.caffeineMG ?? 0) >= 50 || ($0.caffeinePresence == .yes && $0.caffeineMG == nil)) }
      lateExpiry = min(cycle.end, (late.map(\.consumedAt).max() ?? now).addingTimeInterval(12*3600))
    } else if let minute = p.cutoffMinute, let cutoff = calendar.date(bySettingHour: minute/60, minute: minute%60, second: 0, of: day) {
      late = caffeine.filter { $0.consumedAt >= cutoff && $0.consumedAt < endDay && now.timeIntervalSince($0.consumedAt) < 12*3600
        && (($0.caffeineMG ?? 0) >= 50 || ($0.caffeinePresence == .yes && $0.caffeineMG == nil)) }
      lateExpiry = min(endDay, (late.map(\.consumedAt).max() ?? now).addingTimeInterval(12*3600))
    }
    if high || !late.isEmpty {
      let rule = high && !late.isEmpty ? "C03" : high ? "C02" : "C01"
      let basis = high ? caffeine : late
      // Amount candidates are re-evaluated as each contributing entry leaves the rolling window.
      let expiry = high ? min((caffeine.map(\.consumedAt).min() ?? now).addingTimeInterval(24*3600), late.isEmpty ? .distantFuture : lateExpiry) : lateExpiry
      add(rule, .caffeine, 60, basis, expiry, caffeineTotal.hasUnknownCaffeine ? "care.caffeine.partial" : "care.caffeine.reference")
    }
    guard p.volumePromptsAllowed, !asleep else { return result }
    let minute = calendar.component(.hour, from: now)*60 + calendar.component(.minute, from: now)
    let referenceMet = p.referenceAccepted && total.nonAlcoholBeverageML >= p.referenceML
    if referenceMet { add("W04", .water, 10, today, endDay, nil, [], notice: false); return result }
    guard !(ledger.waterTargetMetUntil.map { $0 > now } ?? false),
      !(ledger.waterAcknowledgedUntil.map { $0 > now } ?? false), !(ledger.waterSnoozedUntil.map { $0 > now } ?? false),
      (11*60...19*60+30).contains(minute) else { return result }
    if today.isEmpty { add("W01", .water, 20, [], endDay, "care.water.recordsOnly", ["care.record", "care.ack", "care.mute"]) }
    else if let last = rows.filter({ $0.alcoholPresence == .no }).map(\.consumedAt).max(), now.timeIntervalSince(last) >= 3*3600 {
      add("W03", .water, 20, [today.last!], endDay, "care.water.recordsOnly", ["care.record", "care.snooze", "care.ack"])
    } else if total.plainWaterML == 0 && total.nonAlcoholBeverageML > 0 {
      add("W02", .water, 10, today, endDay, "care.water.coffeeCounts", ["care.record"], notice: false)
    }
    return result
  }
}
public struct CareSelection: Sendable {
  public var candidate: CareCandidate
  public var noticeable: Bool
}
public enum CareAttentionPolicy {
  public static func select(_ candidates: [CareCandidate], ledger: CareLedger, now: Date,
    sessionDismissed: Bool = false) -> CareSelection? {
    let live = candidates.filter { $0.expiresAt > now }.sorted { $0.priority == $1.priority ? $0.id < $1.id : $0.priority > $1.priority }
    if let danger = live.first, danger.category == .danger { return .init(candidate: danger, noticeable: false) }
    guard !sessionDismissed, !(ledger.mutedUntil.map { $0 > now } ?? false),
      !(ledger.dismissedUntil.map { $0 > now } ?? false), let first = live.first else { return nil }
    let seen = ledger.entries.contains { ($0.attentionKey != nil && $0.attentionKey == first.attentionKey && $0.expiresAt > now) || $0.candidateID == first.id || ($0.category == first.category && $0.basisIDs == first.basisIDs && $0.expiresAt > now) }
    return .init(candidate: first, noticeable: first.noticeEligible && !seen)
  }
}
