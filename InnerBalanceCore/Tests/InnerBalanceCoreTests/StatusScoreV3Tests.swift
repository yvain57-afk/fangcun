import Foundation
import Testing
@testable import InnerBalanceCore

@Suite struct StatusScoreV3Tests {
  @Test(arguments: 0..<24) func independentPackageFixtures(_ index: Int) throws {
    let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../docs/plans/fangcun-score-v3/SCORE_V3_FIXTURES.json").standardizedFileURL
    let root = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    let row = try #require((root["cases"] as? [[String: Any]])?[index])
    let raw = try #require(row["input"] as? [String: Any]), expected = try #require(row["expected"] as? [String: Any])
    func number(_ key: String) -> Double? { (raw[key] as? NSNumber)?.doubleValue }
    func count(_ key: String) -> Int { (raw[key] as? NSNumber)?.intValue ?? 0 }
    var i = StatusScoreInput(sleepMinutes: number("sleep_minutes"))
    i.sleepUsable = raw["sleep_usable"] as? Bool ?? true
    i.awakeMinutes = number("awake_minutes"); i.awakeCoverageComplete = raw["awake_coverage_complete"] as? Bool ?? false
    i.regularityDeltaMinutes = number("regularity_delta_minutes"); i.regularityHistoryDays = count("regularity_history_days")
    i.hrvDeviation = number("hrv_deviation"); i.hrvDays = count("hrv_days"); i.hrvSamples = count("hrv_samples"); i.hrvHours = count("hrv_hours")
    i.hrvUsable = raw["hrv_usable"] as? Bool ?? true
    i.rhrDeviation = number("rhr_deviation"); i.rhrDays = count("rhr_days"); i.rhrUsable = raw["rhr_usable"] as? Bool ?? true
    let result = try DailyStatusScoreEngine.evaluate(i, configuration: .init(sleepGoalMinutes: number("sleep_goal_minutes") ?? 480))
    #expect(result.displayScore == (expected["score"] as? NSNumber)?.intValue)
    #expect(result.band?.title == expected["band"] as? String)
    if result.displayScore != nil { #expect(abs(result.components.reduce(0) { $0+$1.normalizedWeight }-1) < 1e-10) }
  }
  @Test func boundariesCircularClockAndInvalidInput() throws {
    for (value,band) in [(49,StatusBand.rest),(50,.low),(69,.low),(70,.fair),(84,.fair),(85,.good)] { #expect(StatusBand.resolve(value) == band) }
    #expect(StatusBand.resolve(-1) == nil && StatusBand.resolve(101) == nil)
    #expect(SleepScoreEngine.circularDistance(1430,10) == 20)
    #expect(SleepScoreEngine.circularMedian([1430,0,10]) == 0)
    #expect(throws: StatusScoreError.self) { try DailyStatusScoreEngine.evaluate(.init(sleepMinutes: .nan)) }
    #expect(try DailyStatusScoreEngine.evaluate(.init()).displayScore == nil)
    #expect(try DailyStatusScoreEngine.evaluate(.init(sleepMinutes: 0)).displayScore == 0)
  }
  @Test func rawSleepThroughStoreProduces78WithoutCardio() async throws {
    let now = ISO8601DateFormatter().date(from: "2026-09-20T04:00:00Z")!
    let source = ReadinessSource(bundleID: "synthetic", samplingMethod: "system")
    let sleep = ReadinessSample(id: UUID(), metric: .sleep, stage: .asleep, start: now.addingTimeInterval(-10.25*3600), end: now.addingTimeInterval(-4*3600), source: source, queriedAt: now)
    struct Provider: ReadinessDataProviding {
      let row: ReadinessSample
      func changes(for metric: ReadinessMetric, cursor: HealthReadCursor?, now: Date) async throws -> ReadinessChangeBatch {
        .init(metric: metric, samples: cursor == nil && metric == .sleep ? [row] : [], cursor: .init(anchor: Data([1]), windowStart: now.addingTimeInterval(-35*86400)))
      }
    }
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try InsightsStore(directory: directory)
    let pipeline = ReadinessPipeline(provider: Provider(row: sleep), store: store)
    let result = try await pipeline.refresh(now: now, calendar: Calendar(identifier: .gregorian), scoreConfiguration: .init())
    #expect(result.currentStatus?.displayScore == 78 && result.currentStatus?.band == .fair)
    #expect(result.currentStatus?.components.map(\.name) == ["sleep"])
    #expect(result.currentStatus?.sleepSubscores["continuity"] == nil)
    let restarted = try InsightsStore(directory: directory)
    #expect(await restarted.snapshot().currentStatus?.scoreID == result.currentStatus?.scoreID)
  }
}
