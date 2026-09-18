import Foundation
import Testing

@testable import InnerBalanceCore

@Suite("Echo personalization")
struct EchoPersonalizationTests {
  @Test("同一天的不同回声会得到不同的一句")
  func differentEchoesReceiveDifferentReflections() {
    let date = Date(timeIntervalSince1970: 1_786_320_000)

    let calm = DailyReflectionSelector.reflection(on: date, echo: .calm)
    let tense = DailyReflectionSelector.reflection(on: date, echo: .tense)

    #expect(calm.id != tense.id)
    #expect(calm.text != tense.text)
  }

  @Test("开场句和六种状态在一年内每天都各不相同")
  func openingAndEveryEchoStayUniqueAcrossAYear() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let start = calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!

    for offset in 0..<366 {
      let date = calendar.date(byAdding: .day, value: offset, to: start)!
      let reflections =
        [
          DailyReflectionSelector.reflection(on: date, echo: nil, calendar: calendar)
        ]
        + DailyEchoState.allCases.map {
          DailyReflectionSelector.reflection(on: date, echo: $0, calendar: calendar)
        }

      #expect(Set(reflections.map(\.id)).count == reflections.count)
    }
  }

  @Test("照顾情绪的金句不出现死亡深渊或怪物意象")
  func careContextAvoidsDistressingQuotationImagery() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let start = calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!
    let blockedIDs: Set<String> = [
      "montaigne-death", "nietzsche-monster", "nietzsche-abyss", "pascal-room",
    ]

    for offset in 0..<366 {
      let date = calendar.date(byAdding: .day, value: offset, to: start)!
      let reflections =
        [
          DailyReflectionSelector.reflection(on: date, echo: nil, calendar: calendar)
        ]
        + DailyEchoState.allCases.map {
          DailyReflectionSelector.reflection(on: date, echo: $0, calendar: calendar)
        }
      #expect(reflections.allSatisfy { !blockedIDs.contains($0.id) })
    }
  }

  @Test("回声会直接得到一个对应的恢复动作")
  func echoSelectsOneRecoveryPractice() {
    #expect(
      EchoPersonalization.recommendedPractice(for: .tense, bodyLoadLevel: .steady)
        == .physiologicalSigh)
    #expect(EchoPersonalization.recommendedPractice(for: .tired, bodyLoadLevel: .steady) == .nsdr)
    #expect(
      EchoPersonalization.recommendedPractice(for: .calm, bodyLoadLevel: .steady) == .meditation)
    #expect(
      EchoPersonalization.recommendedPractice(for: .uncertain, bodyLoadLevel: .steady)
        == .pacedBreathing)
  }

  @Test("身体负荷偏高时会调整没有明确恢复指向的回声推荐")
  func elevatedBodyLoadAdjustsAGentleEchoRecommendation() {
    #expect(
      EchoPersonalization.recommendedPractice(for: .calm, bodyLoadLevel: .elevated)
        == .pacedBreathing)
    #expect(
      EchoPersonalization.recommendedPractice(for: .tense, bodyLoadLevel: .elevated)
        == .physiologicalSigh)
    #expect(EchoPersonalization.recommendedPractice(for: .tired, bodyLoadLevel: .elevated) == .nsdr)
  }

  @Test("每种状态都有一周不重复且有明确出处的名家句")
  func everyEchoHasAWeekOfSourcedQuotations() {
    let start = Date(timeIntervalSince1970: 1_786_320_000)

    for echo in DailyEchoState.allCases {
      let reflections = (0..<7).map { offset in
        DailyReflectionSelector.reflection(
          on: start.addingTimeInterval(Double(offset) * 86_400),
          echo: echo
        )
      }

      #expect(Set(reflections.map(\.text)).count == 7)
      #expect(reflections.allSatisfy { $0.source == .collectedQuotation })
      #expect(reflections.allSatisfy { $0.attribution?.isEmpty == false })
      #expect(reflections.allSatisfy { $0.work?.isEmpty == false })
      #expect(reflections.allSatisfy { !$0.id.hasPrefix("echo-") })
    }
  }

  @Test("每种状态至少一个月不重复金句")
  func everyEchoHasAMonthWithoutRepeatingAQuotation() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let start = calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!

    for echo in DailyEchoState.allCases {
      let reflections = (0..<30).map { offset in
        DailyReflectionSelector.reflection(
          on: calendar.date(byAdding: .day, value: offset, to: start)!,
          echo: echo,
          calendar: calendar
        )
      }

      #expect(Set(reflections.map(\.id)).count == 30)
    }
  }

  @Test("尚未选择状态时也先给一句有作者和作品的名家句")
  func openingReflectionUsesTheSourcedQuotationPool() {
    let reflection = DailyReflectionSelector.reflection(
      on: Date(timeIntervalSince1970: 1_786_320_000),
      echo: nil
    )

    #expect(DailyReflectionSelector.library.contains(reflection))
    #expect(reflection.source == .collectedQuotation)
    #expect(reflection.attribution?.isEmpty == false)
    #expect(reflection.work?.isEmpty == false)
  }

  @Test("回声句只回应主观状态，不替身体数据下结论")
  func echoReflectionsDoNotTurnFeelingsIntoBodyEvidence() {
    let start = Date(timeIntervalSince1970: 1_786_320_000)
    let reflections = DailyEchoState.allCases.flatMap { echo in
      (0..<7).map { offset in
        DailyReflectionSelector.reflection(
          on: start.addingTimeInterval(Double(offset) * 86_400),
          echo: echo
        )
      }
    }

    #expect(reflections.allSatisfy { $0.text.contains("身体") == false })
  }
}
