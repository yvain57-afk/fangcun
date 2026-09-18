public enum EmotionLabel: String, CaseIterable, Hashable, Codable, Sendable {
  case amazed
  case amused
  case angry
  case anxious
  case ashamed
  case brave
  case calm
  case content
  case disappointed
  case discouraged
  case disgusted
  case embarrassed
  case excited
  case frustrated
  case grateful
  case guilty
  case happy
  case hopeless
  case irritated
  case jealous
  case joyful
  case lonely
  case passionate
  case peaceful
  case proud
  case relieved
  case sad
  case scared
  case stressed
  case surprised
  case worried
  case annoyed
  case confident
  case drained
  case hopeful
  case indifferent
  case overwhelmed
  case satisfied
}

public enum EmotionQuadrant: CaseIterable, Sendable {
  case highActivationPositive
  case lowActivationPositive
  case highActivationNegative
  case lowActivationNegative
  case neutral
}

public enum EmotionCatalog {
  public static func label(forAppleIdentifier identifier: String) -> EmotionLabel? {
    EmotionLabel(rawValue: identifier)
  }

  public static func quadrant(
    valence: Double,
    arousal: Double,
    neutralThreshold: Double = 0.15
  ) -> EmotionQuadrant {
    if abs(valence) <= neutralThreshold, abs(arousal) <= neutralThreshold {
      return .neutral
    }

    return switch (valence >= 0, arousal >= 0) {
    case (true, true): .highActivationPositive
    case (true, false): .lowActivationPositive
    case (false, true): .highActivationNegative
    case (false, false): .lowActivationNegative
    }
  }

  public static func labels(for quadrant: EmotionQuadrant) -> [EmotionLabel] {
    switch quadrant {
    case .highActivationPositive:
      [
        .amazed, .amused, .brave, .excited, .happy, .joyful, .passionate, .proud, .confident,
        .hopeful, .surprised,
      ]
    case .lowActivationPositive:
      [.calm, .content, .grateful, .peaceful, .relieved, .satisfied]
    case .highActivationNegative:
      [
        .angry, .anxious, .ashamed, .disgusted, .embarrassed, .frustrated, .guilty, .irritated,
        .jealous, .scared, .stressed, .worried, .annoyed, .overwhelmed,
      ]
    case .lowActivationNegative:
      [.disappointed, .discouraged, .hopeless, .lonely, .sad, .drained]
    case .neutral:
      [.indifferent]
    }
  }
}
