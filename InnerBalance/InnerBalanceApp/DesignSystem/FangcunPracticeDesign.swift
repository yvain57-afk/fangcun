import SwiftUI
import InnerBalanceCore

/// Presentation tokens only. Training parameters remain in PracticeTimeline.
enum FangcunPhaseStyle {
  static func color(_ phase: PracticeBreathPhase?) -> Color {
    switch phase {
    case .exhale, .leftExhale, .rightExhale, .release: Color("FangcunExhale")
    case .topUp, .holdAfterInhale, .holdAfterExhale, .contract: InnerBalanceTheme.emphasis
    default: Color("FangcunInhale")
    }
  }
  static func title(_ phase: PracticeBreathPhase) -> String {
    switch phase {
    case .topUp: "A little more"
    case .holdAfterInhale, .holdAfterExhale: "Pause"
    case .leftInhale: "In · left"
    case .rightInhale: "In · right"
    case .leftExhale: "Out · left"
    case .rightExhale: "Out · right"
    case .contract: "Gently lift"
    case .release: "Unwind"
    default: phase.title
    }
  }
}

struct ProportionalPhaseBar: View {
  let kind: PracticeKind
  var variantID: String? = nil
  var elapsed: TimeInterval? = nil
  var duration: TimeInterval = 300
  var paused = false
  var compact = false
  private var steps: [PracticePhaseStep] { PracticeTimeline.steps(for: kind, variantID: variantID) }
  private var total: Double { steps.reduce(0) { $0 + $1.duration } }
  private var state: PracticeTimelineSnapshot {
    PracticeTimeline.snapshot(kind: kind, elapsed: elapsed ?? 0, duration: duration, variantID: variantID)
  }
  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 6 : 12) {
      if !steps.isEmpty {
        GeometryReader { proxy in
          HStack(spacing: 3) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
              RoundedRectangle(cornerRadius: 5)
                .fill(FangcunPhaseStyle.color(step.phase).opacity(elapsed == nil || state.cueID % steps.count == index ? 0.85 : 0.22))
                .frame(width: max(0, proxy.size.width - CGFloat(steps.count - 1) * 3) * step.duration / total)
            }
          }
          if let elapsed {
            let progress = elapsed.truncatingRemainder(dividingBy: total) / total
            Capsule().fill(InnerBalanceTheme.ink).frame(width: 3, height: compact ? 15 : 25)
              .offset(x: max(0, min(proxy.size.width - 3, proxy.size.width * progress)), y: -4)
          }
        }.frame(height: compact ? 7 : 17)
        Text(steps.map { "\(FangcunPhaseStyle.title($0.phase)) \(Int($0.duration))" }.joined(separator: " · ") + " sec")
          .font(compact ? .caption2.monospacedDigit() : .caption.monospacedDigit())
          .foregroundStyle(InnerBalanceTheme.mutedInk).fixedSize(horizontal: false, vertical: true)
      } else {
        HStack(spacing: 6) {
          Image(systemName: kind == .nsdr ? "moon" : "leaf")
          Text(kind == .progressiveMuscleRelaxation ? "8 muscle groups · Gently tense, then release" : kind == .nsdr ? "Body scan · Quiet rest · Gently return" : "Your own breath · No pace to follow")
        }.font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Practice sequence")
    .accessibilityValue(steps.isEmpty ? "Breathe naturally. No pace to follow." : steps.map { "\(FangcunPhaseStyle.title($0.phase)), \(Int($0.duration)) seconds" }.joined(separator: "，"))
    .accessibilityIdentifier("practice.phaseTrack")
  }
}

struct VolumeAuraView: View {
  let phase: PracticeBreathPhase?
  let amount: Double
  var body: some View {
    let color = FangcunPhaseStyle.color(phase)
    Circle().fill(RadialGradient(colors: [color.opacity(0.16), color.opacity(0.06), .clear], center: .center, startRadius: 30, endRadius: 160))
      .frame(width: 230 + 80 * amount, height: 230 + 80 * amount)
      .overlay {
        if phase == .holdAfterInhale || phase == .holdAfterExhale || phase == .topUp {
          Circle().stroke(color.opacity(0.35), lineWidth: 1.5).padding(5)
        }
      }
  }
}

extension PracticeKind {
  var useContext: String {
    switch self {
    case .physiologicalSigh: "For when everything feels a little much"
    case .pacedBreathing: "An easier end to a busy day"
    case .balancedBreathing: "Find a steady rhythm"
    case .boxBreathing: "A moment before your next task"
    case .diaphragmaticBreathing: "Let breathing feel a little easier"
    case .alternateNostrilBreathing: "One side, then the other"
    case .meditation: "A little room for a busy mind"
    case .nsdr: "Lie down. Let yourself rest."
    case .kegel: "A gentle lift, with time to release"
    case .progressiveMuscleRelaxation: "Notice the difference when you let go"
    }
  }
  var positionNote: String {
    switch self {
    case .nsdr: "Lie down comfortably"
    case .progressiveMuscleRelaxation: "Sit back or lie down"
    case .diaphragmaticBreathing: "Seated or lying down"
    case .kegel: "Sit or lie comfortably"
    default: "Sit comfortably"
    }
  }
}

extension View {
  func fangcunCleanList() -> some View {
    self.scrollContentBackground(.hidden).background(InnerBalanceTheme.canvas)
      .foregroundStyle(InnerBalanceTheme.ink).tint(InnerBalanceTheme.strongFill)
      .listRowBackground(InnerBalanceTheme.surface)
  }
}


struct FangcunDataConfirmation: View {
  let title: String
  let actionTitle: String
  let onCancel: () -> Void
  let onConfirm: () -> Void
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Label("Your choice", systemImage: "hand.raised").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        Text(title).font(.title3.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
        Button("Cancel and keep my data", action: onCancel).buttonStyle(InnerBalancePrimaryButtonStyle())
          .accessibilityIdentifier("data.clear.cancel")
        Button(actionTitle, action: onConfirm).font(.headline).frame(maxWidth: .infinity, minHeight: 44)
          .accessibilityIdentifier("data.clear.confirm")
      }.padding(24)
    }.foregroundStyle(InnerBalanceTheme.ink).tint(InnerBalanceTheme.strongFill)
      .presentationBackground(InnerBalanceTheme.canvas).presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
  }
}

struct PracticeGuidedProgress: View {
  let kind: PracticeKind
  let elapsed: TimeInterval
  let duration: TimeInterval
  var variantID: String? = nil
  var body: some View {
    let segments = PracticeTimeline.segments(for: kind, duration: duration, variantID: variantID)
    let index = segments.lastIndex(where: { elapsed >= $0.start }) ?? 0
    VStack(alignment: .leading, spacing: 10) {
      ProgressView(value: min(max(0, elapsed), duration), total: max(1, duration))
        .tint(Color("FangcunExhale"))
      HStack {
        Text(kind == .progressiveMuscleRelaxation ? "Tense and release · Breathe naturally" : kind == .nsdr ? "Body scan and rest" : "Breathe naturally. No pace to follow.")
        Spacer(minLength: 8)
        if !segments.isEmpty { Text("Step \(index + 1) of \(segments.count)").monospacedDigit() }
      }.font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
    }.padding(.horizontal, 8).accessibilityIdentifier("practice.guidedProgress")
  }
}
