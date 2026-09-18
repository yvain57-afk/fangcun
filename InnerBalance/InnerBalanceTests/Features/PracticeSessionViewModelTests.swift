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

  @Test("NSDR 暂停期间保留当前阶段，恢复后按有效练习时长切换")
  @MainActor
  func nsdrPausePreservesTheSharedPhase() throws {
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let clock = PracticeTestClock(now: startedAt)
    let viewModel = PracticeSessionViewModel(
      plan: try #require(PracticeCatalog.protocol(for: .nsdr)),
      duration: 600,
      now: { clock.now }
    )
    viewModel.start(beforeRating: nil)
    clock.now = startedAt.addingTimeInterval(24)
    viewModel.pause()
    clock.now = startedAt.addingTimeInterval(90)

    let paused = PracticeBodyScanState.make(
      elapsed: viewModel.duration - viewModel.remainingTime,
      duration: viewModel.duration
    )
    #expect(paused.cue == .nsdrFace)
    viewModel.resume()
    #expect(
      PracticeBodyScanState.make(
        elapsed: viewModel.duration - viewModel.remainingTime,
        duration: viewModel.duration
      ) == paused)

    clock.now = startedAt.addingTimeInterval(91)
    let elapsed = viewModel.duration - viewModel.remainingTime
    #expect(PracticeBodyScanState.make(elapsed: elapsed, duration: 600).cue == .nsdrShoulders)
    #expect(PracticeAudioTimeline.cue(for: .nsdr, elapsed: elapsed, duration: 600) == .nsdrShoulders)
    #expect(PracticeHapticTimeline.cueID(for: .nsdr, elapsed: elapsed, duration: 600) == 1)
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
}

@MainActor
private final class PracticeTestClock {
  var now: Date

  init(now: Date) {
    self.now = now
  }
}
