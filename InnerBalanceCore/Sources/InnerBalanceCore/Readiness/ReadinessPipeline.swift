import Foundation

public protocol ReadinessDataProviding: Sendable {
  func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch
}

/// The caller supplies a clock, calendar, and known local practice intervals. No UI, notifications,
/// writes to HealthKit, permission requests, or network dependencies are involved.
public actor ReadinessPipeline {
  private let provider: any ReadinessDataProviding
  private let store: InsightsStore
  private var flight: Task<InsightsSnapshot, Error>?
  internal private(set) var waitingCallers = 0
  public init(provider: any ReadinessDataProviding, store: InsightsStore) { self.provider = provider; self.store = store }

  public func refresh(now: Date, calendar: Calendar, configuration: ReadinessConfiguration = .init(),
    interventions: [ReadinessInterval] = []) async throws -> InsightsSnapshot {
    waitingCallers += 1
    defer { waitingCallers -= 1 }
    if let flight { return try await flight.value }
    let task = Task { try await self.run(now: now, calendar: calendar, configuration: configuration, interventions: interventions) }
    flight = task
    defer { flight = nil }
    return try await task.value
  }

  private func run(now: Date, calendar: Calendar, configuration: ReadinessConfiguration,
    interventions: [ReadinessInterval]) async throws -> InsightsSnapshot {
    let initial = await store.snapshot()
    var candidate = initial
    var failure: ReadinessReadFailure?
    var resetMetrics: Set<ReadinessMetric> = []
    let metrics: [ReadinessMetric] = [.sleep,.hrvSDNN,.restingHeartRate,.workout]
    for metric in metrics {
      var cursor = candidate.ledger.cursors[metric.rawValue]
      if cursor == nil {
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
          cursor = batch.cursor; pages += 1
          if !batch.hasMore { break }
          // Bounded work per refresh. A later opportunity resumes the committed cursor.
          if pages >= 100 { throw ReadinessReadFailure.queryFailed }
        } catch {
          let reason = error as? ReadinessReadFailure ?? .queryFailed
          if reason == .invalidAnchor, !restarted {
            restarted = true; cursor = nil
            resetMetrics.insert(metric)
            candidate.ledger.samples = candidate.ledger.samples.filter { $0.value.metric != metric }
            candidate.ledger.cursors[metric.rawValue] = nil
            continue
          }
          if metric != .workout { failure = reason }
          break
        }
      }
    }
    candidate.ledger.samples = candidate.ledger.samples.filter { $0.value.end >= now.addingTimeInterval(-35*86_400) }
    let samples = candidate.ledger.normalizedSamples
    for metric in metrics {
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
