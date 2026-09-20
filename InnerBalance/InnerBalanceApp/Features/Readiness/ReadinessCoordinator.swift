import Foundation
import Observation
import SwiftUI
import InnerBalanceCore

private struct ReadinessOwnerKey: EnvironmentKey {
  static let defaultValue: ReadinessCoordinator? = nil
}
extension EnvironmentValues {
  var readinessOwner: ReadinessCoordinator? {
    get { self[ReadinessOwnerKey.self] }
    set { self[ReadinessOwnerKey.self] = newValue }
  }
}

/// One app-owned service, independent of view rendering and the legacy home model.
@MainActor @Observable final class ReadinessCoordinator {
  private(set) var snapshot = InsightsSnapshot()
  private(set) var loading = false
  private(set) var errorKey: String?
  private(set) var enabled: Bool
  private(set) var reading: Bool
  private(set) var configuration: ReadinessConfiguration
  private(set) var scoreConfiguration: StatusScoreConfiguration
  private(set) var connected: Bool
  private(set) var now: Date
  var onStatusChange: ((DailyStatusSnapshot?) async -> Void)?
  var onSummaryChange: ((ReadinessAssessment?) async -> Void)?
  var interventions: [ReadinessInterval] = []
  private let clock: () -> Date
  private let defaults: UserDefaults
  private let store: InsightsStore?
  private let provider: (any ReadinessDataProviding)?
  private let healthProvider: ReadinessHealthKitProvider?
  private var pipeline: ReadinessPipeline?
  private var requestVersion = 0
  private var changingSelection = false
  private var observing = false
  private let requiresAuthorization: Bool

  init(store: InsightsStore?, provider: (any ReadinessDataProviding)?, pipeline: ReadinessPipeline? = nil,
    defaults: UserDefaults = .standard, requiresAuthorization: Bool = false, clock: @escaping () -> Date = { .now }) {
    self.store = store; self.provider = provider; self.defaults = defaults; self.clock = clock
    self.requiresAuthorization = requiresAuthorization; self.healthProvider = provider as? ReadinessHealthKitProvider
    self.pipeline = pipeline ?? store.flatMap { s in provider.map { ReadinessPipeline(provider: $0, store: s) } }
    enabled = defaults.object(forKey: "readiness.enabled") as? Bool ?? true
    reading = defaults.object(forKey: "readiness.reading") as? Bool ?? true
    let target = defaults.object(forKey: "readiness.sleepTarget") as? Double ?? 8
    configuration = .init(sleepTargetHours: target)
    scoreConfiguration = .init(sleepGoalMinutes: defaults.object(forKey: "status-v3.sleepGoal") as? Double ?? target*60,
      regularityEnabled: defaults.object(forKey: "status-v3.regularity") as? Bool ?? true)
    connected = !requiresAuthorization
    now = clock()
    if store == nil { errorKey = "readiness.storageError" }
  }
  static func make() -> ReadinessCoordinator {
    #if DEBUG
    let args = ProcessInfo.processInfo.arguments
    if args.contains("--readiness-disabled") {
      let defaults = UserDefaults(suiteName: "readiness.disabled." + UUID().uuidString)!
      defaults.set(false, forKey: "readiness.enabled")
      return .init(store: nil, provider: nil, defaults: defaults)
    }
    if let flag = args.first(where: { $0.hasPrefix("--readiness-fixture=") }) {
      let scenario = String(flag.dropFirst("--readiness-fixture=".count))
      let store = try? InsightsStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
      if scenario.hasPrefix("score") {
        let date = ISO8601DateFormatter().date(from: args.contains("--score-night") ? "2026-09-20T15:22:00Z" : "2026-09-20T04:00:00Z")!
        let defaults = UserDefaults(suiteName:UUID().uuidString)!
        if scenario == "scoreFull240" { defaults.set(false,forKey:"status-v3.regularity") }
        return .init(store: store, provider: ReadinessDemoProvider(scenario: scenario, now: date), defaults: defaults, clock: { date })
      }
      return .init(store: store, provider: ReadinessDemoProvider(scenario: scenario),
        defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }
    #endif
    do {
      let services = try ReadinessServices.make()
      return .init(store: services.store, provider: services.provider, pipeline: services.pipeline, requiresAuthorization: true)
    } catch { return .init(store: nil, provider: nil, requiresAuthorization: true) }
  }
  var current: ReadinessAssessment? {
    guard enabled, reading, var value = snapshot.current, value.configuration == configuration else { return nil }
    value.freshness = AssessmentFreshness.resolve(value, now: now, newerSleepEnd: snapshot.episodes.map(\.end).max())
    return value
  }
  var statusScore: DailyStatusSnapshot? {
    guard enabled, reading, let score = snapshot.currentStatus, score.configuration == scoreConfiguration,
      now < score.validUntil else { return nil }
    return score
  }
  var presentationKey: String {
    guard reading else { return "stopped" }
    guard let current else { return errorKey == nil ? "insufficient" : "failed" }
    guard current.freshness != .stale || current.level == nil else { return "stale" }
    if current.freshness == .historical && current.level != nil { return "historical" }
    return current.availability.rawValue
  }
  var guidance: DayGuidancePresentation { .resolve(current, reading: reading, serviceError: errorKey != nil) }
  var title: String {
    guard let current, current.freshness == .current, let level = current.level else {
      return FangcunCopy.text("readiness.state." + presentationKey)
    }
    return FangcunCopy.text("readiness.level." + level.rawValue)
  }
  var scene: FangcunDayState {
    guard let current, current.freshness == .current else { return .insufficient }
    switch current.level {
    case .usual: return .steady
    case .reduced, .low: return .elevated
    case nil: return current.availability == .limited ? .limited : .insufficient
    }
  }
  func tick() {
    let before = current?.freshness
    let scoreBefore = statusScore?.scoreID
    now = clock()
    if current?.freshness != before || scoreBefore != statusScore?.scoreID {
      Task { await onSummaryChange?(current)
      await onStatusChange?(statusScore) }
    }
  }
  func refresh(healthDataChanged: Bool = false) async {
    tick()
    guard enabled, reading, let pipeline else { return }
    requestVersion += 1
    let version = requestVersion
    loading = true
    defer { if version == requestVersion { loading = false } }
    if requiresAuthorization {
      let status = await HealthAuthorizationCoordinator().status(for: .initialBodyStatus)
      connected = status.state != .notRequested
      guard status.state != .notRequested, version == requestVersion, reading else { return }
    }
    await pipeline.setOnCommit { [weak self] _ in await self?.acceptStoredSnapshot() }
    // Disk-first: a cold start or query failure must not erase a still-valid score.
    await acceptStoredSnapshot()
    do {
      let value = try await pipeline.refresh(now: now, calendar: .current, configuration: configuration,
        interventions: interventions, healthDataChanged: healthDataChanged, scoreConfiguration: scoreConfiguration)
      guard version == requestVersion, reading, enabled else { return }
      snapshot = value; errorKey = value.statusReadFailed == true ? "readiness.refreshError" : nil; tick()
      await onSummaryChange?(current)
      await onStatusChange?(statusScore)
      if !observing, let healthProvider {
        try healthProvider.startObserving(pipeline: pipeline, context: { [weak self] in
          guard let self else { return .init(now: .now, calendar: .current) }
          return .init(now: self.clock(), calendar: .current, configuration: self.configuration, interventions: self.interventions, scoreConfiguration: self.scoreConfiguration)
        }, onSnapshot: { [weak self] value in
          guard let self, self.reading, self.enabled,
            (value.currentStatus?.configuration == self.scoreConfiguration || value.current?.configuration == self.configuration) else { return }
          // Re-read the committed store: a delayed observer result must not replace newer intent.
          Task { await self.acceptStoredSnapshot() }
        })
        observing = true
      }
    } catch ReadinessPipeline.RefreshError.superseded { }
    catch InsightsStoreError.staleTransaction { }
    catch { if version == requestVersion { errorKey = "readiness.refreshError" } }
  }
  private func acceptStoredSnapshot() async {
    let version = requestVersion
    guard let store else { return }
    let value = await store.snapshot()
    guard version == requestVersion, reading, enabled, !changingSelection,
      (value.currentStatus?.configuration == scoreConfiguration || value.current?.configuration == configuration) else { return }
    snapshot = value; tick()
    await onSummaryChange?(current)
      await onStatusChange?(statusScore)
  }
  func setTarget(_ hours: Double) async {
    guard (7...10).contains(hours) else { return }
    configuration = .init(sleepTargetHours: hours)
    scoreConfiguration.sleepGoalMinutes = hours*60
    defaults.set(hours*60, forKey: "status-v3.sleepGoal")
    defaults.set(hours, forKey: "readiness.sleepTarget")
    requestVersion += 1; snapshot.currentStatusID = nil; snapshot.currentAssessmentID = nil
    await onSummaryChange?(nil)
    await onStatusChange?(nil)
    await refresh()
  }
  func setRegularity(_ enabled: Bool) async {
    scoreConfiguration.regularityEnabled = enabled
    defaults.set(enabled, forKey: "status-v3.regularity")
    requestVersion += 1; snapshot.currentStatusID = nil
    await onStatusChange?(nil); await refresh()
  }
  func saveManualSleep(minutes: Double, end: Date) async {
    guard let store else { return }
    do {
      requestVersion += 1
      try await store.saveManualStatusSleep(.init(minutes: minutes, end: end, recordedAt: clock()))
      var value = await store.snapshot()
      if let features = try ScoreFeatureBuilder.build(snapshot:value,now:clock(),calendar:.current,configuration:scoreConfiguration,interventions:interventions) {
        try value.recordStatus(features,configuration:scoreConfiguration,now:clock())
        snapshot = try await store.commit(value,expectedGeneration:value.generation)
        errorKey = nil; tick(); await onStatusChange?(statusScore)
      }
    } catch { errorKey = "readiness.storageError" }
  }
  func selectSource(_ key: String, metric: ReadinessMetric) async {
    requestVersion += 1; snapshot.currentStatusID = nil; snapshot.currentAssessmentID = nil; changingSelection = true
    defer { changingSelection = false }
    await onSummaryChange?(nil)
    await onStatusChange?(nil)
    do { try await store?.selectSource(key, for: metric, now: clock(), calendar: .current); await refresh() }
    catch { errorKey = "readiness.storageError" }
  }
  func selectSleep(_ id: String) async {
    requestVersion += 1; snapshot.currentStatusID = nil; snapshot.currentAssessmentID = nil; changingSelection = true
    defer { changingSelection = false }
    await onSummaryChange?(nil)
    await onStatusChange?(nil)
    do { try await store?.selectSleep(id); await refresh() } catch { errorKey = "readiness.storageError" }
  }
  func stop(clear: Bool = false) async {
    reading = false; defaults.set(false, forKey: "readiness.reading")
    requestVersion += 1; loading = false; snapshot.currentAssessmentID = nil
    healthProvider?.stopObserving(); observing = false
    await pipeline?.retire(); pipeline = nil
    await onSummaryChange?(nil)
    await onStatusChange?(nil)
    do {
      if clear { try await store?.clear(); snapshot = InsightsSnapshot() }
      else { try await store?.invalidateCurrent() }
    } catch { errorKey = "readiness.storageError" }
  }
  func resume() async {
    guard let store, let provider else { return }
    reading = true; defaults.set(true, forKey: "readiness.reading")
    pipeline = ReadinessPipeline(provider: provider, store: store)
    await refresh()
  }
  func setEnabled(_ value: Bool) async {
    if !value { await stop() }
    enabled = value; defaults.set(value, forKey: "readiness.enabled")
    if value { await resume() }
  }
}
