import Foundation

public enum ScoreFeatureBuilder {
  public static func build(snapshot: InsightsSnapshot, now: Date, calendar: Calendar,
    configuration: StatusScoreConfiguration, interventions: [ReadinessInterval] = []) throws -> ScoreFeatureBundle? {
    guard configuration.isValid else { throw StatusScoreError.invalidConfiguration }
    let samples = snapshot.ledger.normalizedSamples
    var sleepPolicy = ReadinessConfiguration()
    sleepPolicy.minimumSleepHours = 0.0001; sleepPolicy.reviewSleepHours = 24
    let built = SleepEpisodeBuilder.build(samples: samples, sourceKey: snapshot.sources[ReadinessMetric.sleep.rawValue]?.sourceKey,
      calendar: calendar, now: now, configuration: sleepPolicy, lookback: 35*86400, previous: snapshot.episodes)
    let recent = built.episodes.filter { $0.end <= now && now.timeIntervalSince($0.end) <= 24*3600 }
    let manual = snapshot.manualSleepID.flatMap { id in recent.first { $0.id == id } }
    let days = Dictionary(grouping: recent) { calendar.startOfDay(for: $0.end) }
    let latestDay = days.keys.max()
    let selected = manual ?? latestDay.flatMap { days[$0]?.max { $0.asleepDuration == $1.asleepDuration ? $0.end < $1.end : $0.asleepDuration < $1.asleepDuration } }
    guard let episode = selected else { return nil }
    var input = StatusScoreInput()
    var dependencies = Set(episode.sampleIDs)
    if episode.sleepDurationUsable, episode.asleepDuration > 0 {
      input.sleepMinutes = episode.asleepDuration / 60
      let related = samples.filter { $0.metric == .sleep && $0.sourceKey == episode.sourceKey && $0.end > episode.start && $0.start < episode.end }
      let awake = SleepEpisodeBuilder.union(related.filter { $0.stage == .awake }.map { .init(start: max(episode.start,$0.start), end: min(episode.end,$0.end)) })
      // Asleep-only is not evidence of complete wake coverage, including when there are zero gaps.
      let covered = SleepEpisodeBuilder.union(episode.intervals + awake)
      let gaps = zip(covered,covered.dropFirst()).map { $1.start.timeIntervalSince($0.end) }
      if !awake.isEmpty, covered.first?.start == episode.start, covered.last?.end == episode.end, gaps.allSatisfy({ $0 < 60 }) {
        input.awakeMinutes = awake.reduce(0) { $0 + $1.duration } / 60; input.awakeCoverageComplete = true
      }
      let past = built.episodes.filter { $0.sourceKey == episode.sourceKey && $0.end < episode.start && $0.sleepDurationUsable }
      let priorDays = Dictionary(grouping: past) { calendar.startOfDay(for: $0.end) }
      let previous = priorDays.values.compactMap { $0.max { $0.asleepDuration < $1.asleepDuration } }.sorted { $0.end > $1.end }.prefix(configuration.regularityCycles)
      input.regularityHistoryDays = previous.count
      if configuration.regularityEnabled, previous.count >= 3 {
        func minute(_ d: Date) -> Double { Double(calendar.component(.hour,from:d)*60+calendar.component(.minute,from:d)) }
        if let center = SleepScoreEngine.circularMedian(previous.map { minute($0.start) }) {
          input.regularityDeltaMinutes = SleepScoreEngine.circularDistance(minute(episode.start),center)
          dependencies.formUnion(previous.flatMap(\.sampleIDs))
        }
      }
    }
    var bundle = ScoreFeatureBundle(input: input, cycleID: episode.recoveryCycleID, asOf: episode.end,
      sleepStart: episode.start, sleepEnd: episode.end, basisSampleIDs: dependencies.sorted { $0.uuidString < $1.uuidString },
      sourceSegments: snapshot.sources.mapValues(\.segmentID), manual: false, windowPolicy: "mainSleep-v3",
      displayValues: input.sleepMinutes.map { ["sleep": $0] } ?? [:], measuredAt: ["sleep": episode.end], fingerprint: "")
    bundle.fingerprint = try fingerprint(bundle, samples: samples, configuration: configuration)
    return bundle
  }
  public static func fingerprint(_ bundle: ScoreFeatureBundle, samples: [ReadinessSample], configuration: StatusScoreConfiguration) throws -> String {
    let ids = Set(bundle.basisSampleIDs)
    var canonical = samples.filter { ids.contains($0.id) }.sorted { $0.id.uuidString < $1.id.uuidString }
    for i in canonical.indices { canonical[i].queriedAt = .distantPast }
    struct Identity: Encodable { let bundle: ScoreFeatureBundle; let samples: [ReadinessSample]; let configuration: StatusScoreConfiguration }
    var stable = bundle; stable.fingerprint = ""
    return try StableDigest.encoded(Identity(bundle: stable, samples: canonical, configuration: configuration))
  }
}
