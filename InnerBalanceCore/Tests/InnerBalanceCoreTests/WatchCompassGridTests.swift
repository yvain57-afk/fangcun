import Testing

@testable import InnerBalanceCore

@Suite("Watch compass grid")
struct WatchCompassGridTests {
  @Test("Watch 情绪罗盘固定提供九个不重复区域")
  func gridContainsNineUniqueRegions() {
    #expect(WatchCompassRegion.all.count == 9)
    #expect(Set(WatchCompassRegion.all.map(\.id)).count == 9)
    #expect(WatchCompassRegion.all.contains { $0.valence == 0 && $0.arousal == 0 })
  }
}
