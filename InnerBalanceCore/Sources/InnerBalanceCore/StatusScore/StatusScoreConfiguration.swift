import Foundation

/// Product rules, not clinically validated thresholds. Independent of legacy readiness-v1.
public struct StatusScoreConfiguration: Codable, Equatable, Sendable {
  public var modelVersion = "fangcun-status-3.0"
  public var qualityPolicyVersion = "status-quality-3.0-gap60"
  public var sleepGoalMinutes = 480.0
  public var regularityEnabled = true
  public var sleepWeight = 0.60
  public var hrvWeight = 0.25
  public var rhrWeight = 0.15
  public var durationWeight = 0.70
  public var continuityWeight = 0.20
  public var regularityWeight = 0.10
  public var minimumHistoryDays = 3
  public var fullHistoryDays = 14
  public var baselineDays = 28
  public var regularityCycles = 14
  public var regularityZeroMinutes = 120.0
  public var hrvFullSamples = 3
  public var hrvFullHours = 2
  public var madMultiplier = 1.4826
  public var hrvScaleFloor = 0.10
  public var rhrScaleFloor = 3.0
  public var nominalCardioScore = 85.0
  public var adverseMultiplier = 15.0
  public var benefitMultiplier = 5.0
  public var maxBenefitZ = 1.0
  public var maxCardioScore = 95.0
  public var highHRVExclusionZ = -2.0
  public var currentHours = 18.0
  public var validHours = 24.0
  public init(sleepGoalMinutes: Double = 480, regularityEnabled: Bool = true) {
    self.sleepGoalMinutes = sleepGoalMinutes; self.regularityEnabled = regularityEnabled
  }
  public var isValid: Bool {
    modelVersion == "fangcun-status-3.0" && (420...600).contains(sleepGoalMinutes)
      && [sleepWeight,hrvWeight,rhrWeight,durationWeight,continuityWeight,regularityWeight,
        regularityZeroMinutes,madMultiplier,hrvScaleFloor,rhrScaleFloor,adverseMultiplier,
        benefitMultiplier,maxBenefitZ,maxCardioScore,currentHours,validHours].allSatisfy { $0.isFinite && $0 > 0 }
      && nominalCardioScore.isFinite && highHRVExclusionZ.isFinite
      && minimumHistoryDays >= 3 && fullHistoryDays >= minimumHistoryDays && baselineDays >= fullHistoryDays
      && regularityCycles >= 3 && hrvFullSamples > 0 && hrvFullHours > 0 && validHours > currentHours
  }
}
public typealias DailyStatusScoreConfiguration = StatusScoreConfiguration

public enum StatusBand: String, Codable, Sendable, CaseIterable {
  case good, fair, low, rest
  public var title: String { switch self { case .good: "良好"; case .fair: "尚可"; case .low: "偏低"; case .rest: "优先休息" } }
  public static func resolve(_ score: Int) -> Self? {
    guard (0...100).contains(score) else { return nil }
    return score >= 85 ? .good : score >= 70 ? .fair : score >= 50 ? .low : .rest
  }
}

public struct StatusScoreInput: Codable, Equatable, Sendable {
  public var sleepMinutes: Double?
  public var sleepUsable = true
  public var awakeMinutes: Double?
  public var awakeCoverageComplete = false
  public var regularityDeltaMinutes: Double?
  public var regularityHistoryDays = 0
  public var hrvDeviation: Double?
  public var hrvDays = 0
  public var hrvSamples = 0
  public var hrvHours = 0
  public var hrvUsable = true
  public var rhrDeviation: Double?
  public var rhrDays = 0
  public var rhrUsable = true
  public init(sleepMinutes: Double? = nil) { self.sleepMinutes = sleepMinutes }
}
public struct StatusScoreComponent: Codable, Equatable, Sendable {
  public var name: String
  public var score: Double
  public var effectiveWeight: Double
  public var normalizedWeight: Double
}
public struct StatusScoreResult: Codable, Equatable, Sendable {
  public var rawScore: Double?
  public var displayScore: Int?
  public var band: StatusBand?
  public var components: [StatusScoreComponent]
  public var sleepSubscores: [String: Double]
}
public enum StatusScoreError: Error { case invalidInput, invalidConfiguration }
