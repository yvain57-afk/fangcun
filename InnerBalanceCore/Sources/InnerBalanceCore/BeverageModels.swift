import Foundation

public enum BeveragePresence: String, Codable, Sendable { case yes, no, unknown }
public enum BeverageDoseMethod: String, Codable, CaseIterable, Sendable { case perServing, per100ML, unknown, legacyEstimate }
public struct BeverageDetails: Codable, Equatable, Sendable {
  public var displayName: String
  public var caffeinePresence: BeveragePresence
  public var caffeineMethod: BeverageDoseMethod
  public var caffeineDose: Double?
  public var alcoholPresence: BeveragePresence
  public var abvPercent: Double?
  public var origin: String
  public init(displayName: String, caffeinePresence: BeveragePresence = .no, caffeineMethod: BeverageDoseMethod = .perServing,
    caffeineDose: Double? = 0, alcoholPresence: BeveragePresence = .no, abvPercent: Double? = nil, origin: String = "local") {
    self.displayName = displayName; self.caffeinePresence = caffeinePresence; self.caffeineMethod = caffeineMethod
    self.caffeineDose = caffeineDose; self.alcoholPresence = alcoholPresence; self.abvPercent = abvPercent; self.origin = origin
  }
  public func caffeineMG(volumeML: Int) -> Double? {
    guard caffeinePresence != .no else { return 0 }
    guard caffeinePresence == .yes, let caffeineDose, caffeineDose.isFinite, caffeineDose >= 0, caffeineMethod != .unknown else { return nil }
    return caffeineMethod == .per100ML ? caffeineDose * Double(volumeML) / 100 : caffeineDose
  }
  public func alcoholGrams(volumeML: Int) -> Double? {
    guard alcoholPresence != .no else { return 0 }
    guard alcoholPresence == .yes, let abvPercent, abvPercent.isFinite, (0...100).contains(abvPercent) else { return nil }
    return Double(volumeML) * abvPercent / 100 * 0.789
  }
}
/// Immutable projection of the authoritative diary, never a second writable record store.
public struct BeverageEvent: Codable, Equatable, Sendable {
  public var id: String
  public var revision: Int
  public var categoryCode: String
  public var displayName: String
  public var consumedAt: Date
  public var recordedAt: Date?
  public var volumeML: Int
  public var caffeineMG: Double?
  public var caffeinePresence: BeveragePresence
  public var alcoholGrams: Double?
  public var alcoholPresence: BeveragePresence
  public var abvPercent: Double?
  public var sugarServings: Double
  public var sugarGrams: Double?
  public var estimateMethod: String
  public var estimateVersion: Int
  public var origin: String
  public var deleted: Bool
  public init(id: String, revision: Int = 1, categoryCode: String = "water", displayName: String = "",
    consumedAt: Date, recordedAt: Date? = nil, volumeML: Int = 250, caffeineMG: Double? = 0,
    caffeinePresence: BeveragePresence = .no, alcoholGrams: Double? = 0, alcoholPresence: BeveragePresence = .no,
    abvPercent: Double? = nil, sugarServings: Double = 0, sugarGrams: Double? = nil,
    estimateMethod: String = "perServing", estimateVersion: Int = 2, origin: String = "local", deleted: Bool = false) {
    self.id = id; self.revision = revision; self.categoryCode = categoryCode; self.displayName = displayName
    self.consumedAt = consumedAt; self.recordedAt = recordedAt; self.volumeML = volumeML
    self.caffeineMG = caffeineMG; self.caffeinePresence = caffeinePresence; self.alcoholGrams = alcoholGrams
    self.alcoholPresence = alcoholPresence; self.abvPercent = abvPercent; self.sugarServings = sugarServings
    self.sugarGrams = sugarGrams; self.estimateMethod = estimateMethod; self.estimateVersion = estimateVersion
    self.origin = origin; self.deleted = deleted
  }
  public var basisID: String { id + ":" + String(revision) }
}
public struct BeverageTotals: Equatable, Sendable {
  public var allBeverageML = 0
  public var nonAlcoholBeverageML = 0
  public var plainWaterML = 0
  public var knownCaffeineMG = 0.0
  public var knownAlcoholGrams = 0.0
  public var hasUnknownCaffeine = false
  public var hasUnknownAlcohol = false
  public init(_ events: [BeverageEvent]) {
    for e in events where !e.deleted {
      allBeverageML += e.volumeML
      if e.alcoholPresence == .no { nonAlcoholBeverageML += e.volumeML }
      if e.categoryCode == "water" { plainWaterML += e.volumeML }
      knownCaffeineMG += e.caffeineMG ?? 0; knownAlcoholGrams += e.alcoholGrams ?? 0
      hasUnknownCaffeine = hasUnknownCaffeine || (e.caffeinePresence != .no && e.caffeineMG == nil)
      hasUnknownAlcohol = hasUnknownAlcohol || (e.alcoholPresence != .no && e.alcoholGrams == nil)
    }
  }
}
