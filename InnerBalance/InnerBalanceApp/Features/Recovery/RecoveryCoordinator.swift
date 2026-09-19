import Foundation
import Observation
import SwiftUI
import InnerBalanceCore

private struct RecoveryOwnerKey: EnvironmentKey { static let defaultValue: RecoveryCoordinator? = nil }
extension EnvironmentValues {
  var recoveryOwner: RecoveryCoordinator? {
    get { self[RecoveryOwnerKey.self] }
    set { self[RecoveryOwnerKey.self] = newValue }
  }
}
@MainActor @Observable final class RecoveryCoordinator {
  let store: RecoveryStore?
  private(set) var records: [RecoverySession] = []
  private(set) var errorKey: String?
  var environment = RecoveryEnvironment.seated
  var canStart: Bool { environment != .driving && environment != .unavailable }
  private var recovered = false
  init(store: RecoveryStore?) { self.store = store; if store == nil { errorKey = "recovery.storageError" } }
  static func make() -> RecoveryCoordinator {
    do {
      var directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("FangcunRecovery")
      #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
      }
      #endif
      return .init(store: try RecoveryStore(directory: directory))
    } catch { return .init(store: nil) }
  }
  func load() async {
    guard let store else { return }
    do {
      if !recovered { try await store.recoverInterrupted(now: .now); recovered = true }
      records = await store.records()
    } catch { errorKey = "recovery.storageError" }
  }
  func save(_ record: RecoverySession) async -> Bool {
    guard let store else { errorKey = "recovery.storageError"; return false }
    do { try await store.save(record); records = await store.records(); errorKey = nil; return true }
    catch { errorKey = "recovery.storageError"; return false }
  }
  func importPractice(_ record: PracticeCompletionRecord) async {
    if records.contains(where: { $0.sessionID == record.sessionID }) { return }
    var value = RecoverySession(sessionID: record.sessionID, action: .practice(record.practiceKind),
      plannedDuration: record.plannedDuration, startedAt: record.startedAt, originDevice: "iPhone")
    value.activeDuration = record.actualDuration; value.endedAt = record.endedAt; value.endReason = .legacyUnknown
    _ = await save(value)
  }
  func feedback(_ id: String, _ value: RecoveryHelpfulness?) async -> Bool {
    guard let store else { return false }
    do { try await store.feedback(sessionID: id, helpfulness: value, now: .now); records = await store.records(); errorKey = nil; return true }
    catch { errorKey = "recovery.storageError"; return false }
  }
  var uncomfortable: Set<RecoveryActionKind> {
    Set(records.filter { $0.feedback?.helpfulness == .uncomfortable || $0.feedbackHistory.contains { $0.helpfulness == .uncomfortable } }.map(\.action))
  }
}

@MainActor @Observable final class RecoverySessionModel {
  enum Phase { case ready, running, paused, saving, feedback, done }
  private(set) var phase = Phase.ready
  private(set) var clock: RecoverySessionClock?
  private(set) var elapsed: TimeInterval = 0
  private(set) var failed = false
  let plan: RecoveryProtocol
  private let now: () -> Date
  init(plan: RecoveryProtocol, now: @escaping () -> Date = { .now }) { self.plan = plan; self.now = now }
  func start(environment: RecoveryEnvironment) {
    guard phase == .ready, environment != .driving, environment != .unavailable,
      plan.action != .movementBreak || environment == .canMove else { return }
    clock = .init(session: .init(action: plan.action, plannedDuration: plan.duration, startedAt: now(), originDevice: "iPhone"))
    clock?.resume(at: now()); phase = .running
  }
  func pause() { guard phase == .running else { return }; clock?.pause(at: now()); elapsed = clock?.elapsed(at: now()) ?? 0; phase = .paused }
  func resume() { guard phase == .paused else { return }; clock?.resume(at: now()); phase = .running }
  func tick() { elapsed = clock?.elapsed(at: now()) ?? 0 }
  func checkpoint(owner: RecoveryCoordinator) async {
    guard phase == .running || phase == .paused, let record = clock?.checkpoint(at: now()) else { return }
    _ = await owner.save(record)
  }
  func finish(owner: RecoveryCoordinator) async {
    guard phase == .running || phase == .paused || (phase == .saving && failed),
      let record = clock?.finish(at: now()) else { return }
    phase = .saving; failed = false
    if await owner.save(record) { phase = .feedback } else { failed = true }
  }
  func feedback(owner: RecoveryCoordinator, value: RecoveryHelpfulness?) async {
    guard phase == .feedback, let id = clock?.session.sessionID else { return }
    if await owner.feedback(id, value) { phase = .done }
  }
}
