import Foundation
import Testing

@testable import InnerBalanceCore

@Suite("Current moment stress decision")
struct CurrentMomentDecisionTests {
  @Test("A newer detailed check-in replaces the quick state")
  func newerDetailedCheckInWins() {
    let now = date(day: 29, hour: 12)
    let detailed = CurrentMomentDetailedState(
      valence: -0.8,
      arousal: 0.9,
      emotion: .stressed,
      recordedAt: date(day: 29, hour: 11),
      stressSources: [.work]
    )

    let decision = CurrentMomentDecisionEngine.decide(
      quick: CurrentMomentQuickState(
        state: .calm,
        recordedAt: date(day: 29, hour: 10)
      ),
      detailed: detailed,
      bodyLoadLevel: .steady,
      now: now,
      calendar: calendar
    )

    #expect(decision.source == .detailed(detailed))
    #expect(decision.assessmentBasis == .selfReport)
    #expect(decision.stressProfile == CurrentStressProfile(level: .high, source: .work))
    #expect(decision.recommendation == .physiologicalSigh)
    #expect(decision.reflectionEcho == .tense)
    #expect(decision.reasonCode == "stress.high.work.physiologicalSigh")
  }

  @Test("A newer quick state replaces the detailed check-in")
  func newerQuickStateWins() {
    let now = date(day: 29, hour: 12)

    let decision = CurrentMomentDecisionEngine.decide(
      quick: CurrentMomentQuickState(
        state: .calm,
        recordedAt: date(day: 29, hour: 11)
      ),
      detailed: CurrentMomentDetailedState(
        valence: -0.8,
        arousal: 0.9,
        emotion: .stressed,
        recordedAt: date(day: 29, hour: 10)
      ),
      bodyLoadLevel: .elevated,
      now: now,
      calendar: calendar
    )

    #expect(decision.source == .quick(.calm))
    #expect(decision.assessmentBasis == .selfReport)
    #expect(decision.stressProfile == CurrentStressProfile(level: .low, source: .none))
    #expect(decision.recommendation == .meditation)
    #expect(decision.reflectionEcho == .calm)
  }

  @Test("A detailed check-in wins when timestamps are equal")
  func equalTimestampsPreferDetailedCheckIn() {
    let timestamp = date(day: 29, hour: 11)
    let detailed = CurrentMomentDetailedState(
      valence: -0.7,
      arousal: 0.8,
      emotion: .anxious,
      recordedAt: timestamp,
      stressSources: [.relationship]
    )

    let decision = CurrentMomentDecisionEngine.decide(
      quick: CurrentMomentQuickState(state: .tired, recordedAt: timestamp),
      detailed: detailed,
      bodyLoadLevel: .watch,
      now: date(day: 29, hour: 12),
      calendar: calendar
    )

    #expect(decision.source == .detailed(detailed))
    #expect(decision.stressProfile == CurrentStressProfile(level: .high, source: .relationship))
    #expect(decision.recommendation == .physiologicalSigh)
  }

  @Test("All six quick states produce a definite targeted response")
  func quickStatesProduceDefiniteResponses() {
    let expectations: [(DailyEchoState, CurrentStressLevel, CurrentStressSource, PracticeKind)] = [
      (.calm, .low, .none, .meditation),
      (.clear, .low, .none, .meditation),
      (.moved, .low, .none, .meditation),
      (.tense, .high, .physicalTension, .physiologicalSigh),
      (.tired, .moderate, .lowEnergy, .nsdr),
      (.uncertain, .moderate, .mentalLoad, .pacedBreathing),
    ]

    for (state, level, source, practice) in expectations {
      let decision = CurrentMomentDecisionEngine.decide(
        quick: CurrentMomentQuickState(
          state: state,
          recordedAt: date(day: 29, hour: 11)
        ),
        detailed: nil,
        bodyLoadLevel: .elevated,
        now: date(day: 29, hour: 12),
        calendar: calendar
      )

      #expect(decision.stressProfile == CurrentStressProfile(level: level, source: source))
      #expect(decision.recommendation == practice)
      #expect(decision.reflectionEcho == state)
      #expect(decision.recommendation != .kegel)
    }
  }

  @Test("Detailed quadrants map to a clear stress level and fallback source")
  func detailedQuadrantsMapToStress() {
    let expectations:
      [(Double, Double, CurrentStressLevel, CurrentStressSource, PracticeKind, DailyEchoState)] = [
        (0.8, 0.8, .low, .none, .meditation, .moved),
        (0.8, -0.8, .low, .none, .meditation, .calm),
        (-0.8, 0.8, .high, .physicalTension, .physiologicalSigh, .tense),
        (-0.8, -0.8, .moderate, .lowEnergy, .nsdr, .tired),
        (0, 0, .moderate, .mentalLoad, .pacedBreathing, .uncertain),
      ]

    for (valence, arousal, level, source, practice, echo) in expectations {
      let decision = CurrentMomentDecisionEngine.decide(
        quick: nil,
        detailed: CurrentMomentDetailedState(
          valence: valence,
          arousal: arousal,
          emotion: nil,
          recordedAt: date(day: 29, hour: 11)
        ),
        bodyLoadLevel: .buildingBaseline,
        now: date(day: 29, hour: 12),
        calendar: calendar
      )

      #expect(decision.stressProfile == CurrentStressProfile(level: level, source: source))
      #expect(decision.recommendation == practice)
      #expect(decision.reflectionEcho == echo)
    }
  }

  @Test("High-pressure and vulnerable emotions set a minimum stress level")
  func emotionFloorsAreApplied() {
    let highEmotions: [EmotionLabel] = [.stressed, .overwhelmed]
    let moderateEmotions: [EmotionLabel] = [.anxious, .scared, .worried, .drained, .hopeless]

    for emotion in highEmotions {
      let decision = detailedDecision(valence: 0.8, arousal: 0.8, emotion: emotion)
      #expect(decision.stressProfile.level == .high)
    }

    for emotion in moderateEmotions {
      let decision = detailedDecision(valence: 0.8, arousal: 0.8, emotion: emotion)
      #expect(decision.stressProfile.level == .moderate)
    }
  }

  @Test("A current expression owns the level even when body load is higher")
  func expressionLevelIsNotOverriddenByBodyLoad() {
    let decision = CurrentMomentDecisionEngine.decide(
      quick: CurrentMomentQuickState(
        state: .calm,
        recordedAt: date(day: 29, hour: 11)
      ),
      detailed: nil,
      bodyLoadLevel: .elevated,
      bodyStressSource: .sleep,
      now: date(day: 29, hour: 12),
      calendar: calendar
    )

    #expect(decision.stressProfile == CurrentStressProfile(level: .low, source: .sleep))
    #expect(decision.recommendation == .nsdr)
    #expect(decision.reflectionEcho == .calm)
  }

  @Test("Explicit context, sensations, and body signals use a stable source priority")
  func sourcePriorityIsStable() {
    let explicit = detailedDecision(
      valence: -0.8,
      arousal: 0.8,
      stressSources: [.work],
      bodySensationCodes: ["fatigue", "shoulders_tight"],
      bodyStressSource: .sleep
    )
    #expect(explicit.stressProfile.source == .work)

    let recoverySensation = detailedDecision(
      valence: -0.8,
      arousal: 0.8,
      bodySensationCodes: ["shoulders_tight", "heavy_head"],
      bodyStressSource: .sleep
    )
    #expect(recoverySensation.stressProfile.source == .lowEnergy)

    let tensionSensation = detailedDecision(
      valence: -0.8,
      arousal: 0.8,
      bodySensationCodes: ["chest_tight"],
      bodyStressSource: .sleep
    )
    #expect(tensionSensation.stressProfile.source == .physicalTension)

    let bodySignal = detailedDecision(
      valence: -0.8,
      arousal: 0.8,
      bodyStressSource: .training
    )
    #expect(bodySignal.stressProfile.source == .training)
  }

  @Test("Every source routes low, moderate, and high pressure to a targeted practice")
  func sourcesRouteToTargetedPractices() {
    let expectations: [(CurrentStressSource, CurrentStressLevel, PracticeKind, DailyEchoState)] = [
      (.sleep, .moderate, .nsdr, .tired),
      (.lowEnergy, .high, .nsdr, .tired),
      (.training, .low, .pacedBreathing, .tired),
      (.training, .high, .nsdr, .tired),
      (.physicalTension, .moderate, .physiologicalSigh, .tired),
      (.work, .low, .pacedBreathing, .clear),
      (.tasks, .high, .physiologicalSigh, .tense),
      (.money, .moderate, .pacedBreathing, .tense),
      (.family, .low, .meditation, .moved),
      (.relationship, .high, .physiologicalSigh, .tense),
      (.health, .moderate, .pacedBreathing, .tired),
      (.bodySignals, .high, .physiologicalSigh, .tense),
      (.mentalLoad, .low, .meditation, .clear),
      (.mentalLoad, .moderate, .pacedBreathing, .uncertain),
      (.none, .high, .physiologicalSigh, .tense),
    ]

    for (source, level, practice, echo) in expectations {
      let decision = decision(level: level, explicitSource: source)

      #expect(decision.stressProfile.source == source)
      #expect(decision.recommendation == practice)
      #expect(decision.reflectionEcho == echo)
      #expect(decision.recommendation != .kegel)
    }
  }

  @Test("No current expression asks for input until body evidence can support a result")
  func noExpressionUsesBodyLoad() {
    let waiting = CurrentMomentDecisionEngine.decide(
      quick: nil,
      detailed: nil,
      bodyLoadLevel: .buildingBaseline,
      now: date(day: 29, hour: 12),
      calendar: calendar
    )
    #expect(waiting.source == .none)
    #expect(waiting.assessmentBasis == .needsInput)
    #expect(waiting.recommendation == nil)
    #expect(waiting.reasonCode == "stress.needsInput")

    let expectations: [(BodyLoadLevel, CurrentStressLevel, PracticeKind)] = [
      (.steady, .low, .meditation),
      (.watch, .moderate, .pacedBreathing),
      (.elevated, .high, .physiologicalSigh),
    ]

    for (bodyLevel, stressLevel, practice) in expectations {
      let decision = CurrentMomentDecisionEngine.decide(
        quick: nil,
        detailed: nil,
        bodyLoadLevel: bodyLevel,
        now: date(day: 29, hour: 12),
        calendar: calendar
      )

      #expect(decision.source == .none)
      #expect(decision.assessmentBasis == .bodyData)
      #expect(decision.stressProfile == CurrentStressProfile(level: stressLevel, source: .none))
      #expect(decision.recommendation == practice)
      #expect(decision.recommendation != .kegel)
      #expect(decision.ruleVersion == "fangcun-stress-response-v2")
    }
  }

  @Test("Expressions from a previous local day expire before body-only assessment")
  func previousDayExpressionsExpire() {
    let decision = CurrentMomentDecisionEngine.decide(
      quick: CurrentMomentQuickState(
        state: .tense,
        recordedAt: date(day: 28, hour: 23, minute: 59)
      ),
      detailed: CurrentMomentDetailedState(
        valence: -0.9,
        arousal: 0.9,
        emotion: .overwhelmed,
        recordedAt: date(day: 28, hour: 22)
      ),
      bodyLoadLevel: .elevated,
      now: date(day: 29, hour: 0, minute: 1),
      calendar: calendar
    )

    #expect(decision.source == .none)
    #expect(decision.stressProfile == CurrentStressProfile(level: .high, source: .none))
    #expect(decision.recommendation == .physiologicalSigh)
  }

  @Test("Detailed state context defaults preserve existing call sites")
  func detailedContextDefaultsAreEmpty() {
    let state = CurrentMomentDetailedState(
      valence: 0,
      arousal: 0,
      emotion: nil,
      recordedAt: date(day: 29, hour: 11)
    )

    #expect(state.stressSources.isEmpty)
    #expect(state.bodySensationCodes.isEmpty)
  }

  private func detailedDecision(
    valence: Double,
    arousal: Double,
    emotion: EmotionLabel? = nil,
    stressSources: [CurrentStressSource] = [],
    bodySensationCodes: [String] = [],
    bodyStressSource: CurrentStressSource? = nil
  ) -> CurrentMomentDecision {
    CurrentMomentDecisionEngine.decide(
      quick: nil,
      detailed: CurrentMomentDetailedState(
        valence: valence,
        arousal: arousal,
        emotion: emotion,
        recordedAt: date(day: 29, hour: 11),
        stressSources: stressSources,
        bodySensationCodes: bodySensationCodes
      ),
      bodyLoadLevel: .steady,
      bodyStressSource: bodyStressSource,
      now: date(day: 29, hour: 12),
      calendar: calendar
    )
  }

  private func decision(
    level: CurrentStressLevel,
    explicitSource: CurrentStressSource
  ) -> CurrentMomentDecision {
    let state: (Double, Double) =
      switch level {
      case .low: (0.8, 0.8)
      case .moderate: (0, 0)
      case .high: (-0.8, 0.8)
      }
    return detailedDecision(
      valence: state.0,
      arousal: state.1,
      stressSources: [explicitSource]
    )
  }

  private var calendar: Calendar {
    var value = Calendar(identifier: .gregorian)
    value.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return value
  }

  private func date(day: Int, hour: Int, minute: Int = 0) -> Date {
    calendar.date(
      from: DateComponents(
        year: 2026,
        month: 8,
        day: day,
        hour: hour,
        minute: minute
      )
    )!
  }
}
