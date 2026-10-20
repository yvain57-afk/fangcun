import Foundation

public struct PracticeProtocol: Equatable, Sendable {
  public let kind: PracticeKind
  public let durationOptions: [TimeInterval]
  public let isAutomaticallyRecommended: Bool
  public let minimumEvidenceDuration: TimeInterval?
  public let writesMindfulSession: Bool
  public let preferredDuration: TimeInterval?

  public var defaultDuration: TimeInterval {
    preferredDuration ?? durationOptions[0]
  }

  public init(
    kind: PracticeKind,
    durationOptions: [TimeInterval],
    isAutomaticallyRecommended: Bool,
    minimumEvidenceDuration: TimeInterval?,
    writesMindfulSession: Bool,
    preferredDuration: TimeInterval? = nil
  ) {
    self.preferredDuration = preferredDuration
    self.kind = kind
    self.durationOptions = durationOptions
    self.isAutomaticallyRecommended = isAutomaticallyRecommended
    self.minimumEvidenceDuration = minimumEvidenceDuration
    self.writesMindfulSession = writesMindfulSession
  }
}

public enum PracticeCatalog {
  public static let buildOne: [PracticeProtocol] = [
    PracticeProtocol(
      kind: .physiologicalSigh,
      durationOptions: [60, 300],
      isAutomaticallyRecommended: true,
      minimumEvidenceDuration: nil,
      writesMindfulSession: true
    ),
    PracticeProtocol(
      kind: .pacedBreathing,
      durationOptions: [180, 300],
      isAutomaticallyRecommended: true,
      minimumEvidenceDuration: 300,
      writesMindfulSession: true
    ),
    PracticeProtocol(
      kind: .meditation,
      durationOptions: [300, 600],
      isAutomaticallyRecommended: true,
      minimumEvidenceDuration: 300,
      writesMindfulSession: true
    ),
    PracticeProtocol(
      kind: .nsdr,
      durationOptions: [600, 1_200],
      isAutomaticallyRecommended: true,
      minimumEvidenceDuration: 600,
      writesMindfulSession: true
    ),
    PracticeProtocol(
      kind: .kegel,
      durationOptions: [180],
      isAutomaticallyRecommended: false,
      minimumEvidenceDuration: nil,
      writesMindfulSession: false
    ),
  ]

  /// Phone V4 catalog; buildOne remains the legacy Watch catalog.
  public static let v4: [PracticeProtocol] = [
    PracticeProtocol(kind: .physiologicalSigh, durationOptions: [60, 300], isAutomaticallyRecommended: true, minimumEvidenceDuration: nil, writesMindfulSession: true, preferredDuration: 300),
    PracticeProtocol(kind: .pacedBreathing, durationOptions: [180, 300], isAutomaticallyRecommended: true, minimumEvidenceDuration: 300, writesMindfulSession: true, preferredDuration: 300),
    PracticeProtocol(kind: .balancedBreathing, durationOptions: [180, 300], isAutomaticallyRecommended: true, minimumEvidenceDuration: nil, writesMindfulSession: true, preferredDuration: 300),
    PracticeProtocol(kind: .boxBreathing, durationOptions: [180, 300], isAutomaticallyRecommended: false, minimumEvidenceDuration: nil, writesMindfulSession: true, preferredDuration: 180),
    PracticeProtocol(kind: .diaphragmaticBreathing, durationOptions: [180, 300], isAutomaticallyRecommended: true, minimumEvidenceDuration: nil, writesMindfulSession: true, preferredDuration: 180),
    PracticeProtocol(kind: .alternateNostrilBreathing, durationOptions: [180, 300], isAutomaticallyRecommended: false, minimumEvidenceDuration: nil, writesMindfulSession: true, preferredDuration: 180),
    PracticeProtocol(kind: .meditation, durationOptions: [300, 600], isAutomaticallyRecommended: true, minimumEvidenceDuration: 300, writesMindfulSession: true, preferredDuration: 300),
    PracticeProtocol(kind: .nsdr, durationOptions: [600, 1200], isAutomaticallyRecommended: true, minimumEvidenceDuration: 600, writesMindfulSession: true, preferredDuration: 600),
    PracticeProtocol(kind: .kegel, durationOptions: [180], isAutomaticallyRecommended: false, minimumEvidenceDuration: nil, writesMindfulSession: false, preferredDuration: 180)
  ]

  /// Additive phone catalog; the original nine and legacy Watch parameters remain intact.
  public static let phone = v4 + [PracticeProtocol(
    kind: .progressiveMuscleRelaxation, durationOptions: [600],
    isAutomaticallyRecommended: false, minimumEvidenceDuration: nil,
    writesMindfulSession: false, preferredDuration: 600
  )]

  public static func `protocol`(for kind: PracticeKind) -> PracticeProtocol? {
    buildOne.first { $0.kind == kind } ?? phone.first { $0.kind == kind }
  }
}
