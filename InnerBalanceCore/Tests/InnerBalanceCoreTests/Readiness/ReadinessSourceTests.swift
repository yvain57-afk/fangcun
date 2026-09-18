import Foundation
import Testing
@testable import InnerBalanceCore

@Suite("M2 normalized sources")
struct ReadinessSourceTests {
  let now = Date(timeIntervalSince1970: 1_789_704_000)
  var source: ReadinessSource { ReadinessSource(bundleID: "org.example.synthetic.ring", productType: "Ring", samplingMethod: "SDNN") }
  func sample(_ day: Int, source: ReadinessSource? = nil, id: UUID = UUID()) -> ReadinessSample {
    ReadinessSample(id: id, metric: .hrvSDNN, value: 50, unit: "ms", start: now.addingTimeInterval(-Double(day) * 86_400),
      end: now.addingTimeInterval(-Double(day) * 86_400), source: source ?? self.source, queriedAt: now)
  }
  @Test func sourceDefinitionsAndRevisions() {
    var other = source; other.bundleID = "org.example.other"
    #expect(source.key(for: .hrvSDNN) != other.key(for: .hrvSDNN))
    #expect(source.key(for: .hrvSDNN) != source.key(for: .hrvRMSSD))
    other = source; other.revision = "new app version"
    #expect(source.key(for: .hrvSDNN) == other.key(for: .hrvSDNN))
    other.compatibilitySegment = "new sampling protocol"
    #expect(source.key(for: .hrvSDNN) != other.key(for: .hrvSDNN))
    #expect(source.identityIncomplete && !source.identityAmbiguous)
  }
  @Test func noSilentSwitchAndManualRebaseline() throws {
    var watch = source; watch.bundleID = "org.example.watch"; watch.isOriginalDeviceRecord = true
    let records = (1...20).map { sample($0) } + [sample(0, source: watch)]
    let chosen = try #require(StableSourceSelector.select(metric: .hrvSDNN, samples: records, existing: nil, calendar: .current, now: now))
    #expect(chosen.sourceKey == source.key(for: .hrvSDNN))
    #expect(StableSourceSelector.select(metric: .hrvSDNN, samples: [sample(0, source: watch)], existing: chosen, calendar: .current, now: now) == chosen)
    let changed = try #require(StableSourceSelector.select(metric: .hrvSDNN, samples: records, existing: chosen,
      requested: watch.key(for: .hrvSDNN), calendar: .current, now: now))
    #expect(changed.sourceKey != chosen.sourceKey && changed.segmentID != chosen.segmentID && changed.manuallySelected)
  }
  @Test func uuidSyncVersionAndExplicitMirrors() {
    let a = sample(1)
    var newer = a; newer.id = UUID(); newer.syncIdentifier = "synthetic-sync"; newer.syncVersion = 2
    var older = a; older.syncIdentifier = "synthetic-sync"; older.syncVersion = 1
    #expect(SampleNormalizer.deduplicate([a,a]).count == 1)
    #expect(SampleNormalizer.deduplicate([older,newer]).map(\.id) == [newer.id])
    var mirror = a; mirror.id = UUID(); mirror.source.bundleID = "org.example.mirror"
    #expect(SampleNormalizer.deduplicate([a,mirror]).count == 2)
    #expect(SampleNormalizer.deduplicate([a,mirror], mirrors: .init(sourcePairs: [[a.sourceKey,mirror.sourceKey]])).count == 1)
  }
  @Test func deletionWinsAndCacheIsBounded() {
    let a = sample(0), old = sample(36)
    let cursor = HealthReadCursor(anchor: Data([1]), windowStart: now.addingTimeInterval(-35*86_400))
    var ledger = ReadinessSampleLedger()
    ledger.apply(.init(metric: .hrvSDNN, samples: [a,old], cursor: cursor), now: now)
    #expect(ledger.samples.count == 1)
    ledger.apply(.init(metric: .hrvSDNN, samples: [a], deletedIDs: [a.id], cursor: cursor), now: now)
    ledger.apply(.init(metric: .hrvSDNN, samples: [a], cursor: cursor), now: now)
    #expect(ledger.samples.isEmpty && ledger.tombstones.contains(a.id.uuidString))
  }
}
