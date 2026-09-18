import Foundation
import InnerBalanceCore
import Observation

enum PracticeSessionPhase: Equatable, Sendable {
  case ready
  case running
  case paused
  case comparison
  case saved
}

@MainActor
@Observable
final class PracticeSessionViewModel {
  let plan: PracticeProtocol
  let duration: TimeInterval

  private let now: () -> Date
  private(set) var phase = PracticeSessionPhase.ready
  private(set) var beforeRating: Int?
  private(set) var startedAt: Date?
  private(set) var pausedAt: Date?
  private(set) var accumulatedPause: TimeInterval = 0
  private(set) var wasInterrupted = false
  private(set) var endedAt: Date?
  private(set) var actualDuration: TimeInterval?

  init(
    plan: PracticeProtocol,
    duration: TimeInterval,
    now: @escaping () -> Date = { .now }
  ) {
    self.plan = plan
    self.duration = duration
    self.now = now
  }

  var remainingTime: TimeInterval {
    guard let startedAt else { return duration }
    let reference = pausedAt ?? now()
    return remainingTime(at: reference, startedAt: startedAt)
  }

  func start(beforeRating: Int?) {
    guard phase == .ready else { return }
    self.beforeRating = beforeRating.map { min(max($0, 0), 10) }
    startedAt = now()
    phase = .running
  }

  func pause() {
    guard phase == .running else { return }
    pausedAt = now()
    phase = .paused
  }

  func resume() {
    guard phase == .paused, let pausedAt else { return }
    accumulatedPause += max(0, now().timeIntervalSince(pausedAt))
    self.pausedAt = nil
    phase = .running
  }

  func handleInterruption() {
    guard phase == .running else { return }
    wasInterrupted = true
    pause()
  }

  func finish() {
    guard phase == .running || phase == .paused else { return }
    let completedAt = now()
    guard let startedAt else { return }
    let reference = pausedAt ?? completedAt
    actualDuration = duration - remainingTime(at: reference, startedAt: startedAt)
    endedAt = completedAt
    phase = .comparison
  }

  func makeCompletion(
    sessionID: String
  ) -> PracticeCompletionRecord? {
    guard phase == .comparison,
      let startedAt,
      let endedAt,
      let actualDuration
    else { return nil }

    return PracticeCompletionRecord(
      sessionID: sessionID,
      practiceKind: plan.kind,
      plannedDuration: duration,
      actualDuration: actualDuration,
      startedAt: startedAt,
      endedAt: endedAt,
      beforeRating: nil,
      afterRating: nil
    )
  }

  func makeCompletion(
    afterRating: Int,
    sessionID: String
  ) -> PracticeCompletionRecord? {
    guard let completion = makeCompletion(sessionID: sessionID) else { return nil }

    return PracticeCompletionRecord(
      sessionID: completion.sessionID,
      practiceKind: completion.practiceKind,
      plannedDuration: completion.plannedDuration,
      actualDuration: completion.actualDuration,
      startedAt: completion.startedAt,
      endedAt: completion.endedAt,
      beforeRating: beforeRating,
      afterRating: beforeRating.map { _ in min(max(afterRating, 0), 10) }
    )
  }

  func markSaved() {
    guard phase == .comparison else { return }
    phase = .saved
  }

  private func remainingTime(at reference: Date, startedAt: Date) -> TimeInterval {
    let elapsed = max(0, reference.timeIntervalSince(startedAt) - accumulatedPause)
    return max(0, duration - elapsed)
  }
}
