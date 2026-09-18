import SwiftUI

extension EnvironmentValues {
  @Entry var fangcunReduceMotion = false
}

struct FangcunDisplayPreferences: ViewModifier {
  @Environment(\.dynamicTypeSize) private var systemTypeSize
  @Environment(\.accessibilityReduceMotion) private var systemReduced
  @AppStorage("fangcun.dark") private var dark = false
  @AppStorage("fangcun.largeType") private var large = false
  @AppStorage("fangcun.reduceMotion") private var reduced = false

  func body(content: Content) -> some View {
    content.preferredColorScheme(FangcunDisplayPolicy.colorScheme(dark: dark))
      .dynamicTypeSize(FangcunDisplayPolicy.typeSize(large: large, system: systemTypeSize))
      .environment(\.fangcunReduceMotion, FangcunDisplayPolicy.reduceMotion(app: reduced, system: systemReduced))
  }
}

enum FangcunDisplayPolicy {
  static func colorScheme(dark: Bool) -> ColorScheme { dark ? .dark : .light }
  static func typeSize(large: Bool, system: DynamicTypeSize) -> DynamicTypeSize { large ? max(.xxxLarge, system) : system }
  static func reduceMotion(app: Bool, system: Bool) -> Bool { app || system }
}
