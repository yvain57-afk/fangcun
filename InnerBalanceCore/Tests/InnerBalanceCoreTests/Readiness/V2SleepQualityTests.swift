import Foundation
import Testing
@testable import InnerBalanceCore

@Suite("V2-02 sleep quality and baseline coverage")
struct V2SleepQualityTests {
  let f = ReadinessFixture()
  func stageOverlapRecords() -> [ReadinessSample] {
    var rows = f.records()
    for i in rows.indices where rows[i].metric == .sleep { rows[i].stage = .core }
    for day in 0...20 {
      rows.append(f.sleep(start: Double(day * 24 + 8), end: Double(day * 24 + 7), seed: 9000 + day, stage: .deep))
    }
    return rows
  }
  @Test func onlyStageOverlapPreservesCurrentAndHistoricalEvidence() throws {
    let result = f.assess(stageOverlapRecords())
    #expect(result.level == .usual)
    #expect(result.actualSleepSeconds == TimeInterval(8 * 3600))
    #expect(result.evidence.allSatisfy { $0.baseline?.validDays == 20 })
    #expect(result.featureSchemaVersion == 2)
  }
  @Test func unresolvedAwakeConflictCannotPublishPreciseDuration() throws {
    let result = f.assess(f.records() + [f.sleep(start: 8,end: 7,seed: 9000,stage: .awake)])
    #expect(result.level == nil)
    #expect(result.actualSleepSeconds == nil)
    #expect(result.contributingSampleIDs.contains(f.id(9000)))
  }
}

extension V2SleepQualityTests {
  @Test func qualitySeparatesStageAndConflictAndSupportsEmptyConfirmedWindow() throws {
    let stage = try #require(f.input(stageOverlapRecords()).sleep.episode)
    #expect(stage.sleepDurationUsable && stage.asleepIntervalsUsableForHRV)
    #expect(!stage.sleepStageBreakdownUsable)
    #expect(stage.quality?.internalReasons.contains(.sleepStageOverlap) == true)
    #expect(stage.quality?.userBlockingReasons.isEmpty == true)
    let rows = f.records() + [f.sleep(start: 12,end: 4,seed: 9000,stage: .awake)]
    let input = f.input(rows), episode = try #require(input.sleep.episode)
    #expect(episode.intervals.isEmpty)
    #expect(episode.start == f.date(12) && episode.end == f.date(4))
    #expect(!episode.sleepDurationUsable && !episode.asleepIntervalsUsableForHRV)
    #expect(input.hrv?.sampleIDs.isEmpty == true && input.rhr?.reliable == true)
    #expect(f.assess(rows).actualSleepSeconds == nil)
  }
  @Test func versionedReplacementResolvesConflictButUnrelatedRecordDoesNot() throws {
    var asleep = f.sleep(start: 12,end: 4,seed: 1,stage: .core)
    asleep.syncIdentifier = "synthetic-sleep"; asleep.syncVersion = 2
    var replaced = f.sleep(start: 8,end: 7,seed: 9000,stage: .awake)
    replaced.syncIdentifier = "synthetic-sleep"; replaced.syncVersion = 1
    let base = f.records().filter { $0.id != f.id(1) }
    let resolved = f.assess(base + [asleep,replaced])
    #expect(resolved.level == .usual && resolved.sleepDurationUsable)
    #expect(resolved.contributingSampleIDs.contains(replaced.id))
    replaced.syncIdentifier = "unrelated-sleep"
    #expect(f.assess(base + [asleep,replaced]).actualSleepSeconds == nil)
  }
  @Test func conflictDeletionInvalidatesAssessmentAndRebuildsSameCycle() throws {
    let rows = f.records() + [f.sleep(start: 8,end: 7,seed: 9000,stage: .awake)]
    let original = f.input(rows)
    var snapshot = InsightsSnapshot(); snapshot.episodes = f.build(rows).episodes
    snapshot.record(ReadinessEngine.evaluate(original))
    let cycle = snapshot.current?.recoveryCycleID
    snapshot.redact([f.id(9000).uuidString])
    #expect(snapshot.current == nil && snapshot.deletionAudit.count == 1)
    let next = ReadinessInputBuilder.build(samples: f.records(), sources: original.sources,
      previousEpisodes: f.build(rows).episodes, now: f.now, calendar: f.calendar)
    snapshot.record(ReadinessEngine.evaluate(next.input))
    #expect(snapshot.current?.recoveryCycleID == cycle)
    #expect(snapshot.current?.level == .usual && snapshot.current?.revision == 2)
  }
  @Test func incompleteSourceIdentityIsDiagnosticNotAComparisonFailure() {
    var rows = f.records()
    for index in rows.indices { rows[index].source.deviceIdentity = nil }
    let result = f.assess(rows)
    #expect(result.level == .usual)
    #expect(result.sleepQuality?.userBlockingReasons.isEmpty == true)
  }
  @Test func oldArchivesDecodeWithoutClearingAndNewPolicyCreatesRelatedRevision() throws {
    let current = f.assess(f.records())
    var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(current)) as? [String: Any])
    json.removeValue(forKey: "sleepQuality")
    var configuration = try #require(json["configuration"] as? [String: Any])
    configuration.removeValue(forKey: "qualityPolicyVersion"); configuration["featureSchemaVersion"] = 1
    json["configuration"] = configuration
    let decoded = try JSONDecoder().decode(ReadinessAssessment.self, from: JSONSerialization.data(withJSONObject: json))
    #expect(decoded.qualityPolicyVersion == nil && decoded.featureSchemaVersion == 1)
    #expect(decoded.assessmentID == current.assessmentID && decoded.actualSleepSeconds == current.actualSleepSeconds)
    var oldInput = f.input(f.records()); oldInput.configuration = decoded.configuration
    var snapshot = InsightsSnapshot(); snapshot.record(ReadinessEngine.evaluate(oldInput))
    let old = try #require(snapshot.current)
    snapshot.record(current)
    #expect(snapshot.assessments.count == 2)
    #expect(snapshot.current?.supersedesID == old.assessmentID && snapshot.current?.revision == 2)
    let data = try JSONEncoder().encode(snapshot)
    #expect(try JSONDecoder().decode(InsightsSnapshot.self, from: data).assessments.count == 2)
    var episodeJSON = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(f.build(f.records()).episodes[0])) as? [String: Any])
    for key in ["quality","recordedStartAt","recordedEndAt"] { episodeJSON.removeValue(forKey: key) }
    // V1 did not attach the new non-blocking identity diagnostic to sleep episodes.
    episodeJSON["flags"] = []
    let episode = try JSONDecoder().decode(ReadinessSleepEpisode.self, from: JSONSerialization.data(withJSONObject: episodeJSON))
    #expect(episode.quality == nil && episode.sleepDurationUsable)
  }
  @Test func auditDistinguishesUnreadMissingSourceMismatchAndRuleExcluded() throws {
    var snapshot = InsightsSnapshot()
    let rows = stageOverlapRecords()
    snapshot.ledger.samples = Dictionary(uniqueKeysWithValues: rows.map { ($0.id.uuidString,$0) })
    snapshot.sources = f.input(rows).sources
    snapshot.initialization = Dictionary(uniqueKeysWithValues: [ReadinessMetric.sleep,.hrvSDNN,.restingHeartRate].map { ($0.rawValue,ReadinessInitialization.complete) })
    let audit = BaselineCoverageAudit.build(snapshot: snapshot,now: f.now,calendar: f.calendar)
    #expect(audit.days.filter { $0.metric == .hrvSDNN && $0.disposition == .included }.count == 20)
    #expect(audit.days.contains { $0.disposition == .rawAbsent })
    snapshot.initialization?[ReadinessMetric.hrvSDNN.rawValue] = .inProgress
    #expect(BaselineCoverageAudit.build(snapshot: snapshot,now: f.now,calendar: f.calendar).days
      .filter { $0.metric == .hrvSDNN }.allSatisfy { $0.disposition == .readingIncomplete })
    snapshot.initialization?[ReadinessMetric.hrvSDNN.rawValue] = .unread
    #expect(BaselineCoverageAudit.build(snapshot: snapshot,now: f.now,calendar: f.calendar).days
      .filter { $0.metric == .hrvSDNN }.allSatisfy { $0.disposition == .notRead })
    snapshot.initialization?[ReadinessMetric.hrvSDNN.rawValue] = .complete
    snapshot.sources[ReadinessMetric.hrvSDNN.rawValue]?.sourceKey = "synthetic-other"
    #expect(BaselineCoverageAudit.build(snapshot: snapshot,now: f.now,calendar: f.calendar).days
      .contains { $0.metric == .hrvSDNN && $0.disposition == .sourceMismatch })
    let awake = f.sleep(start: 32,end: 31,seed: 9900,stage: .awake)
    snapshot.ledger.samples[awake.id.uuidString] = awake
    #expect(BaselineCoverageAudit.build(snapshot: snapshot,now: f.now,calendar: f.calendar).days
      .contains { $0.disposition == .sleepExcluded && $0.filterReasons.contains(.conflictingSleep) })
  }
}
