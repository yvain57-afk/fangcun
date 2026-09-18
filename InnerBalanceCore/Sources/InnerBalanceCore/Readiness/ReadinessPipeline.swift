import Foundation

public protocol ReadinessDataProviding: Sendable {
  func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch
}

/// The caller supplies a clock, calendar, and known local practice intervals. No UI, notifications,
/// writes to HealthKit, permission requests, or network dependencies are involved.
public actor ReadinessPipeline {
  private let provider: any ReadinessDataProviding
  private let store: InsightsStore
  public enum RefreshError: Error { case superseded }
  private struct Request: Sendable {
    var now: Date
    var calendar: Calendar
    var configuration: ReadinessConfiguration
    var interventions: [ReadinessInterval]
    var generation: Int
    func sameSemantics(as other: Self) -> Bool {
      configuration == other.configuration && calendar == other.calendar
        && interventions == other.interventions && generation == other.generation
    }
  }
  private struct Flight {
    var id: UUID
    var request: Request
    var task: Task<InsightsSnapshot, Error>
    var waiters: [CheckedContinuation<InsightsSnapshot, Error>]
  }
  private struct Pending {
    var request: Request
    var waiters: [CheckedContinuation<InsightsSnapshot, Error>]
  }
  private var flight: Flight?
  private var pending: Pending?
  internal private(set) var waitingCallers = 0
  public init(provider: any ReadinessDataProviding, store: InsightsStore) { self.provider = provider; self.store = store }

  public func refresh(now: Date, calendar: Calendar, configuration: ReadinessConfiguration = .init(),
    interventions: [ReadinessInterval] = [], healthDataChanged: Bool = false) async throws -> InsightsSnapshot {
    waitingCallers += 1
    defer { waitingCallers -= 1 }
    let generation = await store.snapshot().generation
    let request = Request(now: now, calendar: calendar, configuration: configuration,
      interventions: interventions.sorted { $0.start == $1.start ? $0.end < $1.end : $0.start < $1.start }, generation: generation)
    guard let flight else { return try await start(request, waiters: []).value }
    if pending == nil, !healthDataChanged, flight.request.sameSemantics(as: request) {
      return try await flight.task.value
    }
    // At most one queued pass. Changes arriving during a query need a pass that starts after that event.
    // Replaced settings are explicitly superseded, never reported as having used the newer settings.
    return try await withCheckedThrowingContinuation { continuation in
      if let queued = pending, !queued.request.sameSemantics(as: request) {
        queued.waiters.forEach { $0.resume(throwing: RefreshError.superseded) }
        pending = nil
      }
      var queued = pending ?? Pending(request: request, waiters: [])
      queued.request.now = max(queued.request.now, now)
      queued.waiters.append(continuation)
      pending = queued
    }
  }

  private func start(_ request: Request, waiters: [CheckedContinuation<InsightsSnapshot, Error>]) -> Task<InsightsSnapshot, Error> {
    let id = UUID()
    let task = Task {
      let result: Result<InsightsSnapshot, Error>
      do {
        result = .success(try await self.run(now: request.now, calendar: request.calendar,
          configuration: request.configuration, interventions: request.interventions))
      } catch { result = .failure(error) }
      self.finished(id, result: result)
      return try result.get()
    }
    flight = Flight(id: id, request: request, task: task, waiters: waiters)
    return task
  }

  private func finished(_ id: UUID, result: Result<InsightsSnapshot, Error>) {
    guard let completed = flight, completed.id == id else { return }
    flight = nil
    completed.waiters.forEach { $0.resume(with: result) }
    if let queued = pending {
      pending = nil
      _ = start(queued.request, waiters: queued.waiters)
    }
    // No autonomous retry loop: a next pass only exists when a caller supplied a pending event/request.
  }

  private func run(now: Date, calendar: Calendar, configuration: ReadinessConfiguration,
    interventions: [ReadinessInterval]) async throws -> InsightsSnapshot {
    let initial = await store.snapshot()
    var candidate = initial
    var initialization = initial.initialization ?? [:]
    var failure: ReadinessReadFailure?
    var anyReadFailed = false
    var resetMetrics: Set<ReadinessMetric> = []
    let metrics: [ReadinessMetric] = [.sleep,.hrvSDNN,.restingHeartRate,.workout]
    for metric in metrics {
      var cursor = candidate.ledger.cursors[metric.rawValue]
      if cursor == nil {
        initialization[metric.rawValue] = .inProgress
        resetMetrics.insert(metric)
        candidate.ledger.samples = candidate.ledger.samples.filter { $0.value.metric != metric }
      }
      var pages = 0
      var restarted = false
      while true {
        do {
          let batch = try await provider.changes(for: metric, cursor: cursor, now: now)
          guard batch.metric == metric, !batch.hasMore || batch.cursor != cursor else { throw ReadinessReadFailure.invalidAnchor }
          candidate.ledger.apply(batch, now: now)
          initialization[metric.rawValue] = batch.hasMore ? .inProgress : .complete
          cursor = batch.cursor; pages += 1
          if !batch.hasMore { break }
          // Bounded work per refresh. A later opportunity resumes the committed cursor.
          if pages >= 100 { throw ReadinessReadFailure.queryFailed }
        } catch {
          let reason = error as? ReadinessReadFailure ?? .queryFailed
          if reason == .invalidAnchor, !restarted {
            restarted = true; cursor = nil
            initialization[metric.rawValue] = .inProgress
            resetMetrics.insert(metric)
            candidate.ledger.samples = candidate.ledger.samples.filter { $0.value.metric != metric }
            candidate.ledger.cursors[metric.rawValue] = nil
            continue
          }
          anyReadFailed = true
          if metric != .workout { failure = reason }
          break
        }
      }
    }
    candidate.ledger.samples = candidate.ledger.samples.filter { $0.value.end >= now.addingTimeInterval(-35*86_400) }
    let samples = candidate.ledger.normalizedSamples
    candidate.lastRefreshAttemptAt = now
    if !anyReadFailed { candidate.lastSuccessfulRefreshAt = now }
    candidate.initialization = initialization
    for metric in metrics {
      guard candidate.sources[metric.rawValue] != nil || initialization[metric.rawValue] == .complete else { continue }
      candidate.sources[metric.rawValue] = StableSourceSelector.select(metric: metric, samples: samples,
        existing: candidate.sources[metric.rawValue], calendar: calendar, now: now)
    }
    let invalidated = candidate.ledger.tombstones != initial.ledger.tombstones || initial.requiresResync || (!initial.ledger.samples.isEmpty && !resetMetrics.subtracting([.workout]).isEmpty)
    var prepared = ReadinessInputBuilder.build(samples: samples, sources: candidate.sources,
      previousEpisodes: initial.episodes, now: now, calendar: calendar, configuration: configuration,
      interventions: interventions, manualSleepID: candidate.manualSleepID, readFailure: failure, cacheInvalidated: invalidated)
    let currentCycle = prepared.input.sleep.episode?.recoveryCycleID
    let used = Set(initial.assessments.filter { $0.recoveryCycleID != currentCycle && ($0.sleepEndAt ?? .distantFuture) < (prepared.input.sleep.episode?.end ?? .distantPast) }
      .flatMap { $0.evidence.filter { $0.feature.metric == .restingHeartRate }.flatMap(\.feature.sampleIDs) })
    if !used.isEmpty {
      prepared = ReadinessInputBuilder.build(samples: samples, sources: candidate.sources,
        previousEpisodes: initial.episodes, now: now, calendar: calendar, configuration: configuration,
        interventions: interventions, usedRestingIDs: used, manualSleepID: candidate.manualSleepID,
        readFailure: failure, cacheInvalidated: invalidated)
    }
    let result = ReadinessEngine.evaluate(prepared.input, cached: initial.current)
    candidate.redact(candidate.ledger.tombstones)
    candidate.episodes = prepared.episodes
    candidate.record(result)
    candidate.requiresResync = failure != nil && initial.requiresResync
    // compare-and-swap rejects a late response after source selection, deletion, or clear().
    return try await store.commit(candidate, expectedGeneration: initial.generation)
  }
}
