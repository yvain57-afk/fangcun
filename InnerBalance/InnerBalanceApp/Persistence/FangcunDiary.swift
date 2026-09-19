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
  case water, coffee, sweetCoffee, beer, soda, tea, milk, alcohol, other
  var id: String { rawValue }
  var title: String { switch self { case .water: "白水"; case .coffee: "美式"; case .sweetCoffee: "甜拿铁"; case .beer: "啤酒"; case .soda: "含糖饮料"; case .tea: "茶"; case .milk: "牛奶"; case .alcohol: "其他酒饮"; case .other: "其他饮品" } }
  var symbol: String { switch self { case .water: "drop"; case .coffee, .sweetCoffee: "cup.and.saucer"; case .beer: "wineglass"; case .soda, .tea, .milk, .alcohol, .other: "takeoutbag.and.cup.and.straw" } }
  var fluid: Int { switch self { case .water: 250; case .coffee, .sweetCoffee: 300; case .beer, .soda: 330; case .tea, .milk, .other: 250; case .alcohol: 150 } }
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
  var details: BeverageDetails? = nil
  var date: Date { consumedAt }
  var displayName: String { details?.displayName ?? kind.title }
  init(id: UUID = UUID(), date: Date, kind: FangcunDrink, caffeine: Int, recordedAt: Date? = .now) {
    self.id = id; consumedAt = date; self.recordedAt = recordedAt; self.kind = kind
    volumeML = kind.fluid; self.caffeine = caffeine; alcoholGrams = Double(kind.alcohol)
    sugarServings = Double(kind.sugar); sugarGrams = nil
    estimateMethod = "fixedCupEstimate"; estimateVersion = 1; revision = 1
  }
  enum CodingKeys: String, CodingKey {
    case id, consumedAt, recordedAt, date, kind, volumeML, caffeine, alcoholGrams, sugarServings, sugarGrams, estimateMethod, estimateVersion, revision, details
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
    details = try c.decodeIfPresent(BeverageDetails.self, forKey: .details)
  }
  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id, forKey: .id); try c.encode(kind, forKey: .kind)
    try c.encode(consumedAt, forKey: .consumedAt); try c.encodeIfPresent(recordedAt, forKey: .recordedAt)
    try c.encode(volumeML, forKey: .volumeML); try c.encode(caffeine, forKey: .caffeine)
    try c.encodeIfPresent(alcoholGrams, forKey: .alcoholGrams); try c.encode(sugarServings, forKey: .sugarServings)
    try c.encodeIfPresent(sugarGrams, forKey: .sugarGrams); try c.encode(estimateMethod, forKey: .estimateMethod)
    try c.encode(estimateVersion, forKey: .estimateVersion); try c.encode(revision, forKey: .revision)
    try c.encodeIfPresent(details, forKey: .details)
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
  @discardableResult func add(_ kind: FangcunDrink, caffeine: Int = 140, at date: Date = .now, now: Date = .now,
    volumeML: Int? = nil, details: BeverageDetails? = nil, commandID: String = UUID().uuidString) -> DrinkCommandResult {
    if let receipt = archive.commands[commandID] { return .committed(receipt) }
    guard editable(date, now: now), entries(on: date).count < 1000,
      (10...3000).contains(volumeML ?? kind.fluid) else { return .rejected }
    var next = archive
    var entry = FangcunDrinkEntry(date: date, kind: kind, caffeine: 0, recordedAt: now)
    entry.volumeML = volumeML ?? kind.fluid
    entry.details = details ?? Self.defaultDetails(kind, caffeine: caffeine)
    guard Self.valid(entry.details!) else { return .rejected }
    entry.caffeine = Int((entry.details!.caffeineMG(volumeML: entry.volumeML) ?? 0).rounded())
    entry.alcoholGrams = entry.details!.alcoholGrams(volumeML: entry.volumeML)
    entry.estimateMethod = entry.details!.caffeineMethod.rawValue; entry.estimateVersion = 2
    next.entries.append(entry)
    let receipt = DrinkCommitReceipt(eventID: commandID, entityID: entry.id, revision: entry.revision, committedAt: now)
    next.commands[commandID] = receipt
    return commit(next, remember: true) ? .committed(receipt) : .failed
  }
  @discardableResult func edit(_ id: UUID, consumedAt: Date, volumeML: Int, now: Date = .now,
    details: BeverageDetails? = nil, commandID: String = UUID().uuidString) -> DrinkCommandResult {
    if let receipt = archive.commands[commandID] { return .committed(receipt) }
    guard editable(consumedAt, now: now), (10...3000).contains(volumeML),
      let index = archive.entries.firstIndex(where: { $0.id == id }) else { return .rejected }
    var next = archive; var entry = next.entries[index]
    entry.consumedAt = consumedAt; entry.volumeML = volumeML
    if let details { guard Self.valid(details) else { return .rejected }; entry.details = details }
    if let detail = entry.details {
      entry.caffeine = Int((detail.caffeineMG(volumeML: volumeML) ?? 0).rounded())
      entry.alcoholGrams = detail.alcoholGrams(volumeML: volumeML)
      entry.estimateMethod = detail.caffeineMethod.rawValue; entry.estimateVersion = 2
    }
    // Legacy estimates are historical facts, not newly inferred concentrations.
    entry.revision = max(entry.revision, next.localRevisions[id.uuidString] ?? 0) + 1
    next.entries[index] = entry; next.localRevisions[id.uuidString] = entry.revision
    let receipt = DrinkCommitReceipt(eventID: commandID, entityID: id, revision: entry.revision, committedAt: now)
    next.commands[commandID] = receipt
    return commit(next, remember: true) ? .committed(receipt) : .failed
  }
  @discardableResult func remove(_ kind: FangcunDrink, on date: Date = .now, commandID: String = UUID().uuidString) -> DrinkCommandResult {
    if let receipt = archive.commands[commandID] { return .committed(receipt) }
    guard let entry = archive.entries.last(where: { $0.kind == kind && Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return .rejected }
    return remove(id: entry.id, commandID: commandID)
  }
  @discardableResult func remove(id: UUID, commandID: String = UUID().uuidString) -> DrinkCommandResult {
    if let receipt = archive.commands[commandID] { return .committed(receipt) }
    guard let entry = archive.entries.first(where: { $0.id == id }) else { return .rejected }
    var next = archive; next.entries.removeAll { $0.id == id }
    let revision = max(entry.revision, next.localRevisions[id.uuidString] ?? 0) + 1
    next.localRevisions[id.uuidString] = revision
    let receipt = DrinkCommitReceipt(eventID: commandID, entityID: id, revision: revision, committedAt: .now)
    next.commands[commandID] = receipt
    return commit(next, remember: true) ? .committed(receipt) : .failed
  }
  var canUndo: Bool { !undoStack.isEmpty && storageMessage == nil }
  @discardableResult func undo(commandID: String = UUID().uuidString) -> DrinkCommandResult {
    if let receipt = archive.commands[commandID] { return .committed(receipt) }
    guard let previous = undoStack.last else { return .rejected }
    var next = archive
    let ids = Set(previous.map(\.id) + archive.entries.map(\.id))
    let changed = ids.filter { id in previous.first(where: { $0.id == id }) != archive.entries.first(where: { $0.id == id }) }
    guard let id = changed.first else { return .rejected }
    next.entries = previous.map { value in
      var entry = value
      if changed.contains(entry.id) {
        entry.revision = max(entry.revision, max(next.localRevisions[entry.id.uuidString] ?? 0,
          archive.entries.first(where: { $0.id == entry.id })?.revision ?? 0)) + 1
        next.localRevisions[entry.id.uuidString] = entry.revision
      }
      return entry
    }
    for id in changed where !previous.contains(where: { $0.id == id }) {
      next.localRevisions[id.uuidString] = max(next.localRevisions[id.uuidString] ?? 0,
        archive.entries.first(where: { $0.id == id })?.revision ?? 0) + 1
    }
    let receipt = DrinkCommitReceipt(eventID: commandID, entityID: id, revision: next.localRevisions[id.uuidString] ?? 1, committedAt: .now)
    next.commands[commandID] = receipt
    guard commit(next, remember: false) else { return .failed }
    undoStack.removeLast(); return .committed(receipt)
  }
  static func defaultDetails(_ kind: FangcunDrink, caffeine: Int) -> BeverageDetails {
    .init(displayName: kind.title,
      caffeinePresence: kind.isCoffee ? (caffeine == 0 ? .no : .yes) : kind == .tea || kind == .other ? .unknown : .no,
      caffeineMethod: kind == .tea || kind == .other ? .unknown : .perServing,
      caffeineDose: kind.isCoffee ? Double(min(1000, max(0, caffeine))) : kind == .tea || kind == .other ? nil : 0,
      alcoholPresence: kind == .beer || kind == .alcohol ? .yes : kind == .other ? .unknown : .no,
      abvPercent: kind == .beer ? 5 : nil)
  }
  private static func valid(_ detail: BeverageDetails) -> Bool {
    !detail.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && detail.displayName.count <= 80
      && (detail.caffeineDose.map { $0.isFinite && (0...2000).contains($0) } ?? true)
      && (detail.abvPercent.map { $0.isFinite && (0...100).contains($0) } ?? true)
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
        entry.details = value.beverageDetails
        if entry.details != nil { entry.details?.origin = "remote" }
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
      sugarGrams: sugarGrams, estimateMethod: estimateMethod, estimateVersion: estimateVersion, beverageDetails: details)
  }
}

struct DrinkCommitReceipt: Codable, Equatable {
  var eventID: String
  var entityID: UUID
  var revision: Int
  var committedAt: Date
}
enum DrinkCommandResult: Equatable {
  case committed(DrinkCommitReceipt), rejected, failed
  var receipt: DrinkCommitReceipt? { if case let .committed(value) = self { value } else { nil } }
}
extension FangcunDrinkEntry {
  var beverage: BeverageEvent {
    .init(id: id.uuidString, revision: revision, categoryCode: kind.rawValue, displayName: displayName,
      consumedAt: consumedAt, recordedAt: recordedAt, volumeML: volumeML,
      caffeineMG: details.map { $0.caffeineMG(volumeML: volumeML) } ?? Double(caffeine),
      caffeinePresence: details?.caffeinePresence ?? (caffeine > 0 ? .yes : .no),
      alcoholGrams: alcoholGrams, alcoholPresence: details?.alcoholPresence ?? (alcoholGrams == nil ? .unknown : (alcoholGrams! > 0 ? .yes : .no)),
      abvPercent: details?.abvPercent, sugarServings: sugarServings, sugarGrams: sugarGrams,
      estimateMethod: estimateMethod, estimateVersion: estimateVersion, origin: details?.origin ?? "legacy")
  }
}
