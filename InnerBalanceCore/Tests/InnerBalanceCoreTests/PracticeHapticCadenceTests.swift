import Testing

@testable import InnerBalanceCore

@Suite("Practice haptic cadence")
struct PracticeHapticCadenceTests {
  @Test("Paced breathing exposes the breath phase instead of a session countdown")
  func pacedBreathingGuideTracksTheCurrentBreath() {
    #expect(PracticeBreathGuide.state(for: .pacedBreathing, elapsed: 0).phase == .inhale)
    #expect(PracticeBreathGuide.state(for: .pacedBreathing, elapsed: 3.9).phase == .inhale)
    #expect(PracticeBreathGuide.state(for: .pacedBreathing, elapsed: 4).phase == .exhale)
    #expect(PracticeBreathGuide.state(for: .pacedBreathing, elapsed: 9.9).phase == .exhale)
    #expect(PracticeBreathGuide.state(for: .pacedBreathing, elapsed: 10).phase == .inhale)
    #expect(PracticeBreathGuide.state(for: .pacedBreathing, elapsed: 4).phaseDuration == 6)
  }

  @Test("Cue identifiers change only at protocol boundaries")
  func cueBoundariesAreStable() {
    #expect(PracticeHapticCadence.cueID(for: .physiologicalSigh, elapsed: 0) == 0)
    #expect(PracticeHapticCadence.cueID(for: .physiologicalSigh, elapsed: 2.9) == 0)
    #expect(PracticeHapticCadence.cueID(for: .physiologicalSigh, elapsed: 3) == 1)
    #expect(PracticeHapticCadence.cueID(for: .physiologicalSigh, elapsed: 5) == 2)
    #expect(PracticeHapticCadence.cueID(for: .physiologicalSigh, elapsed: 12) == 3)

    #expect(PracticeHapticCadence.cueID(for: .pacedBreathing, elapsed: 3.9) == 0)
    #expect(PracticeHapticCadence.cueID(for: .pacedBreathing, elapsed: 4) == 1)
    #expect(PracticeHapticCadence.cueID(for: .pacedBreathing, elapsed: 10) == 2)
    #expect(PracticeHapticCadence.cueID(for: .kegel, elapsed: 4) == 1)
  }

  @Test("手表仅在启用且运行中的相位边界播放一次触觉")
  func phaseHapticConsumptionIsStateful() {
    var lastCueID: Int?

    #expect(
      PracticeHapticCadence.consumeCue(
        for: .pacedBreathing,
        elapsed: 0,
        isActive: true,
        isEnabled: true,
        lastCueID: &lastCueID
      )
    )
    #expect(
      !PracticeHapticCadence.consumeCue(
        for: .pacedBreathing,
        elapsed: 2,
        isActive: true,
        isEnabled: true,
        lastCueID: &lastCueID
      )
    )
    #expect(
      PracticeHapticCadence.consumeCue(
        for: .pacedBreathing,
        elapsed: 4,
        isActive: true,
        isEnabled: true,
        lastCueID: &lastCueID
      )
    )
    #expect(
      !PracticeHapticCadence.consumeCue(
        for: .pacedBreathing,
        elapsed: 10,
        isActive: false,
        isEnabled: true,
        lastCueID: &lastCueID
      )
    )
    #expect(
      !PracticeHapticCadence.consumeCue(
        for: .pacedBreathing,
        elapsed: 10,
        isActive: true,
        isEnabled: false,
        lastCueID: &lastCueID
      )
    )
  }

  @Test("Slow practices use calm sparse cues")
  func slowPracticeCadenceIsSparse() {
    #expect(PracticeHapticCadence.cueID(for: .meditation, elapsed: 9.9) == 0)
    #expect(PracticeHapticCadence.cueID(for: .meditation, elapsed: 10) == 1)
    #expect(PracticeHapticCadence.cueID(for: .nsdr, elapsed: 19.9) == 0)
    #expect(PracticeHapticCadence.cueID(for: .nsdr, elapsed: 20) == 1)
  }
}
