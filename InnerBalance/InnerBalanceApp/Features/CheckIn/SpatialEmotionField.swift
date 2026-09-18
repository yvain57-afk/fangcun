import SwiftUI

enum CompassGeometry {
  static let selectionDiameter: CGFloat = 76

  static func coordinates(for location: CGPoint, size: CGFloat) -> (
    valence: Double, arousal: Double
  ) {
    let center = CGPoint(x: size / 2, y: size / 2)
    let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
    let distance = hypot(vector.dx, vector.dy)
    let radius = drawableRadius(for: size)
    guard radius > 0 else { return (0, 0) }
    let scale = distance > radius ? radius / distance : 1
    return (
      Double(vector.dx * scale / radius),
      Double(-vector.dy * scale / radius)
    )
  }

  static func position(valence: Double, arousal: Double, size: CGFloat) -> CGPoint {
    let center = CGPoint(x: size / 2, y: size / 2)
    let radius = drawableRadius(for: size)
    guard radius > 0 else { return center }

    let vector = CGVector(dx: CGFloat(valence), dy: -CGFloat(arousal))
    let distance = hypot(vector.dx, vector.dy)
    let scale = distance > 1 ? 1 / distance : 1
    return CGPoint(
      x: center.x + vector.dx * scale * radius,
      y: center.y + vector.dy * scale * radius
    )
  }

  private static func drawableRadius(for size: CGFloat) -> CGFloat {
    max(0, size / 2 - selectionDiameter / 2)
  }
}

struct SpatialEmotionField: View {
  let valence: Double
  let arousal: Double
  let hasSelectedPosition: Bool
  let onPositionChanged: (CGPoint, CGFloat) -> Void
  let onPositionCommitted: (CGPoint, CGFloat) -> Void
  let onAdjust: (Double, Double) -> Void

  var body: some View {
    GeometryReader { proxy in
      let size = min(proxy.size.width, proxy.size.height)
      ZStack {
        emotionField
        CompassAxes()
        selectionOrb(size: size)
      }
      .frame(width: size, height: size)
      .contentShape(Circle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { onPositionChanged($0.location, size) }
          .onEnded { onPositionCommitted($0.location, size) }
      )
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("情绪罗盘")
      .accessibilityValue(accessibilityPosition)
      .accessibilityHint("轻点或拖动选择位置，也可使用四个方向操作")
      .accessibilityIdentifier("checkIn.emotionField")
      .accessibilityAction(named: "向愉快") { onAdjust(0.35, 0) }
      .accessibilityAction(named: "向不愉快") { onAdjust(-0.35, 0) }
      .accessibilityAction(named: "向有劲") { onAdjust(0, 0.35) }
      .accessibilityAction(named: "向低缓") { onAdjust(0, -0.35) }
    }
    .aspectRatio(1, contentMode: .fit)
  }

  private var emotionField: some View {
    Circle()
      .fill(InnerBalanceTheme.surface)
      .overlay { Circle().strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1) }
  }

  private func selectionOrb(size: CGFloat) -> some View {
    let position = CompassGeometry.position(valence: valence, arousal: arousal, size: size)
    return ZStack {
      Circle()
        .stroke(InnerBalanceTheme.subtleFill, lineWidth: 12)
        .frame(
          width: CompassGeometry.selectionDiameter,
          height: CompassGeometry.selectionDiameter
        )
      Circle()
        .stroke(InnerBalanceTheme.emphasis, lineWidth: 2)
        .frame(width: 46, height: 46)
      Circle()
        .fill(InnerBalanceTheme.strongFill)
        .frame(width: 24, height: 24)
    }
    .position(position)
    .opacity(EmotionCompassPresentation.orbOpacity(hasSelectedPosition: hasSelectedPosition))
    .accessibilityHidden(true)
  }

  private var accessibilityPosition: String {
    guard hasSelectedPosition else { return "尚未选择" }
    return "\(valence >= 0 ? "较愉快" : "较不愉快")，\(arousal >= 0 ? "较有劲" : "较低缓")"
  }
}

private struct CompassAxes: View {
  var body: some View {
    ZStack {
      Rectangle().fill(InnerBalanceTheme.hairline).frame(height: 1)
      Rectangle().fill(InnerBalanceTheme.hairline).frame(width: 1)
      VStack {
        Text("有劲")
        Spacer()
        Text("低缓")
      }
      .padding(.vertical, 16)
      HStack {
        Text("不愉快")
        Spacer()
        Text("愉快")
      }
      .padding(.horizontal, 16)
    }
    .font(.caption2.weight(.semibold))
    .foregroundStyle(InnerBalanceTheme.mutedInk)
    .clipShape(Circle())
    .accessibilityHidden(true)
  }
}
