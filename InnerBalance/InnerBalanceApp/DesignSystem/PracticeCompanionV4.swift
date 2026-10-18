import SwiftUI
import InnerBalanceCore

/// Intact authored silhouettes: local deformation never moves the face, ears or feet.
struct PracticeCompanionV4: View {
  let kind: PracticeKind
  let elapsed: Double
  let duration: Double
  var variantID: String? = nil
  var isActive = true
  var entryProgress = 1.0
  var completionProgress = 0.0
  var reduceMotionOverride = false
  @Environment(\.accessibilityReduceMotion) private var systemReduced
  @AppStorage("fangcun.reduceMotion") private var reduceMotion = false
  @AppStorage("fangcun.motionMode") private var motionMode = "standard"

  private var snapshot: PracticeTimelineSnapshot {
    PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID)
  }
  private var motion: PracticeVisualMotion { .init(kind: kind, snapshot: snapshot) }
  private var strength: Double {
    (systemReduced || reduceMotion || reduceMotionOverride || motionMode == "static" || ProcessInfo.processInfo.isLowPowerModeEnabled) ? 0 : (motionMode == "gentle" ? 0.55 : 1)
  }
  private var expansion: Double {
    if kind == .diaphragmaticBreathing {
      // Labelled visual demonstration only, never a prescribed breathing pace.
      return (1 - cos(elapsed.truncatingRemainder(dividingBy: 10) / 10 * 2 * .pi)) / 2
    }
    if kind == .nsdr && snapshot.segment?.focus == "belly" {
      return -0.2 * PracticeVisualMotion.eased(snapshot.segmentElapsed / 2.4)
    }
    if kind == .meditation || kind == .nsdr {
      return 0.25 * (1 - cos(elapsed / 8 * 2 * .pi)) / 2
    }
    return motion.expansion
  }
  private var attention: Double {
    let focus = snapshot.segment?.focus
    let cue = (kind == .meditation && focus == "return") || (kind == .nsdr && focus == "face")
    let t = min(1, max(0, cue ? snapshot.segmentElapsed / 2.4 : completionProgress))
    return sin(t * .pi) * strength
  }
  var body: some View {
    GeometryReader { proxy in
      let w = proxy.size.width
      let h = min(proxy.size.height, w * 0.86)
      ZStack {
        scene(w: w, h: h)
          .opacity(entryProgress < 1 && kind == .pacedBreathing ? PracticeVisualMotion.eased((entryProgress - 0.45) / 0.3) : 1)
        if entryProgress < 1 && kind == .pacedBreathing {
          character("dog-sit", size: min(w * 0.80, h * 1.06), warp: 1)
            .position(x: w * 0.5, y: h * 0.5)
            .opacity(1 - PracticeVisualMotion.eased((entryProgress - 0.45) / 0.3))
        }
      }
        .frame(width: w, height: h).frame(maxHeight: .infinity)
    }
    .accessibilityElement(children: .ignore).accessibilityLabel(stageLabel)
    .accessibilityIdentifier("practice.companion")
  }

  @ViewBuilder private func scene(w: CGFloat, h: CGFloat) -> some View {
    switch kind {
    case .balancedBreathing:
      character("cat-sit", size: w * 0.53, warp: 0).position(x: w * 0.27, y: h * 0.52)
      character("dog-sit", size: w * 0.55, warp: 1).position(x: w * 0.73, y: h * 0.54)
    case .pacedBreathing, .nsdr:
      character("v5-dog-sleep", size: w * 1.12, warp: 6)
        .position(x: w * 0.50, y: h * 0.57)
    case .diaphragmaticBreathing:
      character("dog-side", size: w * 0.96, warp: 3).position(x: w * 0.50, y: h * 0.51)
    case .physiologicalSigh:
      character("cat-sit", size: min(w * 0.81, h * 1.08), warp: 0)
        .position(x: w * 0.46, y: h * 0.50)
      prop("cat-flower", width: w * 0.13, height: h * 0.22)
        .rotationEffect(.degrees(snapshot.phase == .exhale ? -6 * sin(min(1, snapshot.elapsedInPhase / 2) * .pi) * strength : 0), anchor: .bottom)
        .position(x: w * 0.83, y: h * 0.55)
    case .meditation:
      character("v5-cat-loaf", size: min(w * 0.96, h * 1.2), warp: 5)
        .position(x: w * 0.50, y: h * 0.50)
      prop("cat-leaf", width: w * 0.10, height: h * 0.12)
        .position(x: w * 0.84, y: h * 0.77)
    case .boxBreathing:
      character("cat-sit", size: min(w * 0.83, h * 1.08), warp: 0)
        .position(x: w * 0.50, y: h * 0.50)
    case .alternateNostrilBreathing:
      character("dog-sit", size: min(w * 0.79, h * 1.06), warp: 1)
        .position(x: w * 0.50, y: h * 0.50)
      prop("dog-leaf", width: w * 0.09, height: h * 0.13)
        .opacity(motion.side == -1 ? 1 : 0.28)
        .position(x: w * 0.10, y: h * 0.56)
      prop("cat-leaf", width: w * 0.09, height: h * 0.13)
        .opacity(motion.side == 1 ? 1 : 0.28)
        .position(x: w * 0.90, y: h * 0.56)
    case .kegel:
      character("dog-coach", size: min(w * 0.87, h * 1.08), warp: 4)
        .position(x: w * 0.53, y: h * 0.50)
    }
  }

  private func character(_ name: String, size: CGFloat, warp: Float, aspect: CGFloat = 1) -> some View {
    Image(name.hasPrefix("v5-") ? "PracticeV5-" + String(name.dropFirst(3)) : "PracticeV4R-" + name).resizable().aspectRatio(contentMode: .fit)
      .frame(width: size, height: size / aspect)
      .visualEffect { content, geometry in
        content.distortionEffect(
          ShaderLibrary.fangcunV4IntactBody(.float2(geometry.size), .float(warp),
            .float(Float((kind == .kegel ? motion.contraction : expansion) * strength)), .float(Float(attention))),
          maxSampleOffset: CGSize(width: 12, height: 12)
        )
      }.accessibilityHidden(true)
  }
  private func prop(_ name: String, width: CGFloat, height: CGFloat) -> some View {
    Image("PracticeV4-" + name).resizable().aspectRatio(contentMode: .fit)
      .frame(width: width, height: height).accessibilityHidden(true)
  }
  private var stageLabel: String {
    switch kind {
    case .physiologicalSigh: "小猫闻花，双吸一呼"
    case .pacedBreathing: "小狗枕爪，缓缓呼气"
    case .balancedBreathing: "猫狗并肩，同步呼吸"
    case .boxBreathing: "小猫安稳坐着，停留时身体保持"
    case .diaphragmaticBreathing: "小狗前爪放在下肋，腹部轻轻起伏；动作示范，按自己的节奏"
    case .alternateNostrilBreathing: "小狗和左右叶子，左右均指你自己"
    case .meditation: "小猫蜷卧闭眼，安静陪伴"
    case .nsdr: "小狗枕爪休息，跟随身体扫描放松"
    case .kegel: "小狗用旗子提示轻收与完全放松，呼吸照常"
    }
  }
}
