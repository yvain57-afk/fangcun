import Foundation
import InnerBalanceCore
import Testing

@testable import InnerBalance

@Suite("Practice session")
struct PracticeSessionViewModelTests {
  @Test("Pause and resume use absolute time without counting the pause")
  @MainActor
  func pauseAndResumeKeepAccurateTime() throws {
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let clock = PracticeTestClock(now: startedAt)
    let plan = try #require(PracticeCatalog.protocol(for: .pacedBreathing))
    let viewModel = PracticeSessionViewModel(
      plan: plan,
      duration: 300,
      now: { clock.now }
    )

    viewModel.start(beforeRating: 7)
    clock.now = startedAt.addingTimeInterval(50)
    viewModel.pause()
    clock.now = startedAt.addingTimeInterval(100)
    #expect(viewModel.remainingTime == 250)

    viewModel.resume()
    clock.now = startedAt.addingTimeInterval(150)

    #expect(viewModel.phase == .running)
    #expect(viewModel.remainingTime == 200)
  }

  @Test("Leaving the active scene pauses the session and preserves the remaining time")
  @MainActor
  func sceneInterruptionPausesSession() throws {
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let clock = PracticeTestClock(now: startedAt)
    let plan = try #require(PracticeCatalog.protocol(for: .meditation))
    let viewModel = PracticeSessionViewModel(
      plan: plan,
      duration: 300,
      now: { clock.now }
    )
    viewModel.start(beforeRating: 6)
    clock.now = startedAt.addingTimeInterval(40)

    viewModel.handleInterruption()
    clock.now = startedAt.addingTimeInterval(100)

    #expect(viewModel.phase == .paused)
    #expect(viewModel.wasInterrupted)
    #expect(viewModel.remainingTime == 260)
  }

  @Test("NSDR 暂停保留完整脚本段落，恢复后按活动时间推进")
  @MainActor
  func nsdrPausePreservesTheSharedPhase() throws {
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let clock = PracticeTestClock(now: startedAt)
    let viewModel = PracticeSessionViewModel(plan: try #require(PracticeCatalog.protocol(for: .nsdr)), duration: 600, now: { clock.now })
    viewModel.start(beforeRating: nil)
    clock.now = startedAt.addingTimeInterval(89)
    viewModel.pause()
    let paused = viewModel.timelineSnapshot
    #expect(paused.phase == nil)
    #expect(paused.segment?.focus == "face")
    clock.now = startedAt.addingTimeInterval(200)
    #expect(viewModel.timelineSnapshot == paused)
    viewModel.resume()
    #expect(viewModel.timelineSnapshot == paused)
    clock.now = startedAt.addingTimeInterval(201)
    #expect(viewModel.timelineSnapshot.segment?.focus == "shoulders")
    #expect(viewModel.timelineSnapshot.cueID == 3)
    #expect(viewModel.elapsedActive == 90)
  }

  @Test("Completing a session creates a restrained subjective comparison record")
  @MainActor
  func completionCreatesSubjectiveEvidence() throws {
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let clock = PracticeTestClock(now: startedAt)
    let plan = try #require(PracticeCatalog.protocol(for: .physiologicalSigh))
    let viewModel = PracticeSessionViewModel(
      plan: plan,
      duration: 60,
      now: { clock.now }
    )
    viewModel.start(beforeRating: 7)
    clock.now = startedAt.addingTimeInterval(60)

    viewModel.finish()
    let record = try #require(
      viewModel.makeCompletion(afterRating: 4, sessionID: "practice-test")
    )

    #expect(record.practiceKind == .physiologicalSigh)
    #expect(record.actualDuration == 60)
    #expect(record.beforeRating == 7)
    #expect(record.afterRating == 4)
    #expect(record.subjectiveChange == -3)

    #expect(viewModel.phase == .comparison)
    viewModel.markSaved()
    #expect(viewModel.phase == .saved)
  }
  @Test("V4 pause releases hold, reanchors inhale and never invents cycles or activity")
  @MainActor
  func v4HoldRecoveryAndIntervals() throws {
    let start = Date(timeIntervalSince1970: 10000)
    let clock = PracticeTestClock(now: start)
    let model = PracticeSessionViewModel(plan: try #require(PracticeCatalog.protocol(for: .boxBreathing)), duration: 180, now: { clock.now })
    model.start(beforeRating: nil)
    clock.now = start.addingTimeInterval(16)
    #expect(model.timelineSnapshot.phase == .holdAfterInhale)
    #expect(model.completedCycles == 1)
    model.pause()
    clock.now = start.addingTimeInterval(116)
    #expect(model.elapsedActive == 16)
    model.resume()
    #expect(model.timelineSnapshot.phase == .inhale)
    #expect(model.timelineSnapshot.phaseProgress == 0)
    #expect(model.timelineGeneration == 1)
    clock.now = start.addingTimeInterval(128)
    model.finish()
    let record = try #require(model.makeCompletion(sessionID: "box-partial"))
    #expect(record.actualDuration == 28)
    #expect(record.metadata?.completedCycles == 2)
    #expect(record.metadata?.completionStatus == "endedEarly")
    #expect(record.metadata?.activeIntervals == [.init(start: start, end: start.addingTimeInterval(16)), .init(start: start.addingTimeInterval(116), end: start.addingTimeInterval(128))])
    clock.now = start.addingTimeInterval(1000)
    model.finish()
    #expect(model.makeCompletion(sessionID: "box-partial") == record)
  }

  @Test("V4 Kegel resumes with full release, retains natural breathing and no ratings")
  @MainActor
  func v4PelvicRecovery() throws {
    let start = Date(timeIntervalSince1970: 10000)
    let clock = PracticeTestClock(now: start)
    let model = PracticeSessionViewModel(plan: try #require(PracticeCatalog.protocol(for: .kegel)), duration: 180, now: { clock.now })
    model.start(beforeRating: 0)
    clock.now = start.addingTimeInterval(2); model.pause()
    clock.now = start.addingTimeInterval(50); model.resume()
    #expect(model.timelineSnapshot.phase == .release)
    #expect(model.timelineSnapshot.phaseDuration == 8)
    clock.now = start.addingTimeInterval(58)
    #expect(model.timelineSnapshot.phase == .contract)
    #expect(model.completedCycles == 0)
    clock.now = start.addingTimeInterval(70)
    #expect(model.completedCycles == 1)
    model.finish()
    let record = try #require(model.makeCompletion(afterRating: 5, sessionID: "pelvic"))
    #expect(record.beforeRating == nil && record.afterRating == nil)
    #expect(record.actualDuration == 22)
  }

  @Test("V4 natural script resumes same segment and frozen actual duration is capped")
  @MainActor
  func v4NaturalPauseAndTarget() throws {
    let start = Date(timeIntervalSince1970: 10000)
    let clock = PracticeTestClock(now: start)
    let model = PracticeSessionViewModel(plan: try #require(PracticeCatalog.protocol(for: .diaphragmaticBreathing)), duration: 180, now: { clock.now })
    model.start(beforeRating: nil)
    clock.now = start.addingTimeInterval(60); model.pause()
    let snapshot = model.timelineSnapshot
    #expect(snapshot.phase == nil)
    #expect(snapshot.segment?.focus == "release")
    clock.now = start.addingTimeInterval(120); model.resume()
    #expect(model.timelineSnapshot == snapshot)
    clock.now = start.addingTimeInterval(600); model.finish()
    let record = try #require(model.makeCompletion(sessionID: "natural"))
    #expect(record.actualDuration == 180)
    #expect(record.metadata?.activeIntervals.reduce(0) { $0 + $1.duration } == 180)
    #expect(record.metadata?.completedCycles == 0)
    #expect(record.metadata?.subjectiveFeedback == nil)
    #expect(record.metadata?.completionStatus == "completed")
  }

  @Test("All ten phone methods end at their exact selected target without extra cycles or health intervals", arguments: PracticeKind.allCases)
  @MainActor
  func allV4DurationTargetsKeepExactActivity(_ kind: PracticeKind) throws {
    // Independent acceptance values: do not derive expected durations or cycles
    // from the timeline implementation being tested.
    let expected: [(duration: TimeInterval, variant: String?, cycles: Int)]
    switch kind {
    case .physiologicalSigh:
      expected = [(60, nil, 5), (300, nil, 25)]
    case .pacedBreathing:
      expected = [(180, nil, 18), (300, nil, 30)]
    case .balancedBreathing:
      expected = [(180, "equal_5_5", 18), (300, "equal_5_5", 30),
                  (180, "easy_4_4", 22), (300, "easy_4_4", 37)]
    case .boxBreathing, .alternateNostrilBreathing:
      expected = [(180, nil, 15), (300, nil, 25)]
    case .diaphragmaticBreathing:
      expected = [(180, nil, 0), (300, nil, 0)]
    case .meditation:
      expected = [(300, nil, 0), (600, nil, 0)]
    case .nsdr:
      expected = [(600, nil, 0), (1200, nil, 0)]
    case .kegel:
      expected = [(180, nil, 15)]
    case .progressiveMuscleRelaxation:
      expected = [(600, "pmr_day", 0), (600, "pmr_sleep", 0)]
    }
    let plan = try #require(PracticeCatalog.phone.first { $0.kind == kind })
    #expect(Set(plan.durationOptions) == Set(expected.map(\.duration)))

    for target in expected {
      // Exercise both an on-time callback and a late foreground callback.
      for callbackDelay: TimeInterval in [0, 17] {
        let start = Date(timeIntervalSince1970: 10000)
        let clock = PracticeTestClock(now: start)
        let model = PracticeSessionViewModel(
          plan: plan, duration: target.duration, variantID: target.variant,
          now: { clock.now }
        )
        model.start(beforeRating: nil)
        clock.now = start.addingTimeInterval(target.duration - 0.25)
        #expect(model.phase == .running)
        #expect(model.remainingTime == 0.25)
        #expect(model.actualDuration == nil)
        #expect(model.makeCompletion(sessionID: model.sessionID) == nil)

        clock.now = start.addingTimeInterval(target.duration)
        #expect(model.remainingTime == 0)
        #expect(model.elapsedActive == target.duration)
        // 4/4 reaches both targets halfway through a cycle. Never wait for
        // that cycle's remaining four seconds before permitting completion.
        if kind == .balancedBreathing, target.variant == "easy_4_4" {
          #expect(model.timelineSnapshot.phase == .exhale)
          #expect(model.timelineSnapshot.elapsedInPhase == 0)
          #expect(model.completedCycles == target.cycles)
        }

        clock.now = start.addingTimeInterval(target.duration + callbackDelay)
        // This is the same remaining-time gate used by the running screen.
        if model.remainingTime == 0 { model.finish() }
        let record = try #require(model.makeCompletion(sessionID: model.sessionID))
        let metadata = try #require(record.metadata)
        let interval = PracticeActiveInterval(start: start, end: start.addingTimeInterval(target.duration))
        #expect(model.phase == .comparison)
        #expect(model.duration == target.duration)
        #expect(record.plannedDuration == target.duration)
        #expect(record.actualDuration == target.duration)
        #expect(model.elapsedActive == target.duration)
        #expect(metadata.completionStatus == "completed")
        #expect(metadata.completedCycles == target.cycles)
        #expect(metadata.activeIntervals == [interval])
        #expect(metadata.activeIntervals.reduce(0) { $0 + $1.duration } == target.duration)
        #expect(model.activeIntervals == [interval])
        #expect(metadata.subjectiveFeedback == nil)

        clock.now = start.addingTimeInterval(target.duration + 120)
        model.finish()
        #expect(model.makeCompletion(sessionID: model.sessionID) == record)
        #expect(model.activeIntervals == [interval])
      }
    }
  }

  @Test("A restart restores only confirmed activity and resumes safely with the same UUID")
  @MainActor
  func checkpointNeverBackfillsWallTime() throws {
    let start = Date(timeIntervalSince1970: 10000)
    let clock = PracticeTestClock(now: start)
    let plan = try #require(PracticeCatalog.protocol(for: .boxBreathing))
    let model = PracticeSessionViewModel(plan: plan, duration: 180, now: { clock.now })
    model.start(beforeRating: nil)
    clock.now = start.addingTimeInterval(16)
    let checkpoint = try #require(model.checkpointValue())
    clock.now = start.addingTimeInterval(1200)
    let restored = PracticeSessionViewModel(plan: plan, duration: 180, checkpoint: checkpoint, now: { clock.now })
    #expect(restored.sessionID == model.sessionID)
    #expect(restored.elapsedActive == 16)
    #expect(restored.phase == .paused)
    #expect(restored.completedCycles == 1)
    restored.resume()
    #expect(restored.timelineSnapshot.phase == .inhale)
    clock.now = start.addingTimeInterval(1212)
    restored.finish()
    let record = try #require(restored.makeCompletion(sessionID: restored.sessionID))
    #expect(record.actualDuration == 28)
    #expect(record.metadata?.completedCycles == 2)
    #expect(record.metadata?.activeIntervals.count == 2)
    let completedDraft = try #require(restored.checkpointValue())
    clock.now = start.addingTimeInterval(3000)
    let pendingSave = PracticeSessionViewModel(plan: plan, duration: 180, checkpoint: completedDraft, now: { clock.now })
    #expect(pendingSave.phase == .comparison)
    #expect(pendingSave.makeCompletion(sessionID: pendingSave.sessionID) == record)
  }

  @Test("Draft corruption and another session's clear do not erase original bytes")
  @MainActor
  func checkpointStorageIsConservative() throws {
    let suite = "v4-checkpoint-test-" + UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let corrupt = Data("unrecognized".utf8)
    defaults.set(corrupt, forKey: PracticeSessionDraftStore.key)
    #expect(PracticeSessionDraftStore.load(defaults: defaults) == nil)
    PracticeSessionDraftStore.clear(sessionID: "unrelated", defaults: defaults)
    #expect(defaults.data(forKey: PracticeSessionDraftStore.key) == corrupt)
    let start = Date(timeIntervalSince1970: 1000)
    let value = PracticeSessionCheckpoint(sessionID: "a", kind: .balancedBreathing, duration: 300, variantID: "easy_4_4", startedAt: start, endedAt: nil, activeIntervals: [.init(start: start, end: start.addingTimeInterval(6))], completedCycles: 0)
    #expect(PracticeSessionDraftStore.save(value, defaults: defaults))
    let quarantined = defaults.dictionaryRepresentation().filter { $0.key.hasPrefix(PracticeSessionDraftStore.quarantinePrefix) }.values.compactMap { $0 as? Data }
    #expect(quarantined == [corrupt])
    #expect(PracticeSessionDraftStore.load(defaults: defaults) == value)
    PracticeSessionDraftStore.clear(sessionID: "b", defaults: defaults)
    #expect(PracticeSessionDraftStore.load(defaults: defaults) == value)
    PracticeSessionDraftStore.clear(sessionID: "a", defaults: defaults)
    #expect(PracticeSessionDraftStore.load(defaults: defaults) == nil)
  }

  @Test("Checkpoint cycle count and active intervals freeze the exact same clock instant")
  @MainActor
  func checkpointCannotCrossCycleBoundaryBetweenReads() throws {
    let base = Date(timeIntervalSince1970: 1000)
    var time: TimeInterval = 0
    var increment: TimeInterval = 0
    let model = PracticeSessionViewModel(plan: try #require(PracticeCatalog.protocol(for: .boxBreathing)), duration: 180, now: {
      let value = base.addingTimeInterval(time)
      time += increment
      return value
    })
    model.start(beforeRating: nil)
    time = 11.999
    increment = 0.002
    let value = try #require(model.checkpointValue())
    #expect(value.actualDuration < 12)
    #expect(value.completedCycles == 0)
  }

}

@MainActor
private final class PracticeTestClock {
  var now: Date

  init(now: Date) {
    self.now = now
  }
}
