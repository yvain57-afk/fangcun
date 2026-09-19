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
  private(set) var now: Date
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
    configuration = .init(sleepTargetHours: defaults.object(forKey: "readiness.sleepTarget") as? Double ?? 8)
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
  var presentationKey: String {
    guard reading else { return "stopped" }
    guard let current else { return errorKey == nil ? "insufficient" : "failed" }
    guard current.freshness != .stale || current.level == nil else { return "stale" }
    if current.freshness == .historical && current.level != nil { return "historical" }
    return current.availability.rawValue
  }
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
    now = clock()
    if current?.freshness != before {
      Task { await onSummaryChange?(current) }
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
      guard status.state != .notRequested, version == requestVersion, reading else { return }
    }
    do {
      let value = try await pipeline.refresh(now: now, calendar: .current, configuration: configuration,
        interventions: interventions, healthDataChanged: healthDataChanged)
      guard version == requestVersion, reading, enabled else { return }
      snapshot = value; errorKey = nil; tick()
      await onSummaryChange?(current)
      if !observing, let healthProvider {
        try healthProvider.startObserving(pipeline: pipeline, context: { [weak self] in
          guard let self else { return .init(now: .now, calendar: .current) }
          return .init(now: self.clock(), calendar: .current, configuration: self.configuration, interventions: self.interventions)
        }, onSnapshot: { [weak self] value in
          guard let self, self.reading, self.enabled,
            value.current?.configuration == self.configuration else { return }
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
      value.current?.configuration == configuration else { return }
    snapshot = value; tick()
    await onSummaryChange?(current)
  }
  func setTarget(_ hours: Double) async {
    guard (7...10).contains(hours) else { return }
    configuration = .init(sleepTargetHours: hours)
    defaults.set(hours, forKey: "readiness.sleepTarget")
    requestVersion += 1; snapshot.currentAssessmentID = nil
    await onSummaryChange?(nil)
    await refresh()
  }
  func selectSource(_ key: String, metric: ReadinessMetric) async {
    requestVersion += 1; snapshot.currentAssessmentID = nil; changingSelection = true
    defer { changingSelection = false }
    await onSummaryChange?(nil)
    do { try await store?.selectSource(key, for: metric, now: clock(), calendar: .current); await refresh() }
    catch { errorKey = "readiness.storageError" }
  }
  func selectSleep(_ id: String) async {
    requestVersion += 1; snapshot.currentAssessmentID = nil; changingSelection = true
    defer { changingSelection = false }
    await onSummaryChange?(nil)
    do { try await store?.selectSleep(id); await refresh() } catch { errorKey = "readiness.storageError" }
  }
  func stop(clear: Bool = false) async {
    reading = false; defaults.set(false, forKey: "readiness.reading")
    requestVersion += 1; loading = false; snapshot.currentAssessmentID = nil
    healthProvider?.stopObserving(); observing = false
    await pipeline?.retire(); pipeline = nil
    await onSummaryChange?(nil)
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
