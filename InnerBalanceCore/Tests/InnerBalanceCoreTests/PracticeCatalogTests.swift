import Testing

@testable import InnerBalanceCore

@Suite("Practice catalog")
struct PracticeCatalogTests {
  @Test("Build 1 contains the five approved practices and Kegel is never automatic")
  func buildOneCatalogIsComplete() throws {
    #expect(PracticeCatalog.buildOne.map(\.kind) == PracticeKind.allCases)

    let sigh = try #require(PracticeCatalog.protocol(for: .physiologicalSigh))
    #expect(sigh.durationOptions == [60, 300])
    #expect(sigh.minimumEvidenceDuration == nil)

    let breathing = try #require(PracticeCatalog.protocol(for: .pacedBreathing))
    #expect(breathing.durationOptions == [180, 300])
    #expect(breathing.minimumEvidenceDuration == 300)

    let kegel = try #require(PracticeCatalog.protocol(for: .kegel))
    #expect(kegel.durationOptions == [180])
    #expect(kegel.isAutomaticallyRecommended == false)
    #expect(kegel.writesMindfulSession == false)
  }
}
