import Foundation
import InnerBalanceCore

/// Presentation only: every value comes from the session's existing timeline.
/// No animation timer, protocol durations, health model or stored preferences live here.
struct PracticeVisualMotion {
  let kind: PracticeKind
  let snapshot: PracticeTimelineSnapshot

  static func eased(_ value: Double) -> Double {
    let t = min(1, max(0, value))
    return t * t * (3 - 2 * t)
  }

  var expansion: Double {
    let t = Self.eased(snapshot.phaseProgress)
    switch snapshot.phase {
    case .inhale, .leftInhale, .rightInhale:
      // topUp follows only the sigh's main inhale.
      return t * (kind == .physiologicalSigh ? 0.82 : 1)
    case .topUp: return 0.82 + 0.18 * t
    case .exhale, .leftExhale, .rightExhale: return 1 - t
    case .holdAfterInhale: return 1
    default: return 0
    }
  }

  var contraction: Double {
    switch snapshot.phase {
    case .contract: Self.eased(snapshot.elapsedInPhase / 0.35)
    case .release: 1 - Self.eased(snapshot.elapsedInPhase / 0.4)
    default: 0
    }
  }

  var side: Int? {
    switch snapshot.phase {
    case .leftInhale, .leftExhale: -1
    case .rightInhale, .rightExhale: 1
    default: nil
    }
  }

  var phaseSeconds: Int { max(1, Int(ceil(snapshot.phaseDuration - snapshot.elapsedInPhase))) }

  var instruction: String {
    switch snapshot.phase {
    case .inhale, .leftInhale, .rightInhale: "Gently open"
    case .topUp: "One small extra breath"
    case .exhale, .leftExhale, .rightExhale: "Slowly soften"
    case .holdAfterInhale, .holdAfterExhale: "Rest here. No effort needed."
    case .contract: "Lift gently · Keep breathing"
    case .release: "Let go completely"
    default: "Your own rhythm. No pace to follow."
    }
  }
}
