public enum PracticeKind: String, CaseIterable, Codable, Equatable, Sendable {
  case physiologicalSigh
  case pacedBreathing
  case meditation
  case nsdr
  case kegel
  case balancedBreathing
  case boxBreathing
  case diaphragmaticBreathing
  case alternateNostrilBreathing
  /// Watch V4 retains the five existing executable methods; new records keep their real IDs.
  public var isLegacyWatchExecutable: Bool {
    switch self {
    case .physiologicalSigh, .pacedBreathing, .meditation, .nsdr, .kegel: true
    default: false
    }
  }
}
