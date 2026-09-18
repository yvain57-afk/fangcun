import Foundation
import Testing
@testable import InnerBalanceCore

@Suite("M2-R04 stable evidence revision")
struct M2ReviewR04Tests {
  let f = ReadinessFixture()
  @Test func movingCutoffDoesNotReviseButNewEvidenceDoes() async throws {
    let dir = try InsightsStoreTests().directory(); defer { try? FileManager.default.removeItem(at: dir) }
    var rows = f.records()
    for i in rows.indices { rows[i].start += 7200; rows[i].end += 7200 }
    let store = try InsightsStore(directory: dir), provider = M2ReviewProvider(rows,now: f.now)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    let first = try #require(try await pipeline.refresh(now: f.now,calendar: f.calendar).current)
    let deltas: [Double] = [60,3599,3600,3601,16*3600,16*3600+1,22*3600]
    for delta in deltas {
      let refreshed = try await pipeline.refresh(now: f.now+delta,calendar: f.calendar)
      let next = try #require(refreshed.current)
      #expect(refreshed.lastSuccessfulRefreshAt == f.now+delta && next.queriedAt == first.queriedAt)
      #expect(next.freshness == (delta <= 16*3600 ? .current : .historical))
      #expect(next.assessmentID == first.assessmentID && next.revision == first.revision)
      #expect(next.inputFingerprint == first.inputFingerprint && next.validUntil == first.validUntil)
    }
    // Replay the open-window clock; a genuinely newer sample must cause a revision.
    var rhr = f.quantity(.restingHeartRate,value: 68,hoursAgo: 0,seed: 9000)
    rhr.start = f.now+70; rhr.end = rhr.start; rhr.queriedAt = f.now+120
    await provider.append([rhr],metric: .restingHeartRate)
    let changed = try #require(try await pipeline.refresh(now: f.now+120,calendar: f.calendar).current)
    #expect(changed.revision > first.revision && changed.level == .reduced)
    #expect(changed.validUntil == first.validUntil)
    let target = try #require(try await pipeline.refresh(now: f.now+180,calendar: f.calendar,configuration: .init(sleepTargetHours: 10)).current)
    #expect(target.revision > changed.revision)
    let stale = try #require(try await pipeline.refresh(now: f.now+22*3600+1,calendar: f.calendar).current)
    #expect(stale.level == nil && stale.freshness == .stale)
  }
}
