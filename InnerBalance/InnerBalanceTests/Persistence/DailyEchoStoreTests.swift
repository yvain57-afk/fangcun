import Foundation
import InnerBalanceCore
import SwiftData
import Testing

@testable import InnerBalance

@Suite("Daily echo")
struct DailyEchoStoreTests {
  @Test("Saving today's echo makes it available immediately and in history")
  @MainActor
  func saveAndReadHistory() throws {
    let container = try ModelContainer(
      for: StoredDailyEcho.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = DailyEchoStore(modelContext: container.mainContext)
    let date = Date(timeIntervalSince1970: 1_786_320_000)

    try store.save(
      state: .calm,
      note: "这句话提醒我，别把地图当成路。",
      reflection: DailyReflection(
        id: "korzybski-map",
        text: "地图并非疆域本身。",
        attribution: "阿尔弗雷德·柯日布斯基"
      ),
      date: date
    )

    #expect(try store.echo(on: date)?.text == "这句话提醒我，别把地图当成路。")
    #expect(try store.echo(on: date)?.state == .calm)
    #expect(try store.history().count == 1)
    #expect(try store.history().first?.reflectionID == "korzybski-map")
    #expect(try store.history().first?.reflectionText == "地图并非疆域本身。")
    #expect(try store.history().first?.attribution == "阿尔弗雷德·柯日布斯基")
    #expect(try store.history().first?.reflectionSource == .ideaAdaptation)
    #expect(try store.history().first?.reflectionWork == nil)
  }

  @Test("Saving again on the same local day edits instead of duplicating")
  @MainActor
  func sameDaySaveUpdatesExistingEcho() throws {
    let container = try ModelContainer(
      for: StoredDailyEcho.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = DailyEchoStore(modelContext: container.mainContext)
    let morning = Date(timeIntervalSince1970: 1_786_320_000)
    let evening = morning.addingTimeInterval(3_600)

    let reflection = DailyReflection(
      id: "quote-a",
      text: "今日摘句",
      attribution: "作者"
    )
    try store.save(state: .tense, note: "第一句", reflection: reflection, date: morning)
    try store.save(state: .clear, note: "后来想到的一句", reflection: reflection, date: evening)

    #expect(try store.history().map(\.text) == ["后来想到的一句"])
    #expect(try store.history().map(\.state) == [.clear])
  }

  @Test("点一下当下状态即可保存，不需要填写文字")
  @MainActor
  func selectedStateSavesWithoutARequiredNote() throws {
    let container = try ModelContainer(
      for: StoredDailyEcho.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = DailyEchoStore(modelContext: container.mainContext)
    let date = Date(timeIntervalSince1970: 1_786_320_000)
    let reflection = DailyReflection(id: "quote", text: "今日摘句", attribution: "作者")

    try store.save(state: .tired, reflection: reflection, date: date)

    #expect(try store.echo(on: date)?.state == .tired)
    #expect(try store.echo(on: date)?.text.isEmpty == true)
  }

  @Test("旧版生成句在历史里会换成同日同状态的名家句")
  @MainActor
  func legacyGeneratedReflectionUsesASourcedQuotationInHistory() throws {
    let container = try ModelContainer(
      for: StoredDailyEcho.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = DailyEchoStore(modelContext: container.mainContext)
    let date = Date(timeIntervalSince1970: 1_786_320_000)
    let reflection = DailyReflection(id: "echo-calm", text: "平静不是停下，是终于不用和自己拔河。")

    try store.save(state: .calm, reflection: reflection, date: date)

    let echo = try store.echo(on: date)
    let stored = try #require(echo)
    #expect(stored.reflectionID.hasPrefix("echo-") == false)
    #expect(stored.attribution?.isEmpty == false)
    #expect(stored.reflectionWork?.isEmpty == false)
    #expect(stored.reflectionSource == .collectedQuotation)
  }

  @Test("真实旧版记录首次读取后固定名家句，跨时区和重启不再变化")
  @MainActor
  func legacyRecordIsMaterializedOnceAcrossTimeZones() throws {
    let container = try ModelContainer(
      for: StoredDailyEcho.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    var shanghai = Calendar(identifier: .gregorian)
    shanghai.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    var losAngeles = Calendar(identifier: .gregorian)
    losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    let date = shanghai.date(
      from: DateComponents(year: 2026, month: 8, day: 12, hour: 0, minute: 15)
    )!
    let legacy = StoredDailyEcho(
      day: date,
      text: "",
      reflectionID: "echo-tense-storm",
      reflectionText: "旧版生成句",
      attribution: "",
      state: .tense,
      localDayIdentifier: "",
      reflectionSource: .ideaAdaptation,
      reflectionWork: nil,
      updatedAt: date
    )
    container.mainContext.insert(legacy)
    try container.mainContext.save()

    let shanghaiStore = DailyEchoStore(modelContext: container.mainContext, calendar: shanghai)
    let shanghaiHistory = try shanghaiStore.history()
    let first = try #require(shanghaiHistory.first)
    let persistedIdentifier = legacy.localDayIdentifier
    let persistedReflectionID = legacy.reflectionID

    let losAngelesStore = DailyEchoStore(
      modelContext: container.mainContext,
      calendar: losAngeles
    )
    let losAngelesHistory = try losAngelesStore.history()
    let second = try #require(losAngelesHistory.first)

    #expect(!persistedIdentifier.isEmpty)
    #expect(!persistedReflectionID.hasPrefix("echo-"))
    #expect(first.reflectionID == second.reflectionID)
    #expect(first.reflectionText == second.reflectionText)
    #expect(first.attribution == second.attribution)
    #expect(first.reflectionWork == second.reflectionWork)
  }

  @Test("已保存的现代版权金句会替换为同日同状态的公版句")
  @MainActor
  func retiredCopyrightedQuotationMigratesToPublicDomainQuotation() throws {
    let container = try ModelContainer(
      for: StoredDailyEcho.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: 12))!
    let legacy = StoredDailyEcho(
      day: date,
      text: "",
      reflectionID: "yalom-better-past",
      reflectionText: "迟早有一天，我们要放弃拥有一个更好过去的希望。",
      attribution: "欧文·亚隆",
      state: .tired,
      localDayIdentifier: "1-2026-8-12",
      reflectionSource: .collectedQuotation,
      reflectionWork: "《直视骄阳》",
      updatedAt: date
    )
    container.mainContext.insert(legacy)
    try container.mainContext.save()

    let history = try DailyEchoStore(
      modelContext: container.mainContext,
      calendar: calendar
    ).history()
    let migrated = try #require(history.first)

    #expect(DailyReflectionSelector.library.contains { $0.id == migrated.reflectionID })
    #expect(migrated.attribution != "欧文·亚隆")
    #expect(migrated.reflectionSource == .collectedQuotation)
  }

  @Test("同一自然日在相邻时区切换后仍是同一条回声")
  @MainActor
  func sameCalendarDaySurvivesTimeZoneChange() throws {
    let container = try ModelContainer(
      for: StoredDailyEcho.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    var shanghai = Calendar(identifier: .gregorian)
    shanghai.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    var tokyo = Calendar(identifier: .gregorian)
    tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    let date = shanghai.date(
      from: DateComponents(year: 2026, month: 8, day: 12, hour: 12)
    )!
    let reflection = DailyReflection(id: "echo", text: "今天这一句")

    try DailyEchoStore(modelContext: container.mainContext, calendar: shanghai).save(
      state: .calm,
      reflection: reflection,
      date: date
    )
    let tokyoStore = DailyEchoStore(modelContext: container.mainContext, calendar: tokyo)
    try tokyoStore.save(state: .clear, reflection: reflection, date: date)

    let storedEcho = try tokyoStore.echo(on: date)
    let echo = try #require(storedEcho)
    #expect(echo.state == .clear)
    #expect(echo.localDayIdentifier == "1-2026-8-12")
    #expect(tokyo.component(.day, from: echo.displayDay(in: tokyo)) == 12)
    #expect(try tokyoStore.history().count == 1)
  }

  @Test("切换时区后本地日期不同就不沿用上一天回声")
  @MainActor
  func differentLocalDayDoesNotReuseEcho() throws {
    let container = try ModelContainer(
      for: StoredDailyEcho.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    var shanghai = Calendar(identifier: .gregorian)
    shanghai.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    var losAngeles = Calendar(identifier: .gregorian)
    losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    let date = shanghai.date(
      from: DateComponents(year: 2026, month: 8, day: 12, hour: 9)
    )!

    try DailyEchoStore(modelContext: container.mainContext, calendar: shanghai).save(
      state: .calm,
      reflection: DailyReflection(id: "echo", text: "今天这一句"),
      date: date
    )

    #expect(
      try DailyEchoStore(modelContext: container.mainContext, calendar: losAngeles)
        .echo(on: date) == nil
    )
  }

}
