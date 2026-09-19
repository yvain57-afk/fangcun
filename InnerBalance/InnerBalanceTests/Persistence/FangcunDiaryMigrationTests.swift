import Foundation
import InnerBalanceCore
import Testing
@testable import InnerBalance

@Suite("M3-01 safe diary migration") @MainActor
struct FangcunDiaryMigrationTests {
  let now = Date(timeIntervalSince1970: 1_789_704_000)
  func fixture(_ defaults: UserDefaults) throws -> Data {
    let bytes = try JSONSerialization.data(withJSONObject: ["entries": [
      ["id": "00000000-0000-0000-0000-000000000001", "date": now.timeIntervalSinceReferenceDate,
       "kind": "sweetCoffee", "caffeine": 170],
      ["id": "00000000-0000-0000-0000-000000000002", "date": now.timeIntervalSinceReferenceDate,
       "kind": "beer", "caffeine": 0]], "snapshots": [
      ["date": now.timeIntervalSinceReferenceDate, "state": "steady", "summary": "Original words", "sleep": "Old sleep", "training": "Old training", "semanticsVersion": 1]]])
    defaults.set(bytes, forKey: "fangcun.native.diary.v1")
    defaults.set(bytes, forKey: "fangcun.native.diary.preM1")
    return bytes
  }
  func setup() throws -> (UserDefaults, String, URL, FangcunDiaryStorage) {
    let name = "synthetic-migration-\(UUID())"
    let defaults = try #require(UserDefaults(suiteName: name))
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(name)
    return (defaults,name,directory,try FangcunDiaryStorage(directory: directory))
  }
  @Test func migrationKeepsIDsTotalsWordsAndVerifiedOriginalBytes() throws {
    let (d,name,dir,file) = try setup()
    defer { d.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: dir) }
    let bytes = try fixture(d)
    let first = FangcunDiary(defaults: d, storage: file)
    let second = FangcunDiary(defaults: d, storage: try FangcunDiaryStorage(directory: dir))
    #expect(first.storageMessage == nil && second.allEntries.count == 2)
    #expect(first.allEntries == second.allEntries)
    let totals = FangcunDrinkTotals(second.allEntries)
    #expect(totals.fluid == 630 && totals.caffeine == 170 && totals.alcohol == 10 && totals.sugar == 1)
    #expect(second.allEntries.allSatisfy { $0.recordedAt == nil && $0.sugarGrams == nil && $0.consumedAt == now && $0.estimateMethod == "legacyFixedCupEstimate" })
    #expect(second.allSnapshots.count == 1 && second.allSnapshots[0].isLegacy)
    #expect(second.allSnapshots[0].summary == "Original words" && second.allSnapshots[0].semanticsVersion == 1)
    for key in ["fangcun.native.diary.v1","fangcun.native.diary.preM1"] {
      #expect(d.data(forKey: key) == bytes)
      #expect(try Data(contentsOf: dir.appendingPathComponent(key+".backup")) == bytes)
      #expect(second.migrationDigests[key] == StableDigest.data(bytes))
    }
  }
  @Test(arguments: [FangcunDiaryStorage.Fault.afterBackup, .beforePublish, .afterPublish])
  func interruptedMigrationResumesWithoutDuplication(_ fault: FangcunDiaryStorage.Fault) throws {
    let (d,name,dir,file) = try setup()
    defer { d.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: dir) }
    let bytes = try fixture(d); file.nextFault = fault
    let interrupted = FangcunDiary(defaults: d, storage: file)
    #expect(interrupted.storageMessage != nil)
    #expect(d.data(forKey: "fangcun.native.diary.v1") == bytes)
    let resumed = FangcunDiary(defaults: d, storage: try FangcunDiaryStorage(directory: dir))
    #expect(resumed.storageMessage == nil && resumed.allEntries.count == 2)
    #expect(resumed.allSnapshots.count == 1)
  }
  @Test func preM1BackupCannotResurrectRemovedDrinks() throws {
    let (d,name,dir,file) = try setup()
    defer { d.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: dir) }
    _ = try fixture(d)
    d.set(Data("{\"entries\":[],\"snapshots\":[]}".utf8), forKey: "fangcun.native.diary.v1")
    let migrated = FangcunDiary(defaults: d, storage: file)
    #expect(migrated.storageMessage == nil && migrated.allEntries.isEmpty)
    #expect(migrated.allSnapshots.count == 1)
  }
  @Test func damagedInputAndTargetNeverBecomeAnEmptyArchive() throws {
    let (d,name,dir,file) = try setup()
    defer { d.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: dir) }
    let bad = Data("damaged original".utf8); d.set(bad, forKey: "fangcun.native.diary.v1")
    let diary = FangcunDiary(defaults: d, storage: file); diary.add(.water)
    #expect(diary.storageMessage != nil && d.data(forKey: "fangcun.native.diary.v1") == bad)
    #expect(try Data(contentsOf: dir.appendingPathComponent("fangcun.native.diary.v1.backup")) == bad)
    #expect(!FileManager.default.fileExists(atPath: dir.appendingPathComponent("diary-v2.json").path))
    try bad.write(to: dir.appendingPathComponent("diary-v2.json"))
    let reloaded = FangcunDiary(defaults: d, storage: file); reloaded.add(.water)
    #expect(reloaded.storageMessage != nil)
    #expect(try Data(contentsOf: dir.appendingPathComponent("diary-v2.json")) == bad)
  }
  @Test func writeFailureRetryEditingAndUndoKeepEstimatesAndUnknowns() throws {
    let (d,name,dir,file) = try setup()
    defer { d.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: dir) }
    let diary = FangcunDiary(defaults: d, storage: file)
    file.nextFault = .beforePublish
    diary.add(.sweetCoffee, caffeine: 170, at: now, now: now)
    #expect(diary.allEntries.isEmpty && diary.storageMessage != nil)
    diary.retry(defaults: d); diary.add(.sweetCoffee, caffeine: 170, at: now, now: now)
    let entry = try #require(diary.allEntries.first)
    let sixDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: now)!
    diary.edit(entry.id, consumedAt: sixDaysAgo, volumeML: 600, now: now)
    let edited = try #require(diary.allEntries.first)
    #expect(edited.id == entry.id && edited.revision == 2 && edited.volumeML == 600 && edited.caffeine == 170)
    #expect(edited.sugarServings == 1 && edited.sugarGrams == nil && edited.recordedAt == now)
    diary.add(.water, at: now-8*86400, now: now)
    diary.add(.water, at: now+1, now: now)
    #expect(diary.allEntries.count == 1)
    diary.undo()
    let undone = try #require(diary.allEntries.first)
    #expect(undone.id == entry.id && undone.volumeML == entry.volumeML && undone.caffeine == entry.caffeine)
    #expect(undone.revision > edited.revision && undone.consumedAt == entry.consumedAt)
    var unknown = FangcunDiaryArchive(); var value = entry; value.alcoholGrams = nil; value.details = nil
    unknown.entries = [value]; try file.save(unknown)
    let reopened = FangcunDiary(defaults: d, storage: file)
    reopened.edit(entry.id, consumedAt: now, volumeML: 150, now: now)
    #expect(reopened.allEntries.first?.alcoholGrams == nil)
    #expect(FangcunDrinkTotals(reopened.allEntries).hasUnknownAlcohol)
    #expect(FangcunDrinkTotals(reopened.allEntries).sugar == 1)
  }
}
