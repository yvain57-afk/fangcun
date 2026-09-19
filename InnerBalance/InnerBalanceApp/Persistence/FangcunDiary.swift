import Foundation
import InnerBalanceCore
import Observation

enum FangcunDayState: String, Codable, CaseIterable {
  case steady, watch, elevated, limited, insufficient
  var title: String { FangcunCopy.text("body.state.\(rawValue).title") }
  var shortTitle: String { FangcunCopy.text("body.state.\(rawValue).short") }
  var scene: FangcunCompanionScene {
    switch self {
    case .steady: .calm
    case .watch, .elevated: .rest
    case .limited, .insufficient: .curious
    }
  }
  static func resolve(_ model: HomeViewModel) -> Self {
    switch model.assessment.availability {
    case .insufficient: return .insufficient
    case .limited, .buildingBaseline: return .limited
    case .available: break
    }
    return switch model.assessment.level {
    case .buildingBaseline: .insufficient
    case .steady: .steady
    case .watch: .watch
    case .elevated: .elevated
    }
  }
}

enum FangcunDrink: String, Codable, CaseIterable, Identifiable {
  case water, coffee, sweetCoffee, beer, soda
  var id: String { rawValue }
  var title: String { switch self { case .water: "白水"; case .coffee: "美式"; case .sweetCoffee: "甜拿铁"; case .beer: "啤酒"; case .soda: "含糖饮料" } }
  var symbol: String { switch self { case .water: "drop"; case .coffee, .sweetCoffee: "cup.and.saucer"; case .beer: "wineglass"; case .soda: "takeoutbag.and.cup.and.straw" } }
  var fluid: Int { switch self { case .water: 250; case .coffee, .sweetCoffee: 300; case .beer, .soda: 330 } }
  var alcohol: Int { self == .beer ? 10 : 0 }
  var sugar: Int { self == .sweetCoffee || self == .soda ? 1 : 0 }
  var isCoffee: Bool { self == .coffee || self == .sweetCoffee }
}

struct FangcunDrinkEntry: Codable, Identifiable, Equatable {
  var id: UUID
  var consumedAt: Date
  var recordedAt: Date?
  var kind: FangcunDrink
  var volumeML: Int
  var caffeine: Int
  var alcoholGrams: Double?
  var sugarServings: Double
  var sugarGrams: Double?
  var estimateMethod: String
  var estimateVersion: Int
  var revision: Int
  var date: Date { consumedAt }
  init(id: UUID = UUID(), date: Date, kind: FangcunDrink, caffeine: Int, recordedAt: Date? = .now) {
    self.id = id; consumedAt = date; self.recordedAt = recordedAt; self.kind = kind
    volumeML = kind.fluid; self.caffeine = caffeine; alcoholGrams = Double(kind.alcohol)
    sugarServings = Double(kind.sugar); sugarGrams = nil
    estimateMethod = "fixedCupEstimate"; estimateVersion = 1; revision = 1
  }
  enum CodingKeys: String, CodingKey {
    case id, consumedAt, recordedAt, date, kind, volumeML, caffeine, alcoholGrams, sugarServings, sugarGrams, estimateMethod, estimateVersion, revision
  }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(UUID.self, forKey: .id); kind = try c.decode(FangcunDrink.self, forKey: .kind)
    consumedAt = try c.decodeIfPresent(Date.self, forKey: .consumedAt) ?? c.decode(Date.self, forKey: .date)
    recordedAt = try c.decodeIfPresent(Date.self, forKey: .recordedAt)
    volumeML = try c.decodeIfPresent(Int.self, forKey: .volumeML) ?? kind.fluid
    caffeine = try c.decode(Int.self, forKey: .caffeine)
    let legacy = !c.contains(.consumedAt)
    alcoholGrams = legacy ? Double(kind.alcohol) : try c.decodeIfPresent(Double.self, forKey: .alcoholGrams)
    sugarServings = try c.decodeIfPresent(Double.self, forKey: .sugarServings) ?? Double(kind.sugar)
    sugarGrams = try c.decodeIfPresent(Double.self, forKey: .sugarGrams)
    estimateMethod = try c.decodeIfPresent(String.self, forKey: .estimateMethod) ?? "legacyFixedCupEstimate"
    estimateVersion = try c.decodeIfPresent(Int.self, forKey: .estimateVersion) ?? 1
    revision = try c.decodeIfPresent(Int.self, forKey: .revision) ?? 1
  }
  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id, forKey: .id); try c.encode(kind, forKey: .kind)
    try c.encode(consumedAt, forKey: .consumedAt); try c.encodeIfPresent(recordedAt, forKey: .recordedAt)
    try c.encode(volumeML, forKey: .volumeML); try c.encode(caffeine, forKey: .caffeine)
    try c.encodeIfPresent(alcoholGrams, forKey: .alcoholGrams); try c.encode(sugarServings, forKey: .sugarServings)
    try c.encodeIfPresent(sugarGrams, forKey: .sugarGrams); try c.encode(estimateMethod, forKey: .estimateMethod)
    try c.encode(estimateVersion, forKey: .estimateVersion); try c.encode(revision, forKey: .revision)
  }
  func migrated() -> Self {
    var result = self; result.recordedAt = nil; result.estimateMethod = "legacyFixedCupEstimate"; return result
  }
}

struct FangcunDaySnapshot: Codable, Identifiable {
  let date: Date
  let state: FangcunDayState
  let summary: String
  let sleep: String
  let training: String
  /// Missing in original archives. Those snapshots retain their original interpretation.
  let semanticsVersion: Int?
  var migrationOrigin: String? = nil
  var id: Date { date }
  var isLegacy: Bool { semanticsVersion == nil || migrationOrigin != nil }
  var displayStateTitle: String {
    guard semanticsVersion == nil else { return state.shortTitle }
    return switch state {
    case .steady: "平稳"
    case .elevated: "偏高"
    case .insufficient: "数据不足"
    case .watch, .limited: state.shortTitle
    }
  }

  init(date: Date, state: FangcunDayState, summary: String, sleep: String, training: String,
    semanticsVersion: Int? = 1) {
    self.date = date; self.state = state; self.summary = summary
    self.sleep = sleep; self.training = training; self.semanticsVersion = semanticsVersion
  }
}

@MainActor @Observable
final class FangcunDiary {
  private var archive = FangcunDiaryArchive()
  private var undoStack: [[FangcunDrinkEntry]] = []
  private var storage: FangcunDiaryStorage?
  private let defaults: UserDefaults
  private(set) var storageMessage: String?
  private(set) var migrationDigests: [String: String] = [:]
  var allEntries: [FangcunDrinkEntry] { archive.entries }
  var allSnapshots: [FangcunDaySnapshot] { archive.snapshots }
  init(defaults: UserDefaults = .standard, storage: FangcunDiaryStorage? = nil) {
    self.defaults = defaults
    do {
      let file = try storage ?? FangcunDiaryStorage(directory: FangcunDiaryStorage.directory(defaults: defaults))
      self.storage = file
      archive = try file.load(defaults: defaults)
      migrationDigests = archive.migrationDigests
    } catch { storageMessage = FangcunCopy.text("diary.storage.readFailure") }
  }

  func entries(on date: Date = .now) -> [FangcunDrinkEntry] {
    archive.entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
  }
  func snapshot(on date: Date) -> FangcunDaySnapshot? {
    archive.snapshots.last { Calendar.current.isDate($0.date, inSameDayAs: date) }
  }
  func legacySnapshots(on date: Date) -> [FangcunDaySnapshot] {
    archive.snapshots.filter { $0.isLegacy && Calendar.current.isDate($0.date, inSameDayAs: date) }
  }
  func add(_ kind: FangcunDrink, caffeine: Int = 140, at date: Date = .now, now: Date = .now, volumeML: Int? = nil) {
    guard editable(date, now: now), entries(on: date).count < 1000 else { return }
    var next = archive
    var entry = FangcunDrinkEntry(date: date, kind: kind, caffeine: kind.isCoffee ? min(500, max(0, caffeine)) : 0, recordedAt: now)
    if let volumeML {
      guard (10...3000).contains(volumeML) else { return }
      let ratio = Double(volumeML) / Double(entry.volumeML)
      entry.volumeML = volumeML; entry.caffeine = Int((Double(entry.caffeine)*ratio).rounded())
      entry.alcoholGrams = entry.alcoholGrams.map { $0*ratio }; entry.sugarServings *= ratio
      entry.estimateMethod = "scaledCupEstimate"
    }
    next.entries.append(entry)
    commit(next, remember: true)
  }
  func edit(_ id: UUID, consumedAt: Date, volumeML: Int, now: Date = .now) {
    guard editable(consumedAt, now: now), (10...3000).contains(volumeML),
      let index = archive.entries.firstIndex(where: { $0.id == id }) else { return }
    var next = archive; var entry = next.entries[index]
    let ratio = Double(volumeML) / Double(max(1, entry.volumeML))
    entry.consumedAt = consumedAt; entry.volumeML = volumeML
    entry.caffeine = Int((Double(entry.caffeine)*ratio).rounded())
    entry.alcoholGrams = entry.alcoholGrams.map { $0*ratio }
    entry.sugarServings *= ratio; entry.sugarGrams = entry.sugarGrams.map { $0*ratio }
    entry.revision += 1; entry.estimateMethod = "scaledCupEstimate"
    next.entries[index] = entry; commit(next, remember: true)
  }
  func remove(_ kind: FangcunDrink, on date: Date = .now) {
    guard let index = archive.entries.lastIndex(where: { $0.kind == kind && Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }
    var next = archive; next.entries.remove(at: index); commit(next, remember: true)
  }
  var canUndo: Bool { !undoStack.isEmpty && storageMessage == nil }
  func undo() {
    guard let previous = undoStack.last else { return }
    var next = archive; next.entries = previous
    if commit(next, remember: false) { undoStack.removeLast() }
  }
  func record(_ snapshot: FangcunDaySnapshot) {
    var next = archive
    next.snapshots.removeAll { !$0.isLegacy && Calendar.current.isDate($0.date, inSameDayAs: snapshot.date) }
    next.snapshots.append(snapshot); commit(next, remember: false)
  }
  private func editable(_ date: Date, now: Date) -> Bool {
    let earliest = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: now))!
    return date >= earliest && date <= now
  }
  @discardableResult private func commit(_ next: FangcunDiaryArchive, remember: Bool) -> Bool {
    guard storageMessage == nil, let storage else { return false }
    do {
      try storage.save(next)
      if remember { undoStack.append(archive.entries); if undoStack.count > 50 { undoStack.removeFirst() } }
      archive = next; return true
    } catch { storageMessage = FangcunCopy.text("diary.storage.writeFailure"); return false }
  }
  func applySync(_ events: [SyncEvent]) throws {
    guard storageMessage == nil else { throw SyncStore.Failure.corrupt }
    var next = archive
    var changed = false
    for event in events where event.kind == .drink && event.revision > (next.syncRevisions[event.entityID] ?? 0) {
      changed = true
      guard let id = UUID(uuidString: event.entityID) else { throw SyncStore.Failure.invalid }
      next.entries.removeAll { $0.id == id }
      if !event.deleted {
        let value = try JSONDecoder().decode(SyncedDrink.self, from: event.payload)
        guard let kind = FangcunDrink(rawValue: value.kind) else { throw SyncStore.Failure.unknownProtocol }
        var entry = FangcunDrinkEntry(id: id, date: value.consumedAt, kind: kind, caffeine: value.caffeineMG, recordedAt: value.recordedAt)
        entry.volumeML = value.volumeML; entry.alcoholGrams = value.alcoholGrams
        entry.sugarServings = value.sugarServings; entry.sugarGrams = value.sugarGrams
        entry.estimateMethod = value.estimateMethod; entry.estimateVersion = value.estimateVersion; entry.revision = event.revision
        next.entries.append(entry)
      }
      next.syncRevisions[event.entityID] = event.revision
    }
    guard changed else { return }
    guard commit(next, remember: false) else { throw SyncStore.Failure.corrupt }
    // A remote change invalidates an old local undo snapshot; it must not restore deleted peer records.
    undoStack.removeAll()
  }
  func retry(defaults: UserDefaults? = nil) {
    guard let storage else { return }
    do { archive = try storage.load(defaults: defaults ?? self.defaults); storageMessage = nil }
    catch { storageMessage = FangcunCopy.text("diary.storage.readFailure") }
  }

}

struct FangcunDrinkTotals {
  let fluid: Int, caffeine: Int
  let alcohol: Double, sugar: Double
  let hasUnknownAlcohol: Bool
  init(_ entries: [FangcunDrinkEntry]) {
    fluid = entries.reduce(0) { $0 + $1.volumeML }
    caffeine = entries.reduce(0) { $0 + $1.caffeine }
    alcohol = entries.reduce(0) { $0 + ($1.alcoholGrams ?? 0) }
    hasUnknownAlcohol = entries.contains { $0.alcoholGrams == nil }
    sugar = entries.reduce(0) { $0 + $1.sugarServings }
  }
}


extension FangcunDrinkEntry {
  var syncValue: SyncedDrink {
    .init(id: id.uuidString, kind: kind.rawValue, consumedAt: consumedAt, recordedAt: recordedAt,
      volumeML: volumeML, caffeineMG: caffeine, alcoholGrams: alcoholGrams, sugarServings: sugarServings,
      sugarGrams: sugarGrams, estimateMethod: estimateMethod, estimateVersion: estimateVersion)
  }
}
