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
    case .inhale, .leftInhale, .rightInhale: "随圆环展开，轻轻吸气"
    case .topUp: "再展开一点，轻补一口"
    case .exhale, .leftExhale, .rightExhale: "随圆环收拢，慢慢呼气"
    case .holdAfterInhale, .holdAfterExhale: "圆环保持，轻松停留"
    case .contract: "向内轻收 · 呼吸照常"
    case .release: "舒展开来 · 完全放松"
    default: "按自己的节奏，不必跟拍"
    }
  }
}
