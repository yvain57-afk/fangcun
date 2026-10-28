import SwiftUI
import InnerBalanceCore

enum FangcunCompanionScene: String {
  case calm = "duo-calm", rest = "dog-rest", curious = "cat-curious"
  case drink = "dog-drink", breathe = "breathing", complete = "duo-complete"
  var mode: Float {
    switch self { case .calm: 0; case .rest: 1; case .curious: 2; case .drink: 3; case .breathe: 4; case .complete: 5 }
  }
  var ratio: CGFloat { self == .calm || self == .complete ? 1.5 : 1 }
  var label: String {
    switch self {
    case .calm: "Cat and dog keeping you company"
    case .rest: "Dog resting beside you"
    case .curious: "Cat looking around curiously"
    case .drink: "Dog beside a glass of water"
    case .breathe: "Cat following the breathing rhythm"
    case .complete: "Cat and dog celebrating a small pause"
    }
  }
}

struct FangcunCompanion: View {
  let scene: FangcunCompanionScene
  var breath: Double = 0
  var paused = false
  var reaction = 0
  var event: CompanionMotionEvent = .entered
  var committedEvent: CompanionEvent? = nil
  @Environment(\.accessibilityReduceMotion) private var systemReduced
  @Environment(\.scenePhase) private var phase
  @AppStorage("fangcun.reduceMotion") private var reduced = false
  @AppStorage("fangcun.motionMode") private var mode = CompanionMotionMode.standard.rawValue
  @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
  @State private var start = Date.now
  @State private var visible = true
  @State private var gesture: CompanionPresentation?
  @State private var coordinator = CompanionMotionCoordinator()
  private var key: String { committedEvent?.id ?? (scene.rawValue + ":" + String(reaction)) }
  private var staticMode: Bool { systemReduced || reduced || mode == "static" || lowPower }
  private var active: Bool { !staticMode && !paused && visible && phase == .active }
  private var eventValue: Float { event == .waterCommitted ? 1 : event == .drinkUndone ? 2 : event == .drinkCommitted ? 3 : 0 }
  var body: some View {
    Group {
      if scene == .breathe {
        // Authoritative session expansion survives pause. No decorative timeline.
        artwork(time: 0, amount: staticMode ? 0 : Float(breath), intensity: 1)
      } else if active, let gesture {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
          artwork(time: Float(context.date.timeIntervalSince(start)), amount: 0, intensity: Float(gesture.intensity))
        }
      } else { artwork(time: 0, amount: 0, intensity: 0) }
    }
    .aspectRatio(scene.ratio, contentMode: .fit)
    .accessibilityHidden(true)
    .onAppear { visible = true }
    .onDisappear { visible = false; gesture = nil; coordinator.stop() }
    .onScrollVisibilityChange { isVisible in visible = isVisible; if !isVisible { gesture = nil } }
    .onChange(of: active) { _, isActive in if !isActive { gesture = nil; coordinator.stop() } }
    .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
      lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    .task(id: key) {
      guard scene != .breathe else { return }
      let now = Date.now
      let motion = committedEvent ?? CompanionEvent(id: key, kind: coordinator.seen.isEmpty ? event : event == .entered ? .guidanceChanged : event, committedAt: now)
      gesture = coordinator.accept(motion, scene: scene.rawValue, context: "native", now: now,
        mode: CompanionMotionMode(rawValue: mode) ?? .standard, reduceMotion: systemReduced || reduced,
        lowPower: lowPower, visible: visible, active: phase == .active, covered: paused)
      guard let duration = gesture?.duration else { return }
      start = now
      do { try await Task.sleep(for: .seconds(duration)) } catch { return }
      gesture = nil; coordinator.stop()
    }
  }
  @ViewBuilder private func artwork(time: Float, amount: Float, intensity: Float) -> some View {
    if scene == .breathe {
      LittleExhaleCat(opening: Double(amount))
    } else if scene == .rest {
      LittleExhaleRestingDog(lift: 0)
    } else {
      let acknowledgement = staticMode ? 0 : sin(min(Double(time), 1) * .pi) * Double(intensity)
      // Native transparent layers retain their cream fill in both appearances.
      // White-keying the old illustrations erased the characters in dark mode.
      switch scene {
      case .drink:
        GeometryReader { geometry in
          LittleExhaleSeatedDog(leftLift: 0, rightLift: acknowledgement * 0.3)
          Image(systemName: "mug.fill")
            .font(.system(size: geometry.size.width * 0.17))
            .foregroundStyle(Color("FangcunInhale"))
            .position(x: geometry.size.width * 0.13, y: geometry.size.height * 0.77)
        }
      case .curious:
        LittleExhaleCat(opening: 0.2).rotationEffect(.degrees(-1.2 * acknowledgement))
      default:
        HStack(alignment: .bottom, spacing: 0) {
          LittleExhaleCat(opening: scene == .complete ? 0.35 + acknowledgement * 0.2 : 0.1)
          LittleExhaleSeatedDog(leftLift: scene == .complete ? 0.5 : 0, rightLift: 0)
        }
      }

    }
  }
}

extension View {
  func fangcunPaperCard() -> some View {
    self.padding(16)
      .background(InnerBalanceTheme.surface, in: RoundedRectangle(cornerRadius: 18))
      .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1) }
  }
}
