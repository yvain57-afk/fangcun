import Foundation
import Testing
import InnerBalanceCore
@testable import InnerBalance

@Suite @MainActor struct BeverageV2Tests {
  @Test func testDilutingPerServingCoffeeKeepsDose() throws {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let diary = FangcunDiary(defaults: defaults)
    diary.add(.coffee, caffeine: 140, volumeML: 500)
    #expect(diary.allEntries.first?.caffeine == 140)
    let id = try #require(diary.allEntries.first?.id)
    diary.edit(id, consumedAt: .now, volumeML: 300)
    #expect(diary.allEntries.first?.caffeine == 140)
  }
  @Test func testNewBeerUsesVolumeAndABV() {
    let diary = FangcunDiary(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    diary.add(.beer)
    #expect(abs((diary.allEntries.first?.alcoholGrams ?? -1) - 330 * 0.05 * 0.789) < 0.001)
  }
  @Test func committedCommandsAreDurableAndUndoIsANewRevision() throws {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let storage = try FangcunDiaryStorage(directory: root)
    let diary = FangcunDiary(defaults: defaults, storage: storage)
    storage.nextFault = .beforePublish
    #expect(diary.add(.water, commandID: "tap") == .failed)
    #expect(diary.allEntries.isEmpty)
    diary.retry()
    let committed = diary.add(.water, commandID: "tap")
    let receipt = try #require(committed.receipt)
    #expect(diary.add(.water, commandID: "tap") == committed && diary.allEntries.count == 1)
    let restarted = FangcunDiary(defaults: defaults, storage: storage)
    #expect(restarted.add(.water, commandID: "tap") == committed && restarted.allEntries.count == 1)
    let undone = try #require(diary.undo(commandID: "undo").receipt)
    #expect(undone.entityID == receipt.entityID && undone.revision > receipt.revision && diary.allEntries.isEmpty)
    #expect(diary.undo(commandID: "undo").receipt == undone && diary.allEntries.isEmpty)
  }
  @Test func unknownDoseProjectionAndLegacyBeerNeverBecomeZeroOrRecalculated() throws {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let storage = try FangcunDiaryStorage(directory: root)
    var archive = FangcunDiaryArchive()
    let beer = FangcunDrinkEntry(date: .now, kind: .beer, caffeine: 0)
    archive.entries = [beer]; try storage.save(archive)
    let diary = FangcunDiary(defaults: defaults, storage: storage)
    diary.edit(beer.id, consumedAt: .now, volumeML: 500)
    #expect(diary.allEntries.first?.alcoholGrams == 10 && diary.allEntries.first?.id == beer.id)
    diary.add(.coffee, details: .init(displayName: "Unknown", caffeinePresence: .yes, caffeineMethod: .unknown, caffeineDose: nil))
    let unknown = try #require(diary.allEntries.last?.beverage)
    #expect(unknown.caffeineMG == nil && unknown.caffeinePresence == .yes)
    #expect(BeverageTotals(diary.allEntries.map(\.beverage)).hasUnknownCaffeine)
  }
}
