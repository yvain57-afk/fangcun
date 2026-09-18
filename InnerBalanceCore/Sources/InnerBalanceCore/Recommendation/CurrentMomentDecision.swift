import Foundation

public enum CurrentStressLevel: String, CaseIterable, Codable, Hashable, Sendable {
  case low
  case moderate
  case high
}

public enum CurrentStressSource: String, CaseIterable, Codable, Hashable, Sendable {
  case none
  case work
  case tasks
  case health
  case family
  case relationship
  case money
  case training
  case sleep
  case physicalTension
  case mentalLoad
  case lowEnergy
  case bodySignals
}

public struct CurrentStressProfile: Equatable, Hashable, Codable, Sendable {
  public let level: CurrentStressLevel
  public let source: CurrentStressSource

  public init(level: CurrentStressLevel, source: CurrentStressSource) {
    self.level = level
    self.source = source
  }
}

public enum CurrentStressAssessmentBasis: String, Codable, Hashable, Sendable {
  case selfReport
  case bodyData
  case needsInput
}

public struct CurrentMomentQuickState: Equatable, Sendable {
  public let state: DailyEchoState
  public let recordedAt: Date

  public init(state: DailyEchoState, recordedAt: Date) {
    self.state = state
    self.recordedAt = recordedAt
  }
}

public struct CurrentMomentDetailedState: Equatable, Sendable {
  public let valence: Double
  public let arousal: Double
  public let emotion: EmotionLabel?
  public let recordedAt: Date
  public let stressSources: [CurrentStressSource]
  public let bodySensationCodes: [String]

  public init(
    valence: Double,
    arousal: Double,
    emotion: EmotionLabel?,
    recordedAt: Date,
    stressSources: [CurrentStressSource] = [],
    bodySensationCodes: [String] = []
  ) {
    self.valence = valence
    self.arousal = arousal
    self.emotion = emotion
    self.recordedAt = recordedAt
    self.stressSources = stressSources
    self.bodySensationCodes = bodySensationCodes
  }
}

public enum CurrentMomentSource: Equatable, Sendable {
  case none
  case quick(DailyEchoState)
  case detailed(CurrentMomentDetailedState)
}

public struct CurrentMomentDecision: Equatable, Sendable {
  public let source: CurrentMomentSource
  public let assessmentBasis: CurrentStressAssessmentBasis
  public let stressProfile: CurrentStressProfile
  public let recommendation: PracticeKind?
  public let reflectionEcho: DailyEchoState
  public let reasonCode: String
  public let ruleVersion: String
}

public enum CurrentMomentDecisionEngine {
  public static let ruleVersion = "fangcun-stress-response-v2"

  public static func decide(
    quick: CurrentMomentQuickState?,
    detailed: CurrentMomentDetailedState?,
    bodyLoadLevel: BodyLoadLevel,
    bodyStressSource: CurrentStressSource? = nil,
    now: Date,
    calendar: Calendar = .current
  ) -> CurrentMomentDecision {
    let activeQuick = quick.flatMap {
      isActive(recordedAt: $0.recordedAt, now: now, calendar: calendar) ? $0 : nil
    }
    let activeDetailed = detailed.flatMap {
      isActive(recordedAt: $0.recordedAt, now: now, calendar: calendar) ? $0 : nil
    }

    if let activeDetailed,
      activeQuick.map({ activeDetailed.recordedAt >= $0.recordedAt }) ?? true
    {
      let level = stressLevel(for: activeDetailed)
      let stressSource = stressSource(
        for: activeDetailed,
        bodyStressSource: bodyStressSource
      )
      return makeDecision(
        source: .detailed(activeDetailed),
        assessmentBasis: .selfReport,
        level: level,
        stressSource: stressSource,
        reflectionEcho: reflectionEcho(
          level: level,
          source: stressSource,
          detailed: activeDetailed
        )
      )
    }

    if let activeQuick {
      let level = stressLevel(for: activeQuick.state)
      let stressSource = bodyStressSource ?? fallbackSource(for: activeQuick.state)
      return makeDecision(
        source: .quick(activeQuick.state),
        assessmentBasis: .selfReport,
        level: level,
        stressSource: stressSource,
        reflectionEcho: activeQuick.state
      )
    }

    guard bodyLoadLevel != .buildingBaseline else {
      return CurrentMomentDecision(
        source: .none,
        assessmentBasis: .needsInput,
        stressProfile: CurrentStressProfile(level: .low, source: .none),
        recommendation: nil,
        reflectionEcho: .calm,
        reasonCode: "stress.needsInput",
        ruleVersion: ruleVersion
      )
    }

    let level = stressLevel(for: bodyLoadLevel)
    let stressSource = bodyStressSource ?? .none
    return makeDecision(
      source: .none,
      assessmentBasis: .bodyData,
      level: level,
      stressSource: stressSource,
      reflectionEcho: reflectionEcho(
        level: level,
        source: stressSource,
        detailed: nil
      )
    )
  }

  private static func makeDecision(
    source: CurrentMomentSource,
    assessmentBasis: CurrentStressAssessmentBasis,
    level: CurrentStressLevel,
    stressSource: CurrentStressSource,
    reflectionEcho: DailyEchoState
  ) -> CurrentMomentDecision {
    let practice = recommendedPractice(level: level, source: stressSource)
    return CurrentMomentDecision(
      source: source,
      assessmentBasis: assessmentBasis,
      stressProfile: CurrentStressProfile(level: level, source: stressSource),
      recommendation: practice,
      reflectionEcho: reflectionEcho,
      reasonCode: "stress.\(level.rawValue).\(stressSource.rawValue).\(practice.rawValue)",
      ruleVersion: ruleVersion
    )
  }

  private static func stressLevel(for state: DailyEchoState) -> CurrentStressLevel {
    switch state {
    case .calm, .clear, .moved:
      .low
    case .tired, .uncertain:
      .moderate
    case .tense:
      .high
    }
  }

  private static func stressLevel(
    for detailed: CurrentMomentDetailedState
  ) -> CurrentStressLevel {
    let quadrant = EmotionCatalog.quadrant(
      valence: detailed.valence,
      arousal: detailed.arousal
    )
    var level: CurrentStressLevel =
      switch quadrant {
      case .highActivationPositive, .lowActivationPositive:
        .low
      case .lowActivationNegative, .neutral:
        .moderate
      case .highActivationNegative:
        .high
      }

    switch detailed.emotion {
    case .stressed, .overwhelmed:
      level = higher(level, .high)
    case .anxious, .scared, .worried, .drained, .hopeless:
      level = higher(level, .moderate)
    default:
      break
    }
    return level
  }

  private static func stressLevel(for bodyLoadLevel: BodyLoadLevel) -> CurrentStressLevel {
    switch bodyLoadLevel {
    case .buildingBaseline, .steady:
      .low
    case .watch:
      .moderate
    case .elevated:
      .high
    }
  }

  private static func higher(
    _ lhs: CurrentStressLevel,
    _ rhs: CurrentStressLevel
  ) -> CurrentStressLevel {
    rank(lhs) >= rank(rhs) ? lhs : rhs
  }

  private static func rank(_ level: CurrentStressLevel) -> Int {
    switch level {
    case .low: 0
    case .moderate: 1
    case .high: 2
    }
  }

  private static func stressSource(
    for detailed: CurrentMomentDetailedState,
    bodyStressSource: CurrentStressSource?
  ) -> CurrentStressSource {
    if let explicitSource = detailed.stressSources.first {
      return explicitSource
    }

    let sensations = Set(detailed.bodySensationCodes.map { $0.lowercased() })
    if !sensations.isDisjoint(with: ["fatigue", "heavy_head"]) {
      return .lowEnergy
    }
    if !sensations.isDisjoint(
      with: ["shoulders_tight", "chest_tight", "stomach_discomfort", "shallow_breath"]
    ) {
      return .physicalTension
    }
    if let bodyStressSource {
      return bodyStressSource
    }
    return fallbackSource(for: detailed)
  }

  private static func fallbackSource(for state: DailyEchoState) -> CurrentStressSource {
    switch state {
    case .tense:
      .physicalTension
    case .tired:
      .lowEnergy
    case .uncertain:
      .mentalLoad
    case .calm, .clear, .moved:
      .none
    }
  }

  private static func fallbackSource(
    for detailed: CurrentMomentDetailedState
  ) -> CurrentStressSource {
    switch EmotionCatalog.quadrant(
      valence: detailed.valence,
      arousal: detailed.arousal
    ) {
    case .highActivationNegative:
      .physicalTension
    case .lowActivationNegative:
      .lowEnergy
    case .neutral:
      .mentalLoad
    case .highActivationPositive, .lowActivationPositive:
      .none
    }
  }

  private static func recommendedPractice(
    level: CurrentStressLevel,
    source: CurrentStressSource
  ) -> PracticeKind {
    switch source {
    case .sleep, .lowEnergy:
      .nsdr
    case .training:
      level == .low ? .pacedBreathing : .nsdr
    case .physicalTension:
      .physiologicalSigh
    case .work, .tasks, .money:
      level == .high ? .physiologicalSigh : .pacedBreathing
    case .family, .relationship:
      level == .high ? .physiologicalSigh : .meditation
    case .health, .bodySignals:
      level == .high ? .physiologicalSigh : .pacedBreathing
    case .mentalLoad, .none:
      switch level {
      case .low: .meditation
      case .moderate: .pacedBreathing
      case .high: .physiologicalSigh
      }
    }
  }

  private static func reflectionEcho(
    level: CurrentStressLevel,
    source: CurrentStressSource,
    detailed: CurrentMomentDetailedState?
  ) -> DailyEchoState {
    switch source {
    case .work, .tasks, .money:
      return level == .low ? .clear : .tense
    case .family, .relationship:
      return level == .low ? .moved : .tense
    case .training, .sleep, .lowEnergy:
      return .tired
    case .physicalTension, .health, .bodySignals:
      return level == .high ? .tense : .tired
    case .mentalLoad:
      switch level {
      case .low: return .clear
      case .moderate: return .uncertain
      case .high: return .tense
      }
    case .none:
      if let detailed {
        return
          switch EmotionCatalog.quadrant(
            valence: detailed.valence,
            arousal: detailed.arousal
          )
        {
        case .highActivationPositive: .moved
        case .lowActivationPositive: .calm
        case .highActivationNegative: .tense
        case .lowActivationNegative: .tired
        case .neutral: .uncertain
        }
      }
      return switch level {
      case .low: .calm
      case .moderate: .uncertain
      case .high: .tense
      }
    }
  }

  private static func isActive(
    recordedAt: Date,
    now: Date,
    calendar: Calendar
  ) -> Bool {
    recordedAt <= now && calendar.isDate(recordedAt, inSameDayAs: now)
  }
}
