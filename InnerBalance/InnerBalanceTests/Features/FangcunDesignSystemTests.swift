import Testing
import UIKit

@testable import InnerBalance

@Suite("Fangcun design system")
struct FangcunDesignSystemTests {
  @Test("The iPhone interface uses only approved flat monochrome primitives")
  func flatMonochromePrimitives() throws {
    let appSource = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appending(path: "InnerBalanceApp")
    let bannedTokens = [
      "LinearGradient(",
      "RadialGradient(",
      ".shadow(",
      ".ultraThinMaterial",
      "design: .serif",
      "design: .rounded",
      ".preferredColorScheme(.dark)",
    ]
    let enumerator = try #require(
      FileManager.default.enumerator(
        at: appSource,
        includingPropertiesForKeys: nil
      )
    )
    var violations: [String] = []

    for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
      let source = try String(contentsOf: fileURL, encoding: .utf8)
      for token in bannedTokens where source.contains(token) {
        violations.append("\(fileURL.lastPathComponent): \(token)")
      }
    }

    #expect(violations == [])
  }

  @Test("The system tab bar keeps the native floating surface")
  func nativeFloatingTabBar() throws {
    let rootView = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appending(path: "InnerBalanceApp/App/RootView.swift")
    let source = try String(contentsOf: rootView, encoding: .utf8)

    #expect(!source.contains("configureWithOpaqueBackground()"))
    #expect(!source.contains("isTranslucent = false"))
    #expect(!source.contains("scrollEdgeAppearance = appearance"))
    #expect(!source.contains(".toolbarBackground(InnerBalanceTheme.elevatedSurface, for: .tabBar)"))
    #expect(!source.contains(".toolbarBackground(.visible, for: .tabBar)"))
  }

  @Test("Scrollable pages do not reserve a second tab bar height")
  func compactScrollTailSpacing() throws {
    let appSource = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appending(path: "InnerBalanceApp")
    let home = try String(
      contentsOf: appSource.appending(path: "Features/Home/HomeView.swift"),
      encoding: .utf8
    )
    let practiceLibrary = try String(
      contentsOf: appSource.appending(path: "Features/Practice/PracticeLibraryView.swift"),
      encoding: .utf8
    )

    #expect(!home.contains(".padding(.bottom, 112)"))
    #expect(!practiceLibrary.contains(".padding(.bottom, FangcunLayout.spacing(28))"))
  }

  @Test("The warm paper palette is accessible in both appearances")
  @MainActor
  func approvedPaperPalette() throws {
    let expected: [String: (light: UInt32, dark: UInt32)] = [
      "AccentColor": (0x403A34, 0x51463D),
      "FangcunAccent": (0x403A34, 0x51463D),
      "FangcunAccentWash": (0xE8E0D5, 0xC9BCAF),
      "FangcunBackground": (0xF2EDE5, 0xD9D0C4),
      "FangcunButtonText": (0xFFF9F0, 0xF9F1E7),
      "FangcunCard": (0xF8F4ED, 0xE3DBCF),
      "FangcunPrimaryText": (0x292521, 0x2D2823),
      "FangcunRaisedCard": (0xFFF9F1, 0xEEE6DB),
      "FangcunSecondaryText": (0x6B625A, 0x605850),
      "FangcunWarmHighlight": (0x9A6D4B, 0x8C6246),
    ]

    for (name, pair) in expected {
      let light = try resolvedRGB(named: name, style: .light)
      let dark = try resolvedRGB(named: name, style: .dark)
      #expect(light.hex == pair.light, "\(name) light appearance drifted")
      #expect(dark.hex == pair.dark, "\(name) dark appearance drifted")
    }

    let lightBackground = try resolvedRGB(named: "FangcunBackground", style: .light)
    let lightPrimary = try resolvedRGB(named: "FangcunPrimaryText", style: .light)
    let lightSecondary = try resolvedRGB(named: "FangcunSecondaryText", style: .light)
    let darkBackground = try resolvedRGB(named: "FangcunBackground", style: .dark)
    let darkPrimary = try resolvedRGB(named: "FangcunPrimaryText", style: .dark)
    let darkSecondary = try resolvedRGB(named: "FangcunSecondaryText", style: .dark)
    let lightButton = try resolvedRGB(named: "FangcunAccent", style: .light)
    let lightButtonText = try resolvedRGB(named: "FangcunButtonText", style: .light)
    let darkButton = try resolvedRGB(named: "FangcunAccent", style: .dark)
    let darkButtonText = try resolvedRGB(named: "FangcunButtonText", style: .dark)

    #expect(contrast(lightPrimary, lightBackground) >= 4.5)
    #expect(contrast(lightSecondary, lightBackground) >= 4.5)
    #expect(contrast(darkPrimary, darkBackground) >= 4.5)
    #expect(contrast(darkSecondary, darkBackground) >= 4.5)
    #expect(contrast(lightButtonText, lightButton) >= 4.5)
    #expect(contrast(darkButtonText, darkButton) >= 4.5)
  }

  @Test("The paper appearance stays ink-on-paper when the system turns dark")
  func paperAppearanceDoesNotInvertAtNight() throws {
    let appEntry = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appending(path: "InnerBalanceApp/App/InnerBalanceApp.swift")
    let source = try String(contentsOf: appEntry, encoding: .utf8)

    #expect(source.contains(".preferredColorScheme(.light)"))
  }

  @Test("Breathing-field tokens keep the approved base measurements")
  func approvedBaseMeasurements() {
    #expect(FangcunLayout.gridUnit == 4)
    #expect(FangcunLayout.pageHorizontalPadding == 24)
    #expect(FangcunLayout.spacing(5) == 20)
    #expect(FangcunSurface.levelOneBorderOpacity == 0.04)
    #expect(FangcunSurface.editorialResponseCornerRadius == 12)
    #expect(FangcunTypography.display.basePointSize == 50)
    #expect(FangcunTypography.display.tracking == -1.2)
    #expect(FangcunTypography.quote.basePointSize == 22)
    #expect(FangcunTypography.quote.tracking == 0.33)
    #expect(FangcunTypography.action.basePointSize == 28)
    #expect(FangcunTypography.action.tracking == -0.28)
    #expect(FangcunTypography.body.basePointSize == 16)
  }

  @Test("Motion feedback stays subtle and removes physical movement for Reduce Motion")
  func motionFeedbackPolicy() {
    #expect(FangcunMotion.pressDuration == 0.14)
    #expect(FangcunMotion.stateDuration == 0.18)
    #expect(FangcunMotion.entranceDuration == 0.20)
    #expect(FangcunMotion.pressScale(isPressed: true, reduceMotion: false) == 0.97)
    #expect(FangcunMotion.pressScale(isPressed: true, reduceMotion: true) == 1)
    #expect(FangcunMotion.pressOpacity(isPressed: true) < 1)
    #expect(
      FangcunMotion.entranceTranslation(isPresented: false, reduceMotion: false) == 8
    )
    #expect(
      FangcunMotion.entranceTranslation(isPresented: false, reduceMotion: true) == 0
    )
    #expect(abs(FangcunMotion.entranceDelay(for: 3, reduceMotion: false) - 0.09) < 0.000_001)
    #expect(FangcunMotion.entranceDelay(for: 3, reduceMotion: true) == 0)
  }

  @MainActor
  private func resolvedRGB(
    named name: String,
    style: UIUserInterfaceStyle
  ) throws -> RGBColor {
    let color = try #require(UIColor(named: name))
      .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    #expect(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
    return RGBColor(red: red, green: green, blue: blue)
  }

  private func contrast(_ lhs: RGBColor, _ rhs: RGBColor) -> Double {
    let lighter = max(lhs.relativeLuminance, rhs.relativeLuminance)
    let darker = min(lhs.relativeLuminance, rhs.relativeLuminance)
    return (lighter + 0.05) / (darker + 0.05)
  }
}

private struct RGBColor {
  let red: CGFloat
  let green: CGFloat
  let blue: CGFloat

  var hex: UInt32 {
    UInt32(red * 255 + 0.5) << 16
      | UInt32(green * 255 + 0.5) << 8
      | UInt32(blue * 255 + 0.5)
  }

  var isNeutral: Bool {
    abs(red - green) <= 1.0 / 255.0
      && abs(green - blue) <= 1.0 / 255.0
      && abs(red - blue) <= 1.0 / 255.0
  }

  var relativeLuminance: Double {
    let channels = [red, green, blue].map { component in
      let value = Double(component)
      return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
  }
}
