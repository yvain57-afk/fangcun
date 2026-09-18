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

  @Test func legacySnapshotKeepsItsMeaningAndSurvivesSameDayRefresh() throws {
    let name = "fangcun-test-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    let date = Date.now
    let original = try JSONSerialization.data(withJSONObject: [
      "entries": [], "snapshots": [["date": date.timeIntervalSinceReferenceDate,
        "state": "steady", "summary": "Original summary", "sleep": "Original sleep", "training": "Original training"]]
    ])
    defaults.set(original, forKey: "fangcun.native.diary.v1")
    let diary = FangcunDiary(defaults: defaults)
    #expect(defaults.data(forKey: "fangcun.native.diary.v1") == original)
    #expect(diary.snapshot(on: date)?.isLegacy == true)
    #expect(diary.snapshot(on: date)?.displayStateTitle == "平稳")
    diary.record(FangcunDaySnapshot(date: date.addingTimeInterval(1), state: .watch,
      summary: "New summary", sleep: "New sleep", training: "New training"))
    let reloaded = FangcunDiary(defaults: defaults)
    #expect(reloaded.snapshot(on: date)?.state == .watch)
    #expect(reloaded.snapshot(on: date)?.isLegacy == false)
    #expect(reloaded.legacySnapshots(on: date).count == 1)
    #expect(reloaded.legacySnapshots(on: date).first?.summary == "Original summary")
    #expect(reloaded.legacySnapshots(on: date).first?.sleep == "Original sleep")
    #expect(defaults.data(forKey: "fangcun.native.diary.preM1") == original)
    diary.add(.water, at: date)
    #expect(defaults.data(forKey: "fangcun.native.diary.preM1") == original)
  }
}
