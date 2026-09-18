import Foundation
import Synchronization
import Testing
@testable import InnerBalance
@testable import InnerBalanceCore

@Suite("M2-R05 observer completion ordering") @MainActor
struct ReadinessObserverTests {
  @Test func acknowledgesOnlyAfterProcessingAndPersistence() async {
    let events = Mutex<[String]>(["received"])
    let task = ReadinessHealthKitProvider.handleObserverUpdate(error: nil, completion: {
      events.withLock { $0.append("ack") }
    }, onChange: {
      events.withLock { $0.append("processing") }
      await Task.yield()
      events.withLock { $0.append("persisted") }
    })
    await task.value
    #expect(events.withLock { $0 } == ["received","processing","persisted","ack"])
  }
  @Test func processingErrorAndCancellationFinishBeforeExactlyOneAcknowledgement() async {
    for cancelled in [false,true] {
      let events = Mutex<[String]>([])
      let task = ReadinessHealthKitProvider.handleObserverUpdate(error: nil, completion: {
        events.withLock { $0.append("ack") }
      }, onChange: {
        defer { events.withLock { $0.append("saved-failure") } }
        if cancelled { throw CancellationError() }
        throw CocoaError(.fileWriteUnknown)
      })
      await task.value
      #expect(events.withLock { $0 } == ["saved-failure","ack"])
    }
  }
  @Test func callbackErrorStillAcknowledgesOnceWithoutRunningProcessing() async {
    let events = Mutex<[String]>([])
    let task = ReadinessHealthKitProvider.handleObserverUpdate(error: CocoaError(.fileReadUnknown), completion: {
      events.withLock { $0.append("ack") }
    }, onChange: { events.withLock { $0.append("processing") } })
    await task.value
    #expect(events.withLock { $0 } == ["ack"])
  }
}

extension ReadinessObserverTests {
  @Test func sdkCompletionAdapterIsOneShot() async {
    let count = Mutex(0)
    let callback: @Sendable () -> Void = { count.withLock { $0 += 1 } }
    let owner = ReadinessObserverCompletion(callback)
    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<20 { group.addTask { owner.call() } }
    }
    #expect(count.withLock { $0 } == 1)
  }
  @Test func actualTaskCancellationAcknowledgesAfterCooperativeCleanup() async {
    let events = Mutex<[String]>([])
    var started = false
    var outcome: ReadinessObserverOutcome?
    let task = ReadinessHealthKitProvider.handleObserverUpdate(error: nil, completion: {
      events.withLock { $0.append("ack") }
    }, onChange: {
      started = true
      defer { events.withLock { $0.append("cleanup") } }
      try await Task.sleep(for: .seconds(30))
    }, onOutcome: { outcome = $0 })
    while !started { await Task.yield() }
    task.cancel(); await task.value
    #expect(outcome == .cancelled && events.withLock { $0 } == ["cleanup","ack"])
  }
}

extension ReadinessObserverTests {
  @Test func mergedObserverCallbacksWaitForCatchupPersistence() async throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("observer-synthetic-"+UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let store = try InsightsStore(directory: dir), provider = ObserverPipelineProvider()
    let pipeline = ReadinessPipeline(provider: provider,store: store)
    let now = Date(timeIntervalSince1970: 1_789_704_000)
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let fixedCalendar = calendar
    let first = Task { try await pipeline.refresh(now: now,calendar: fixedCalendar) }
    await provider.waitUntilPaused()
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000009000")!
    let sample = ReadinessSample(id: id,metric: .sleep,unit: "category",stage: .asleep,start: now-12*3600,end: now-4*3600,
      source: .init(bundleID: "org.example.observer",samplingMethod: "system"),queriedAt: now)
    await provider.add(sample)
    let events = Mutex<[String]>([])
    var tasks: [Task<Void,Never>] = []
    for i in 0..<2 {
      tasks.append(ReadinessHealthKitProvider.handleObserverUpdate(error: nil,completion: {
        events.withLock { $0.append("ack-\(i)") }
      },onChange: {
        let updated = try await pipeline.refresh(now: now,calendar: fixedCalendar,healthDataChanged: true)
        #expect(updated.ledger.samples[id.uuidString] != nil)
        events.withLock { $0.append("persisted-\(i)") }
      }))
    }
    for _ in 0..<100_000 { if await pipeline.waitingCallers == 3 { break }; await Task.yield() }
    let waiting = await pipeline.waitingCallers
    await provider.resume()
    _ = try await first.value
    for task in tasks { await task.value }
    #expect(waiting == 3)
    #expect(await provider.calls == 8)
    let trace = events.withLock { $0 }
    for i in 0..<2 {
      let persisted = try #require(trace.firstIndex(of: "persisted-\(i)"))
      let ack = try #require(trace.firstIndex(of: "ack-\(i)"))
      #expect(persisted < ack && trace.filter { $0 == "ack-\(i)" }.count == 1)
    }
    let reopened = try InsightsStore(directory: dir)
    #expect(await reopened.snapshot().ledger.samples[id.uuidString] != nil)
  }
}

private actor ObserverPipelineProvider: ReadinessDataProviding {
  private var sample: ReadinessSample?
  private var pause = true
  private var gate: CheckedContinuation<Void,Never>?
  private var waiter: CheckedContinuation<Void,Never>?
  var calls = 0
  func add(_ sample: ReadinessSample) { self.sample = sample }
  func waitUntilPaused() async { if gate == nil { await withCheckedContinuation { waiter = $0 } } }
  func resume() { gate?.resume(); gate = nil }
  func changes(for metric: ReadinessMetric,cursor: HealthReadCursor?,now: Date) async throws -> ReadinessChangeBatch {
    calls += 1
    if metric == .restingHeartRate && pause {
      pause = false
      await withCheckedContinuation { gate = $0; waiter?.resume(); waiter = nil }
    }
    let rows = metric == .sleep && cursor?.anchor != Data([1]) ? sample.map { [$0] } ?? [] : []
    return .init(metric: metric,samples: rows,cursor: .init(anchor: rows.isEmpty ? cursor?.anchor ?? Data([0]) : Data([1]),windowStart: now-35*86400))
  }
}
