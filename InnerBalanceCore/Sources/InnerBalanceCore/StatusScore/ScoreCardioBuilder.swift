import Foundation

/// Current and historical records share exactly the same source, unit and intervention filters.
enum ScoreCardioBuilder {
  static func append(to bundle: inout ScoreFeatureBundle, episodes: [ReadinessSleepEpisode],
    current: ReadinessSleepEpisode?, samples: [ReadinessSample], sources: [String: SelectedReadinessSource],
    now: Date, calendar: Calendar, configuration: StatusScoreConfiguration, interventions: [ReadinessInterval]) {
    var policy = ReadinessConfiguration()
    policy.minimumHRVSamples = 1; policy.minimumHRVHours = 1
    var ids = Set(bundle.basisSampleIDs)
    let hSource = sources[ReadinessMetric.hrvSDNN.rawValue]
    if let current, current.asleepIntervalsUsableForHRV {
      let h = CurrentMetricExtractor.extract(metric: .hrvSDNN, samples: samples, sourceKey: hSource?.sourceKey,
        episode: current, now: now, interventions: interventions, configuration: policy)
      // Bad siblings do not invalidate independently usable samples. The extractor removes each bad row.
      if let value = h.value, h.sampleCount > 0 {
        let day = calendar.startOfDay(for: current.end)
        let cutoff = calendar.date(byAdding: .day, value: -configuration.baselineDays, to: day)!
        let past = episodes.filter { $0.sourceKey == current.sourceKey && $0.end < current.start
          && $0.asleepIntervalsUsableForHRV && calendar.startOfDay(for: $0.end) < day && $0.end >= cutoff }
        let nights = Dictionary(grouping: past) { calendar.startOfDay(for: $0.end) }.values.compactMap {
          $0.max { $0.asleepDuration == $1.asleepDuration ? $0.end < $1.end : $0.asleepDuration < $1.asleepDuration }
        }
        let history = nights.map { episode in
          CurrentMetricExtractor.extract(metric: .hrvSDNN, samples: samples, sourceKey: hSource?.sourceKey,
            episode: episode, now: current.start, interventions: interventions, excludingIDs: Set(h.sampleIDs), configuration: policy)
        }.filter { $0.value != nil && $0.sampleCount > 0 }
        bundle.input.hrvDays = history.count; bundle.input.hrvSamples = h.sampleCount; bundle.input.hrvHours = h.coveredHours
        if history.count >= configuration.minimumHistoryDays, let center = BodyLoadEngine.median(history.compactMap(\.value)),
          let mad = BodyLoadEngine.median(history.compactMap(\.value).map({ abs($0-center) })) {
          bundle.input.hrvDeviation = (center-value)/max(configuration.hrvScaleFloor,configuration.madMultiplier*mad)
          bundle.displayValues["hrv"] = h.displayValue; bundle.measuredAt["hrv"] = h.latestMeasuredAt
          ids.formUnion(h.sampleIDs); ids.formUnion(history.flatMap(\.sampleIDs))
          // Sleep intervals used to admit both current and historical HRV are also deletion dependencies.
          ids.formUnion(current.sampleIDs); ids.formUnion(nights.flatMap(\.sampleIDs))
          bundle.sourceSegments["hrv"] = hSource?.segmentID
        }
      }
    }
    let rSource = sources[ReadinessMetric.restingHeartRate.rawValue]
    let rRows = samples.filter { row in
      row.metric == .restingHeartRate && row.sourceKey == rSource?.sourceKey && row.unit == "count/min"
        && row.start <= row.end && row.end <= now && !row.manuallyEntered && !row.source.bundleID.isEmpty
        && !row.source.identityAmbiguous && row.value.map { $0.isFinite && $0 > 0 && $0 <= policy.maximumRestingBPM } == true
    }
    let sleepWindow = current.flatMap { $0.sleepDurationUsable ? $0 : nil }
    let windowStart = sleepWindow?.end.addingTimeInterval(-24*3600) ?? calendar.startOfDay(for: now)
    let windowEnd = sleepWindow.map { min(now,$0.end.addingTimeInterval(3*3600)) } ?? now
    let r = rRows.filter { $0.end >= windowStart && $0.end <= windowEnd }.max { $0.end == $1.end ? $0.id.uuidString < $1.id.uuidString : $0.end < $1.end }
    if let r, let value = r.value {
      let currentDay = calendar.startOfDay(for: r.end)
      let cutoff = calendar.date(byAdding: .day, value: -configuration.baselineDays, to: currentDay)!
      let history = Dictionary(grouping: rRows.filter { $0.id != r.id && $0.end >= cutoff && $0.end < currentDay }) {
        calendar.startOfDay(for: $0.end)
      }.values.compactMap { $0.max { $0.end == $1.end ? $0.id.uuidString < $1.id.uuidString : $0.end < $1.end } }
      bundle.input.rhrDays = history.count
      if history.count >= configuration.minimumHistoryDays, let center = BodyLoadEngine.median(history.compactMap(\.value)),
        let mad = BodyLoadEngine.median(history.compactMap(\.value).map({ abs($0-center) })) {
        bundle.input.rhrDeviation = (value-center)/max(configuration.rhrScaleFloor,configuration.madMultiplier*mad)
        bundle.displayValues["rhr"] = value; bundle.measuredAt["rhr"] = r.end
        ids.insert(r.id); ids.formUnion(history.map(\.id)); bundle.sourceSegments["rhr"] = rSource?.segmentID
        if sleepWindow == nil {
          bundle.windowPolicy += "+dailyRHR-v3"
          if current == nil && !bundle.manual { bundle.asOf = r.end; bundle.cycleID = "dailyRHR-v3|\(calendar.timeZone.identifier)|\(currentDay.timeIntervalSince1970)" }
        } else { bundle.windowPolicy += "+morningRHR-v3" }
      }
    }
    bundle.basisSampleIDs = ids.sorted { $0.uuidString < $1.uuidString }
  }
}
