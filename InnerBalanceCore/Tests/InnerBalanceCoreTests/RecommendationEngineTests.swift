import Testing

@testable import InnerBalanceCore

@Suite("Practice recommendation")
struct RecommendationEngineTests {
  @Test("High-activation negative state recommends a physiological sigh")
  func highActivationNegativeRecommendsSigh() {
    let input = RecommendationInput(
      valence: -0.8,
      arousal: 0.9,
      emotion: .stressed,
      bodyLoadLevel: .watch
    )

    let recommendation = RecommendationEngine.recommend(for: input)

    #expect(recommendation.practice == .physiologicalSigh)
    #expect(recommendation.reasonCode == "high_activation_negative")
  }

  @Test("A drained low-activation state recommends NSDR")
  func drainedStateRecommendsNSDR() {
    let input = RecommendationInput(
      valence: -0.6,
      arousal: -0.8,
      emotion: .drained,
      bodyLoadLevel: .elevated
    )

    let recommendation = RecommendationEngine.recommend(for: input)

    #expect(recommendation.practice == .nsdr)
    #expect(recommendation.reasonCode == "low_activation_recovery")
  }

  @Test("Neutral compass coordinates do not trigger a negative-state practice")
  func neutralCoordinatesUseGentleReset() {
    let input = RecommendationInput(
      valence: -0.01,
      arousal: 0.01,
      emotion: nil,
      bodyLoadLevel: .steady
    )

    let recommendation = RecommendationEngine.recommend(for: input)

    #expect(recommendation.practice == .meditation)
    #expect(recommendation.reasonCode == "gentle_reset")
  }

  @Test("Kegel is never returned by automatic recommendations")
  func kegelIsNeverAutomaticallyRecommended() {
    for valence in [-1.0, 0, 1.0] {
      for arousal in [-1.0, 0, 1.0] {
        for level in [BodyLoadLevel.steady, .watch, .elevated] {
          let recommendation = RecommendationEngine.recommend(
            for: RecommendationInput(
              valence: valence,
              arousal: arousal,
              emotion: nil,
              bodyLoadLevel: level
            )
          )

          #expect(recommendation.practice != .kegel)
        }
      }
    }
  }
}
