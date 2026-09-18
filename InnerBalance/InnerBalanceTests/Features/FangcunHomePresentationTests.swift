import Testing

@testable import InnerBalance

@Suite("Editorial home presentation")
struct FangcunHomePresentationTests {
  @Test("Echo choices use three paper columns and two accessibility columns")
  func echoGridColumns() {
    #expect(FangcunEchoGridLayout.columnCount(isAccessibilitySize: false) == 3)
    #expect(FangcunEchoGridLayout.columnCount(isAccessibilitySize: true) == 2)
  }

  @Test("Arc layout does not invent a selected state")
  func noVisualPreset() {
    #expect(FangcunEchoGridLayout.isSelected(candidate: .calm, selection: nil) == false)
  }

  @Test("已有状态冷启动不触发选择触觉")
  func hapticOnlyFollowsAnExplicitTap() {
    #expect(!FangcunEchoGridLayout.shouldPlayHaptic(for: .loaded))
    #expect(FangcunEchoGridLayout.shouldPlayHaptic(for: .tapped))
  }
}
