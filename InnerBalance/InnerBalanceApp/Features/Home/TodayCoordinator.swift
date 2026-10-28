import Foundation
import InnerBalanceCore

enum TodayBodyContext: Equatable, Sendable {
  case loading
  case unavailable
  case buildingBaseline
  case insufficientEvidence
  case steady
  case watch
  case elevated

  static func resolve(
    accessState: HealthAccessState,
    isLoading: Bool,
    level: BodyLoadLevel,
    hasReliableEvidence: Bool
  ) -> TodayBodyContext {
    if isLoading { return .loading }
    if accessState == .unavailable || accessState == .notRequested { return .unavailable }
    if level == .buildingBaseline { return .buildingBaseline }
    if !hasReliableEvidence { return .insufficientEvidence }
    return switch level {
    case .buildingBaseline: .buildingBaseline
    case .steady: .steady
    case .watch: .watch
    case .elevated: .elevated
    }
  }

  var decisionLevel: BodyLoadLevel {
    switch self {
    case .loading, .unavailable, .buildingBaseline, .insufficientEvidence:
      .buildingBaseline
    case .steady:
      .steady
    case .watch:
      .watch
    case .elevated:
      .elevated
    }
  }

  var explanation: String {
    switch self {
    case .loading:
      "Health data is still loading."
    case .unavailable:
      "No usable health data yet. This suggestion uses only your check-in."
    case .buildingBaseline:
      "Your baseline is still building. For now, this suggestion uses your check-in."
    case .insufficientEvidence:
      "There isn't enough health data to assess body load yet."
    case .steady:
      "Recent measures are broadly within your personal range."
    case .watch:
      "One measure differs from your recent level. Consider leaving room for an easier day."
    case .elevated:
      "Two or more measures differ from your recent level. Consider prioritizing recovery today."
    }
  }

  var awaitingSelectionExplanation: String {
    switch self {
    case .loading:
      "Health data is still loading."
    case .unavailable:
      "No usable health data yet."
    case .buildingBaseline:
      "Your personal baseline is still building."
    case .insufficientEvidence:
      "There isn't enough health data yet."
    case .steady:
      "Recent measures are broadly within your personal range."
    case .watch:
      "One measure differs from your recent level."
    case .elevated:
      "Two or more measures differ from your recent level."
    }
  }
}

struct TodayViewState: Equatable, Sendable {
  let currentSource: CurrentMomentSource
  let currentStateTitle: String?
  let selectedQuickState: DailyEchoState?
  let isStressIdentified: Bool
  let stressProfile: CurrentStressProfile
  let stressLevelTitle: String
  let stressSourceRoleTitle: String
  let stressSourceTitle: String
  let reflectionContextTitle: String
  let reflection: DailyReflection
  let explanation: String
  let recommendedPractice: PracticeKind?
  let recoveryAction: TodayRecoveryAction
  let latestPractice: PracticeCompletionRecord?
  let reasonCode: String
  let ruleVersion: String
}

enum TodayRecoveryAction: Equatable, Sendable {
  case needsInput
  case continueNormally
  case practice(PracticeKind)
}

struct TodayCoordinator: Sendable {
  let calendar: Calendar

  init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  func makeViewState(
    quick: CurrentMomentQuickState?,
    detailed: CurrentMomentDetailedState?,
    bodyContext: TodayBodyContext,
    bodyStressSource: CurrentStressSource? = nil,
    latestPractice: PracticeCompletionRecord?,
    now: Date
  ) -> TodayViewState {
    let decision = CurrentMomentDecisionEngine.decide(
      quick: quick,
      detailed: detailed,
      bodyLoadLevel: bodyContext.decisionLevel,
      bodyStressSource: bodyStressSource,
      now: now,
      calendar: calendar
    )
    let currentStateTitle = title(for: decision.source)
    let selectedQuickState = quickSelection(for: decision.source)
    let isStressIdentified = decision.assessmentBasis != .needsInput
    let recoveryAction = recoveryAction(
      isStressIdentified: isStressIdentified,
      decision: decision
    )
    let recommendedPractice: PracticeKind? =
      if case .practice(let practice) = recoveryAction { practice } else { nil }
    let reflection =
      if let selectedQuickState, bodyStressSource == nil {
        DailyReflectionSelector.reflection(
          on: now,
          echo: selectedQuickState,
          calendar: calendar
        )
      } else if isStressIdentified, decision.stressProfile.source != .none {
        DailyReflectionSelector.reflection(
          on: now,
          stressProfile: decision.stressProfile,
          calendar: calendar
        )
      } else {
        DailyReflectionSelector.reflection(
          on: now,
          echo: decision.reflectionEcho,
          calendar: calendar
        )
      }
    let currentPractice = latestPractice.flatMap {
      calendar.isDate($0.endedAt, inSameDayAs: now) ? $0 : nil
    }

    return TodayViewState(
      currentSource: decision.source,
      currentStateTitle: currentStateTitle,
      selectedQuickState: selectedQuickState,
      isStressIdentified: isStressIdentified,
      stressProfile: decision.stressProfile,
      stressLevelTitle: isStressIdentified
        ? stressLevelTitle(for: decision.stressProfile.level) : "No check-in yet",
      stressSourceRoleTitle: stressSourceRoleTitle(for: decision.stressProfile.source),
      stressSourceTitle: isStressIdentified
        ? stressSourceTitle(for: decision.stressProfile.source) : "Source not specified",
      reflectionContextTitle: reflectionContextTitle(for: decision.stressProfile),
      reflection: reflection,
      explanation: isStressIdentified
        ? guidance(for: decision.stressProfile) : "Start with how you feel right now.",
      recommendedPractice: recommendedPractice,
      recoveryAction: recoveryAction,
      latestPractice: currentPractice,
      reasonCode: decision.reasonCode,
      ruleVersion: decision.ruleVersion
    )
  }

  private func recoveryAction(
    isStressIdentified: Bool,
    decision: CurrentMomentDecision
  ) -> TodayRecoveryAction {
    guard isStressIdentified else { return .needsInput }
    if decision.stressProfile.level == .low {
      return .continueNormally
    }
    guard let practice = decision.recommendation else { return .needsInput }
    return .practice(practice)
  }

  private func title(for source: CurrentMomentSource) -> String? {
    switch source {
    case .none:
      nil
    case .quick(let state):
      state.title
    case .detailed(let state):
      state.emotion?.displayName ?? "Check-in saved"
    }
  }

  private func quickSelection(for source: CurrentMomentSource) -> DailyEchoState? {
    guard case .quick(let state) = source else { return nil }
    return state
  }

  private func stressLevelTitle(for level: CurrentStressLevel) -> String {
    switch level {
    case .low: "Lower reported pressure"
    case .moderate: "Some reported pressure"
    case .high: "Higher reported pressure"
    }
  }

  private func stressSourceTitle(for source: CurrentStressSource) -> String {
    switch source {
    case .none: "No clear source"
    case .work: "Work"
    case .tasks: "Too much to do"
    case .health: "Physical discomfort"
    case .family: "Family"
    case .relationship: "Relationships"
    case .money: "Money"
    case .training: "Exercise recovery"
    case .sleep: "Not enough sleep"
    case .physicalTension: "Physical tension"
    case .mentalLoad: "Thoughts and feelings"
    case .lowEnergy: "Low energy"
    case .bodySignals: "Recovery"
    }
  }

  private func stressSourceRoleTitle(for source: CurrentStressSource) -> String {
    switch source {
    case .work, .tasks, .health, .family, .relationship, .money, .training, .sleep:
      "Mostly connected to"
    case .physicalTension, .mentalLoad, .lowEnergy, .bodySignals:
      "Showing up as"
    case .none:
      "What's on your mind"
    }
  }

  private func reflectionContextTitle(for profile: CurrentStressProfile) -> String {
    switch profile.source {
    case .none:
      return "A thought for this moment"
    case .physicalTension:
      return "A thought for a tense moment"
    case .mentalLoad:
      return "A thought for a busy mind"
    case .lowEnergy:
      return "A thought for a tired day"
    case .bodySignals:
      return "A thought for recovery"
    default:
      return "A thought about \(stressSourceTitle(for: profile.source))"
    }
  }

  private func guidance(for profile: CurrentStressProfile) -> String {
    if profile.level == .low {
      return "Things feel steady. There's no need to add anything."
    }
    switch profile.source {
    case .sleep:
      return "Sleep may be affecting recovery. A little rest could be useful."
    case .training:
      return "You may still be recovering from exercise. Consider an easier day."
    case .lowEnergy:
      return "Your energy feels low. You might like to lie down for a while."
    case .work, .tasks, .money:
      return profile.level == .high
        ? "You're feeling tense. Start with a small pause."
        : "There's a lot on your mind. A gentle breathing break might help."
    case .family, .relationship:
      return "This matters to you. Make a few minutes for yourself, if you can."
    case .health, .physicalTension, .bodySignals:
      return profile.level == .high
        ? "You're noticing tension in your body. Take a small pause."
        : "Your body feels busy. You might try slowing the pace."
    case .mentalLoad:
      return profile.level == .high
        ? "You're feeling tense. Start with a small pause."
        : "Your mind feels full. Try a few easier breaths."
    case .none:
      return switch profile.level {
      case .low: "Things feel steady. There's no need to add anything."
      case .moderate: "Things have been building up. You might like three minutes to unwind."
      case .high: "You're feeling tense. Start with a small pause."
      }
    }
  }
}

enum TodayRecordPresentation {
  static func includes(
    eventDate: Date?,
    now: Date,
    calendar: Calendar = .current
  ) -> Bool {
    guard let eventDate else { return false }
    return calendar.isDate(eventDate, inSameDayAs: now)
  }
}
