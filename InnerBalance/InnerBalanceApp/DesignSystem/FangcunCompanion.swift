import SwiftUI

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
  @Environment(\.accessibilityReduceMotion) private var systemReduced
  @Environment(\.scenePhase) private var phase
  @AppStorage("fangcun.reduceMotion") private var reduced = false
  @State private var start = Date.now
  @State private var visible = true
  @State private var frozenTime = 0.0
  @State private var gestureFinished = false

  var body: some View {
    let mode = scene.mode
    let amount = Float(breath)
    let reduceValue: Float = systemReduced || reduced ? 1 : 0
    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: stopped)) { context in
      let time = stopped ? frozenTime : context.date.timeIntervalSince(start)
      Image("Companion-\(scene.rawValue)")
        .resizable().aspectRatio(contentMode: .fit)
        .visualEffect { content, geometry in
          content.distortionEffect(
            ShaderLibrary.fangcunCompanionWarp(.float2(geometry.size), .float(mode),
              .float(Float(time)), .float(amount), .float(reduceValue)),
            maxSampleOffset: CGSize(width: 10, height: 10))
        }
    }
    .aspectRatio(scene.ratio, contentMode: .fit)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .accessibilityLabel(scene.label)
    .onAppear { start = .now; visible = true }
    .onDisappear { visible = false }
    .onScrollVisibilityChange { isVisible in visible = isVisible }
    .onChange(of: stopped) { wasStopped, isStopped in
      if isStopped { frozenTime = Date.now.timeIntervalSince(start) }
      else if wasStopped { start = Date.now.addingTimeInterval(-frozenTime) }
    }
    .onChange(of: reaction) { _, _ in start = .now; frozenTime = 0 }
    .task(id: reaction) {
      guard scene == .drink || scene == .complete else { return }
      gestureFinished = false
      do { try await Task.sleep(for: .milliseconds(1500)) }
      catch { return }
      gestureFinished = true
    }
  }
  // Breathing receives its expansion from the session clock; it needs no second clock.
  private var stopped: Bool { scene == .breathe || gestureFinished || paused || systemReduced || reduced || !visible || phase != .active }
}

extension View {
  func fangcunPaperCard() -> some View {
    self.padding(20)
      .background(InnerBalanceTheme.surface, in: RoundedRectangle(cornerRadius: 24))
      .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(InnerBalanceTheme.hairline.opacity(0.5), lineWidth: 0.7) }
  }
}
