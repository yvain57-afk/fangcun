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
  var id = UUID()
  let date: Date
  let kind: FangcunDrink
  let caffeine: Int
}

struct FangcunDaySnapshot: Codable, Identifiable {
  let date: Date
  let state: FangcunDayState
  let summary: String
  let sleep: String
  let training: String
  /// Missing in original archives. Those snapshots retain their original interpretation.
  let semanticsVersion: Int?
  var id: Date { date }
  var isLegacy: Bool { semanticsVersion == nil }
  var displayStateTitle: String {
    guard isLegacy else { return state.shortTitle }
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
  private struct Archive: Codable {
    var entries: [FangcunDrinkEntry] = []
    var snapshots: [FangcunDaySnapshot] = []
  }
  private var archive = Archive()
  private var undoStack: [[FangcunDrinkEntry]] = []
  private let defaults: UserDefaults
  private let key = "fangcun.native.diary.v1"
  private(set) var storageMessage: String?

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if let data = defaults.data(forKey: key) {
      do { archive = try JSONDecoder().decode(Archive.self, from: data) }
      catch { storageMessage = "本机记录暂时无法读取，原始数据已保留。" }
    }
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
  func add(_ kind: FangcunDrink, caffeine: Int = 140, at date: Date = .now) {
    guard storageMessage == nil, entries(on: date).count < 1000 else { return }
    remember()
    archive.entries.append(FangcunDrinkEntry(date: date, kind: kind, caffeine: kind.isCoffee ? min(500, max(0, caffeine)) : 0))
    save()
  }
  func remove(_ kind: FangcunDrink, on date: Date = .now) {
    guard storageMessage == nil, let index = archive.entries.lastIndex(where: { $0.kind == kind && Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }
    remember(); archive.entries.remove(at: index); save()
  }
  var canUndo: Bool { !undoStack.isEmpty && storageMessage == nil }
  func undo() {
    guard storageMessage == nil, let previous = undoStack.popLast() else { return }
    archive.entries = previous; save()
  }
  func record(_ snapshot: FangcunDaySnapshot) {
    guard storageMessage == nil else { return }
    archive.snapshots.removeAll { !$0.isLegacy && Calendar.current.isDate($0.date, inSameDayAs: snapshot.date) }
    archive.snapshots.append(snapshot); save()
  }
  private func remember() { undoStack.append(archive.entries); if undoStack.count > 50 { undoStack.removeFirst() } }
  private func save() {
    do {
      let data = try JSONEncoder().encode(archive)
      if defaults.data(forKey: "fangcun.native.diary.preM1") == nil,
        let original = defaults.data(forKey: key) {
        defaults.set(original, forKey: "fangcun.native.diary.preM1")
      }
      defaults.set(data, forKey: key)
    }
    catch { storageMessage = "记录暂时未能保存，请稍后再试。" }
  }
}

struct FangcunDrinkTotals {
  let fluid: Int, caffeine: Int, alcohol: Int, sugar: Int
  init(_ entries: [FangcunDrinkEntry]) {
    fluid = entries.reduce(0) { $0 + $1.kind.fluid }
    caffeine = entries.reduce(0) { $0 + $1.caffeine }
    alcohol = entries.reduce(0) { $0 + $1.kind.alcohol }
    sugar = entries.reduce(0) { $0 + $1.kind.sugar }
  }
}
