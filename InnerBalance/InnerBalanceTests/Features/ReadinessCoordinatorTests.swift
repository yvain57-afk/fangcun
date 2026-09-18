import Foundation
import Testing
import InnerBalanceCore
@testable import InnerBalance

@MainActor struct ReadinessCoordinatorTests {
  private func make(_ scenario: String, clock: @escaping () -> Date = { .now }) throws -> (ReadinessCoordinator, ReadinessDemoProvider, InsightsStore, URL) {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = try InsightsStore(directory: directory)
    let provider = ReadinessDemoProvider(scenario: scenario, now: clock())
    return (.init(store: store, provider: provider, defaults: UserDefaults(suiteName: UUID().uuidString)!, clock: clock), provider, store, directory)
  }
  @Test(arguments: ["assessable", "provisional", "limited", "insufficient", "awaitingData", "failed"])
  func rawProviderThroughPipelineStoreAndOwner(_ scenario: String) async throws {
    let (owner, _, store, directory) = try make(scenario)
    defer { try? FileManager.default.removeItem(at: directory) }
    await owner.refresh()
    #expect(owner.current?.availability.rawValue == scenario)
    #expect(owner.current?.assessmentID == (await store.snapshot()).current?.assessmentID)
    #expect(owner.presentationKey == scenario)
    if scenario == "assessable" {
      #expect(owner.current?.evidence.first?.feature.displayValue == 50)
      #expect(owner.current?.evidence.first?.feature.value != 50)
    }
  }
  @Test func failedRefreshKeepsAnchorAndIndependentCheckTimes() async throws {
    var now = Date.now
    let (owner, provider, _, directory) = try make("assessable", clock: { now })
    defer { try? FileManager.default.removeItem(at: directory) }
    await owner.refresh()
    let first = try #require(owner.current)
    let success = owner.snapshot.lastSuccessfulRefreshAt
    now = now.addingTimeInterval(60)
    await owner.refresh()
    #expect(owner.current?.assessmentID == first.assessmentID)
    #expect(owner.current?.latestMeasuredAt == first.latestMeasuredAt)
    await provider.setFailure(true)
    now = now.addingTimeInterval(60)
    await owner.refresh()
    #expect(owner.current?.refreshFailure != nil)
    #expect(owner.current?.latestMeasuredAt == first.latestMeasuredAt)
    #expect(owner.snapshot.lastRefreshAttemptAt == now)
    #expect(owner.snapshot.lastSuccessfulRefreshAt != success)
    #expect(owner.snapshot.lastSuccessfulRefreshAt != now)
  }
  @Test func clockBoundariesStopAndExplicitResumeDoNotRewardPractices() async throws {
    var now = Date.now
    let (owner, _, store, directory) = try make("assessable", clock: { now })
    defer { try? FileManager.default.removeItem(at: directory) }
    await owner.refresh()
    let first = try #require(owner.current)
    now = try #require(first.sleepEndAt).addingTimeInterval(18*3600+1); owner.tick()
    #expect(owner.presentationKey == "historical")
    now = try #require(first.sleepEndAt).addingTimeInterval(24*3600+1); owner.tick()
    #expect(owner.presentationKey == "stale")
    await owner.stop()
    #expect(owner.current == nil)
    #expect(await store.snapshot().current == nil)
    await owner.refresh(healthDataChanged: true)
    #expect(owner.current == nil)
    #expect(!(await store.snapshot()).assessments.isEmpty)
    await owner.resume()
    #expect(owner.reading)
    await owner.stop(clear: true)
    #expect(await store.snapshot().assessments.isEmpty)
    #expect(!owner.reading)
  }
  @Test func settingsVersionAndSourcesPersistWithoutChangingGoldenParameters() async throws {
    let (owner, _, store, directory) = try make("assessable")
    defer { try? FileManager.default.removeItem(at: directory) }
    await owner.refresh()
    await owner.setTarget(9)
    #expect(owner.current?.configuration.sleepTargetHours == 9)
    #expect(owner.current?.configuration.matureDays == 14)
    let source = try #require(owner.snapshot.sources[ReadinessMetric.hrvSDNN.rawValue])
    await owner.selectSource(source.sourceKey, metric: .hrvSDNN)
    let episode = try #require(owner.snapshot.episodes.last)
    await owner.selectSleep(episode.id)
    #expect(await store.snapshot().manualSleepID == episode.id)
    let reopen = try InsightsStore(directory: directory)
    #expect(await reopen.snapshot().assessments.count >= 2)
  }
  actor GatedProvider: ReadinessDataProviding {
    let raw = ReadinessDemoProvider(scenario: "assessable")
    var entered = false
    var gate: CheckedContinuation<Void, Never>?
    func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch {
      if !entered { entered = true; await withCheckedContinuation { gate = $0 } }
      return try await raw.changes(for: metric, cursor: cursor, now: now)
    }
    func release() { gate?.resume(); gate = nil }
  }
  @Test func latestIntentWinsAndStopIsolatesLateOwnerResults() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try InsightsStore(directory: directory)
    let provider = GatedProvider()
    let owner = ReadinessCoordinator(store: store, provider: provider, defaults: UserDefaults(suiteName: UUID().uuidString)!)
    let first = Task { await owner.refresh() }
    while !(await provider.entered) { await Task.yield() }
    let target = Task { await owner.setTarget(9.5) }
    while owner.configuration.sleepTargetHours != 9.5 { await Task.yield() }
    await provider.release()
    await first.value; await target.value
    #expect(owner.current?.configuration.sleepTargetHours == 9.5)
    await owner.stop(clear: true)
    await owner.refresh(healthDataChanged: true)
    #expect(owner.current == nil)
    #expect(await store.snapshot().assessments.isEmpty)
  }

}
