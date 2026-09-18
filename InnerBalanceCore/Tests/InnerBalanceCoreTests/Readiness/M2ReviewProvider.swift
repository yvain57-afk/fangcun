import Foundation
@testable import InnerBalanceCore

actor M2ReviewProvider: ReadinessDataProviding {
  let now: Date
  var pages: [ReadinessMetric: [[ReadinessSample]]]
  var failAt: String?
  var pauseMetric: ReadinessMetric?
  var gate: CheckedContinuation<Void,Never>?
  var waiter: CheckedContinuation<Void,Never>?
  var calls = 0
  init(_ rows: [ReadinessSample], now: Date) {
    self.now = now
    pages = Dictionary(uniqueKeysWithValues: [ReadinessMetric.sleep,.hrvSDNN,.restingHeartRate,.workout].map { metric in
      (metric,[rows.filter { $0.metric == metric }])
    })
  }
  func setPages(_ chunks: [[ReadinessSample]], metric: ReadinessMetric) { pages[metric] = chunks }
  func failOnce(metric: ReadinessMetric, page: Int) { failAt = "\(metric.rawValue):\(page)" }
  func pause(at metric: ReadinessMetric) { pauseMetric = metric }
  func waitUntilPaused() async { if gate == nil { await withCheckedContinuation { waiter = $0 } } }
  func resume() { gate?.resume(); gate = nil }
  func append(_ rows: [ReadinessSample], metric: ReadinessMetric) { pages[metric,default: []].append(rows) }
  func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch {
    calls += 1
    if pauseMetric == metric {
      pauseMetric = nil
      await withCheckedContinuation { gate = $0; waiter?.resume(); waiter = nil }
    }
    let index = cursor?.anchor.flatMap { Int(String(decoding: $0,as: UTF8.self)) } ?? 0
    if failAt == "\(metric.rawValue):\(index)" { failAt = nil; throw ReadinessReadFailure.queryFailed }
    let chunks = pages[metric] ?? []
    let next = min(index+1,chunks.count)
    return .init(metric: metric, samples: index < chunks.count ? chunks[index] : [],
      cursor: .init(anchor: Data(String(next).utf8),windowStart: cursor?.windowStart ?? self.now-35*86_400),
      hasMore: next < chunks.count)
  }
}
