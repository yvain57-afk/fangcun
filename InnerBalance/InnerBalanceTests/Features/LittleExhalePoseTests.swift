import Foundation
import InnerBalanceCore
import Testing
@testable import InnerBalance

struct LittleExhalePoseTests {
  private func pose(_ kind: PracticeKind, _ time: Double, strength: Double = 1) -> LittleExhalePose {
    .make(kind: kind, snapshot: PracticeTimeline.snapshot(kind: kind, elapsed: time, duration: 600), strength: strength)
  }
  @Test func twoPartInhaleExhaleAndHoldsHaveDifferentVisiblePoses() {
    #expect(pose(.physiologicalSigh, 0).pawOpening == 0)
    #expect(pose(.physiologicalSigh, 3).pawOpening == 0.82)
    #expect(pose(.physiologicalSigh, 5).pawOpening == 1)
    #expect(pose(.physiologicalSigh, 11).pawOpening < 0.1)
    #expect(pose(.boxBreathing, 3) == pose(.boxBreathing, 5.9))
    #expect(pose(.boxBreathing, 9) == pose(.boxBreathing, 11.9))
    #expect(pose(.pacedBreathing, 4).headLift > pose(.pacedBreathing, 0).headLift)
  }
  @Test func reducedMotionIsStableAcrossAllActualTimelines() {
    for kind in PracticeKind.allCases {
      for time in stride(from: 0.0, through: 599, by: 1.7) {
        #expect(pose(kind, time, strength: 0) == LittleExhalePose())
      }
    }
  }
  @Test func nostrilGestureMatchesTheUsersSideAndPelvicFloorDoesNotMimicABreath() {
    for time in [1.0, 10] { #expect(pose(.alternateNostrilBreathing, time).leftLift == 1); #expect(pose(.alternateNostrilBreathing, time).rightLift == 0) }
    for time in [4.0, 7] { #expect(pose(.alternateNostrilBreathing, time).rightLift == 1); #expect(pose(.alternateNostrilBreathing, time).leftLift == 0) }
    #expect(pose(.kegel, 1).rightLift == 1)
    #expect(pose(.kegel, 5).rightLift == 0)
    for time in [0.0, 1, 4, 7, 11] { #expect(pose(.kegel, time).headLift == 0 && pose(.kegel, time).pawOpening == 0) }
  }
  @Test func muscleRelaxationClosesForHandTensionAndOpensForRelease() throws {
    let segments = PracticeTimeline.segments(for: .progressiveMuscleRelaxation, duration: 600)
    let tense = try #require(segments.first { $0.focus == "pmr_m01_gentle_tension" })
    let release = try #require(segments.first { $0.focus == "pmr_m01_release" })
    #expect(pose(.progressiveMuscleRelaxation, tense.start + 1).pawOpening == 0)
    #expect(pose(.progressiveMuscleRelaxation, release.start + 2).pawOpening == 0.35)
    for segment in segments where segment.focus.hasSuffix("gentle_tension") && segment.focus != tense.focus {
      #expect(pose(.progressiveMuscleRelaxation, segment.start + 1).pawOpening == 0.35)
    }
  }
  @Test func naturalBreathingSettlesInsteadOfInventingARecurringPace() {
    for kind in [PracticeKind.nsdr, .meditation, .diaphragmaticBreathing] {
      for segment in PracticeTimeline.segments(for: kind, duration: 600) where segment.end - segment.start > 8 {
        #expect(pose(kind, segment.start + 3) == pose(kind, segment.start + 7))
      }
    }
  }
}

struct LittleExhaleBundleTests {
  @Test func allPracticeVariantsHavePackagedEnglishAudio() throws {
    for kind in PracticeKind.allCases {
      #expect(PracticeVoiceAssets.isAvailable(for: kind))
      for variant in [nil, "easy_4_4", "equal_5_5", "pmr_day", "pmr_sleep"] as [String?] {
        let name = PracticeGuidanceContent.introductionResource(for: kind, variantID: variant)
        let url = try #require(PracticeVoiceAssets.url(named: name))
        #expect(url.lastPathComponent.hasPrefix("le2_"))
      }
    }
    #expect(FangcunCopy.text("readiness.unknown").range(of: "[\\u4e00-\\u9fff]", options: .regularExpression) == nil)
  }
}

struct LittleExhaleFeedbackCompatibilityTests {
  @Test func oldAndNewLabelsKeepTheSameStoredValuesAndSafetyMeaning() {
    for (old, english, expected) in [("更舒服", "A little easier", RecoveryHelpfulness.helpful), ("差不多", "About the same", .unchanged), ("不舒服", "Less comfortable", .uncomfortable)] {
      #expect(PracticeFeedbackCopy.storedValue(old) == old)
      #expect(PracticeFeedbackCopy.storedValue(english) == old)
      #expect(PracticeFeedbackCopy.helpfulness(old) == expected)
      #expect(PracticeFeedbackCopy.helpfulness(english) == expected)
      #expect(PracticeFeedbackCopy.englishTitle(old) == english)
    }
    #expect(PracticeFeedbackCopy.englishTitle("用户自己的文字") == "用户自己的文字")
    #expect(PracticeFeedbackCopy.helpfulness("unknown") == nil)
  }
}
