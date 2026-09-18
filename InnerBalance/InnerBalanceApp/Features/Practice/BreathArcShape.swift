import SwiftUI

struct BreathArcShape: Shape {
  enum Side { case left, right }
  let side: Side

  nonisolated func path(in rect: CGRect) -> Path {
    var path = Path()
    let direction: CGFloat = switch side {
    case .left: -1
    case .right: 1
    }
    let centerX = rect.midX
    let outerX = centerX + direction * rect.width * 0.48
    let innerX = centerX + direction * rect.width * 0.12

    path.move(to: CGPoint(x: centerX, y: rect.minY))
    path.addCurve(
      to: CGPoint(x: centerX, y: rect.maxY),
      control1: CGPoint(x: outerX, y: rect.minY + rect.height * 0.18),
      control2: CGPoint(x: outerX, y: rect.maxY - rect.height * 0.18)
    )
    path.addCurve(
      to: CGPoint(x: centerX, y: rect.minY),
      control1: CGPoint(x: innerX, y: rect.maxY - rect.height * 0.24),
      control2: CGPoint(x: innerX, y: rect.minY + rect.height * 0.24)
    )
    return path
  }
}
