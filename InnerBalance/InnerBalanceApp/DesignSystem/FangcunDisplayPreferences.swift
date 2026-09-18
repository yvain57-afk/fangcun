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
    content.preferredColorScheme(dark ? .dark : .light)
      .dynamicTypeSize(large ? max(.xxxLarge, systemTypeSize) : systemTypeSize)
      .environment(\.fangcunReduceMotion, reduced || systemReduced)
  }
}
