public struct WatchCompassRegion: Equatable, Hashable, Identifiable, Sendable {
  public let valence: Double
  public let arousal: Double

  public init(valence: Double, arousal: Double) {
    self.valence = valence
    self.arousal = arousal
  }

  public var id: String { "\(valence)-\(arousal)" }

  public static let all: [WatchCompassRegion] = [0.75, 0, -0.75].flatMap { arousal in
    [-0.75, 0, 0.75].map { valence in
      WatchCompassRegion(valence: valence, arousal: arousal)
    }
  }
}
