import Foundation
@testable import InnerBalanceCore

struct ReadinessFixture {
  let now = Date(timeIntervalSince1970: 1_789_704_000)
  var calendar: Calendar {
    var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c
  }
  var source: ReadinessSource { .init(bundleID: "org.example.synthetic", productType: "SyntheticDevice", samplingMethod: "system") }
  func date(_ hoursAgo: Double) -> Date { now.addingTimeInterval(-hoursAgo*3600) }
  func id(_ seed: Int) -> UUID { UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", seed))! }
  func sleep(start: Double, end: Double, seed: Int, stage: SleepStage = .asleep) -> ReadinessSample {
    .init(id: id(seed), metric: .sleep, unit: "category", stage: stage, start: date(start), end: date(end), source: source, queriedAt: now)
  }
  func quantity(_ metric: ReadinessMetric, value: Double, hoursAgo: Double, seed: Int) -> ReadinessSample {
    .init(id: id(seed), metric: metric, value: value, unit: metric == .hrvSDNN ? "ms" : "count/min",
      start: date(hoursAgo), end: date(hoursAgo), source: source, queriedAt: now)
  }
  func records(days: Int = 20, hrv: Double = 50, rhr: Double = 60, sleepHours: Double = 8,
    currentHRVCount: Int = 4, currentHRVSameHour: Bool = false) -> [ReadinessSample] {
    var result: [ReadinessSample] = []
    for day in 0...days {
      let offset = Double(day*24)
      result.append(sleep(start: offset+4+(day == 0 ? sleepHours : 8), end: offset+4, seed: day*100+1))
      let count = day == 0 ? currentHRVCount : 4
      for n in 0..<count {
        result.append(quantity(.hrvSDNN, value: day == 0 ? hrv : 50,
          hoursAgo: offset+5+(day == 0 && currentHRVSameHour ? 0.1+Double(n)*0.1 : Double(n)), seed: day*100+10+n))
      }
      result.append(quantity(.restingHeartRate, value: day == 0 ? rhr : 60, hoursAgo: offset+3, seed: day*100+30))
    }
    return result
  }
  func build(_ records: [ReadinessSample], previous: [ReadinessSleepEpisode] = [], now: Date? = nil) -> SleepEpisodeBuild {
    SleepEpisodeBuilder.build(samples: records, sourceKey: source.key(for: .sleep), calendar: calendar,
      now: now ?? self.now, lookback: 35*86_400, previous: previous)
  }
}
