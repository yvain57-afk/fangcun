import Foundation
import Testing
import InnerBalanceCore
@testable import InnerBalance

@Suite @MainActor struct DayGuidanceV2Tests {
  @Test(arguments: ["assessable", "reduced", "low", "oneDay", "sleepOnly", "insufficient"])
  func rawProviderToOwnerProducesScopedLanguage(_ scenario: String) async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let owner = ReadinessCoordinator(store: try InsightsStore(directory: root), provider: ReadinessDemoProvider(scenario: scenario),
      defaults: UserDefaults(suiteName: UUID().uuidString)!)
    await owner.refresh()
    let g = owner.guidance
    #expect(g.reasons.count <= 2 && !g.actionKey.isEmpty)
    switch scenario {
    case "assessable": #expect(g.kind == .recoveryAssessment && g.titleKey == "guidance.usual")
    case "reduced": #expect(g.titleKey == "guidance.reduced" && g.scene == .rest)
    case "low": #expect(g.titleKey == "guidance.low" && g.scene == .rest)
    case "oneDay":
      #expect(g.kind == .scopedAdvice && g.titleKey == "guidance.sleepAdvice")
      #expect(owner.current?.evidence.allSatisfy { ($0.baseline?.validDays ?? 0) < 7 } == true)
    case "sleepOnly": #expect(g.kind == .scopedAdvice && g.titleKey == "guidance.sleepAdvice")
    default: #expect(g.kind == .onboarding && g.titleKey == "guidance.notYet")
    }
    #expect(!g.summary.contains("sourceIdentityIncomplete") && !g.summary.contains("MAD"))
  }
}
