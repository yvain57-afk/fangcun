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
    case .topUp: "补吸"
    case .holdAfterInhale, .holdAfterExhale: "停留"
    case .leftInhale: "左吸"
    case .rightInhale: "右吸"
    case .leftExhale: "左呼"
    case .rightExhale: "右呼"
    case .contract: "轻收"
    case .release: "放松"
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
        Text(steps.map { "\(FangcunPhaseStyle.title($0.phase)) \(Int($0.duration))" }.joined(separator: " · ") + " 秒")
          .font(compact ? .caption2.monospacedDigit() : .caption.monospacedDigit())
          .foregroundStyle(InnerBalanceTheme.mutedInk).fixedSize(horizontal: false, vertical: true)
      } else {
        HStack(spacing: 6) {
          Image(systemName: kind == .nsdr ? "moon" : "leaf")
          Text(kind == .progressiveMuscleRelaxation ? "八组肌肉 · 轻收再松开 · 自然呼吸" : kind == .nsdr ? "身体扫描 · 安静休息 · 慢慢回来" : "自然呼吸 · 不必跟拍")
        }.font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("引导顺序")
    .accessibilityValue(steps.isEmpty ? "自然呼吸，不必跟拍" : steps.map { "\(FangcunPhaseStyle.title($0.phase))\(Int($0.duration))秒" }.joined(separator: "，"))
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
    case .physiologicalSigh: "紧绷时，先缓一缓"
    case .pacedBreathing: "忙碌之后，慢下来"
    case .balancedBreathing: "找回均匀的节奏"
    case .boxBreathing: "开始工作前，收回注意力"
    case .diaphragmaticBreathing: "练习轻松、不费力的呼吸"
    case .alternateNostrilBreathing: "跟随左右，专注当下"
    case .meditation: "给纷乱的念头一点空间"
    case .nsdr: "躺下来，让身体休息"
    case .kegel: "练习盆底的轻收与放松"
    case .progressiveMuscleRelaxation: "轻轻用力，再让身体歇一歇"
    }
  }
  var positionNote: String {
    switch self {
    case .nsdr: "舒适躺卧"
    case .progressiveMuscleRelaxation: "舒服坐靠或躺卧"
    case .diaphragmaticBreathing: "坐姿或躺卧"
    case .kegel: "坐稳或躺好"
    default: "放松坐稳"
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
        Label("由你决定", systemImage: "hand.raised").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        Text(title).font(.title3.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
        Button("取消，保留数据", action: onCancel).buttonStyle(InnerBalancePrimaryButtonStyle())
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
        Text(kind == .progressiveMuscleRelaxation ? "分组收放 · 自然呼吸" : kind == .nsdr ? "身体扫描与休息" : "自然呼吸，不必跟拍")
        Spacer(minLength: 8)
        if !segments.isEmpty { Text("引导 \(index + 1) / \(segments.count)").monospacedDigit() }
      }.font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
    }.padding(.horizontal, 8).accessibilityIdentifier("practice.guidedProgress")
  }
}
