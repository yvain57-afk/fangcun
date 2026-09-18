import Foundation
import Testing
@testable import InnerBalanceCore

struct ReadinessLifecycleTests {
  actor SuspendedProvider: ReadinessDataProviding {
    var continuation: CheckedContinuation<Void, Never>?
    var entered = false
    func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch {
      if !entered { entered = true; await withCheckedContinuation { continuation = $0 } }
      return .init(metric: metric, samples: [], cursor: .init(windowStart: now))
    }
    func release() { continuation?.resume(); continuation = nil }
  }
  @Test func retiringRejectsInFlightQueuedAndFutureRefreshes() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try InsightsStore(directory: directory)
    let provider = SuspendedProvider()
    let pipeline = ReadinessPipeline(provider: provider, store: store)
    let first = Task { try await pipeline.refresh(now: .now, calendar: .current) }
    while !(await provider.entered) { await Task.yield() }
    let pending = Task { try await pipeline.refresh(now: .now, calendar: .current, healthDataChanged: true) }
    while await pipeline.waitingCallers < 2 { await Task.yield() }
    await pipeline.retire()
    await provider.release()
    for task in [first, pending] {
      do { _ = try await task.value; Issue.record("Retired refresh published") }
      catch ReadinessPipeline.RefreshError.superseded {} catch { Issue.record("Unexpected error: \(error)") }
    }
    #expect(await store.snapshot().assessments.isEmpty)
    do { _ = try await pipeline.refresh(now: .now, calendar: .current); Issue.record("Retired owner revived") }
    catch ReadinessPipeline.RefreshError.superseded {}
  }
}
