import SwiftUI
import InnerBalanceCore

/// A deterministic cutout stage. Every moving component is an authored RGBA sprite;
/// the only distortion is local torso expansion with a fixed ground anchor.
struct PracticeCompanionV4: View {
  let kind: PracticeKind
  let elapsed: Double
  let duration: Double
  var variantID: String? = nil
  var isActive = true
  var entryProgress = 1.0
  var completionProgress = 0.0
  @Environment(\.accessibilityReduceMotion) private var systemReduced
  @Environment(\.scenePhase) private var appPhase
  @AppStorage("fangcun.reduceMotion") private var reduceMotion = false
  @AppStorage("fangcun.motionMode") private var motionMode = "standard"
  @State private var visible = true
  private var snapshot: PracticeTimelineSnapshot {
    PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID)
  }
  private var animated: Bool { isActive && visible && appPhase == .active && !systemReduced && !reduceMotion && motionMode != "static" && !ProcessInfo.processInfo.isLowPowerModeEnabled }
  private var intensity: Double { animated ? (motionMode == "gentle" ? 0.45 : 1) : 0 }
  private var p: Double { snapshot.phaseProgress }
  private func smooth(_ v: Double) -> Double { let t = min(1,max(0,v)); return t*t*(3-2*t) }
  private var breath: Double {
    guard isActive else { return 0 }
    switch snapshot.phase {
    case .inhale, .leftInhale, .rightInhale: return smooth(p) * (kind == .physiologicalSigh ? 0.82 : 1)
    case .topUp: return 0.82 + 0.18 * smooth(p)
    case .holdAfterInhale: return 1
    case .exhale, .leftExhale, .rightExhale: return 1-smooth(p)
    default: return 0
    }
  }
  private var event: Double { animated ? sin(min(1,snapshot.elapsedInPhase/2.4) * .pi) : 0 }
  private var blink: Bool {
    // Low-frequency expressions belong at a full-cycle boundary, never at a
    // top-up, nostril switch, hold or pelvic-floor contraction instruction.
    animated && ((snapshot.phase == .inhale && snapshot.cycleIndex % 4 == 3 && snapshot.elapsedInPhase < 0.35)
      || (completionProgress > 0.2 && completionProgress < 0.6))
  }
  private var closingGesture: Double { animated ? sin(min(1,max(0,completionProgress)) * .pi) : 0 }
  private var quietEyes: Bool { kind == .pacedBreathing || kind == .nsdr || kind == .meditation }
  private var liesDown: Bool { kind == .pacedBreathing || kind == .diaphragmaticBreathing || kind == .nsdr }
  private var settling: Double { animated && entryProgress < 1 ? 1 - smooth(entryProgress) : 0 }
  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = min(proxy.size.height,width * 0.78)
      ZStack {
        stage(width: width,height: height)
          .opacity(animated && liesDown && entryProgress < 1 ? smooth((entryProgress-0.60)/0.35) : 1)
        if animated && liesDown && entryProgress < 1 {
          // Three authored key poses preserve anatomy through the change in support.
          // Only the final layered rig is used for the actual training timeline.
          sprite("dog-poster",w:width*0.58,h:height*0.70,x:width*0.48,y:height*0.53)
            .opacity(1-smooth((entryProgress-0.16)/0.20))
          sprite("rest-crouch",w:width*0.67,h:height*0.60,x:width*0.48,y:height*0.61)
            .opacity(smooth((entryProgress-0.16)/0.20) * (1-smooth((entryProgress-0.60)/0.35)))
        }
      }
      .frame(width: width,height: height)
      .frame(maxHeight: .infinity)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(stageLabel)
    .onAppear { visible = true }
    .onDisappear { visible = false }
    .onScrollVisibilityChange { visible = $0 }
  }
  private var stageLabel: String {
    let scene = switch kind {
    case .physiologicalSigh: "小猫闻花，双吸一呼"
    case .pacedBreathing: "小狗枕爪，缓缓呼气"
    case .balancedBreathing: "猫狗并肩，同步呼吸"
    case .boxBreathing: "小猫与四角坐垫，停留时身体保持"
    case .diaphragmaticBreathing: "小狗侧躺，轻放前爪在下肋；按自己的节奏"
    case .alternateNostrilBreathing: "小狗和左右叶子，左右均指你自己"
    case .meditation: "小猫安静坐稳，注意力回来时轻睁眼"
    case .nsdr: "小狗盖好薄毯，跟随身体扫描放松"
    case .kegel: "小狗举旗提示轻收，落旗提示完全放松；呼吸照常"
    }
    return scene
  }
  @ViewBuilder private func stage(width w: CGFloat,height h: CGFloat) -> some View {
    if kind == .balancedBreathing {
      Image("PracticeV4-cat-mat").resizable()
        .frame(width:w*0.81,height:h*0.17).position(x:w*0.5,y:h*0.86)
        .accessibilityHidden(true)
      cat(w:w*0.67,h:h*0.95).offset(x:-w*(0.20 + settling*0.025),y:0)
      dog(w:w*0.66,h:h*0.95).offset(x:w*0.20,y:0)
    } else if kind == .pacedBreathing || kind == .diaphragmaticBreathing || kind == .nsdr {
      restingDog(w:w,h:h)
    } else if kind == .physiologicalSigh || kind == .meditation || kind == .boxBreathing {
      if kind == .boxBreathing {
        sprite("cat-mat",w:w*0.65,h:h*0.19,x:w*0.5,y:h*0.86)
        ForEach(0..<4) { index in
          let activeIndex = snapshot.cueID % 4
          RoundedRectangle(cornerRadius: 3).fill(InnerBalanceTheme.strongFill.opacity(activeIndex == index && isActive ? 0.9 : 0.18))
            .frame(width: 9,height:9)
            .position(x:w*(index == 0 || index == 3 ? 0.22 : 0.78),y:h*(index < 2 ? 0.78 : 0.93))
        }
      }
      cat(w:w,h:h)
      if kind == .physiologicalSigh {
        sprite("cat-flower",w:w*0.15,h:h*0.26,x:w*0.75,y:h*0.56,
          angle: snapshot.phase == .exhale ? event*intensity*5 : 0,anchor:.bottom)
      }
      if kind == .meditation {
        let returnPoint = snapshot.segment?.focus == "return"
        sprite("cat-leaf",w:w*0.10,h:h*0.13,x:w*0.74,y:h*(returnPoint ? 0.66-event*0.03*intensity : 0.69),angle:-18)
      }
    } else {
      dog(w:w,h:h)
      if kind == .alternateNostrilBreathing {
        let left = snapshot.phase == .leftInhale || snapshot.phase == .leftExhale
        sprite("dog-leaf",w:w*0.13,h:h*0.18,x:w*0.14,y:h*0.50,angle:left ? -8*intensity : 0)
          .opacity(!isActive || left ? 1 : 0.4)
        sprite("cat-leaf",w:w*0.13,h:h*0.18,x:w*0.86,y:h*0.50,angle:left ? 0 : 8*intensity)
          .opacity(!isActive || !left ? 1 : 0.4)
        HStack { Text("你的左侧"); Spacer(); Text("你的右侧") }
          .font(.caption2).foregroundStyle(InnerBalanceTheme.mutedInk)
          .frame(width:w*0.90).position(x:w*0.5,y:h*0.90)
      }
    }
  }
  private func sprite(_ name:String,w:CGFloat,h:CGFloat,x:CGFloat,y:CGFloat,angle:Double=0,anchor:UnitPoint = .center) -> some View {
    Image("PracticeV4-"+name).resizable().aspectRatio(contentMode:.fit)
      .frame(width:w,height:h).rotationEffect(.degrees(angle),anchor:anchor).position(x:x,y:y)
      .accessibilityHidden(true)
  }
  private func torso(_ name:String,w:CGFloat,h:CGFloat,x:CGFloat,y:CGFloat,amount:Double) -> some View {
    Image("PracticeV4-"+name).resizable().aspectRatio(contentMode:.fit)
      .frame(width:w,height:h)
      .visualEffect { content,geometry in
        content.distortionEffect(ShaderLibrary.fangcunV4Torso(.float2(geometry.size),.float(Float(amount))),maxSampleOffset:CGSize(width:5,height:5))
      }.position(x:x,y:y).accessibilityHidden(true)
  }
  private func cat(w:CGFloat,h:CGFloat) -> some View {
    let t = snapshot.phase == .topUp ? 1.0 : breath
    let headAngle = kind == .physiologicalSigh ? intensity*(breath*1.2 - (snapshot.phase == .topUp ? 0.4 : 0) + sin(entryProgress * .pi)*2) : 0
    let closed = quietEyes && snapshot.segment?.focus != "return" || blink
    return ZStack {
      sprite("cat-tail",w:w*0.22,h:h*0.42,x:w*0.30,y:h*0.64,angle:closingGesture*intensity*3,anchor:.bottomTrailing)
      torso("torso-cat",w:w*0.43,h:h*0.45,x:w*0.51,y:h*0.68,amount:breath*intensity)
      sprite("cat-paw-left",w:w*0.09,h:h*0.24,x:w*0.45,y:h*(0.81-settling*0.035*intensity),angle:kind == .boxBreathing ? -event*intensity*4 : 0,anchor:.top)
      sprite("cat-paw-right",w:w*0.09,h:h*0.24,x:w*0.57,y:h*0.81)
      sprite(closed ? "cat-closed" : "cat-head",w:w*0.49,h:h*0.48,x:w*(0.51+t*0.004*intensity),y:h*(0.40+closingGesture*0.006),angle:headAngle,anchor:.bottom)
    }.frame(width:w,height:h)
  }
  private func dog(w:CGFloat,h:CGFloat) -> some View {
    let turn: Double = {
      guard kind == .alternateNostrilBreathing && isActive else { return 0 }
      switch snapshot.phase {
      case .leftInhale: return -1
      case .rightExhale: return -1 + 2*smooth(snapshot.elapsedInPhase/0.25)
      case .rightInhale: return 1
      case .leftExhale: return 1 - 2*smooth(snapshot.elapsedInPhase/0.25)
      default: return 0
      }
    }()
    let flag = kind == .kegel && snapshot.phase == .contract && isActive ? smooth(snapshot.elapsedInPhase/0.35) : kind == .kegel && snapshot.phase == .release && isActive ? 1-smooth(snapshot.elapsedInPhase/0.4) : 0
    return ZStack {
      sprite("dog-tail",w:w*0.17,h:h*0.26,x:w*0.68,y:h*0.77)
      torso("torso-cat",w:w*0.41,h:h*0.45,x:w*0.51,y:h*0.69,amount:kind == .kegel ? 0 : breath*intensity)
      sprite("dog-paw-left",w:w*0.10,h:h*0.23,x:w*0.45,y:h*(0.81-settling*0.025*intensity),angle: -flag*intensity*16,anchor:.top)
      sprite("dog-paw-right",w:w*0.10,h:h*0.23,x:w*0.57,y:h*0.81)
      ZStack {
        sprite(blink ? "dog-closed" : "dog-head",w:w*0.46,h:h*0.44,x:w*0.50,y:h*(0.40+closingGesture*0.006))
        sprite("dog-ear-left",w:w*0.22,h:h*0.28,x:w*0.32,y:h*0.34,angle: -event*intensity,anchor:.topTrailing)
        sprite("dog-ear-right",w:w*0.18,h:h*0.29,x:w*0.70,y:h*0.38,angle:event*intensity,anchor:.topLeading)
      }.rotationEffect(.degrees(turn*intensity*2),anchor:UnitPoint(x:0.5,y:0.57))
      if kind == .kegel {
        sprite("dog-flag",w:w*0.20,h:h*0.36,x:w*0.32,y:h*(0.71 - flag*0.12),angle: -8 + flag*8,anchor:.bottom)
      }
    }.frame(width:w,height:h)
  }
  private func restingDog(w:CGFloat,h:CGFloat) -> some View {
    let prone = kind == .pacedBreathing
    let focus = snapshot.segment?.focus ?? ""
    let relax = ["shoulders","belly","legs","feet","lowerRibs","release"].contains(focus) ? smooth(snapshot.elapsedInPhase/2.4) : 0
    let eyesClosed = quietEyes && focus != "return" || blink
    return ZStack {
      sprite("rest-pillow",w:w*0.72,h:h*0.23,x:w*0.40,y:h*0.88)
      sprite("dog-tail",w:w*0.13,h:h*0.20,x:w*0.83,y:h*0.70)
      torso(prone ? "rest-prone" : "torso-dog-side",w:w*0.54,h:h*0.40,x:w*0.60,y:h*0.67,
        amount:prone ? breath*intensity : (focus == "belly" ? -0.25*relax*intensity : 0))
      sprite("rest-legs",w:w*0.21,h:h*0.22,x:w*(0.73+((focus == "legs" || focus == "feet") ? 0.014*relax*intensity : 0)),y:h*0.76)
      if kind == .nsdr {
        sprite("rest-blanket",w:w*0.36,h:h*0.31,x:w*0.69,y:h*0.68)
      }
      sprite("dog-paw-left",w:w*0.12,h:h*0.18,x:w*0.29,y:h*0.84,angle:-65)
      sprite("rest-paw",w:w*0.29,h:h*0.18,x:w*0.48,y:h*(prone ? 0.83 : 0.73),
        angle: !prone && focus == "lowerRibs" ? event*intensity*5 : 0,anchor:.trailing)
      ZStack {
        sprite(eyesClosed ? "rest-closed" : "rest-head",w:w*0.38,h:h*0.42,x:w*0.34,y:h*0.63)
        sprite("rest-ear-left",w:w*0.20,h:h*0.28,x:w*0.21,y:h*0.55,angle:-event*intensity,anchor:.topTrailing)
        sprite("rest-ear-right",w:w*0.15,h:h*0.29,x:w*0.50,y:h*0.60,angle:event*intensity,anchor:.topLeading)
      }.rotationEffect(.degrees(focus == "face" ? event*intensity*0.8 : 0),anchor:UnitPoint(x:0.34,y:0.74))
        .offset(y: focus == "shoulders" ? h*0.008*relax*intensity : 0)
    }.frame(width:w,height:h)
  }
}
