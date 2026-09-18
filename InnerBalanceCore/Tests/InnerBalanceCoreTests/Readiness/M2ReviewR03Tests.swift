import Foundation
import Testing
@testable import InnerBalanceCore

@Suite("M2-R03 semantic single flight")
struct M2ReviewR03Tests {
  let f = ReadinessFixture()
  func waitForTwo(_ pipeline: ReadinessPipeline) async {
    for _ in 0..<100_000 { if await pipeline.waitingCallers >= 2 { return }; await Task.yield() }
    #expect(Bool(false), "second request did not enter")
  }
  @Test func changedConfigurationRunsAfterOldFlight() async throws {
    let dir = try InsightsStoreTests().directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = M2ReviewProvider(f.records(),now: f.now)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    await provider.pause(at: .sleep)
    let a = Task { try await pipeline.refresh(now: f.now,calendar: f.calendar) }
    await provider.waitUntilPaused()
    let b = Task { try await pipeline.refresh(now: f.now,calendar: f.calendar,configuration: .init(sleepTargetHours: 10)) }
    await waitForTwo(pipeline); await provider.resume()
    let first = try await a.value, second = try await b.value
    #expect(first.current?.configuration.sleepTargetHours == 8)
    #expect(second.current?.configuration.sleepTargetHours == 10 && second.current?.sleepSeverity == 2)
    #expect(await store.snapshot().current?.configuration.sleepTargetHours == 10)
  }
  @Test func contextAndTimezoneChangeAreNotOldResult() async throws {
    let dir = try InsightsStoreTests().directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = M2ReviewProvider(f.records(),now: f.now)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    await provider.pause(at: .sleep)
    let a = Task { try await pipeline.refresh(now: f.now,calendar: f.calendar) }
    await provider.waitUntilPaused()
    var calendar = f.calendar; calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    let changed = calendar
    let b = Task { try await pipeline.refresh(now: f.now,calendar: changed,interventions: [.init(start: f.date(9),end: f.date(4))]) }
    await waitForTwo(pipeline); await provider.resume()
    _ = try await a.value
    let result = try await b.value
    #expect(result.current?.timeZoneID == "Asia/Tokyo" && result.current?.level == nil)
    #expect(result.current?.qualityFlags.contains(.interventionExcluded) == true)
  }
  @Test func healthEventAfterSleepReadSchedulesOneCatchup() async throws {
    let dir = try InsightsStoreTests().directory(); defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = M2ReviewProvider(f.records(),now: f.now)
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    await provider.pause(at: .restingHeartRate)
    let a = Task { try await pipeline.refresh(now: f.now,calendar: f.calendar) }
    await provider.waitUntilPaused()
    await provider.append([f.sleep(start: 4,end: 3.5,seed: 9000)],metric: .sleep)
    let event = Task { try await pipeline.refresh(now: f.now,calendar: f.calendar,healthDataChanged: true) }
    await waitForTwo(pipeline); await provider.resume()
    _ = try await a.value
    let result = try await event.value
    #expect(result.ledger.samples[f.id(9000).uuidString] != nil)
    #expect(result.current?.sleepEndAt == f.date(3.5))
    #expect(await provider.calls == 8)
  }
}
