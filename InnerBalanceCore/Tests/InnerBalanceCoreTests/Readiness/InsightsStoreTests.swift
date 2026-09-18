import Foundation
import Testing
@testable import InnerBalanceCore

actor SyntheticReadinessProvider: ReadinessDataProviding {
  var pages: [ReadinessMetric: [ReadinessChangeBatch]] = [:]
  var failure: ReadinessReadFailure?
  var invalidateOnce: ReadinessMetric?
  var calls = 0
  var pauseNext = false
  var gate: CheckedContinuation<Void, Never>?
  var waiting: CheckedContinuation<Void, Never>?
  let now: Date
  init(_ rows: [ReadinessSample], now: Date) {
    self.now = now
    for metric in [ReadinessMetric.sleep,.hrvSDNN,.restingHeartRate,.workout] {
      pages[metric] = [ReadinessChangeBatch(metric: metric, samples: rows.filter { $0.metric == metric },
        cursor: .init(anchor: Data([1]),windowStart: now-35*86_400))]
    }
  }
  func setFailure(_ value: ReadinessReadFailure?) { failure = value }
  func append(metric: ReadinessMetric, rows: [ReadinessSample] = [], deleted: [UUID] = []) {
    let n = (pages[metric]?.count ?? 0)+1
    pages[metric,default: []].append(.init(metric: metric,samples: rows,deletedIDs: deleted,
      cursor: .init(anchor: Data([UInt8(n)]),windowStart: now-35*86_400)))
  }
  func resetHRVSnapshot() {
    pages[.hrvSDNN]?[0].samples.removeAll { $0.end > now-24*3600 }
    invalidateOnce = .hrvSDNN
  }
  func pause() { pauseNext = true }
  func waitUntilPaused() async { if gate == nil { await withCheckedContinuation { waiting = $0 } } }
  func resume() { gate?.resume(); gate = nil }
  func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch {
    calls += 1
    if pauseNext {
      pauseNext = false
      await withCheckedContinuation { continuation in gate = continuation; waiting?.resume(); waiting = nil }
    }
    if invalidateOnce == metric { invalidateOnce = nil; throw ReadinessReadFailure.invalidAnchor }
    if let failure { throw failure }
    let index = Int(cursor?.anchor?.first ?? 0)
    if let list = pages[metric], index < list.count {
      var result = list[index]; result.hasMore = index+1 < list.count; return result
    }
    return ReadinessChangeBatch(metric: metric,samples: [],cursor: cursor ?? .init(anchor: Data([0]),windowStart: now-35*86_400))
  }
}

@Suite("M2 atomic Insights store and provider pipeline")
struct InsightsStoreTests {
  let f = ReadinessFixture()
  func directory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("fangcun-synthetic-"+UUID().uuidString)
    try FileManager.default.createDirectory(at: url,withIntermediateDirectories: true); return url
  }
  func candidate() -> InsightsSnapshot {
    var value = InsightsSnapshot()
    let rows = f.records()
    for metric in [ReadinessMetric.sleep,.hrvSDNN,.restingHeartRate] {
      value.ledger.apply(.init(metric: metric,samples: rows.filter { $0.metric == metric },
        cursor: .init(anchor: Data([1]),windowStart: f.date(35*24))), now: f.now)
    }
    value.sources = f.input(rows).sources
    value.episodes = f.build(rows).episodes
    value.record(f.assess(rows)); return value
  }
  @Test func transactionFaultsKeepCursorsAndAssessmentTogether() async throws {
    let dir = try directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir)
    await store.injectNextFault(.beforePublish)
    await #expect(throws: InsightsStoreError.injectedFailure) { try await store.commit(candidate(),expectedGeneration: 0) }
    #expect(await store.snapshot().ledger.cursors.isEmpty)
    let first = try await store.commit(candidate(),expectedGeneration: 0)
    #expect(first.current?.level == .usual && first.ledger.cursors.count == 3)
    var next = first; next.ledger.cursors[ReadinessMetric.sleep.rawValue]?.anchor = Data([2])
    await store.injectNextFault(.afterPublish)
    await #expect(throws: InsightsStoreError.injectedFailure) { try await store.commit(next,expectedGeneration: 1) }
    let reopened = try InsightsStore(directory: dir)
    #expect(await reopened.snapshot().ledger.cursors[ReadinessMetric.sleep.rawValue]?.anchor == Data([2]))
    #expect(await reopened.snapshot().current?.level == .usual)
    await #expect(throws: InsightsStoreError.staleTransaction) { try await reopened.commit(first,expectedGeneration: 1) }
  }
  @Test func deletionBarrierSurvivesInterruptedPublishAndCorruptPrimary() async throws {
    let dir = try directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir)
    let original = try await store.commit(candidate(),expectedGeneration: 0)
    var deleted = original; deleted.ledger.tombstones.insert(f.id(10).uuidString)
    await store.injectNextFault(.afterPrivacy)
    await #expect(throws: InsightsStoreError.injectedFailure) { try await store.commit(deleted,expectedGeneration: original.generation) }
    let reopened = try InsightsStore(directory: dir)
    let cleaned = await reopened.snapshot()
    #expect(cleaned.ledger.samples[f.id(10).uuidString] == nil && cleaned.current == nil)
    #expect(!cleaned.deletionAudit.isEmpty)
    _ = try await reopened.commit(cleaned,expectedGeneration: cleaned.generation)
    try Data("broken".utf8).write(to: dir.appendingPathComponent("insights-v1.json"))
    let recovered = try InsightsStore(directory: dir)
    let restored = await recovered.snapshot()
    #expect(restored.requiresResync && restored.ledger.cursors.isEmpty && restored.current == nil)
    #expect(restored.ledger.samples[f.id(10).uuidString] == nil)
    var replay = restored
    replay.ledger.apply(.init(metric: .hrvSDNN,samples: [f.quantity(.hrvSDNN,value: 50,hoursAgo: 6,seed: 10)],
      cursor: .init(anchor: Data([3]),windowStart: f.date(35*24))),now: f.now)
    #expect(replay.ledger.samples[f.id(10).uuidString] == nil)
  }
  @Test func corruptedJournalAndUnknownSchemaFailClosedWithoutWiping() async throws {
    let dir = try directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir)
    _ = try await store.commit(candidate(),expectedGeneration: 0)
    let primary = dir.appendingPathComponent("insights-v1.json")
    let original = try Data(contentsOf: primary)
    var object = try #require(JSONSerialization.jsonObject(with: original) as? [String: Any])
    object["schemaVersion"] = 99
    let future = try JSONSerialization.data(withJSONObject: object)
    try future.write(to: primary)
    #expect(throws: InsightsStoreError.unsupportedSchema) { _ = try InsightsStore(directory: dir) }
    #expect(try Data(contentsOf: primary) == future)
    try original.write(to: primary)
    try Data("broken".utf8).write(to: dir.appendingPathComponent("deletions-v1.json"))
    #expect(throws: InsightsStoreError.corrupt) { _ = try InsightsStore(directory: dir) }
    #expect(try Data(contentsOf: primary) == original)
  }
  @Test func providerToStorePaginationRevisionsAndDeletion() async throws {
    let dir = try directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = SyntheticReadinessProvider(f.records(),now: f.now)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    let first = try await pipeline.refresh(now: f.now,calendar: f.calendar)
    #expect(first.current?.level == .usual && first.current?.revision == 1)
    let same = try await pipeline.refresh(now: f.now+60,calendar: f.calendar)
    #expect(same.current?.assessmentID == first.current?.assessmentID && same.current?.validUntil == first.current?.validUntil)
    await provider.append(metric: .sleep,rows: [f.sleep(start: 4,end: 3.5,seed: 9999)])
    let late = try await pipeline.refresh(now: f.now+120,calendar: f.calendar)
    #expect(late.current?.recoveryCycleID == first.current?.recoveryCycleID)
    #expect(late.current?.revision == 2 && late.current?.supersedesID == first.current?.assessmentID)
    await provider.append(metric: .hrvSDNN,deleted: [f.id(10),f.id(11)])
    await provider.append(metric: .hrvSDNN,rows: [f.quantity(.hrvSDNN,value: 50,hoursAgo: 6,seed: 10)])
    let deleted = try await pipeline.refresh(now: f.now+180,calendar: f.calendar)
    #expect(deleted.current?.level == nil && deleted.current?.revision == 3)
    #expect(deleted.ledger.samples[f.id(10).uuidString] == nil)
    #expect(deleted.ledger.cursors[ReadinessMetric.hrvSDNN.rawValue]?.anchor == Data([3]))
    let reopened = try InsightsStore(directory: dir)
    #expect(await reopened.snapshot().current?.availability == .limited)
    #expect(await reopened.snapshot().assessments.allSatisfy { !$0.contributingSampleIDs.contains(f.id(10)) })
  }
  @Test func sourceChangeAndClearRejectLateRequests() async throws {
    let dir = try directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = SyntheticReadinessProvider(f.records(),now: f.now)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    _ = try await pipeline.refresh(now: f.now,calendar: f.calendar)
    await provider.pause()
    let old = Task { try await pipeline.refresh(now: f.now+60,calendar: f.calendar) }
    await provider.waitUntilPaused()
    try await store.selectSource("explicit-new-source",for: .hrvSDNN,now: f.now,calendar: f.calendar)
    await provider.resume()
    await #expect(throws: InsightsStoreError.staleTransaction) { try await old.value }
    #expect(await store.snapshot().sources[ReadinessMetric.hrvSDNN.rawValue]?.sourceKey == "explicit-new-source")
    await provider.pause()
    let old2 = Task { try await pipeline.refresh(now: f.now+120,calendar: f.calendar) }
    await provider.waitUntilPaused()
    try await store.clear()
    await provider.resume()
    await #expect(throws: InsightsStoreError.staleTransaction) { try await old2.value }
    #expect(await store.snapshot().ledger.samples.isEmpty)
    let reopened = try InsightsStore(directory: dir)
    #expect(await reopened.snapshot().current == nil)
  }
  @Test func failureKeepsOriginalCacheButEmptyInitialReadIsNotPermissionDenial() async throws {
    let dir = try directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = SyntheticReadinessProvider(f.records(),now: f.now)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    let first = try await pipeline.refresh(now: f.now,calendar: f.calendar)
    await provider.setFailure(.protectedDataUnavailable)
    let failed = try await pipeline.refresh(now: f.now+60,calendar: f.calendar)
    #expect(failed.current?.computedAt == first.current?.computedAt && failed.current?.level == .usual)
    #expect(failed.current?.refreshFailure == .protectedDataUnavailable)
    #expect(failed.ledger.cursors == first.ledger.cursors)
    try await store.clear()
    await provider.setFailure(nil)
    let emptyProvider = SyntheticReadinessProvider([],now: f.now)
    let empty = try await ReadinessPipeline(provider: emptyProvider,store: store).refresh(now: f.now,calendar: f.calendar)
    #expect(empty.current?.availability == .insufficient && empty.current?.refreshFailure == nil)
  }
  @Test func concurrentRefreshCoalescesAndInvalidAnchorRebuildsCurrentEvidence() async throws {
    let dir = try directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = SyntheticReadinessProvider(f.records(),now: f.now)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    await provider.pause()
    let first = Task { try await pipeline.refresh(now: f.now,calendar: f.calendar) }
    await provider.waitUntilPaused()
    let second = Task { try await pipeline.refresh(now: f.now,calendar: f.calendar) }
    for _ in 0..<10_000 {
      if await pipeline.waitingCallers == 2 { break }
      await Task.yield()
    }
    let joined = await pipeline.waitingCallers
    await provider.resume()
    let a = try await first.value, b = try await second.value
    #expect(joined == 2 && a.generation == b.generation)
    #expect(await provider.calls == 4)
    await provider.resetHRVSnapshot()
    let reset = try await pipeline.refresh(now: f.now+60,calendar: f.calendar)
    #expect(reset.current?.level == nil && reset.current?.availability == .limited)
    #expect(reset.ledger.samples[f.id(10).uuidString] == nil)
  }

}
