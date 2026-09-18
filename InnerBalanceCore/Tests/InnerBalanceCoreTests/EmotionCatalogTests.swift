import Testing

@testable import InnerBalanceCore

@Suite("Emotion catalog")
struct EmotionCatalogTests {
  @Test("All 38 Apple labels are mapped exactly once")
  func everyLabelIsMappedExactlyOnce() {
    let mapped = EmotionQuadrant.allCases.flatMap { EmotionCatalog.labels(for: $0) }
    let expectedAppleIdentifiers: Set<String> = [
      "amazed", "amused", "angry", "anxious", "ashamed", "brave", "calm", "content",
      "disappointed", "discouraged", "disgusted", "embarrassed", "excited", "frustrated",
      "grateful", "guilty", "happy", "hopeless", "irritated", "jealous", "joyful", "lonely",
      "passionate", "peaceful", "proud", "relieved", "sad", "scared", "stressed", "surprised",
      "worried", "annoyed", "confident", "drained", "hopeful", "indifferent", "overwhelmed",
      "satisfied",
    ]

    #expect(expectedAppleIdentifiers.count == 38)
    #expect(Set(EmotionLabel.allCases.map(\.rawValue)) == expectedAppleIdentifiers)
    #expect(mapped.count == expectedAppleIdentifiers.count)
    #expect(Set(mapped.map(\.rawValue)) == expectedAppleIdentifiers)
  }

  @Test("Unknown Apple label is left unclassified")
  func unknownAppleLabelIsUnclassified() {
    #expect(EmotionCatalog.label(forAppleIdentifier: "calm") == .calm)
    #expect(EmotionCatalog.label(forAppleIdentifier: "future_apple_label") == nil)
  }

  @Test("Compass coordinates resolve to a stable quadrant")
  func compassCoordinatesResolveToQuadrant() {
    #expect(EmotionCatalog.quadrant(valence: 0.7, arousal: 0.8) == .highActivationPositive)
    #expect(EmotionCatalog.quadrant(valence: 0.7, arousal: -0.8) == .lowActivationPositive)
    #expect(EmotionCatalog.quadrant(valence: -0.7, arousal: 0.8) == .highActivationNegative)
    #expect(EmotionCatalog.quadrant(valence: -0.7, arousal: -0.8) == .lowActivationNegative)
    #expect(EmotionCatalog.quadrant(valence: 0.05, arousal: 0.05) == .neutral)
  }
}
