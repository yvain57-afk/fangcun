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
  let variantID: String?
  let sessionID: String
  private var lastCheckpointTick: TimeInterval = 0
  private let persistsDraft: Bool
  private(set) var timelineGeneration = 0
  private(set) var activeIntervals: [PracticeActiveInterval] = []
  private var intervalStartedAt: Date?
  private var phaseAnchor: TimeInterval = 0
  private var phaseOffset: TimeInterval = 0
  private var cycleLeadIn: TimeInterval = 0
  private var priorCompletedCycles = 0
  private var pmrReleaseOnlyCueID: Int?
  private(set) var selectedFeedback: String?

  private let now: () -> Date
  private let activeTick: () -> TimeInterval
  private var intervalStartedTick: TimeInterval?
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
    variantID: String? = nil,
    checkpoint: PracticeSessionCheckpoint? = nil,
    now: (() -> Date)? = nil
  ) {
    let restored = checkpoint.flatMap { $0.isValid && $0.kind == plan.kind && $0.duration == duration ? $0 : nil }
    self.sessionID = restored?.sessionID ?? UUID().uuidString
    self.persistsDraft = now == nil
    self.variantID = PracticeTimeline.variantID(for: plan.kind, requested: restored?.variantID ?? variantID)
    self.plan = plan
    self.duration = duration
    self.now = now ?? { .now }
    self.activeTick = now.map { clock in { clock().timeIntervalSinceReferenceDate } } ?? { ProcessInfo.processInfo.systemUptime }
    if let restored {
      self.startedAt = restored.startedAt
      self.activeIntervals = restored.activeIntervals
      self.priorCompletedCycles = restored.completedCycles
      self.phaseAnchor = restored.actualDuration
      if let endedAt = restored.endedAt {
        self.endedAt = endedAt
        self.actualDuration = restored.actualDuration
        self.phase = .comparison
      } else {
        self.phase = .paused
        self.pausedAt = self.now()
        self.wasInterrupted = true
      }
    }
  }

  var elapsedActive: TimeInterval {
    if let actualDuration { return actualDuration }
    let closed = activeIntervals.reduce(0) { $0 + $1.duration }
    let live = intervalStartedTick.map { max(0, activeTick() - $0) } ?? 0
    return min(duration, closed + live)
  }

  var remainingTime: TimeInterval { max(0, duration - elapsedActive) }

  /// Guided scripts retain their position; paced protocols re-anchor on a safe phase.
  var phaseElapsed: TimeInterval {
    let mode = PracticeTimeline.mode(for: plan.kind)
    return mode == .pacedBreath || mode == .pelvicFloor
      ? max(0, elapsedActive - phaseAnchor) + phaseOffset : elapsedActive
  }

  var timelineSnapshot: PracticeTimelineSnapshot {
    let snapshot = PracticeTimeline.snapshot(kind: plan.kind, elapsed: phaseElapsed, duration: duration, variantID: variantID)
    guard plan.kind == .progressiveMuscleRelaxation, snapshot.cueID == pmrReleaseOnlyCueID,
      let segment = snapshot.segment, segment.focus.hasSuffix("gentle_tension") else { return snapshot }
    return snapshot.recoveringMuscleRelease()
  }

  var completedCycles: Int { completedCycles(at: elapsedActive) }

  private func completedCycles(at activeDuration: TimeInterval) -> Int {
    let length = PracticeTimeline.steps(for: plan.kind, variantID: variantID).reduce(0) { $0 + $1.duration }
    guard length > 0 else { return 0 }
    return priorCompletedCycles + Int(max(0, activeDuration - phaseAnchor - cycleLeadIn) / length)
  }

  func setFeedback(_ feedback: String?) {
    selectedFeedback = PracticeFeedbackCopy.storedValue(feedback) ?? feedback
  }

  func start(beforeRating: Int?) {
    guard phase == .ready else { return }
    self.beforeRating = plan.kind == .kegel ? nil : beforeRating.map { min(max($0, 0), 10) }
    startedAt = now()
    intervalStartedAt = startedAt
    intervalStartedTick = activeTick()
    phase = .running
    checkpointNow()
  }

  func pause() {
    guard phase == .running else { return }
    pausedAt = now()
    closeActiveInterval(at: pausedAt!)
    phase = .paused
    checkpointNow()
  }

  func resume() {
    guard phase == .paused, let pausedAt else { return }
    if plan.kind == .progressiveMuscleRelaxation, timelineSnapshot.segment?.focus.hasSuffix("gentle_tension") == true {
      pmrReleaseOnlyCueID = timelineSnapshot.cueID
    }
    accumulatedPause += max(0, now().timeIntervalSince(pausedAt))
    self.pausedAt = nil
    priorCompletedCycles = completedCycles
    phaseAnchor = elapsedActive
    phaseOffset = plan.kind == .kegel ? 4 : 0
    cycleLeadIn = plan.kind == .kegel ? 8 : 0
    intervalStartedAt = now()
    intervalStartedTick = activeTick()
    timelineGeneration += 1
    phase = .running
    checkpointNow()
  }

  func handleInterruption() {
    guard phase == .running else { return }
    wasInterrupted = true
    pause()
  }

  func finish() {
    guard phase == .running || phase == .paused else { return }
    let completedAt = now()
    guard startedAt != nil else { return }
    closeActiveInterval(at: pausedAt ?? completedAt)
    actualDuration = elapsedActive
    endedAt = max(completedAt, activeIntervals.last?.end ?? completedAt)
    phase = .comparison
    checkpointNow()
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
      afterRating: nil,
      metadata: PracticeSessionMetadata(
        protocolVersion: plan.kind == .progressiveMuscleRelaxation ? PracticeSessionMetadata.muscleRelaxationProtocolVersion : PracticeTimeline.protocolVersion,
        timelineVariantID: variantID, sceneID: PracticeTimeline.sceneID(for: plan.kind),
        completionStatus: actualDuration >= duration ? "completed" : "endedEarly",
        completedCycles: completedCycles, activeIntervals: activeIntervals,
        subjectiveFeedback: selectedFeedback
      )
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
      afterRating: beforeRating.map { _ in min(max(afterRating, 0), 10) },
      metadata: completion.metadata
    )
  }

  func markSaved() {
    guard phase == .comparison else { return }
    phase = .saved
    clearDraft()
  }

  func checkpointIfNeeded() {
    guard phase == .running, activeTick() - lastCheckpointTick >= 5 else { return }
    checkpointNow()
  }

  func checkpointValue() -> PracticeSessionCheckpoint? {
    guard let startedAt else { return nil }
    var intervals = activeIntervals
    if let start = intervalStartedAt, let tick = intervalStartedTick {
      let remaining = max(0, duration - intervals.reduce(0) { $0 + $1.duration })
      let end = start.addingTimeInterval(min(remaining, max(0, activeTick() - tick)))
      if end > start { intervals.append(.init(start: start, end: end)) }
    }
    let confirmedDuration = intervals.reduce(0) { $0 + $1.duration }
    return .init(sessionID: sessionID, kind: plan.kind, duration: duration, variantID: variantID,
      startedAt: startedAt, endedAt: endedAt, activeIntervals: intervals,
      completedCycles: completedCycles(at: confirmedDuration))
  }

  func clearDraft() {
    if persistsDraft { PracticeSessionDraftStore.clear(sessionID: sessionID) }
  }

  private func checkpointNow() {
    guard persistsDraft, let value = checkpointValue() else { return }
    if PracticeSessionDraftStore.save(value) { lastCheckpointTick = activeTick() }
  }

  private func closeActiveInterval(at end: Date) {
    guard let start = intervalStartedAt else { return }
    let saved = activeIntervals.reduce(0) { $0 + $1.duration }
    let live = max(0, activeTick() - (intervalStartedTick ?? activeTick()))
    let intervalEnd = start.addingTimeInterval(min(live, max(0, duration - saved)))
    if intervalEnd > start { activeIntervals.append(.init(start: start, end: intervalEnd)) }
    intervalStartedAt = nil
    intervalStartedTick = nil
  }
}
