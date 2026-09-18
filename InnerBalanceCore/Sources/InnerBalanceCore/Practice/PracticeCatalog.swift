import Foundation

public struct PracticeProtocol: Equatable, Sendable {
  public let kind: PracticeKind
  public let durationOptions: [TimeInterval]
  public let isAutomaticallyRecommended: Bool
  public let minimumEvidenceDuration: TimeInterval?
  public let writesMindfulSession: Bool

  public var defaultDuration: TimeInterval {
    durationOptions[0]
  }

  public init(
    kind: PracticeKind,
    durationOptions: [TimeInterval],
    isAutomaticallyRecommended: Bool,
    minimumEvidenceDuration: TimeInterval?,
    writesMindfulSession: Bool
  ) {
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

  public static func `protocol`(for kind: PracticeKind) -> PracticeProtocol? {
    buildOne.first { $0.kind == kind }
  }
}
