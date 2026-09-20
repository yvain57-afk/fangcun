import Foundation
import Testing
@testable import InnerBalanceCore

@Suite struct StatusScoreDataV3Tests {
  let now = ISO8601DateFormatter().date(from: "2026-09-20T12:00:00Z")!
  var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
  func row(_ metric: ReadinessMetric, day: Int = 0, value: Double? = nil, minutes: Double = 375, source: String = "synthetic") -> ReadinessSample {
    let end = now.addingTimeInterval(-5*3600-Double(day)*86400)
    return .init(id: UUID(), metric: metric, value: value, unit: metric == .hrvSDNN ? "ms" : metric == .restingHeartRate ? "count/min" : "category",
      stage: metric == .sleep ? .asleep : nil, start: metric == .sleep ? end.addingTimeInterval(-minutes*60) : end.addingTimeInterval(-1),
      end: end, source: .init(bundleID: source, samplingMethod: metric.rawValue), queriedAt: now)
  }
  func state(_ rows: [ReadinessSample]) -> InsightsSnapshot {
    var s = InsightsSnapshot(); s.ledger.samples = Dictionary(uniqueKeysWithValues: rows.map { ($0.id.uuidString,$0) })
    for metric in [ReadinessMetric.sleep,.hrvSDNN,.restingHeartRate] {
      s.sources[metric.rawValue] = StableSourceSelector.select(metric: metric, samples: rows, existing: nil, calendar: calendar, now: now)
    }
    return s
  }
  func features(_ rows: [ReadinessSample], config: StatusScoreConfiguration = .init()) throws -> ScoreFeatureBundle {
    try #require(try ScoreFeatureBuilder.build(snapshot: state(rows), now: now, calendar: calendar, configuration: config))
  }
  @Test func perfectSleepWithRegularityRemainsInClosedRange() throws {
    let rows = (0...20).map { row(.sleep,day:$0,minutes:480) }
    var s = state(rows)
    try s.recordStatus(features(rows),configuration:.init(),now:now)
    #expect(s.currentStatus?.rawScore == 100 && s.currentStatus?.isValid == true)
  }
  @Test func rawFourHoursWithMatureCardioMatches64WhenRegularityIsDisabled() throws {
    var rows = (0...20).flatMap { [row(.sleep,day:$0,minutes:$0 == 0 ? 240:480),row(.hrvSDNN,day:$0,value:50),row(.restingHeartRate,day:$0,value:60)] }
    for hour in [1,2] { var h = row(.hrvSDNN,value:50); h.start = h.start.addingTimeInterval(-Double(hour)*3600); h.end = h.end.addingTimeInterval(-Double(hour)*3600); rows.append(h) }
    let config = StatusScoreConfiguration(regularityEnabled:false)
    let f = try features(rows,config:config), result = try DailyStatusScoreEngine.evaluate(f.input,configuration:config)
    #expect(result.displayScore == 64 && result.band == .low)
    #expect(result.components.map(\.name) == ["sleep","hrv","rhr"])
    #expect(result.components.map(\.normalizedWeight) == [0.6,0.25,0.15])
  }
  @Test func rawRHRHistoryIndependentOfSleepAndDailyFallback() throws {
    let rows = (0...20).map { row(.restingHeartRate,day:$0,value:60) }
    let f = try features(rows)
    #expect(f.input.rhrDays == 20 && f.input.rhrDeviation == 0)
    #expect(f.windowPolicy.contains("dailyRHR"))
    let score = try DailyStatusScoreEngine.evaluate(f.input)
    #expect(score.displayScore == 85 && score.components.map(\.name) == ["rhr"])
    let withSleep = try features(rows+[row(.sleep)])
    #expect(withSleep.input.rhrDays == 20 && withSleep.windowPolicy.contains("morningRHR"))
    #expect(withSleep.basisSampleIDs.count == 22)
    #expect(try ScoreFeatureBuilder.build(snapshot: state([row(.hrvSDNN,value:50)]), now: now, calendar: calendar, configuration: .init()) == nil)
  }
  @Test(arguments: [2,3,7,14]) func sparseHRVProgressiveHistory(_ days: Int) throws {
    let rows = (0...days).flatMap { [row(.sleep,day:$0),row(.hrvSDNN,day:$0,value:50)] }
    let f = try features(rows)
    #expect(f.input.hrvDays == days && f.input.hrvSamples == 1 && f.input.hrvHours == 1)
    let score = try DailyStatusScoreEngine.evaluate(f.input)
    if days == 2 { #expect(score.components.map(\.name) == ["sleep"]) }
    else {
      let h = try #require(score.components.first { $0.name == "hrv" })
      #expect(abs(h.effectiveWeight - 0.25*min(1,Double(days)/14)/3/2) < 1e-10)
      #expect(f.basisSampleIDs.count == rows.count)
    }
  }
  @Test func rawShortSleepOverlapsAndNoInventedContinuity() throws {
    var a = row(.sleep,minutes:45); a.stage = .core
    var b = a; b.id = UUID(); b.stage = .deep
    let f = try features([a,b])
    #expect(f.input.sleepMinutes == 45 && f.input.awakeMinutes == nil)
    #expect(try DailyStatusScoreEngine.evaluate(f.input).displayScore == 9)
    var awake = a; awake.id = UUID(); awake.stage = .awake
    #expect(try DailyStatusScoreEngine.evaluate(features([a,awake]).input).displayScore == nil)
  }
  @Test func displayedHRVUsesTheSameLogRepresentativeAsScoring() throws {
    var rows = (0...3).map { row(.sleep,day:$0) } + (1...3).map { row(.hrvSDNN,day:$0,value:50) }
    rows.append(row(.hrvSDNN,value:25))
    var high = row(.hrvSDNN,value:100); high.start = high.start.addingTimeInterval(-3600); high.end = high.end.addingTimeInterval(-3600); rows.append(high)
    let f = try features(rows)
    #expect(abs((f.displayValues["hrv"] ?? 0)-50) < 1e-8)
    #expect(abs(f.input.hrvDeviation ?? 1) < 1e-8)
  }
  @Test func invalidAndInterventionHRVRowsDoNotContaminateUsableSamples() throws {
    var rows = (0...3).flatMap { [row(.sleep,day:$0),row(.hrvSDNN,day:$0,value:50)] }
    var bad = row(.hrvSDNN,value: .nan); bad.start = bad.start.addingTimeInterval(-3600); bad.end = bad.end.addingTimeInterval(-3600); rows.append(bad)
    let f = try features(rows)
    #expect(f.input.hrvSamples == 1 && f.input.hrvDeviation == 0)
    let current = try #require(rows.first { $0.metric == .hrvSDNN })
    let excluded = try #require(try ScoreFeatureBuilder.build(snapshot: state(rows), now: now, calendar: calendar, configuration: .init(), interventions: [.init(start:current.start,end:current.end)]))
    #expect(excluded.input.hrvDeviation == nil && excluded.input.sleepMinutes == 375)
  }
  @Test func revisionsIgnoreQueryClockButTrackCompositionConfigurationAndDeletion() throws {
    var rows = [row(.sleep)]
    var s = state(rows)
    let first = try features(rows); try s.recordStatus(first,configuration:.init(),now:now)
    let old = try #require(s.currentStatus)
    rows[0].queriedAt = now.addingTimeInterval(100)
    var again = state(rows); again.statusScores = s.statusScores; again.currentStatusID = s.currentStatusID
    let later = try #require(try ScoreFeatureBuilder.build(snapshot: again, now: now.addingTimeInterval(3600), calendar: calendar, configuration:.init()))
    #expect(later.fingerprint == first.fingerprint)
    try again.recordStatus(later,configuration:.init(),now:now.addingTimeInterval(3600))
    #expect(again.currentStatus?.scoreID == old.scoreID)
    rows += (0...3).map { row(.restingHeartRate,day:$0,value:60) }
    let expanded = try features(rows); try again.recordStatus(expanded,configuration:.init(),now:now)
    #expect(again.currentStatus?.revision == 2 && again.currentStatus?.compositionUpdated == true)
    #expect(again.currentStatus?.supersedes == old.scoreID)
    let changed = StatusScoreConfiguration(sleepGoalMinutes:540)
    try again.recordStatus(features(rows,config:changed),configuration:changed,now:now)
    #expect(again.currentStatus?.revision == 3 && again.statusScores?.first?.displayScore == 78)
    let dependent = try #require(rows.last?.id)
    again.redact([dependent.uuidString])
    #expect(again.currentStatus == nil && again.statusScores?.count == 1)
    #expect(again.statusDeletionAudit?.count == 2)
  }
  @Test func explicitHealthSleepSelectionSupersedesManualOverrideWithoutErasingHistory() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:dir) }
    let store = try InsightsStore(directory:dir)
    try await store.saveManualStatusSleep(.init(minutes:60,end:now.addingTimeInterval(-3600),recordedAt:now))
    var s = await store.snapshot()
    let manual = try #require(try ScoreFeatureBuilder.build(snapshot:s,now:now,calendar:calendar,configuration:.init()))
    try s.recordStatus(manual,configuration:.init(),now:now)
    let row = row(.sleep); s.ledger.samples[row.id.uuidString] = row
    s.sources = state([row]).sources
    s.episodes = SleepEpisodeBuilder.build(samples:[row],sourceKey:row.sourceKey,calendar:calendar,now:now).episodes
    let episode = try #require(s.episodes.first)
    try await store.commit(s,expectedGeneration:s.generation)
    try await store.selectSleep(episode.id)
    let selected = await store.snapshot()
    #expect(selected.manualStatusSleep == nil && selected.statusScores?.count == 1)
    let health = try #require(try ScoreFeatureBuilder.build(snapshot:selected,now:now,calendar:calendar,configuration:.init()))
    #expect(!health.manual && health.input.sleepMinutes == 375)
  }
  @Test func manualZeroIsRealZeroAndSurvivesDiskWithoutHealthWrite() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:dir) }
    let store = try InsightsStore(directory:dir)
    let manual = SelfReportedSleep(minutes:0,end:now.addingTimeInterval(-3600),recordedAt:now)
    try await store.saveManualStatusSleep(manual)
    var s = await store.snapshot()
    let f = try #require(try ScoreFeatureBuilder.build(snapshot:s,now:now,calendar:calendar,configuration:.init()))
    try s.recordStatus(f,configuration:.init(),now:now)
    try await store.commit(s,expectedGeneration:s.generation)
    let reopened = try InsightsStore(directory:dir)
    let restored = await reopened.snapshot()
    #expect(restored.currentStatus?.displayScore == 0 && restored.currentStatus?.features.manual == true)
    #expect(restored.ledger.samples.isEmpty)
    try await reopened.deleteSamples([manual.id])
    #expect(await reopened.snapshot().currentStatus == nil)
  }
  actor Provider: ReadinessDataProviding {
    var rows: [ReadinessSample]
    var fail: ReadinessMetric?
    var held: CheckedContinuation<Void,Never>?
    var holdHRV = false
    var isWaiting: Bool { held != nil }
    init(_ rows: [ReadinessSample], hold: Bool = false) { self.rows = rows; holdHRV = hold }
    func setFailure(_ metric: ReadinessMetric?) { fail = metric }
    func release() { holdHRV = false; held?.resume(); held = nil }
    func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch {
      if metric == .hrvSDNN && holdHRV { await withCheckedContinuation { held = $0 } }
      if metric == fail { throw ReadinessReadFailure.queryFailed }
      return .init(metric:metric,samples:cursor == nil ? rows.filter { $0.metric == metric } : [],cursor:.init(anchor:Data([1]),windowStart:now.addingTimeInterval(-35*86400)))
    }
  }
  @Test func sleepPublishesBeforeHRVAndCursorThenFailureRetainsScore() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:dir) }
    let rows = [row(.sleep)] + (0...3).map { row(.restingHeartRate,day:$0,value:60) }
    let store = try InsightsStore(directory:dir), provider = Provider(rows,hold:true)
    let pipeline = ReadinessPipeline(provider:provider,store:store)
    let task = Task { try await pipeline.refresh(now:now,calendar:calendar,scoreConfiguration:.init()) }
    for _ in 0..<10000 { if await provider.isWaiting { break }; await Task.yield() }
    let early = await store.snapshot()
    await provider.release()
    let final = try await task.value
    #expect(early.currentStatus?.displayScore == 78)
    #expect(early.ledger.cursors[ReadinessMetric.sleep.rawValue] != nil && early.ledger.cursors[ReadinessMetric.hrvSDNN.rawValue] == nil)
    #expect(early.initialization?[ReadinessMetric.sleep.rawValue] == .complete)
    #expect(final.currentStatus?.revision == 2 && final.currentStatus?.components.count == 2)
    await provider.setFailure(.restingHeartRate)
    let failed = try await pipeline.refresh(now:now.addingTimeInterval(7200),calendar:calendar,scoreConfiguration:.init())
    #expect(failed.currentStatus?.scoreID == final.currentStatus?.scoreID && failed.currentStatus?.asOf == final.currentStatus?.asOf)
    #expect(failed.statusReadFailed == true)
  }
  @Test func completedSleepPaginationSelectsSourceBeforePublishingAndFaultDoesNotAdvanceCursor() async throws {
    struct Pages: ReadinessDataProviding {
      let first: [ReadinessSample]; let last: [ReadinessSample]
      func changes(for metric:ReadinessMetric,cursor:HealthReadCursor?,now:Date) async throws -> ReadinessChangeBatch {
        if metric == .sleep {
          return .init(metric:metric,samples:cursor == nil ? first:last,
            cursor:.init(anchor:Data([cursor == nil ? 1:2]),windowStart:now.addingTimeInterval(-35*86400)),hasMore:cursor == nil)
        }
        return .init(metric:metric,samples:[],cursor:.init(anchor:Data([1]),windowStart:now.addingTimeInterval(-35*86400)))
      }
    }
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at:dir) }
    let provider = Pages(first:[row(.sleep,minutes:240,source:"first-page")],last:(0...3).map { row(.sleep,day:$0,minutes:480,source:"later-pages") })
    let store = try InsightsStore(directory:dir), pipeline = ReadinessPipeline(provider:provider,store:store)
    await store.injectNextFault(.beforePublish)
    await #expect(throws:InsightsStoreError.self) { try await pipeline.refresh(now:now,calendar:calendar,scoreConfiguration:.init()) }
    #expect(await store.snapshot().ledger.cursors.isEmpty)
    let result = try await pipeline.refresh(now:now,calendar:calendar,scoreConfiguration:.init())
    #expect(result.currentStatus?.displayScore == 100)
    #expect(result.sources[ReadinessMetric.sleep.rawValue]?.sourceKey == provider.last.first?.sourceKey)
    #expect(result.statusScores?.allSatisfy { $0.displayScore == 100 } == true)
  }
  @Test func scoreDTORejectsBadBoundsUnknownVersionAndCarriesNoSamples() async throws {
    var s = state([row(.sleep)])
    try s.recordStatus(features([row(.sleep)]),configuration:.init(),now:now)
    var dto = DailyStatusSummaryDTO(snapshot:s.currentStatus,installationID:"synthetic-phone",sequence:1,now:now)
    #expect(dto.isValid && dto.score == 78)
    let data = try JSONEncoder().encode(dto), text = String(decoding:data,as:UTF8.self)
    #expect(!text.contains("basisSampleIDs") && !text.contains("sourceSegments") && !text.contains("sleepMinutes"))
    dto.score = 101; #expect(!dto.isValid)
    dto.score = 78; dto.schemaVersion = 99; #expect(!dto.isValid)
  }
}
