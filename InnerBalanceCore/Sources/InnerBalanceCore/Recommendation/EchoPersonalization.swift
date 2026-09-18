public enum EchoPersonalization {
  public static func recommendedPractice(
    for echo: DailyEchoState,
    bodyLoadLevel: BodyLoadLevel
  ) -> PracticeKind {
    if bodyLoadLevel == .elevated, echo != .tense, echo != .tired {
      return .pacedBreathing
    }
    return switch echo {
    case .tense: .physiologicalSigh
    case .tired: .nsdr
    case .uncertain, .clear: .pacedBreathing
    case .calm, .moved: .meditation
    }
  }
}
