import Foundation
import Testing
@testable import InnerBalanceCore

struct PracticeGuidance20261020Tests {
  @Test("Original six natural tracks retain every pre-review boundary")
  func originalSegmentBoundaries() {
    let expected: [(PracticeKind, Double, [Double])] = [
      (.diaphragmaticBreathing,180,[0,25,50,85,120,155,175,180]),
      (.diaphragmaticBreathing,300,[0,30,60,120,185,245,285,300]),
      (.meditation,300,[0,25,55,100,145,200,260,285,300]),
      (.meditation,600,[0,30,70,140,220,300,400,500,565,600]),
      (.nsdr,600,[0,30,60,90,130,170,210,250,290,330,370,415,460,510,570,600]),
      (.nsdr,1200,[0,45,90,150,230,310,390,470,550,640,720,810,900,1000,1100,1170,1200])
    ]
    for (kind,duration,bounds) in expected {
      let segments = PracticeTimeline.segments(for: kind, duration: duration)
      #expect(segments.map(\.start) + [segments.last!.end] == bounds)
      #expect(segments.allSatisfy { !$0.text.isEmpty })
    }
    #expect(PracticeGuidanceContent.introduction(for: .balancedBreathing, variantID: "easy_4_4").contains("吸气四秒"))
    #expect(!PracticeGuidanceContent.introduction(for: .balancedBreathing, variantID: "easy_4_4").contains("吸气五秒"))
  }

  @Test("PMR is separate, not a new recommended dose or a Watch exercise")
  func additiveCatalog() throws {
    #expect(PracticeCatalog.v4.count == 9)
    let plan = try #require(PracticeCatalog.protocol(for: .progressiveMuscleRelaxation))
    #expect(plan.durationOptions == [600])
    #expect(!plan.isAutomaticallyRecommended && !plan.writesMindfulSession)
    #expect(!PracticeKind.progressiveMuscleRelaxation.isLegacyWatchExecutable)
    #expect(PracticeTimeline.steps(for: .progressiveMuscleRelaxation).isEmpty)
    #expect(PracticeTimeline.variantID(for: .progressiveMuscleRelaxation, requested: "unknown") == "pmr_day")
  }

  @Test("Each PMR ending covers ten minutes and only the ending differs")
  func pmrTimingsAndRecovery() throws {
    let day = PracticeTimeline.segments(for: .progressiveMuscleRelaxation, duration: 600, variantID: "pmr_day")
    let sleep = PracticeTimeline.segments(for: .progressiveMuscleRelaxation, duration: 600, variantID: "pmr_sleep")
    #expect(day.count == 31 && sleep.count == 31)
    #expect(Array(day.prefix(29)) == Array(sleep.prefix(29)))
    for segments in [day,sleep] {
      #expect(segments.first?.start == 0 && segments.last?.end == 600)
      for pair in zip(segments,segments.dropFirst()) { #expect(pair.0.end == pair.1.start) }
      let contractions = segments.filter { $0.focus.hasSuffix("gentle_tension") }
      #expect(contractions.count == 8)
      #expect(contractions.map(\.start) == [100,150,200,250,300,350,400,450])
      #expect(contractions.allSatisfy { $0.end-$0.start == 5 })
      #expect(segments.filter { $0.focus.hasSuffix("release") }.allSatisfy { $0.end-$0.start == 25 })
    }
    let tension = PracticeTimeline.snapshot(kind: .progressiveMuscleRelaxation, elapsed: 102, duration: 600)
    let rest = tension.recoveringMuscleRelease()
    #expect(rest.phaseDuration == 5 && rest.elapsedInPhase == 2)
    #expect(rest.segment?.focus == "pmr_m01_release")
    #expect(rest.segment?.id.hasSuffix("_resume_release") == true)
    #expect(PracticeTimeline.snapshot(kind: .progressiveMuscleRelaxation, elapsed: 105, duration: 600).segment?.focus == "pmr_m01_release")
    #expect(try JSONDecoder().decode(PracticeKind.self, from: Data("\"progressiveMuscleRelaxation\"".utf8)) == .progressiveMuscleRelaxation)
  }
}
