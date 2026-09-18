import Foundation
import Testing

@testable import InnerBalanceCore

@Suite("Daily reflection")
struct DailyReflectionTests {
  @Test("The reflection remains stable throughout one local day")
  func reflectionIsStableWithinOneDay() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let morning = calendar.date(
      from: DateComponents(year: 2026, month: 8, day: 11, hour: 7)
    )!
    let evening = calendar.date(
      from: DateComponents(year: 2026, month: 8, day: 11, hour: 22)
    )!

    let morningReflection = DailyReflectionSelector.reflection(
      on: morning,
      theme: .universal,
      calendar: calendar
    )
    let eveningReflection = DailyReflectionSelector.reflection(
      on: evening,
      theme: .universal,
      calendar: calendar
    )

    #expect(morningReflection == eveningReflection)
  }

  @Test("A body-load refresh cannot replace today's quotation")
  func bodyLoadChangeKeepsTheSameDailyQuotation() {
    let date = Date(timeIntervalSince1970: 1_786_320_000)
    let steady = DailyReflectionSelector.reflection(on: date, theme: .steady)
    let recovery = DailyReflectionSelector.reflection(on: date, theme: .recovery)

    #expect(steady == recovery)
  }

  @Test("Elevated body load uses a recovery reflection theme")
  func elevatedBodyLoadUsesRecoveryTheme() {
    #expect(DailyReflectionTheme.forBodyLoad(.elevated) == .recovery)
  }

  @Test("Consecutive local days reveal different reflections")
  func consecutiveDaysRevealDifferentReflections() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let firstDay = calendar.date(
      from: DateComponents(year: 2026, month: 8, day: 11, hour: 8)
    )!
    let nextDay = calendar.date(byAdding: .day, value: 1, to: firstDay)!

    let first = DailyReflectionSelector.reflection(
      on: firstDay,
      theme: .steady,
      calendar: calendar
    )
    let next = DailyReflectionSelector.reflection(
      on: nextDay,
      theme: .steady,
      calendar: calendar
    )

    #expect(first != next)
  }

  @Test("The last day of a 31-day month does not collide with the next month")
  func monthBoundaryUsesDistinctDailySeed() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let lastDay = calendar.date(
      from: DateComponents(year: 2026, month: 8, day: 31, hour: 8)
    )!
    let nextMonth = calendar.date(
      from: DateComponents(year: 2026, month: 9, day: 1, hour: 8)
    )!

    let first = DailyReflectionSelector.reflection(
      on: lastDay,
      theme: .universal,
      calendar: calendar
    )
    let next = DailyReflectionSelector.reflection(
      on: nextMonth,
      theme: .universal,
      calendar: calendar
    )

    #expect(first != next)
  }

  @Test("Daily selections always carry an author and a work")
  func dailySelectionsCarryAuthorsAndWorks() {
    let reflection = DailyReflectionSelector.reflection(
      on: Date(timeIntervalSince1970: 0),
      theme: .universal
    )

    #expect(!reflection.id.isEmpty)
    #expect(reflection.attribution?.isEmpty == false)
    #expect(reflection.work?.isEmpty == false)
    #expect(reflection.source == .collectedQuotation)
  }

  @Test("金句库只收录有明确作品的哲学与心理学名家句")
  func quotationLibraryContainsOnlySourcedFamousWords() {
    let library = DailyReflectionSelector.library

    #expect(library.count >= 72)
    #expect(Set(library.map(\.id)).count == library.count)
    #expect(library.allSatisfy { $0.source == .collectedQuotation })
    #expect(library.allSatisfy { $0.work?.isEmpty == false })
    #expect(library.allSatisfy { $0.attribution?.isEmpty == false })
    #expect(!library.contains { $0.attribution == "庄子" })
    #expect(!library.contains { $0.work?.contains("薄伽梵歌") == true })
    let modernAuthors = [
      "卡尔·罗杰斯", "丹尼尔·卡尼曼", "维克多·弗兰克尔",
      "伯特兰·罗素", "迈克尔·波兰尼", "理查德·费曼",
      "乔治·奥威尔", "亚伯拉罕·马斯洛", "埃里希·弗洛姆",
      "欧文·亚隆", "唐纳德·温尼科特", "罗洛·梅",
      "利昂·费斯廷格", "阿尔贝·加缪", "让-保罗·萨特",
      "西蒙娜·韦伊",
    ]
    #expect(library.allSatisfy { !modernAuthors.contains($0.attribution ?? "") })
    let internalWords = ["待考", "转述", "参照", "原句", "收藏摘句"]
    #expect(
      library.allSatisfy { reflection in
        internalWords.allSatisfy { !(reflection.attribution ?? "").contains($0) }
      }
    )
    #expect(library.contains { $0.id == "kierkegaard-backwards-forwards" } == false)
    #expect(library.contains { $0.id == "schopenhauer-will" } == false)
    #expect(library.first { $0.id == "aurelius-judgment" }?.work == "《沉思录》")
    #expect(library.first { $0.id == "james-attention" }?.work == "《心理学原理》")
    #expect(library.first { $0.id == "spinoza-clear" }?.work == "《伦理学》")
  }

  @Test("每条金句都有可审核的公版来源与方寸自译声明")
  func everyQuotationCarriesAuditablePublicDomainProvenance() throws {
    for reflection in DailyReflectionSelector.library {
      let provenance = try #require(reflection.provenance)

      #expect(provenance.authorDeathYear <= 1910)
      #expect(provenance.sourcePublicationYear <= 1925)
      #expect(provenance.sourceURL.hasPrefix("https://"))
      #expect(provenance.translationCredit == "方寸自译")
    }
  }

  @Test("Daily copy avoids abstract coaching language")
  func dailyCopyAvoidsAbstractCoachingLanguage() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
    let unwantedPhrases = [
      "觉察", "节律", "余地", "信号", "真正的",
      "今天可以放心", "身体今天没", "身体安安静静", "你是真的有点累",
    ]

    for theme in [
      DailyReflectionTheme.universal,
      .steady,
      .attention,
      .recovery,
    ] {
      for offset in 0..<14 {
        let reflection = DailyReflectionSelector.reflection(
          on: calendar.date(byAdding: .day, value: offset, to: start)!,
          theme: theme,
          calendar: calendar
        )
        let copy = reflection.text + (reflection.attribution ?? "")

        for phrase in unwantedPhrases {
          #expect(!copy.contains(phrase))
        }
      }
    }
  }

  @Test("Every body theme offers a week of varied words")
  func everyThemeOffersAWeekOfVariety() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!

    for theme in [
      DailyReflectionTheme.universal,
      .steady,
      .attention,
      .recovery,
    ] {
      let words = Set(
        (0..<14).map { offset in
          DailyReflectionSelector.reflection(
            on: calendar.date(byAdding: .day, value: offset, to: start)!,
            theme: theme,
            calendar: calendar
          ).text
        })

      #expect(words.count >= 7)
    }
  }

  @Test(
    "Pressure reflections stay inside the source and level pool",
    arguments: CurrentStressSource.allCases,
    CurrentStressLevel.allCases
  )
  func pressureReflectionsUseOnlyTheirRestrictedPool(
    source: CurrentStressSource,
    level: CurrentStressLevel
  ) {
    let calendar = utcCalendar
    let start = calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!
    let profile = CurrentStressProfile(level: level, source: source)
    let selectedIDs = Set(
      (0..<12).map { offset in
        DailyReflectionSelector.reflection(
          on: calendar.date(byAdding: .day, value: offset, to: start)!,
          stressProfile: profile,
          calendar: calendar
        ).id
      })

    #expect(selectedIDs == expectedPressureQuoteIDs(for: profile))
    #expect(selectedIDs.count == 4)
    #expect(selectedIDs.count < DailyReflectionSelector.library.count)
  }

  @Test("The same pressure profile remains stable throughout one local day")
  func pressureReflectionIsStableWithinOneDay() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let morning = calendar.date(
      from: DateComponents(year: 2026, month: 9, day: 2, hour: 7)
    )!
    let evening = calendar.date(
      from: DateComponents(year: 2026, month: 9, day: 2, hour: 23)
    )!
    let profile = CurrentStressProfile(level: .high, source: .work)

    let morningReflection = DailyReflectionSelector.reflection(
      on: morning,
      stressProfile: profile,
      calendar: calendar
    )
    let eveningReflection = DailyReflectionSelector.reflection(
      on: evening,
      stressProfile: profile,
      calendar: calendar
    )

    #expect(morningReflection == eveningReflection)
  }

  @Test(
    "Pressure level changes the eligible quotation",
    arguments: CurrentStressSource.allCases
  )
  func pressureLevelChangesTheQuotation(source: CurrentStressSource) {
    let date = Date(timeIntervalSince1970: 1_788_278_400)
    let reflections = CurrentStressLevel.allCases.map { level in
      DailyReflectionSelector.reflection(
        on: date,
        stressProfile: CurrentStressProfile(level: level, source: source),
        calendar: utcCalendar
      )
    }

    #expect(Set(reflections.map(\.id)).count == CurrentStressLevel.allCases.count)
  }

  private var utcCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  private func expectedPressureQuoteIDs(
    for profile: CurrentStressProfile
  ) -> Set<String> {
    let ids: [String] =
      switch (pressureQuoteGroup(for: profile.source), profile.level) {
      case (.workAndTasks, .low):
        ["james-effort", "aurelius-last-act", "seneca-begin", "montaigne-use"]
      case (.workAndTasks, .moderate):
        ["james-wise", "james-attention", "epictetus-use", "seneca-postponing"]
      case (.workAndTasks, .high):
        ["epictetus-control", "seneca-imagination", "aurelius-no-opinion", "seneca-delay"]
      case (.relationships, .low):
        ["seneca-company", "james-appreciation", "montaigne-belong", "nietzsche-love"]
      case (.relationships, .moderate):
        ["pascal-heart", "spinoza-hatred", "aurelius-revenge", "epictetus-insult"]
      case (.relationships, .high):
        ["seneca-delay", "epictetus-control", "aurelius-within", "spinoza-opposite"]
      case (.money, .low):
        ["schopenhauer-possession", "seneca-poor", "montaigne-use", "spinoza-good"]
      case (.money, .moderate):
        ["schopenhauer-cards", "nietzsche-desire", "spinoza-desire", "james-wise"]
      case (.money, .high):
        ["epictetus-control", "seneca-imagination", "aurelius-no-opinion", "epictetus-wish"]
      case (.healthAndBody, .low):
        ["montaigne-live", "spinoza-life", "aurelius-within", "montaigne-cheerful"]
      case (.healthAndBody, .moderate):
        ["spinoza-clear", "epictetus-use", "pascal-reed", "aurelius-judgment"]
      case (.healthAndBody, .high):
        ["seneca-imagination", "epictetus-control", "aurelius-no-opinion", "spinoza-opposite"]
      case (.training, .low):
        ["james-effort", "aurelius-last-act", "epictetus-progress", "montaigne-use"]
      case (.training, .moderate):
        ["schopenhauer-cards", "epictetus-use", "seneca-brave", "aurelius-be-one"]
      case (.training, .high):
        ["epictetus-control", "aurelius-no-opinion", "seneca-imagination", "aurelius-within"]
      case (.sleepAndEnergy, .low):
        ["montaigne-cheerful", "spinoza-life", "james-worth-living", "montaigne-live"]
      case (.sleepAndEnergy, .moderate):
        ["schopenhauer-alone", "pascal-present", "james-wise", "montaigne-belong"]
      case (.sleepAndEnergy, .high):
        ["aurelius-within", "epictetus-wish", "seneca-imagination", "spinoza-clear"]
      case (.mentalLoad, .low):
        ["james-attention", "james-wise", "aurelius-thoughts", "montaigne-belong"]
      case (.mentalLoad, .moderate):
        ["james-wandering", "epictetus-views", "spinoza-clear", "aurelius-judgment"]
      case (.mentalLoad, .high):
        ["seneca-imagination", "epictetus-control", "aurelius-no-opinion", "seneca-delay"]
      case (.unspecified, .low):
        ["montaigne-live", "james-worth-living", "spinoza-life", "aurelius-color"]
      case (.unspecified, .moderate):
        ["james-attention", "epictetus-use", "spinoza-clear", "aurelius-within"]
      case (.unspecified, .high):
        ["epictetus-control", "seneca-imagination", "aurelius-no-opinion", "spinoza-opposite"]
      }
    return Set(ids)
  }

  private func pressureQuoteGroup(for source: CurrentStressSource) -> PressureQuoteGroup {
    switch source {
    case .work, .tasks:
      .workAndTasks
    case .family, .relationship:
      .relationships
    case .money:
      .money
    case .health, .physicalTension, .bodySignals:
      .healthAndBody
    case .training:
      .training
    case .sleep, .lowEnergy:
      .sleepAndEnergy
    case .mentalLoad:
      .mentalLoad
    case .none:
      .unspecified
    }
  }

  private enum PressureQuoteGroup {
    case workAndTasks
    case relationships
    case money
    case healthAndBody
    case training
    case sleepAndEnergy
    case mentalLoad
    case unspecified
  }
}
