import Foundation
import Testing
@testable import InnerBalanceCore

@Suite("M2-R02 paged source discovery")
struct M2ReviewR02Tests {
  let f = ReadinessFixture()
  @Test(arguments: [false,true]) func incompleteDiscoveryResumesWithoutFreezingFirstSource(manual: Bool) async throws {
    let dir = try InsightsStoreTests().directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = M2ReviewProvider(f.records(),now: f.now)
    var a = f.quantity(.hrvSDNN,value: 50,hoursAgo: 6,seed: 9000); a.source.bundleID = "synthetic.first-page"
    await provider.setPages([[a],f.records().filter { $0.metric == .hrvSDNN }],metric: .hrvSDNN)
    await provider.failOnce(metric: .hrvSDNN,page: 1)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    let partial = try await pipeline.refresh(now: f.now,calendar: f.calendar)
    #expect(partial.current?.level == nil)
    #expect(partial.sources[ReadinessMetric.hrvSDNN.rawValue] == nil)
    #expect(partial.ledger.cursors[ReadinessMetric.hrvSDNN.rawValue]?.anchor == Data("1".utf8))
    if manual { try await store.selectSource(a.sourceKey,for: .hrvSDNN,now: f.now,calendar: f.calendar) }
    let reopened = try InsightsStore(directory: dir)
    let finished = try await ReadinessPipeline(provider: provider,store: reopened).refresh(now: f.now+60,calendar: f.calendar)
    #expect(finished.sources[ReadinessMetric.hrvSDNN.rawValue]?.sourceKey == (manual ? a.sourceKey : f.source.key(for: .hrvSDNN)))
    #expect(finished.current?.level == (manual ? nil : .usual))
    var alternate = f.quantity(.hrvSDNN,value: 60,hoursAgo: 5,seed: 9999); alternate.source.bundleID = "new.watch"
    await provider.append([alternate],metric: .hrvSDNN)
    let stable = try await ReadinessPipeline(provider: provider,store: reopened).refresh(now: f.now+120,calendar: f.calendar)
    #expect(stable.sources == finished.sources)
  }
  @Test func workBudgetDoesNotFreezeIncompleteDiscovery() async throws {
    let dir = try InsightsStoreTests().directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = M2ReviewProvider(f.records(),now: f.now)
    var a = f.quantity(.hrvSDNN,value: 50,hoursAgo: 6,seed: 9000); a.source.bundleID = "synthetic.first-page"
    await provider.setPages(Array(repeating: [a],count: 100)+[f.records().filter { $0.metric == .hrvSDNN }],metric: .hrvSDNN)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    let partial = try await pipeline.refresh(now: f.now,calendar: f.calendar)
    #expect(partial.current?.level == nil && partial.sources[ReadinessMetric.hrvSDNN.rawValue] == nil)
    let completed = try await pipeline.refresh(now: f.now+60,calendar: f.calendar)
    #expect(completed.current?.level == .usual)
    #expect(completed.sources[ReadinessMetric.hrvSDNN.rawValue]?.sourceKey == f.source.key(for: .hrvSDNN))
  }
}
