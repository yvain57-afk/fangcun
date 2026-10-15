import InnerBalanceCore
import Testing
@testable import InnerBalance

@Suite("V4 visual guidance repair")
struct PracticeVisualMotionTests {
  private func motion(_ kind: PracticeKind, _ time: Double, variant: String? = nil) -> PracticeVisualMotion {
    .init(kind: kind, snapshot: PracticeTimeline.snapshot(kind: kind, elapsed: time, duration: 300, variantID: variant))
  }
  @Test func sighExpansionIsContinuousAndTopUpIsSmallerThanMainInhale() {
    #expect(motion(.physiologicalSigh, 0).expansion == 0)
    #expect(abs(motion(.physiologicalSigh, 3).expansion - 0.82) < 0.00001)
    #expect(motion(.physiologicalSigh, 5).expansion == 1)
    #expect(motion(.physiologicalSigh, 8).expansion < motion(.physiologicalSigh, 6).expansion)
    for boundary in [3.0, 5.0, 12.0, 24.0] {
      #expect(abs(motion(.physiologicalSigh, boundary - 0.001).expansion - motion(.physiologicalSigh, boundary).expansion) < 0.001)
    }
  }
  @Test func holdsKeepTheSameGeometryWhileTheirCountdownAdvances() {
    #expect(motion(.boxBreathing, 3).expansion == 1)
    #expect(motion(.boxBreathing, 5.9).expansion == 1)
    #expect(motion(.boxBreathing, 9).expansion == 0)
    #expect(motion(.boxBreathing, 11.9).expansion == 0)
    #expect(motion(.boxBreathing, 3).phaseSeconds == 3)
    #expect(motion(.boxBreathing, 5.9).phaseSeconds == 1)
  }
  @Test func balancedVariantsAndNostrilDirectionFollowTheActualProtocol() {
    #expect(motion(.balancedBreathing, 4, variant: "easy_4_4").expansion == 1)
    #expect(motion(.balancedBreathing, 4, variant: "equal_5_5").expansion < 1)
    #expect([0.0, 3, 6, 9].map { motion(.alternateNostrilBreathing, $0).side } == [-1, 1, 1, -1])
    #expect(motion(.alternateNostrilBreathing, 1).expansion < motion(.alternateNostrilBreathing, 2).expansion)
    #expect(motion(.alternateNostrilBreathing, 4).expansion > motion(.alternateNostrilBreathing, 5).expansion)
  }
  @Test func pelvicFloorGuideContractsThenReleasesWithoutABreathingPulse() {
    #expect(motion(.kegel, 0.4).contraction == 1)
    #expect(motion(.kegel, 3.9).contraction == 1)
    #expect(motion(.kegel, 4.5).contraction == 0)
    #expect(motion(.kegel, 11.9).contraction == 0)
    for time in [0.0, 1, 4, 7, 11.9] { #expect(motion(.kegel, time).expansion == 0) }
  }
}
