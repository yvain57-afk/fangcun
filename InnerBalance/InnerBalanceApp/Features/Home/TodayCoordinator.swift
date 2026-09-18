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
      "身体数据还在读取。"
    case .unavailable:
      "目前没有可用的身体数据，这次只按你的状态推荐。"
    case .buildingBaseline:
      "个人参考还在建立，这次先按你的状态推荐。"
    case .insufficientEvidence:
      "现有身体数据还不够，暂时不判断身体负荷。"
    case .steady:
      "近期身体指标大致在你的个人范围内。"
    case .watch:
      "有一项身体指标偏离近期水平，今天别把强度拉满。"
    case .elevated:
      "有两项以上身体指标偏离近期水平，今天先把恢复放前面。"
    }
  }

  var awaitingSelectionExplanation: String {
    switch self {
    case .loading:
      "身体数据还在读取。"
    case .unavailable:
      "目前没有可用的身体数据。"
    case .buildingBaseline:
      "个人参考还在建立。"
    case .insufficientEvidence:
      "现有身体数据还不够。"
    case .steady:
      "近期身体指标大致在你的个人范围内。"
    case .watch:
      "有一项身体指标偏离近期水平。"
    case .elevated:
      "有两项以上身体指标偏离近期水平。"
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
        ? stressLevelTitle(for: decision.stressProfile.level) : "还没判断",
      stressSourceRoleTitle: stressSourceRoleTitle(for: decision.stressProfile.source),
      stressSourceTitle: isStressIdentified
        ? stressSourceTitle(for: decision.stressProfile.source) : "来源待确认",
      reflectionContextTitle: reflectionContextTitle(for: decision.stressProfile),
      reflection: reflection,
      explanation: isStressIdentified
        ? guidance(for: decision.stressProfile) : "选一下现在的状态，我马上给你结论。",
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
      state.emotion?.displayName ?? "罗盘已记录"
    }
  }

  private func quickSelection(for source: CurrentMomentSource) -> DailyEchoState? {
    guard case .quick(let state) = source else { return nil }
    return state
  }

  private func stressLevelTitle(for level: CurrentStressLevel) -> String {
    switch level {
    case .low: "压力较低"
    case .moderate: "压力中等"
    case .high: "压力较高"
    }
  }

  private func stressSourceTitle(for source: CurrentStressSource) -> String {
    switch source {
    case .none: "没有明显来源"
    case .work: "工作"
    case .tasks: "待办太多"
    case .health: "身体不适"
    case .family: "家庭"
    case .relationship: "关系"
    case .money: "金钱"
    case .training: "训练恢复"
    case .sleep: "睡眠不足"
    case .physicalTension: "身体持续紧绷"
    case .mentalLoad: "思绪和情绪"
    case .lowEnergy: "精力消耗"
    case .bodySignals: "身体恢复"
    }
  }

  private func stressSourceRoleTitle(for source: CurrentStressSource) -> String {
    switch source {
    case .work, .tasks, .health, .family, .relationship, .money, .training, .sleep:
      "主要来自"
    case .physicalTension, .mentalLoad, .lowEnergy, .bodySignals:
      "主要表现"
    case .none:
      "压力来源"
    }
  }

  private func reflectionContextTitle(for profile: CurrentStressProfile) -> String {
    switch profile.source {
    case .none:
      return "此刻的一句"
    case .physicalTension:
      return "给此刻紧绷的一句"
    case .mentalLoad:
      return "给纷乱思绪的一句"
    case .lowEnergy:
      return "给疲惫的一句"
    case .bodySignals:
      return "给身体恢复的一句"
    default:
      return "给「\(stressSourceTitle(for: profile.source))」的一句"
    }
  }

  private func guidance(for profile: CurrentStressProfile) -> String {
    if profile.level == .low {
      return "现在状态稳，照常往下走。"
    }
    switch profile.source {
    case .sleep:
      return "睡眠正在拖累恢复，先补一段休息。"
    case .training:
      return "训练后的恢复还没跟上，今天先减量。"
    case .lowEnergy:
      return "精力已经掉下来，先躺下休息一会儿。"
    case .work, .tasks, .money:
      return profile.level == .high
        ? "紧绷已经很明显，现在先停一分钟。"
        : "事情正在占满注意力，先把呼吸慢下来。"
    case .family, .relationship:
      return "这件事正在牵动你，先留几分钟给自己。"
    case .health, .physicalTension, .bodySignals:
      return profile.level == .high
        ? "身体的紧绷已经很明显，现在先停一下。"
        : "身体正在持续用力，先把节奏放慢。"
    case .mentalLoad:
      return profile.level == .high
        ? "紧绷已经很明显，现在先停一分钟。"
        : "思绪有点满，先把呼吸慢下来。"
    case .none:
      return switch profile.level {
      case .low: "现在状态稳，照常往下走。"
      case .moderate: "压力已经有些累积，先缓三分钟。"
      case .high: "紧绷已经很明显，现在先停一分钟。"
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
