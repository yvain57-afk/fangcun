import Foundation
import Testing
@testable import InnerBalanceCore

@Suite struct BeverageCareTests {
  var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 8*3600)!; return c }
  func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
  }
  func date(_ hour: Int, _ minute: Int = 0) -> Date { at(19, hour, minute) }
  func coffee(_ at: Date, mg: Double? = 140, recorded: Date? = nil, origin: String = "local") -> BeverageEvent {
    .init(id: at.ISO8601Format(), categoryCode: "coffee", consumedAt: at, recordedAt: recorded ?? at,
      volumeML: 300, caffeineMG: mg, caffeinePresence: .yes, origin: origin)
  }
  func alcohol(_ at: Date, grams: Double? = 14) -> BeverageEvent {
    .init(id: at.ISO8601Format(), categoryCode: "alcohol", consumedAt: at, recordedAt: at,
      volumeML: 150, alcoholGrams: grams, alcoholPresence: .yes)
  }
  func rules(_ events: [BeverageEvent], _ now: Date, _ p: CarePreferences = .init(), _ l: CareLedger = .init()) -> [CareCandidate] {
    BeverageCareEngine.evaluate(events: events, preferences: p, ledger: l, now: now, calendar: calendar)
  }
  @Test func noRecordsMeansInvitationNotDehydration() {
    #expect(rules([], date(10)).isEmpty)
    #expect(rules([], date(11,30)).map(\.ruleID) == ["W01"])
    #expect(rules([], date(20)).isEmpty)
  }
  @Test func coffeeCountsFluidAndUnknownAlcoholDoesNot() {
    let c = coffee(date(11))
    let total = BeverageTotals([c, alcohol(date(11), grams: nil)])
    #expect(total.allBeverageML == 450 && total.nonAlcoholBeverageML == 300 && total.plainWaterML == 0)
    #expect(total.hasUnknownAlcohol)
    #expect(rules([c], date(12)).map(\.ruleID) == ["W02"])
  }
  @Test func doseMethodsAndABVAreExplicit() {
    let serving = BeverageDetails(displayName: "Coffee", caffeinePresence: .yes, caffeineDose: 140)
    #expect(serving.caffeineMG(volumeML: 300) == 140 && serving.caffeineMG(volumeML: 500) == 140)
    let label = BeverageDetails(displayName: "Label", caffeinePresence: .yes, caffeineMethod: .per100ML, caffeineDose: 32)
    #expect(label.caffeineMG(volumeML: 250) == 80 && label.caffeineMG(volumeML: 500) == 160)
    let beer = BeverageDetails(displayName: "Beer", alcoholPresence: .yes, abvPercent: 5)
    let wine = BeverageDetails(displayName: "Wine", alcoholPresence: .yes, abvPercent: 12)
    #expect(abs(beer.alcoholGrams(volumeML: 330)! - 13.0185) < 0.001)
    #expect(abs(wine.alcoholGrams(volumeML: 150)! - 14.202) < 0.001)
  }
  @Test func referenceRequiresAcceptanceAndNeverCreatesDebt() {
    let water = BeverageEvent(id: "w", consumedAt: date(10), volumeML: 1500)
    #expect(!rules([water], date(12)).contains { $0.ruleID == "W04" })
    var p = CarePreferences(); p.referenceAccepted = true
    #expect(rules([water], date(12), p).map(\.ruleID) == ["W04"])
    var ledger = CareLedger(); ledger.waterTargetMetUntil = at(20,0)
    #expect(rules([], date(12), p, ledger).isEmpty)
  }
  @Test func restrictionAndAcknowledgementSuppressWaterWithoutChangingFacts() {
    var p = CarePreferences(); p.fluidRestricted = true
    #expect(rules([], date(12), p).isEmpty)
    var l = CareLedger(); l.waterAcknowledgedUntil = date(15)
    #expect(rules([], date(12), .init(), l).isEmpty)
    #expect(rules([], date(15), .init(), l).map(\.ruleID) == ["W01"])
    let a = alcohol(date(12), grams: 35)
    #expect(rules([a], date(12,1), p).first?.noteKey == "care.fluidRestricted")
  }
  @Test func lateCaffeineUsesConsumedTimeAndConfirmedSleep() {
    var p = CarePreferences(); p.sleepPlanConfirmed = true
    #expect(rules([coffee(date(9), recorded: date(16))], date(16), p).allSatisfy { $0.category != .caffeine })
    #expect(rules([coffee(date(16))], date(16,1), p).contains { $0.ruleID == "C01" })
    #expect(rules([coffee(date(16), mg: 10)], date(16,1), p).allSatisfy { $0.category != .caffeine })
    #expect(rules([coffee(date(16), mg: nil)], date(16,1), p).contains { $0.ruleID == "C01" })
    #expect(rules([coffee(date(16))], date(16,1)).allSatisfy { $0.category != .caffeine })
  }
  @Test func midnightBelongsToOngoingSleepAndExpires() {
    var p = CarePreferences(); p.sleepPlanConfirmed = true
    #expect(rules([coffee(at(20,0,30))], at(20,1), p).contains { $0.ruleID == "C01" })
    #expect(rules([coffee(at(20,0,30))], at(20,8), p).allSatisfy { $0.ruleID != "C01" })
    #expect(rules([alcohol(at(19,23,30))], at(20,0,30), p).contains { $0.ruleID == "A01" })
  }
  @Test func amountAndLateMergeUnknownQualifiedAndBackfillPassive() {
    var p = CarePreferences(); p.sleepPlanConfirmed = true
    let rows = [coffee(date(10), mg: 200), coffee(date(16), mg: 210), coffee(date(15), mg: nil)]
    let c = rules(rows, date(16,1), p).filter { $0.category == .caffeine }
    #expect(c.count == 1 && c[0].ruleID == "C03" && c[0].noteKey == "care.caffeine.partial")
    let backfill = coffee(date(10), mg: 420, recorded: date(17))
    #expect(rules([backfill], date(17), p).first { $0.category == .caffeine }?.noticeEligible == false)
  }
  @Test func manualCutoffHasNoImaginarySleepAndShiftOverrideWorks() {
    var p = CarePreferences(); p.cutoffMinute = 900
    #expect(rules([coffee(date(16))], date(17), p).contains { $0.ruleID == "C01" })
    #expect(rules([coffee(date(16))], at(20,1), p).allSatisfy { $0.ruleID != "C01" })
    p.sleepPlanConfirmed = true; p.sleepOverride = .init(start: at(20,8), end: at(20,16))
    #expect(rules([coffee(at(19,20))], at(19,21), p).allSatisfy { $0.ruleID != "C01" })
    #expect(rules([coffee(at(20,1))], at(20,2), p).contains { $0.ruleID == "C01" })
  }
  @Test func alcoholUnknownNotExcessWaterCannotCancelAndSafetyWins() {
    let now = date(18)
    #expect(rules([alcohol(now, grams: nil)], now).first?.ruleID == "A03")
    let rows = [alcohol(now, grams: 35), BeverageEvent(id: "water", consumedAt: now, volumeML: 1000)]
    #expect(rules(rows, now).first?.ruleID == "A02")
    var l = CareLedger(); l.severeSymptomsAt = now
    #expect(rules(rows, now, .init(), l).map(\.ruleID) == ["A05"])
    var p = CarePreferences(); p.inAppEnabled = false
    #expect(rules(rows, now, p, l).map(\.ruleID) == ["A05"])
  }
  @Test func nextCycleAlcoholIsPassiveNotHangoverDiagnosis() {
    var p = CarePreferences(); p.sleepPlanConfirmed = true
    let c = rules([alcohol(at(19,22))], at(20,9), p).first { $0.ruleID == "A04" }
    #expect(c != nil && c?.noticeEligible == false)
    #expect(rules([alcohol(at(19,22))], at(20,17), p).allSatisfy { $0.ruleID != "A04" })
  }
  @Test func priorityDismissAndSameBasisDoNotReplay() {
    let now = date(16); let c = rules([alcohol(now, grams: 35), coffee(now, mg: 420)], now)
    let selected = CareAttentionPolicy.select(c, ledger: .init(), now: now)!
    #expect(selected.candidate.category == .alcohol)
    var l = CareLedger(); l.dismissedUntil = now.addingTimeInterval(4*3600)
    #expect(CareAttentionPolicy.select(c, ledger: l, now: now) == nil)
    l.dismissedUntil = nil
    l.entries.append(.init(candidateID: selected.candidate.id, basisIDs: selected.candidate.basisIDs, expiresAt: selected.candidate.expiresAt, category: .alcohol))
    #expect(CareAttentionPolicy.select(c, ledger: l, now: now)?.noticeable == false)
  }
  @Test func muteSurvivesRestartAndTimezoneChange() throws {
    var l = CareLedger(); l.muteToday(now: date(18), calendar: calendar)
    let reloaded = try JSONDecoder().decode(CareLedger.self, from: JSONEncoder().encode(l))
    var other = calendar; other.timeZone = TimeZone(secondsFromGMT: 0)!
    #expect(reloaded.mutedUntil == at(20,0))
    #expect(CareAttentionPolicy.select(rules([], date(19)), ledger: reloaded, now: date(19)) == nil)
  }
  @Test func nonMaterialNameEditDoesNotReplayCare() {
    let now = date(16); var row = coffee(now, mg: 420)
    let first = rules([row], now).first { $0.category == .caffeine }!
    var l = CareLedger()
    var receipt = CareLedgerEntry(candidateID: first.id, basisIDs: first.basisIDs, expiresAt: first.expiresAt, category: .caffeine)
    receipt.attentionKey = first.attentionKey; l.entries = [receipt]
    row.displayName = "Renamed"; row.revision += 1
    let revised = rules([row], now)
    #expect(CareAttentionPolicy.select(revised, ledger: l, now: now)?.noticeable == false)
  }
  @Test func threeDayOneShotPlansReserveBothBudgetsAndCooldown() {
    var p = CarePreferences(); p.waterPush = true; p.caffeinePush = true; p.sleepPlanConfirmed = true
    let plans = CareNotificationPlanner.plan(events: [], preferences: p, ledger: .init(), now: date(10), calendar: calendar)
    #expect(!plans.isEmpty && plans.count <= 6)
    for plan in plans {
      #expect(plans.filter { calendar.isDate($0.fireAt, inSameDayAs: plan.fireAt) }.count <= 2)
      #expect(plans.filter { $0.fireAt <= plan.fireAt && plan.fireAt.timeIntervalSince($0.fireAt) < 24*3600 }.count <= 2)
      #expect(plan.bodyKey == "care.notification.generic")
    }
    for pair in zip(plans, plans.dropFirst()) { #expect(pair.1.fireAt.timeIntervalSince(pair.0.fireAt) >= 4*3600) }
  }
  @Test func recentFluidAndReferenceMetCancelWaterAndRestrictionWins() {
    var p = CarePreferences(); p.waterPush = true; p.referenceAccepted = true
    let water = BeverageEvent(id: "w", consumedAt: date(11), volumeML: 250)
    var plans = CareNotificationPlanner.plan(events: [water], preferences: p, ledger: .init(), now: date(11), calendar: calendar)
    #expect(plans.allSatisfy { $0.fireAt >= date(13) })
    var met = water; met.volumeML = 1500
    plans = CareNotificationPlanner.plan(events: [met], preferences: p, ledger: .init(), now: date(11), calendar: calendar)
    #expect(plans.allSatisfy { !calendar.isDate($0.fireAt, inSameDayAs: date(11)) })
    p.fluidRestricted = true
    #expect(CareNotificationPlanner.plan(events: [], preferences: p, ledger: .init(), now: date(10), calendar: calendar).isEmpty)
  }
  @Test func lateAlcoholRequestDoesNotLeakIntoQuietHours() {
    var p = CarePreferences(); p.alcoholPush = true
    var l = CareLedger(); l.requestedAlcoholReminderAt = date(21,40)
    #expect(CareNotificationPlanner.plan(events: [], preferences: p, ledger: l, now: date(21,10), calendar: calendar).isEmpty)
  }
  @Test func twoAlcoholRecordsAcrossMidnightKeepSixHourTotal() {
    let rows = [alcohol(at(19,23), grams: 15), alcohol(at(20,1), grams: 15)]
    #expect(rules(rows, at(20,1,1)).first?.ruleID == "A02")
    #expect(rules(rows, at(20,5,1)).allSatisfy { $0.ruleID != "A02" })
  }
  @Test func twoReservationsAndAlcoholRequestCannotAddAThirdOrDeferIt() {
    var p = CarePreferences(); p.waterPush = true; p.alcoholPush = true
    var l = CareLedger(); l.requestedAlcoholReminderAt = date(20,30)
    let initial = CareNotificationPlanner.plan(events: [], preferences: p, ledger: .init(), now: date(10), calendar: calendar)
    let todays = initial.filter { calendar.isDate($0.fireAt, inSameDayAs: date(10)) }
    #expect(todays.count == 2)
    l.entries = todays.map { .init(candidateID: $0.id, basisIDs: [], channel: "push", scheduledAt: $0.fireAt,
      expiresAt: $0.expiresAt, requestID: $0.id, category: $0.category) }
    let replanned = CareNotificationPlanner.plan(events: [], preferences: p, ledger: l, now: date(10), calendar: calendar)
    #expect(replanned.filter { calendar.isDate($0.fireAt, inSameDayAs: date(10)) }.count == 2)
    #expect(replanned.allSatisfy { $0.category != .alcohol })
    let afterTwo = CareNotificationPlanner.plan(events: [], preferences: p, ledger: l, now: date(20), calendar: calendar)
    #expect(afterTwo.allSatisfy { $0.category != .alcohol })
  }
}
