import InnerBalanceCore
import SwiftUI

/// The character, phase field and proportional track share the actual session clock.
struct PracticeVisualGuide: View {
  let kind: PracticeKind
  let elapsed: TimeInterval
  let duration: TimeInterval
  var variantID: String? = nil
  var isPaused = false
  var reduceMotion = false
  @Environment(\.accessibilityReduceMotion) private var systemReduced
  @AppStorage("fangcun.motionMode") private var motionMode = "standard"
  @AppStorage("fangcun.reduceMotion") private var savedReduced = false
  private var state: PracticeTimelineSnapshot {
    PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID)
  }
  private var motion: PracticeVisualMotion { .init(kind: kind, snapshot: state) }
  private var reduced: Bool {
    reduceMotion || savedReduced || systemReduced || motionMode == "static" || ProcessInfo.processInfo.isLowPowerModeEnabled
  }
  private var expansion: Double {
    if kind == .kegel {
      return reduced ? (state.phase == .contract ? 0 : 1) : 1 - motion.contraction
    }
    if reduced {
      return switch state.phase {
      case .inhale, .leftInhale, .rightInhale: kind == .physiologicalSigh ? 0.82 : 1
      case .topUp, .holdAfterInhale: 1
      default: 0
      }
    }
    return motion.expansion
  }
  var body: some View {
    VStack(spacing: kind == .alternateNostrilBreathing ? 12 : 20) {
      ZStack {
        VolumeAuraView(phase: state.phase, amount: expansion)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(kind == .kegel ? "Lift and release guide" : "Breathing guide")
          .accessibilityIdentifier(kind == .kegel ? "practice.contractionGuide" : "practice.breathEnvelope")
        PracticeCompanionV4(kind: kind, elapsed: elapsed, duration: duration,
          variantID: variantID, isActive: !isPaused, reduceMotionOverride: reduced)
          .frame(width: kind == .balancedBreathing ? 300 : 274, height: 260)
      }
      .frame(maxWidth: .infinity).frame(height: 290)
      if kind == .alternateNostrilBreathing {
        HStack {
          sideLabel("Your left", active: motion.side == -1)
          Spacer(minLength: 12)
          sideLabel("Your right", active: motion.side == 1)
        }
      }
      if !isPaused {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(motion.instruction).font(.subheadline.weight(.medium))
          Spacer(minLength: 4)
          Text("\(motion.phaseSeconds) sec").font(.title3.monospacedDigit().weight(.semibold))
            .contentTransition(.identity).accessibilityIdentifier("practice.phaseSeconds")
        }.foregroundStyle(InnerBalanceTheme.ink)

      }
      ProportionalPhaseBar(kind: kind, variantID: variantID, elapsed: elapsed, duration: duration, paused: isPaused)
      if !isPaused {
        Text("Round \(state.cycleIndex + 1)")
          .font(.caption.monospacedDigit()).foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }.frame(maxWidth: 360)
      .accessibilityElement(children: .contain).accessibilityIdentifier("practice.visualGuide")
  }
  private func sideLabel(_ title: String, active: Bool) -> some View {
    Text(title).font(.caption.weight(active ? .bold : .regular))
      .foregroundStyle(active ? InnerBalanceTheme.ink : InnerBalanceTheme.mutedInk)
      .padding(.horizontal, 12).padding(.vertical, 8)
      .background(active ? InnerBalanceTheme.subtleFill : .clear, in: Capsule())
  }
}
