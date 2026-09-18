import Foundation
import InnerBalanceCore

/// M2 data-service factory. App lifecycle / UI subscription remains an explicit M3 integration.
/// Creating this service never prompts for authorization or starts background observers.
@MainActor
enum ReadinessServices {
  static func make() throws -> (pipeline: ReadinessPipeline, store: InsightsStore, provider: ReadinessHealthKitProvider) {
    let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true)
    let store = try InsightsStore(directory: support.appendingPathComponent("FangcunInsights", isDirectory: true))
    let provider = ReadinessHealthKitProvider()
    return (ReadinessPipeline(provider: provider, store: store), store, provider)
  }
}
