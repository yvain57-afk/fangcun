import Foundation

/// Local diagnostic material. Contains health-record identifiers and must never be
/// attached to public verification or sent by the sync service.
public struct BaselineCoverageAudit: Codable, Sendable {
  public enum Disposition: String, Codable, Sendable {
    case included, notRead, readingIncomplete, initializationUnknown, rawAbsent
    case sourceNotSelected, sourceMismatch, noSleepCandidate, sleepExcluded, featureExcluded
  }
  public struct Day: Codable, Sendable {
    public var metric: ReadinessMetric
    public var day: Date
    public var initialization: ReadinessInitialization?
    public var rawCount: Int
    public var normalizedCount: Int
    public var selectedSourceCount: Int
    public var selectedSourceKey: String?
    public var sleepCandidateIDs: [String]
    public var selectedSleepID: String?
    public var sleepQuality: ReadinessSleepQuality?
    public var includedSampleIDs: [UUID]
    public var coveredHours: Int
    public var disposition: Disposition
    public var filterReasons: [ReadinessReason]
  }
  public var qualityPolicyVersion: String?
  public var generatedAt: Date
  public var timeZoneID: String
  public var currentSleepID: String?
  public var days: [Day]

  public static func build(snapshot: InsightsSnapshot, now: Date, calendar: Calendar,
    configuration: ReadinessConfiguration = .init(), interventions: [ReadinessInterval] = []) -> Self {
    let raw = Array(snapshot.ledger.samples.values), rows = SampleNormalizer.deduplicate(raw)
    let prepared = ReadinessInputBuilder.build(samples: raw, sources: snapshot.sources,
      previousEpisodes: snapshot.episodes, now: now, calendar: calendar, configuration: configuration,
      interventions: interventions, manualSleepID: snapshot.manualSleepID)
    let current = prepared.input.sleep.episode
    let selected = current.map { BaselineBuilder.selectedEpisodes(prepared.episodes, before: $0,
      calendar: calendar, configuration: configuration) } ?? []
    let currentIDs = Set((prepared.input.hrv?.sampleIDs ?? []) + (prepared.input.rhr?.sampleIDs ?? []))
    let exclusions = interventions + rows.filter { $0.metric == .mindfulSession }.map { ReadinessInterval(start: $0.start, end: $0.end) }
    let currentDay = calendar.startOfDay(for: current?.end ?? now)
    var audit: [Day] = [], usedRHR: Set<UUID> = []
    for offset in stride(from: configuration.baselineDays, through: 1, by: -1) {
      guard let day = calendar.date(byAdding: .day, value: -offset, to: currentDay) else { continue }
      let candidates = prepared.episodes.filter { calendar.isDate($0.end, inSameDayAs: day) }
      let episode = selected.first { calendar.isDate($0.end, inSameDayAs: day) }
      for metric in [ReadinessMetric.sleep, .hrvSDNN, .restingHeartRate] {
        let key = snapshot.sources[metric.rawValue]?.sourceKey
        let rawDay = raw.filter { $0.metric == metric && calendar.isDate($0.end, inSameDayAs: day) }
        let normalized = rows.filter { $0.metric == metric && calendar.isDate($0.end, inSameDayAs: day) }
        let sourced = normalized.filter { $0.sourceKey == key }
        let state = snapshot.initialization?[metric.rawValue]
        let feature = metric == .sleep ? nil : episode.map {
          CurrentMetricExtractor.extract(metric: metric, samples: rows, sourceKey: key, episode: $0,
            now: current?.start ?? now, interventions: exclusions, usedRestingIDs: usedRHR,
            excludingIDs: currentIDs, configuration: configuration)
        }
        var reasons = Set(episode?.quality?.userBlockingReasons ?? episode?.flags ?? [])
        reasons.formUnion(feature?.reasons ?? [])
        let disposition: Disposition
        if state == .unread { disposition = .notRead }
        else if state == .inProgress { disposition = .readingIncomplete }
        else if state == nil { disposition = .initializationUnknown }
        else if key == nil { disposition = rawDay.isEmpty ? .rawAbsent : .sourceNotSelected }
        else if episode == nil { disposition = rawDay.isEmpty && candidates.isEmpty ? .rawAbsent : .noSleepCandidate }
        else if episode?.sleepDurationUsable != true { disposition = .sleepExcluded }
        else if metric == .sleep { disposition = .included }
        else if feature?.reliable == true {
          disposition = .included
          if metric == .restingHeartRate { usedRHR.formUnion(feature?.sampleIDs ?? []) }
        } else if sourced.isEmpty && !normalized.isEmpty { disposition = .sourceMismatch }
        else if normalized.isEmpty { disposition = .rawAbsent }
        else { disposition = .featureExcluded }
        audit.append(Day(metric: metric, day: day, initialization: state,
          rawCount: rawDay.count, normalizedCount: normalized.count, selectedSourceCount: sourced.count,
          selectedSourceKey: key, sleepCandidateIDs: candidates.map(\.id), selectedSleepID: episode?.id,
          sleepQuality: episode?.quality, includedSampleIDs: disposition == .included
            ? (feature?.sampleIDs ?? episode?.sampleIDs ?? []) : [],
          coveredHours: feature?.coveredHours ?? 0, disposition: disposition,
          filterReasons: reasons.sorted { $0.rawValue < $1.rawValue }))
      }
    }
    return Self(qualityPolicyVersion: configuration.qualityPolicyVersion, generatedAt: now,
      timeZoneID: calendar.timeZone.identifier, currentSleepID: current?.id, days: audit)
  }
}
