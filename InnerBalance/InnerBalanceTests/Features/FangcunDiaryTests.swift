import Foundation
import Testing
@testable import InnerBalance

@Suite("Native diary persistence") @MainActor
struct FangcunDiaryTests {
  @Test func compositeDrinkUndoAndReload() throws {
    let name = "fangcun-test-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    let store = FangcunDiary(defaults: defaults)
    let today = Date.now
    store.add(.water, at: today)
    store.add(.sweetCoffee, caffeine: 170, at: today)
    var totals = FangcunDrinkTotals(store.entries(on: today))
    #expect(totals.fluid == 550 && totals.caffeine == 170 && totals.sugar == 1)
    store.remove(.sweetCoffee, on: today)
    store.undo()
    totals = FangcunDrinkTotals(FangcunDiary(defaults: defaults).entries(on: today))
    #expect(totals.fluid == 550 && totals.caffeine == 170 && totals.sugar == 1)
    store.undo()
    #expect(store.entries(on: today).map(\.kind) == [.water])
  }
  @Test func dayBoundariesAndUnknownHistory() throws {
    let name = "fangcun-test-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    let store = FangcunDiary(defaults: defaults)
    let today = Calendar.current.startOfDay(for: .now).addingTimeInterval(60)
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
    store.add(.beer, at: yesterday)
    store.add(.water, at: today)
    store.remove(.beer, on: today)
    #expect(store.entries(on: yesterday).count == 1)
    #expect(FangcunDrinkTotals(store.entries(on: today)).alcohol == 0)
    #expect(store.snapshot(on: yesterday) == nil)
    store.record(FangcunDaySnapshot(date: today, state: .insufficient, summary: "未知", sleep: "未记录", training: "未记录"))
    #expect(FangcunDiary(defaults: defaults).snapshot(on: today)?.state == .insufficient)
  }
  @Test func unreadableArchiveIsNotOverwritten() throws {
    let name = "fangcun-test-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    let data = Data("damaged".utf8)
    defaults.set(data, forKey: "fangcun.native.diary.v1")
    let store = FangcunDiary(defaults: defaults)
    store.add(.water)
    #expect(store.storageMessage != nil)
    #expect(defaults.data(forKey: "fangcun.native.diary.v1") == data)
  }
}
