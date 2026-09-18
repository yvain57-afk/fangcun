import Foundation
import Testing
@testable import InnerBalanceCore

@Suite("M2 sleep and baselines")
struct ReadinessFeatureTests {
  let f = ReadinessFixture()
  @Test func sleepUnionDoesNotMixSourcesOrCountAwake() throws {
    var other = f.sleep(start: 12, end: 4, seed: 4); other.source.bundleID = "other"
    let rows = [f.sleep(start: 12,end: 8,seed: 1),f.sleep(start: 9,end: 7,seed: 2),f.sleep(start: 6,end: 4,seed: 3),other]
    let build = f.build(rows)
    #expect(build.episodes.count == 1)
    #expect(try #require(build.episodes.first).asleepDuration == 7*3600)
    #expect(build.episodes[0].sampleIDs.count == 3)
  }
  @Test func lateSleepKeepsCycleAndAmbiguousMatchesRequireReview() throws {
    let before = f.build([f.sleep(start: 12,end: 5,seed: 1)])
    let after = f.build([f.sleep(start: 12,end: 5,seed: 1),f.sleep(start: 5,end: 4,seed: 2)], previous: before.episodes)
    #expect(after.episodes.first?.id == before.episodes.first?.id)
    #expect(after.episodes.first?.recoveryCycleID == before.episodes.first?.recoveryCycleID)
    var duplicate = try #require(before.episodes.first); duplicate.id = "conflicting-old-id"
    #expect(f.build([f.sleep(start: 12,end: 4,seed: 2)], previous: before.episodes+[duplicate]).episodes.first?.flags.contains(.ambiguousRevision) == true)
  }
  @Test func shiftWorkNapManualChoiceAndArrival() throws {
    let build = f.build([f.sleep(start: 23,end: 18,seed: 1),f.sleep(start: 9,end: 4,seed: 2),f.sleep(start: 2,end: 1,seed: 3)])
    let selection = SleepEpisodeBuilder.select(build, now: f.now)
    #expect(selection.flags.contains(.ambiguousSleep))
    let short = try #require(build.episodes.first { $0.asleepDuration == 3600 })
    let manual = SleepEpisodeBuilder.select(build, now: f.now, manualEpisodeID: short.id)
    #expect(manual.manuallySelected && manual.flags.contains(.shortSleep))
    #expect(!manual.flags.contains(.ambiguousSleep))
    let arriving = f.build([f.sleep(start: 9,end: 0.25,seed: 4)])
    #expect(SleepEpisodeBuilder.select(arriving, now: f.now).awaitingData)
  }
  @Test func excessiveFutureAndConflictingSleep() {
    #expect(f.build([f.sleep(start: 20,end: 4,seed: 1)]).episodes.first?.flags.contains(.excessiveSleep) == true)
    #expect(f.build([f.sleep(start: 8,end: -1,seed: 1)]).flags.contains(.futureSleep))
    let conflicts = [f.sleep(start: 12,end: 4,seed: 1,stage: .core),f.sleep(start: 8,end: 7,seed: 2,stage: .awake)]
    #expect(f.build(conflicts).episodes.first?.flags.contains(.conflictingSleep) == true)
  }
  @Test func sparseCoverageInterventionAndRestingReuse() throws {
    let rows = f.records(currentHRVCount: 3, currentHRVSameHour: true)
    let sleep = try #require(SleepEpisodeBuilder.select(f.build(rows), now: f.now).episode)
    let narrow = CurrentMetricExtractor.extract(metric: .hrvSDNN, samples: rows, sourceKey: f.source.key(for: .hrvSDNN), episode: sleep, now: f.now)
    #expect(!narrow.reliable && narrow.reasons.contains(.narrowHRVCoverage))
    let excluded = CurrentMetricExtractor.extract(metric: .hrvSDNN, samples: rows, sourceKey: f.source.key(for: .hrvSDNN), episode: sleep, now: f.now,
      interventions: [.init(start: f.date(5),end: f.date(4.5))])
    #expect(excluded.sampleCount == 0 && excluded.reasons.contains(.interventionExcluded))
    let r = CurrentMetricExtractor.extract(metric: .restingHeartRate, samples: rows, sourceKey: f.source.key(for: .restingHeartRate),
      episode: sleep, now: f.now, usedRestingIDs: [f.id(30)])
    #expect(r.displayValue == 60 && !r.reliable && r.reasons.contains(.restingSampleReused))
  }
  @Test func baselineHasIndependentDaysNoCurrentOrFutureAndMADFloors() throws {
    var rows = f.records()
    rows.removeAll { $0.metric == .restingHeartRate && $0.end < f.date(3+3*24) }
    let build = f.build(rows), current = try #require(SleepEpisodeBuilder.select(build, now: f.now).episode)
    let baseline = BaselineBuilder.build(episodes: build.episodes, samples: rows, beforeEpisode: current,
      hrvSource: f.source.key(for: .hrvSDNN), rhrSource: f.source.key(for: .restingHeartRate),
      currentSampleIDs: Set((10...13).map(f.id)+[f.id(30)]), calendar: f.calendar)
    #expect(baseline.hrv.validDays == 20 && baseline.rhr.validDays == 3)
    #expect(baseline.hrv.scale == 0.10 && baseline.rhr.scale == 3)
    #expect(baseline.hrv.center == log(50) && baseline.rhr.center == 60)
    #expect(!baseline.hrv.sampleIDs.contains(f.id(10)) && !baseline.rhr.sampleIDs.contains(f.id(30)))
  }
  @Test func daylightSavingBucketsAreAbsoluteAndCycleIsTimezoneIndependent() throws {
    let rows = f.records()
    let build = f.build(rows)
    var shifted = f.calendar; shifted.timeZone = TimeZone(identifier: "America/New_York")!
    let another = SleepEpisodeBuilder.build(samples: rows, sourceKey: f.source.key(for: .sleep), calendar: shifted,
      now: f.now, lookback: 35*86_400, previous: build.episodes)
    #expect(another.episodes.map(\.id) == build.episodes.map(\.id))
    let episode = try #require(build.episodes.last)
    let feature = CurrentMetricExtractor.extract(metric: .hrvSDNN, samples: rows,
      sourceKey: f.source.key(for: .hrvSDNN), episode: episode, now: f.now)
    #expect(feature.coveredHours == 4)
  }
}
