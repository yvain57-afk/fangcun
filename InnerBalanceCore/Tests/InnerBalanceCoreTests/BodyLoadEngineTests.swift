import Foundation
import Testing

@testable import InnerBalanceCore

@Suite("Body load baseline")
struct BodyLoadEngineTests {
  @Test("Median is resistant to an extreme sample")
  func medianIgnoresExtremeSample() {
    #expect(BodyLoadEngine.median([42, 44, 45, 46, 190]) == 45)
  }

  @Test("Baseline requires five distinct valid days")
  func baselineRequiresFiveDays() {
    let fourDays = (1...4).map { day in
      HealthMetricSample(value: Double(day * 10), date: date(day), isAppleWatch: true)
    }
    let fifthDay = HealthMetricSample(value: 50, date: date(5), isAppleWatch: true)

    #expect(
      BodyLoadEngine.dailyMedianBaseline(
        from: fourDays,
        now: date(10),
        calendar: calendar
      ) == nil
    )
    #expect(
      BodyLoadEngine.dailyMedianBaseline(
        from: fourDays + [fifthDay],
        now: date(10),
        calendar: calendar
      ) != nil
    )
  }

  @Test("Baseline ignores samples older than 14 days")
  func baselineUsesFourteenDayWindow() {
    let now = date(31)
    let recentDays = (18...21).map { day in
      HealthMetricSample(value: Double(day), date: date(day), isAppleWatch: true)
    }
    let expiredDay = HealthMetricSample(value: 999, date: date(16), isAppleWatch: true)

    #expect(
      BodyLoadEngine.dailyMedianBaseline(
        from: recentDays + [expiredDay],
        now: now,
        calendar: calendar
      ) == nil
    )
  }

  @Test("Recent summary prefers valid Apple Watch samples")
  func recentSummaryPrefersWatch() {
    let now = date(10)
    let samples = [
      HealthMetricSample(value: 90, date: now.addingTimeInterval(-900), isAppleWatch: false),
      HealthMetricSample(value: 50, date: now.addingTimeInterval(-1_800), isAppleWatch: true),
      HealthMetricSample(value: 60, date: now.addingTimeInterval(-600), isAppleWatch: true),
      HealthMetricSample(value: 999, date: now.addingTimeInterval(-90_000), isAppleWatch: true),
      HealthMetricSample(value: .nan, date: now, isAppleWatch: true),
    ]

    let summary = BodyLoadEngine.recentSummary(
      from: samples,
      now: now,
      window: 24 * 3_600
    )

    #expect(summary?.value == 55)
    #expect(summary?.sampleCount == 2)
    #expect(summary?.usesAppleWatch == true)
  }

  @Test("Latest reading is the newest valid Watch sample, not the recent median")
  func latestReadingPrefersNewestWatchSample() {
    let now = date(10)
    let samples = [
      HealthMetricSample(value: 90, date: now.addingTimeInterval(-60), isAppleWatch: false),
      HealthMetricSample(value: 48, date: now.addingTimeInterval(-1_800), isAppleWatch: true),
      HealthMetricSample(value: 62, date: now.addingTimeInterval(-300), isAppleWatch: true),
      HealthMetricSample(value: .nan, date: now, isAppleWatch: true),
    ]

    let latest = BodyLoadEngine.latestSample(from: samples, now: now, window: 36 * 3_600)

    #expect(latest?.value == 62)
    #expect(latest?.date == now.addingTimeInterval(-300))
    #expect(latest?.isAppleWatch == true)
  }

  @Test("Elevated load requires two independent reliable signals")
  func elevatedLoadRequiresTwoSignals() {
    let hrv = BodyLoadEvidence(kind: .heartRateVariability, state: .elevated, isReliable: true)
    let restingHeartRate = BodyLoadEvidence(
      kind: .restingHeartRate,
      state: .elevated,
      isReliable: true
    )
    let unreliableSleep = BodyLoadEvidence(kind: .sleep, state: .elevated, isReliable: false)

    #expect(BodyLoadEngine.assess(evidence: [hrv], baselineDays: 5).availability == .limited)
    #expect(
      BodyLoadEngine.assess(evidence: [hrv, unreliableSleep], baselineDays: 5).availability == .limited)
    #expect(
      BodyLoadEngine.assess(evidence: [hrv, restingHeartRate], baselineDays: 5).level == .elevated)
  }

  @Test("Recent workout suppresses an elevated conclusion")
  func recentWorkoutSuppressesElevatedConclusion() {
    let evidence = [
      BodyLoadEvidence(kind: .heartRateVariability, state: .elevated, isReliable: true),
      BodyLoadEvidence(kind: .restingHeartRate, state: .elevated, isReliable: true),
    ]

    let assessment = BodyLoadEngine.assess(
      evidence: evidence,
      baselineDays: 5,
      recentWorkout: true
    )

    #expect(assessment.level != .steady)
    #expect(assessment.availability == .limited)
    #expect(assessment.workoutExcludedEvidenceIDs == ["hrv", "rhr"])
  }

  @Test("Recent workout keeps non-workout-sensitive evidence")
  func recentWorkoutKeepsIndependentEvidence() {
    let evidence = [
      BodyLoadEvidence(kind: .sleep, state: .elevated, isReliable: true),
      BodyLoadEvidence(kind: .respiratoryRate, state: .elevated, isReliable: true),
      BodyLoadEvidence(kind: .heartRateVariability, state: .withinRange, isReliable: true),
    ]

    let assessment = BodyLoadEngine.assess(
      evidence: evidence,
      baselineDays: 5,
      recentWorkout: true
    )

    #expect(assessment.level == .elevated)
  }

  @Test("History alone never permits a steady conclusion", arguments: [0, 4, 5, 14])
  func historyWithoutCurrentEvidence(_ days: Int) {
    let result = BodyLoadEngine.assess(evidence: [], baselineDays: days)
    #expect(result.availability == .insufficient)
    #expect(result.level != .steady)
  }

  @Test("Two distinct reliable kinds including cardiovascular evidence are required")
  func currentEvidenceGate() {
    let hrv = BodyLoadEvidence(kind: .heartRateVariability, state: .withinRange, isReliable: true)
    let sleep = BodyLoadEvidence(kind: .sleep, state: .withinRange, isReliable: true)
    let respiratory = BodyLoadEvidence(kind: .respiratoryRate, state: .withinRange, isReliable: true)
    for evidence in [[hrv], [sleep], [hrv, hrv], [sleep, respiratory]] {
      let result = BodyLoadEngine.assess(evidence: evidence, baselineDays: 5)
      #expect(result.availability == .limited)
      #expect(result.level != .steady)
    }
    #expect(BodyLoadEngine.assess(evidence: [hrv, sleep], baselineDays: 5).level == .steady)
  }

  @Test("Observation is separate from elevated when enough independent evidence exists")
  func observationVersusElevated() {
    let hrv = BodyLoadEvidence(kind: .heartRateVariability, state: .elevated, isReliable: true)
    let sleep = BodyLoadEvidence(kind: .sleep, state: .withinRange, isReliable: true)
    let result = BodyLoadEngine.assess(evidence: [hrv, sleep], baselineDays: 5)
    #expect(result.availability == .available)
    #expect(result.level == .watch)
    #expect(result.elevatedEvidenceIDs == ["hrv"])
  }

  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  private func date(_ day: Int) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 8, day: day, hour: 8))!
  }
}
