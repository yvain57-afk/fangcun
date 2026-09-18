import Foundation
import Testing

@testable import InnerBalanceCore

@Suite("Sleep episode analysis")
struct SleepEpisodeAnalyzerTests {
  @Test("Overlapping sleep samples are counted once")
  func overlappingSamplesAreDeduplicated() {
    let samples = [
      SleepSampleInterval(
        start: date(day: 9, hour: 22),
        end: date(day: 10, hour: 2),
        sourceName: "Apple Watch",
        isAppleWatch: true
      ),
      SleepSampleInterval(
        start: date(day: 10, hour: 0),
        end: date(day: 10, hour: 6),
        sourceName: "Health",
        isAppleWatch: false
      ),
    ]

    let result = SleepEpisodeAnalyzer.primarySleep(
      from: samples,
      now: date(day: 10, hour: 8)
    )

    #expect(result?.asleepDuration == TimeInterval(8 * 3_600))
    #expect(result?.sampleCount == 2)
  }

  @Test("A daytime nap is not added to the primary sleep")
  func napIsSeparatedFromPrimarySleep() {
    let samples = [
      SleepSampleInterval(
        start: date(day: 9, hour: 13),
        end: date(day: 9, hour: 14),
        sourceName: "Apple Watch",
        isAppleWatch: true
      ),
      SleepSampleInterval(
        start: date(day: 9, hour: 22),
        end: date(day: 10, hour: 6),
        sourceName: "Apple Watch",
        isAppleWatch: true
      ),
    ]

    let result = SleepEpisodeAnalyzer.primarySleep(
      from: samples,
      now: date(day: 10, hour: 8)
    )

    #expect(result?.asleepDuration == TimeInterval(8 * 3_600))
    #expect(result?.start == date(day: 9, hour: 22))
    #expect(result?.sampleCount == 1)
  }

  @Test("An implausibly long episode is excluded from body load")
  func implausiblyLongSleepNeedsReview() {
    let sample = SleepSampleInterval(
      start: date(day: 9, hour: 10),
      end: date(day: 10, hour: 4),
      sourceName: "Imported sleep",
      isAppleWatch: false
    )

    let result = SleepEpisodeAnalyzer.primarySleep(
      from: [sample],
      now: date(day: 10, hour: 8)
    )

    #expect(result?.quality == .needsReview)
    #expect(result?.isUsableForBodyLoad == false)
  }

  private func date(day: Int, hour: Int, minute: Int = 0) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar.date(
      from: DateComponents(year: 2026, month: 8, day: day, hour: hour, minute: minute)
    )!
  }
}
