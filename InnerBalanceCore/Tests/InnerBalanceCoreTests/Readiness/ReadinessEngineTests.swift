import Foundation
import Testing
@testable import InnerBalanceCore

extension ReadinessFixture {
  func input(_ records: [ReadinessSample], now: Date? = nil, sources: [String: SelectedReadinessSource]? = nil,
    readFailure: ReadinessReadFailure? = nil) -> ReadinessInput {
    let clock = now ?? self.now
    let selected = sources ?? Dictionary(uniqueKeysWithValues: [ReadinessMetric.sleep,.hrvSDNN,.restingHeartRate].compactMap { metric in
      StableSourceSelector.select(metric: metric, samples: records, existing: nil, calendar: calendar, now: clock).map { (metric.rawValue, $0) }
    })
    return ReadinessInputBuilder.build(samples: records, sources: selected, now: clock, calendar: calendar, readFailure: readFailure).input
  }
  func assess(_ records: [ReadinessSample]) -> ReadinessAssessment { ReadinessEngine.evaluate(input(records)) }
}

@Suite("M2 readiness rules and replay")
struct ReadinessEngineTests {
  let f = ReadinessFixture()
  @Test func originalGoldenFileThroughRawSamples() throws {
    struct Golden: Decodable {
      struct Case: Decodable {
        struct Input: Decodable { var hrvDeviation: Double; var rhrDeviation: Double; var sleepDeficitMinutes: Double }
        struct Expected: Decodable { var availability: String; var autonomicSeverity: Int?; var sleepSeverity: Int?; var level: String? }
        var id: String; var input: Input; var expected: Expected
      }
      var cases: [Case]
    }
    var root = URL(fileURLWithPath: #filePath)
    for _ in 0..<5 { root.deleteLastPathComponent() }
    let fixtures = try JSONDecoder().decode(Golden.self, from: Data(contentsOf: root.appendingPathComponent("docs/plans/fangcun-v1/READINESS_GOLDEN_FIXTURES.json")))
    #expect(fixtures.cases.count == 10)
    for fixture in fixtures.cases {
      var rows = f.records(hrv: exp(log(50)-fixture.input.hrvDeviation*0.10), rhr: 60+fixture.input.rhrDeviation*3,
        sleepHours: 8-fixture.input.sleepDeficitMinutes/60)
      // Golden precondition: four samples across three absolute hour buckets.
      let index = try #require(rows.firstIndex { $0.id == f.id(13) })
      rows[index].start = f.date(6.2); rows[index].end = f.date(6.2)
      let result = f.assess(rows)
      #expect(result.availability.rawValue == fixture.expected.availability, "\(fixture.id)")
      #expect(result.level?.rawValue == fixture.expected.level, "\(fixture.id)")
      #expect(result.autonomicSeverity == fixture.expected.autonomicSeverity, "\(fixture.id)")
      #expect(result.sleepSeverity == fixture.expected.sleepSeverity, "\(fixture.id)")
      #expect(result.evidence.first?.feature.coveredHours == 3)
      #expect(result.evidence.first?.baseline?.validDays == 20)
    }
  }
  @Test func independentBaselineBoundariesAndCurrentCoverage() {
    for days in [6,7,8,13,14,28] {
      let result = f.assess(f.records(days: days))
      #expect(result.availability == (days < 7 ? .limited : days < 14 ? .provisional : .assessable))
      #expect((result.level == nil) == (days < 7))
    }
    var mixed = f.records()
    mixed.removeAll { $0.metric == .restingHeartRate && $0.end < f.date(3+3*24) }
    #expect(f.assess(mixed).availability == .limited)
    mixed = f.records()
    mixed.removeAll { $0.metric == .hrvSDNN && $0.end < f.date(8+8*24) }
    #expect(f.assess(mixed).availability == .provisional)
    for count in [1,2,3] {
      #expect(f.assess(f.records(currentHRVCount: count)).availability == (count < 3 ? .limited : .assessable))
    }
    #expect(f.assess(f.records(currentHRVCount: 3,currentHRVSameHour: true)).availability == .limited)
  }
  @Test func enoughHistoryCannotInventCurrentAndPartialDataStayLimited() {
    let all = f.records()
    #expect(f.assess(all.filter { $0.end < f.date(24) }).level == nil)
    #expect(f.assess(all.filter { $0.end < f.date(24) }).availability == .insufficient)
    #expect(f.assess(all.filter { $0.metric == .sleep }).availability == .insufficient)
    #expect(f.assess(all.filter { $0.metric != .restingHeartRate }).availability == .limited)
    #expect(f.assess(all.filter { $0.metric != .sleep }).availability == .insufficient)
    #expect(f.assess([]).availability == .insufficient)
  }
  @Test func nonFiniteNegativeManualAmbiguousAndExtremeValuesDoNotBecomeUsual() {
    for value in [Double.nan, Double.infinity, -1, 0, 20_000] {
      let result = f.assess(f.records(hrv: value))
      #expect(result.level == nil)
      #expect(result.availability == .limited)
    }
    for variant in 0..<3 {
      var rows = f.records()
      for i in rows.indices where rows[i].id == f.id(10) {
        if variant == 0 { rows[i].manuallyEntered = true }
        if variant == 1 { rows[i].source.identityAmbiguous = true }
        if variant == 2 { rows[i].unit = "seconds" }
      }
      #expect(f.assess(rows).level == nil)
    }
    #expect(f.assess(f.records(hrv: exp(log(50)+0.21))).qualityFlags.contains(.hrvAtypicallyHigh))
  }
  @Test func noSilentFallbackAndSourceSwitchRebuildsOnlyNewSourceHistory() {
    let all = f.records()
    let selected = f.input(all).sources
    var foreign = f.quantity(.hrvSDNN,value: 80,hoursAgo: 6,seed: 9999); foreign.source.bundleID = "another.app"
    let missing = all.filter { !($0.metric == .hrvSDNN && $0.end > f.date(24)) } + [foreign]
    let absent = ReadinessEngine.evaluate(f.input(missing,sources: selected))
    #expect(absent.level == nil && absent.evidence.first?.feature.sampleCount == 0)
    var switched = selected
    switched[ReadinessMetric.hrvSDNN.rawValue] = StableSourceSelector.select(metric: .hrvSDNN, samples: missing,
      existing: selected[ReadinessMetric.hrvSDNN.rawValue], requested: foreign.sourceKey, calendar: f.calendar, now: f.now)
    let new = ReadinessEngine.evaluate(f.input(missing,sources: switched))
    #expect(new.evidence.first?.baseline?.validDays == 0 && new.level == nil)
    #expect(new.sources[ReadinessMetric.hrvSDNN.rawValue]?.segmentID != selected[ReadinessMetric.hrvSDNN.rawValue]?.segmentID)
  }
  @Test func queryFailureCacheInvalidationAndFreshnessBoundaries() throws {
    let all = f.records(), input = f.input(all), good = ReadinessEngine.evaluate(input)
    for (hours, expected) in [(18.0, ReadinessFreshness.current),(18.0001,.historical),(24,.historical),(24.0001,.stale)] {
      #expect(AssessmentFreshness.resolve(good, now: try #require(good.sleepEndAt).addingTimeInterval(hours*3600)) == expected)
    }
    var failed = input; failed.now = f.now.addingTimeInterval(60); failed.readFailure = .protectedDataUnavailable
    let cached = ReadinessEngine.evaluate(failed,cached: good)
    #expect(cached.level == good.level && cached.computedAt == good.computedAt && cached.validUntil == good.validUntil)
    #expect(cached.refreshFailure == .protectedDataUnavailable)
    #expect(ReadinessEngine.evaluate(failed).availability == .failed)
    failed.cacheInvalidated = true
    #expect(ReadinessEngine.evaluate(failed,cached: good).level == nil)
    #expect(AssessmentFreshness.resolve(good, now: f.now, newerSleepEnd: f.date(1)) == .historical)
    var refreshed = input; refreshed.now = f.now.addingTimeInterval(60); refreshed.queriedAt = refreshed.now
    let same = ReadinessEngine.evaluate(refreshed)
    #expect(same.inputFingerprint == good.inputFingerprint && same.validUntil == good.validUntil)
  }
  @Test func trainingAndBackgroundEventsDoNotSuppressOrReward() {
    let records = f.records(hrv: exp(log(50)-0.2),rhr: 66)
    let before = f.assess(records)
    let workout = ReadinessSample(id: f.id(9999),metric: .workout,value: 2700,unit: "s",
      start: f.date(6.75),end: f.date(6),source: f.source,activityType: 1,queriedAt: f.now)
    let after = f.assess(records+[workout])
    #expect(after.level == before.level && after.autonomicSeverity == 2)
    #expect(after.inputFingerprint == before.inputFingerprint)
    // Engine accepts no drink totals, completion count, or subjective reward input.
    #expect(after.evidence.first?.feature.sampleCount == 4)
  }
  @Test func arrivalBufferAndRealDSTRepeatedHour() throws {
    var records = f.records()
    let shift = 3.75*3600.0
    for i in records.indices { records[i].start += shift; records[i].end += shift }
    #expect(f.assess(records).availability == .awaitingData)
    let parse = ISO8601DateFormatter()
    let t1 = try #require(parse.date(from: "2026-11-01T05:15:00Z"))
    let t2 = try #require(parse.date(from: "2026-11-01T06:15:00Z"))
    var calendar = f.calendar; calendar.timeZone = TimeZone(identifier: "America/New_York")!
    #expect(calendar.component(.hour,from: t1) == 1 && calendar.component(.hour,from: t2) == 1)
    var sleep = f.sleep(start: 12,end: 4,seed: 1); sleep.start = t1-3600; sleep.end = t2+3600
    let now = t2+7200
    let episode = try #require(SleepEpisodeBuilder.build(samples: [sleep],sourceKey: sleep.sourceKey,calendar: calendar,now: now).episodes.first)
    let samples = [t1,t1+60,t2].enumerated().map { i, t in
      ReadinessSample(id: f.id(10+i),metric: .hrvSDNN,value: 50,unit: "ms",start: t,end: t,source: f.source,queriedAt: now)
    }
    let feature = CurrentMetricExtractor.extract(metric: .hrvSDNN,samples: samples,sourceKey: f.source.key(for: .hrvSDNN),episode: episode,now: now)
    #expect(feature.reliable && feature.coveredHours == 2 && episode.asleepDuration == 3*3600)
  }
}
