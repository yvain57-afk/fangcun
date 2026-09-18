import Foundation
import Testing

@testable import InnerBalanceCore

@Suite("Heart-rate evidence windows")
struct HeartRateEvidenceAnalyzerTests {
  @Test("Uses valid samples from the first and last minute")
  func firstAndLastWindows() throws {
    let start = Date(timeIntervalSince1970: 1_786_320_000)
    let end = start.addingTimeInterval(300)
    let samples = [
      HeartRateSample(date: start.addingTimeInterval(5), beatsPerMinute: 70),
      HeartRateSample(date: start.addingTimeInterval(20), beatsPerMinute: 72),
      HeartRateSample(date: start.addingTimeInterval(50), beatsPerMinute: 74),
      HeartRateSample(date: start.addingTimeInterval(150), beatsPerMinute: 120),
      HeartRateSample(date: end.addingTimeInterval(-50), beatsPerMinute: 63),
      HeartRateSample(date: end.addingTimeInterval(-20), beatsPerMinute: 65),
      HeartRateSample(date: end.addingTimeInterval(-5), beatsPerMinute: 67),
    ]

    let evidence = try #require(
      HeartRateEvidenceAnalyzer.analyze(samples: samples, startDate: start, endDate: end)
    )

    #expect(evidence.startBeatsPerMinute == 72)
    #expect(evidence.endBeatsPerMinute == 65)
    #expect(evidence.sampleCount == 6)
  }

  @Test("Overlapping windows and implausible samples never create evidence")
  func insufficientIndependentWindows() {
    let start = Date(timeIntervalSince1970: 1_786_320_000)
    let end = start.addingTimeInterval(90)
    let samples = [
      HeartRateSample(date: start.addingTimeInterval(35), beatsPerMinute: 65),
      HeartRateSample(date: start.addingTimeInterval(45), beatsPerMinute: 500),
      HeartRateSample(date: start.addingTimeInterval(50), beatsPerMinute: 67),
      HeartRateSample(date: start.addingTimeInterval(55), beatsPerMinute: 69),
    ]

    #expect(
      HeartRateEvidenceAnalyzer.analyze(samples: samples, startDate: start, endDate: end) == nil
    )
  }
}
