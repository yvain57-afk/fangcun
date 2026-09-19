#if DEBUG
import Foundation
import InnerBalanceCore

/// Raw synthetic samples only. The production pipeline, store and UI process these unchanged.
actor ReadinessDemoProvider: ReadinessDataProviding {
  let scenario: String
  let reference: Date
  var failure = false
  init(scenario: String, now: Date = .now) { self.scenario = scenario; reference = now }
  func setFailure(_ value: Bool) { failure = value }
  func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch {
    if scenario == "failed" || failure { throw ReadinessReadFailure.queryFailed }
    let source = ReadinessSource(bundleID: "org.example.synthetic", name: "Synthetic Wearable Source With A Long English Display Name", samplingMethod: "system")
    var rows: [ReadinessSample] = []
    let days = scenario == "provisional" ? 8 : scenario == "oneDay" ? 1 : 20
    if scenario != "insufficient", cursor == nil {
      for day in 0...days {
        let offset = Double(day * 24)
        let end = reference.addingTimeInterval(-(offset + (scenario == "awaitingData" ? 0.1 : 4))*3600)
        func id(_ n: Int) -> UUID { UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", day*100+n))! }
        rows.append(.init(id: id(1), metric: .sleep, unit: "category", stage: .asleep,
          start: end.addingTimeInterval(-(day == 0 && ["reduced", "low", "sleepOnly"].contains(scenario) ? 5 : 8)*3600), end: end, source: source, queriedAt: now))
        for n in 0..<4 {
          let date = end.addingTimeInterval(-Double(n+1)*3600)
          rows.append(.init(id: id(10+n), metric: .hrvSDNN, value: day == 0 && scenario == "low" ? 20 : 50, unit: "ms", start: date, end: date, source: source, queriedAt: now))
        }
        if scenario != "limited" {
          let date = min(end.addingTimeInterval(3600), reference)
          rows.append(.init(id: id(30), metric: .restingHeartRate, value: 60, unit: "count/min", start: date, end: date, source: source, queriedAt: now))
        }
      }
    }
    return .init(metric: metric, samples: rows.filter { $0.metric == metric && (scenario != "sleepOnly" || $0.metric == .sleep) },
      cursor: .init(anchor: Data([1]), windowStart: cursor?.windowStart ?? now.addingTimeInterval(-35*86400)))
  }
}
#endif
