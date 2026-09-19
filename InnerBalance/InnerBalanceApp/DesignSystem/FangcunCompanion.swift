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
    case .calm: "猫咪和小狗安静相伴"
    case .rest: "小狗趴下陪你休息"
    case .curious: "猫咪好奇地观察"
    case .drink: "小狗在水杯旁陪你记录"
    case .breathe: "猫咪跟随节拍呼吸"
    case .complete: "猫咪和小狗轻轻碰爪"
    }
  }
}

struct FangcunCompanion: View {
  let scene: FangcunCompanionScene
  var breath: Double = 0
  var paused = false
  var reaction = 0
  var event: CompanionMotionEvent = .entered
  @Environment(\.accessibilityReduceMotion) private var systemReduced
  @Environment(\.scenePhase) private var phase
  @AppStorage("fangcun.reduceMotion") private var reduced = false
  @AppStorage("fangcun.motionMode") private var mode = CompanionMotionMode.standard.rawValue
  @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
  @State private var start = Date.now
  @State private var visible = true
  @State private var gesture: CompanionPresentation?
  @State private var coordinator = CompanionMotionCoordinator()
  private var key: String { scene.rawValue + ":" + String(reaction) }
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
      let motion = CompanionEvent(id: key, kind: event, committedAt: now)
      gesture = coordinator.accept(motion, scene: scene.rawValue, context: "native", now: now,
        mode: CompanionMotionMode(rawValue: mode) ?? .standard, reduceMotion: systemReduced || reduced,
        lowPower: lowPower, visible: visible, active: phase == .active, covered: paused)
      guard let duration = gesture?.duration else { return }
      start = now
      do { try await Task.sleep(for: .seconds(duration)) } catch { return }
      gesture = nil; coordinator.stop()
    }
  }
  private func artwork(time: Float, amount: Float, intensity: Float) -> some View {
    Image("Companion-\(scene.rawValue)").resizable().aspectRatio(contentMode: .fit)
      .colorEffect(ShaderLibrary.fangcunPaperAlpha())
      .visualEffect { content, geometry in
        content.distortionEffect(ShaderLibrary.fangcunCompanionWarp(.float2(geometry.size), .float(scene.mode),
          .float(time), .float(amount), .float(staticMode ? 1 : 0), .float(eventValue), .float(intensity)),
          maxSampleOffset: CGSize(width: 10, height: 10))
      }
  }
}

extension View {
  func fangcunPaperCard() -> some View {
    self.padding(20)
      .background(InnerBalanceTheme.surface, in: RoundedRectangle(cornerRadius: 24))
      .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(InnerBalanceTheme.hairline.opacity(0.5), lineWidth: 0.7) }
  }
}
