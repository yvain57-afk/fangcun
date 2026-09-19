import Foundation

public struct ReadinessMetricFeature: Codable, Equatable, Sendable {
  public var metric: ReadinessMetric
  public var sourceKey: String?
  public var value: Double?
  public var displayValue: Double?
  public var unit: String
  public var window: ReadinessInterval
  public var latestMeasuredAt: Date?
  public var sampleIDs: [UUID]
  public var sampleCount: Int { sampleIDs.count }
  public var coveredHours: Int
  public var reliable: Bool
  public var reasons: [ReadinessReason]
}

public struct ReadinessMetricBaseline: Codable, Equatable, Sendable {
  public var metric: ReadinessMetric
  public var sourceKey: String?
  public var validDays: Int
  public var center: Double?
  public var scale: Double?
  public var sampleIDs: [UUID]
}

public struct ReadinessBaselines: Codable, Sendable {
  public var hrv: ReadinessMetricBaseline
  public var rhr: ReadinessMetricBaseline
}

public enum CurrentMetricExtractor {
  public static func extract(metric: ReadinessMetric, samples: [ReadinessSample],
    sourceKey: String?, episode: ReadinessSleepEpisode, now: Date,
    interventions: [ReadinessInterval] = [], usedRestingIDs: Set<UUID> = [],
    excludingIDs: Set<UUID> = [], configuration: ReadinessConfiguration = .init()) -> ReadinessMetricFeature {
    let isHRV = metric == .hrvSDNN
    let window = isHRV ? ReadinessInterval(start: episode.start, end: episode.end)
      : ReadinessInterval(start: episode.end.addingTimeInterval(-24*3600), end: min(now, episode.end.addingTimeInterval(3*3600)))
    let expectedUnit = isHRV ? "ms" : "count/min"
    let rows = SampleNormalizer.deduplicate(samples).filter { row in
      guard row.metric == metric, row.sourceKey == sourceKey, !excludingIDs.contains(row.id),
        row.end <= now, row.end >= row.start else { return false }
      if isHRV { return episode.intervals.contains { row.start >= $0.start && row.end <= $0.end } }
      return row.end >= window.start && row.end <= window.end
    }
    var reasons: Set<ReadinessReason> = []
    var valid: [ReadinessSample] = []
    for row in rows {
      guard row.unit == expectedUnit else { reasons.insert(.unitMismatch); continue }
      guard let value = row.value, value.isFinite, value > 0 else { reasons.insert(.invalidValue); continue }
      guard value <= (isHRV ? configuration.maximumHRVMS : configuration.maximumRestingBPM) else {
        reasons.insert(.extremeValue); continue
      }
      guard !row.manuallyEntered else { reasons.insert(.manuallyEntered); continue }
      guard !row.source.bundleID.isEmpty else { reasons.insert(.sourceUnknown); continue }
      guard !row.source.identityAmbiguous else { reasons.insert(.sourceAmbiguous); continue }
      if row.source.identityIncomplete { reasons.insert(.sourceIdentityIncomplete) }
      if isHRV, interventions.contains(where: {
        ReadinessInterval(start: $0.start.addingTimeInterval(-configuration.interventionBufferMinutes*60),
          end: $0.end.addingTimeInterval(configuration.interventionBufferMinutes*60))
          .overlaps(ReadinessInterval(start: row.start, end: row.end))
      }) { reasons.insert(.interventionExcluded); continue }
      valid.append(row)
    }
    if !isHRV {
      valid = valid.max { $0.end == $1.end ? $0.id.uuidString < $1.id.uuidString : $0.end < $1.end }.map { [$0] } ?? []
      if let row = valid.first, usedRestingIDs.contains(row.id) { reasons.insert(.restingSampleReused) }
    }
    let hours = Set(valid.map { Int(floor($0.end.timeIntervalSince1970 / 3600)) }).count
    if valid.isEmpty { reasons.insert(isHRV ? .hrvMissing : .rhrMissing) }
    if isHRV && valid.count < configuration.minimumHRVSamples { reasons.insert(.sparseHRV) }
    if isHRV && hours < configuration.minimumHRVHours { reasons.insert(.narrowHRVCoverage) }
    if isHRV && !episode.asleepIntervalsUsableForHRV {
      reasons.formUnion(episode.quality?.userBlockingReasons ?? episode.flags)
    }
    let blockers: Set<ReadinessReason> = [.unitMismatch,.invalidValue,.extremeValue,.manuallyEntered,
      .sourceUnknown,.sourceAmbiguous,.restingSampleReused,.hrvMissing,.rhrMissing,.sparseHRV,.narrowHRVCoverage]
    let values = valid.compactMap(\.value)
    return ReadinessMetricFeature(metric: metric, sourceKey: sourceKey,
      value: BodyLoadEngine.median(isHRV ? values.map(log) : values),
      displayValue: BodyLoadEngine.median(values), unit: expectedUnit, window: window,
      latestMeasuredAt: valid.map(\.end).max(), sampleIDs: valid.map(\.id).sorted { $0.uuidString < $1.uuidString },
      coveredHours: hours, reliable: reasons.isDisjoint(with: blockers) && (!isHRV || episode.asleepIntervalsUsableForHRV), reasons: reasons.sorted { $0.rawValue < $1.rawValue })
  }
}

public enum BaselineBuilder {
  public static func build(episodes: [ReadinessSleepEpisode], samples: [ReadinessSample],
    beforeEpisode current: ReadinessSleepEpisode, hrvSource: String?, rhrSource: String?,
    currentSampleIDs: Set<UUID>, calendar: Calendar, interventions: [ReadinessInterval] = [],
    configuration: ReadinessConfiguration = .init()) -> ReadinessBaselines {
    let selected = selectedEpisodes(episodes, before: current, calendar: calendar, configuration: configuration)
    var hrv: [ReadinessMetricFeature] = [], rhr: [ReadinessMetricFeature] = []
    var usedRHR: Set<UUID> = []
    for episode in selected where episode.sleepDurationUsable {
      let h = CurrentMetricExtractor.extract(metric: .hrvSDNN, samples: samples, sourceKey: hrvSource,
        episode: episode, now: current.start, interventions: interventions, excludingIDs: currentSampleIDs, configuration: configuration)
      let r = CurrentMetricExtractor.extract(metric: .restingHeartRate, samples: samples, sourceKey: rhrSource,
        episode: episode, now: current.start, usedRestingIDs: usedRHR, excludingIDs: currentSampleIDs, configuration: configuration)
      if h.reliable { hrv.append(h) }
      if r.reliable { rhr.append(r); usedRHR.formUnion(r.sampleIDs) }
    }
    return ReadinessBaselines(hrv: summarize(hrv, metric: .hrvSDNN, source: hrvSource, floor: configuration.hrvScaleFloor, configuration: configuration),
      rhr: summarize(rhr, metric: .restingHeartRate, source: rhrSource, floor: configuration.rhrScaleFloor, configuration: configuration))
  }

  static func selectedEpisodes(_ episodes: [ReadinessSleepEpisode], before current: ReadinessSleepEpisode,
    calendar: Calendar, configuration: ReadinessConfiguration) -> [ReadinessSleepEpisode] {
    let currentDay = calendar.startOfDay(for: current.end)
    let cutoff = calendar.date(byAdding: .day, value: -configuration.baselineDays, to: currentDay) ?? currentDay
    let candidates = episodes.filter {
      $0.id != current.id && $0.sourceKey == current.sourceKey && $0.end < current.start
        && calendar.startOfDay(for: $0.end) >= cutoff && calendar.startOfDay(for: $0.end) < currentDay
    }
    let days = Dictionary(grouping: candidates) { calendar.startOfDay(for: $0.end) }
    return days.values.compactMap { $0.max {
      $0.asleepDuration == $1.asleepDuration ? $0.end < $1.end : $0.asleepDuration < $1.asleepDuration
    }}.sorted { $0.end < $1.end }
  }

  private static func summarize(_ features: [ReadinessMetricFeature], metric: ReadinessMetric,
    source: String?, floor: Double, configuration: ReadinessConfiguration) -> ReadinessMetricBaseline {
    let values = features.compactMap(\.value)
    let center = BodyLoadEngine.median(values)
    let mad = center.flatMap { median in BodyLoadEngine.median(values.map { abs($0-median) }) }
    return ReadinessMetricBaseline(metric: metric, sourceKey: source, validDays: values.count,
      center: center, scale: mad.map { max(configuration.madMultiplier * $0, floor) },
      sampleIDs: Array(Set(features.flatMap(\.sampleIDs))).sorted { $0.uuidString < $1.uuidString })
  }
}
