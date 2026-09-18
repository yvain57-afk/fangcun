import SwiftUI

struct PracticeTransportControls: View {
  let isPaused: Bool
  let onTogglePause: () -> Void
  let onFinish: () -> Void

  var body: some View {
    HStack {
      Button(action: onFinish) {
        Label("结束", systemImage: "xmark")
          .labelStyle(.titleAndIcon)
          .frame(minWidth: 76, minHeight: 52)
      }
      .buttonStyle(PracticeQuietControlStyle())

      Spacer()

      Button(action: onTogglePause) {
        Image(systemName: isPaused ? "play.fill" : "pause.fill")
          .font(.title3.weight(.semibold))
          .frame(width: 68, height: 68)
      }
      .buttonStyle(PracticePrimaryControlStyle())
      .accessibilityLabel(isPaused ? "继续练习" : "暂停练习")
    }
    .padding(.top, FangcunLayout.spacing(3))
    .padding(.bottom, FangcunLayout.spacing(4))
    .sensoryFeedback(.impact(weight: .light), trigger: isPaused)
  }
}

private struct PracticeQuietControlStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(InnerBalanceTheme.mutedInk)
      .background(InnerBalanceTheme.subtleFill, in: Capsule())
      .overlay { Capsule().strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1) }
      .opacity(configuration.isPressed ? 0.62 : 1)
  }
}

private struct PracticePrimaryControlStyle: ButtonStyle {
  @Environment(\.fangcunReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(InnerBalanceTheme.inverseInk)
      .background(InnerBalanceTheme.strongFill, in: Circle())
      .scaleEffect(
        FangcunMotion.pressScale(
          isPressed: configuration.isPressed,
          reduceMotion: reduceMotion
        )
      )
      .animation(
        FangcunMotion.pressAnimation(reduceMotion: reduceMotion),
        value: configuration.isPressed
      )
  }
}
