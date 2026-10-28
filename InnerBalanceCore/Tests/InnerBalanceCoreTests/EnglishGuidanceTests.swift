import Foundation
import Testing
@testable import InnerBalanceCore

struct EnglishGuidanceTests {
  @Test func englishEditionPreservesEveryOriginalSegmentBoundaryAndIdentity() {
    for kind in PracticeKind.allCases {
      for duration in PracticeCatalog.protocol(for: kind)?.durationOptions ?? [] {
        for variant in [nil, "easy_4_4", "equal_5_5", "pmr_day", "pmr_sleep"] as [String?] {
          let original = OriginalPracticeGuidanceContent.segments(for: kind, duration: duration, variantID: variant)
          let english = PracticeGuidanceContent.segments(for: kind, duration: duration, variantID: variant)
          #expect(original.count == english.count)
          for (a, b) in zip(original, english) {
            #expect(a.id == b.id && a.start == b.start && a.end == b.end && a.focus == b.focus)
            #expect(!b.text.isEmpty)
            #expect(b.text.range(of: "[\\u4e00-\\u9fff]", options: .regularExpression) == nil)
          }
          #expect(PracticeGuidanceContent.introductionResource(for: kind, variantID: variant) == OriginalPracticeGuidanceContent.introductionResource(for: kind, variantID: variant))
        }
      }
      for cycle in 0..<2 {
        #expect(PracticeGuidanceContent.phaseTexts(for: kind, cycle: cycle).count == PracticeTimeline.steps(for: kind).count)
      }
    }
  }

  @Test func selectedEvenRhythmIsExplainedWithoutChangingEitherOption() {
    let short = PracticeGuidanceContent.introduction(for: .balancedBreathing, variantID: "easy_4_4")
    #expect(short.contains("four seconds and out for four"))
    #expect(!short.contains("five"))
    #expect(PracticeTimeline.steps(for: .balancedBreathing, variantID: "easy_4_4").map(\.duration) == [4, 4])
    #expect(PracticeTimeline.steps(for: .balancedBreathing).map(\.duration) == [5, 5])
  }
}

struct EnglishReflectionPresentationTests {
  @Test func englishProjectionPreservesIdentityAndOriginalLibrary() {
    for original in DailyReflectionSelector.library {
      let shown = original.englishPresentation
      #expect(shown.id == original.id)
      #expect(shown.text.range(of: "[\\u4e00-\\u9fff]", options: .regularExpression) == nil)
      #expect(shown.attribution?.hasPrefix("Inspired by ") == true)
      #expect(shown.source == .ideaAdaptation)
      #expect(DailyReflectionSelector.library.first { $0.id == original.id } == original)
    }
    let personal = DailyReflection(id: "personal", text: "我的原文")
    #expect(personal.englishPresentation == personal)
  }
}
