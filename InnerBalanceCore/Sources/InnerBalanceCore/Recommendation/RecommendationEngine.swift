public struct RecommendationInput: Equatable, Sendable {
  public let valence: Double
  public let arousal: Double
  public let emotion: EmotionLabel?
  public let bodyLoadLevel: BodyLoadLevel

  public init(
    valence: Double,
    arousal: Double,
    emotion: EmotionLabel?,
    bodyLoadLevel: BodyLoadLevel
  ) {
    self.valence = valence
    self.arousal = arousal
    self.emotion = emotion
    self.bodyLoadLevel = bodyLoadLevel
  }
}

public struct PracticeRecommendation: Equatable, Sendable {
  public let practice: PracticeKind
  public let reasonCode: String
}

public enum RecommendationEngine {
  public static func recommend(for input: RecommendationInput) -> PracticeRecommendation {
    let quadrant = EmotionCatalog.quadrant(
      valence: input.valence,
      arousal: input.arousal
    )

    if quadrant == .highActivationNegative {
      return PracticeRecommendation(
        practice: .physiologicalSigh,
        reasonCode: "high_activation_negative"
      )
    }

    if input.emotion == .drained
      || (quadrant == .lowActivationNegative && input.arousal < -0.35)
    {
      return PracticeRecommendation(
        practice: .nsdr,
        reasonCode: "low_activation_recovery"
      )
    }

    if input.bodyLoadLevel == .elevated {
      return PracticeRecommendation(
        practice: .pacedBreathing,
        reasonCode: "elevated_body_load"
      )
    }

    return PracticeRecommendation(practice: .meditation, reasonCode: "gentle_reset")
  }
}
