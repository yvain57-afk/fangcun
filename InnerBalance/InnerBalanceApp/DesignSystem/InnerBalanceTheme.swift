import SwiftUI

enum FangcunLayout {
  static let gridUnit: CGFloat = 4
  static let pageHorizontalPadding: CGFloat = 24

  static func spacing(_ units: CGFloat) -> CGFloat {
    gridUnit * units
  }
}

enum FangcunSurface {
  static let levelOneBorderOpacity = 0.04
  static let levelOneCornerRadius: CGFloat = 24
  static let responseCornerRadius: CGFloat = 28
  static let compactCornerRadius: CGFloat = 18
  static let editorialResponseCornerRadius: CGFloat = 12
  static let editorialActionCornerRadius: CGFloat = 8
}

struct FangcunTypographyToken: Equatable {
  let basePointSize: CGFloat
  let tracking: CGFloat
}

enum FangcunTypography {
  static let display = FangcunTypographyToken(basePointSize: 50, tracking: -1.2)
  static let quote = FangcunTypographyToken(basePointSize: 22, tracking: 0.33)
  static let action = FangcunTypographyToken(basePointSize: 28, tracking: -0.28)
  static let body = FangcunTypographyToken(basePointSize: 16, tracking: 0)
}

enum FangcunMotion {
  static let pressDuration = 0.14
  static let stateDuration = 0.18
  static let entranceDuration = 0.20
  static let reducedMotionFadeDuration = 0.12
  static let entranceOffset: CGFloat = 8
  static let entranceDelayStep = 0.03

  static func pressScale(isPressed: Bool, reduceMotion: Bool) -> CGFloat {
    isPressed && !reduceMotion ? 0.97 : 1
  }

  static func pressOpacity(isPressed: Bool) -> Double {
    isPressed ? 0.84 : 1
  }

  static func entranceTranslation(isPresented: Bool, reduceMotion: Bool) -> CGFloat {
    isPresented || reduceMotion ? 0 : entranceOffset
  }

  static func entranceDelay(for index: Int, reduceMotion: Bool) -> Double {
    reduceMotion ? 0 : Double(max(0, index)) * entranceDelayStep
  }

  static func pressAnimation(reduceMotion: Bool) -> Animation {
    reduceMotion
      ? .easeOut(duration: reducedMotionFadeDuration)
      : strongEaseOut(duration: pressDuration)
  }

  static func stateAnimation(reduceMotion: Bool) -> Animation {
    reduceMotion
      ? .easeOut(duration: reducedMotionFadeDuration)
      : strongEaseOut(duration: stateDuration)
  }

  static func entranceAnimation(index: Int, reduceMotion: Bool) -> Animation {
    if reduceMotion {
      return .easeOut(duration: reducedMotionFadeDuration)
    }
    return strongEaseOut(duration: entranceDuration)
      .delay(entranceDelay(for: index, reduceMotion: false))
  }

  private static func strongEaseOut(duration: Double) -> Animation {
    .timingCurve(0.23, 1, 0.32, 1, duration: duration)
  }
}

enum InnerBalanceTheme {
  static let canvas = Color("FangcunBackground")
  static let surface = Color("FangcunCard")
  static let elevatedSurface = Color("FangcunRaisedCard")
  static let ink = Color("FangcunPrimaryText")
  static let mutedInk = Color("FangcunSecondaryText")
  static let strongFill = Color("FangcunAccent")
  static let subtleFill = Color("FangcunAccentWash")
  static let emphasis = Color("FangcunWarmHighlight")
  static let inverseInk = Color("FangcunButtonText")
  static let hairline = ink.opacity(0.10)
}

private struct FangcunQuoteTextStyle: ViewModifier {
  @ScaledMetric(relativeTo: .title2) private var pointSize = FangcunTypography.quote.basePointSize
  @ScaledMetric(relativeTo: .title2) private var lineSpacing: CGFloat = 9

  func body(content: Content) -> some View {
    content
      .font(.system(size: pointSize, weight: .semibold, design: .default))
      .tracking(FangcunTypography.quote.tracking)
      .lineSpacing(lineSpacing)
  }
}

private struct FangcunActionTextStyle: ViewModifier {
  @ScaledMetric(relativeTo: .title) private var pointSize = FangcunTypography.action.basePointSize

  func body(content: Content) -> some View {
    content
      .font(.system(size: pointSize, weight: .semibold, design: .default))
      .tracking(FangcunTypography.action.tracking)
  }
}

private struct FangcunBodyTextStyle: ViewModifier {
  @ScaledMetric(relativeTo: .body) private var pointSize = FangcunTypography.body.basePointSize

  func body(content: Content) -> some View {
    content.font(.system(size: pointSize, weight: .regular, design: .default))
  }
}

private struct FangcunSectionLabelTextStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.caption.weight(.semibold))
      .tracking(1.2)
      .foregroundStyle(InnerBalanceTheme.strongFill)
  }
}

private struct FangcunLevelOneSurface: ViewModifier {
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    content
      .background(
        InnerBalanceTheme.elevatedSurface,
        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(
            Color.primary.opacity(FangcunSurface.levelOneBorderOpacity),
            lineWidth: 1
          )
      }
  }
}

private struct FangcunResponseSurface: ViewModifier {
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    content
      .background(
        InnerBalanceTheme.elevatedSurface,
        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1)
      }
  }
}

struct FangcunEditorialRule: View {
  @Environment(\.colorSchemeContrast) private var colorSchemeContrast

  let emphasized: Bool

  init(emphasized: Bool = false) {
    self.emphasized = emphasized
  }

  var body: some View {
    Rectangle()
      .fill(
        InnerBalanceTheme.ink.opacity(
          emphasized ? 0.92 : (colorSchemeContrast == .increased ? 0.36 : 0.12)
        )
      )
      .accessibilityHidden(true)
  }
}

private struct FangcunEntranceModifier: ViewModifier {
  @Environment(\.fangcunReduceMotion) private var reduceMotion

  let index: Int
  let isPresented: Bool

  func body(content: Content) -> some View {
    content
      .opacity(isPresented ? 1 : 0)
      .offset(
        y: FangcunMotion.entranceTranslation(
          isPresented: isPresented,
          reduceMotion: reduceMotion
        )
      )
      .animation(
        FangcunMotion.entranceAnimation(index: index, reduceMotion: reduceMotion),
        value: isPresented
      )
  }
}

extension View {
  func fangcunQuoteStyle() -> some View {
    modifier(FangcunQuoteTextStyle())
  }

  func fangcunActionStyle() -> some View {
    modifier(FangcunActionTextStyle())
  }

  func fangcunBodyStyle() -> some View {
    modifier(FangcunBodyTextStyle())
  }

  func fangcunSectionLabelStyle() -> some View {
    modifier(FangcunSectionLabelTextStyle())
  }

  func fangcunLevelOneSurface(
    cornerRadius: CGFloat = FangcunSurface.levelOneCornerRadius
  ) -> some View {
    modifier(FangcunLevelOneSurface(cornerRadius: cornerRadius))
  }

  func fangcunResponseSurface(
    cornerRadius: CGFloat = FangcunSurface.responseCornerRadius
  ) -> some View {
    modifier(FangcunResponseSurface(cornerRadius: cornerRadius))
  }

  func fangcunEntrance(index: Int, isPresented: Bool) -> some View {
    modifier(FangcunEntranceModifier(index: index, isPresented: isPresented))
  }
}

struct FangcunPressButtonStyle: ButtonStyle {
  @Environment(\.fangcunReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(
        FangcunMotion.pressScale(
          isPressed: configuration.isPressed,
          reduceMotion: reduceMotion
        )
      )
      .opacity(FangcunMotion.pressOpacity(isPressed: configuration.isPressed))
      .animation(
        FangcunMotion.pressAnimation(reduceMotion: reduceMotion),
        value: configuration.isPressed
      )
  }
}

struct InnerBalancePrimaryButtonStyle: ButtonStyle {
  @Environment(\.fangcunReduceMotion) private var reduceMotion

  let onStrongSurface: Bool
  let cornerRadius: CGFloat

  init(
    onStrongSurface: Bool = false,
    cornerRadius: CGFloat = FangcunLayout.spacing(5)
  ) {
    self.onStrongSurface = onStrongSurface
    self.cornerRadius = cornerRadius
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(
        onStrongSurface ? InnerBalanceTheme.strongFill : InnerBalanceTheme.inverseInk
      )
      .frame(maxWidth: .infinity)
      .padding(.vertical, FangcunLayout.spacing(4))
      .background(
        onStrongSurface ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.strongFill,
        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
      .scaleEffect(
        FangcunMotion.pressScale(
          isPressed: configuration.isPressed,
          reduceMotion: reduceMotion
        )
      )
      .opacity(FangcunMotion.pressOpacity(isPressed: configuration.isPressed))
      .animation(
        FangcunMotion.pressAnimation(reduceMotion: reduceMotion),
        value: configuration.isPressed
      )
  }
}
