import Foundation

public enum ReadinessAvailability: String, Codable, Sendable { case assessable, provisional, limited, insufficient, awaitingData, failed }
public enum ReadinessLevel: String, Codable, Sendable { case usual, reduced, low }
public enum ReadinessFreshness: String, Codable, Sendable { case current, historical, stale }
public enum ReadinessSyncState: String, Codable, Sendable { case local, queued, received, disconnected }

public struct ReadinessInput: Codable, Sendable {
  public var sleep: ReadinessSleepSelection
  public var hrv: ReadinessMetricFeature?
  public var rhr: ReadinessMetricFeature?
  public var baselines: ReadinessBaselines?
  public var sourceDetails: [String: ReadinessSource]
  public var sources: [String: SelectedReadinessSource]
  public var configuration: ReadinessConfiguration
  public var now: Date
  public var queriedAt: Date?
  public var timeZoneID: String
  public var readFailure: ReadinessReadFailure?
  public var cacheInvalidated: Bool
  public var dependencySampleIDs: [UUID]?
  public var evidenceContextVersion: String?
}

public struct ReadinessPreparedInput: Sendable {
  public var input: ReadinessInput
  public var episodes: [ReadinessSleepEpisode]
}

public enum ReadinessInputBuilder {
  private struct EvidenceContext: Encodable {
    var calendar: Calendar
    var interventions: [ReadinessInterval]
  }
  public static func build(samples: [ReadinessSample], sources: [String: SelectedReadinessSource],
    previousEpisodes: [ReadinessSleepEpisode] = [], now: Date, calendar: Calendar,
    configuration: ReadinessConfiguration = .init(), interventions: [ReadinessInterval] = [],
    usedRestingIDs: Set<UUID> = [], manualSleepID: String? = nil,
    readFailure: ReadinessReadFailure? = nil, cacheInvalidated: Bool = false) -> ReadinessPreparedInput {
    let rows = SampleNormalizer.deduplicate(samples)
    let built = SleepEpisodeBuilder.build(samples: rows, sourceKey: sources[ReadinessMetric.sleep.rawValue]?.sourceKey,
      calendar: calendar, now: now, configuration: configuration, lookback: 35*86_400, previous: previousEpisodes)
    // Historical malformed episodes do not invalidate a separate current night.
    let recent = SleepEpisodeBuilder.build(samples: rows, sourceKey: sources[ReadinessMetric.sleep.rawValue]?.sourceKey,
      calendar: calendar, now: now, configuration: configuration, lookback: 48*3600, previous: built.episodes)
    let sleep = SleepEpisodeBuilder.select(recent, now: now, manualEpisodeID: manualSleepID, configuration: configuration)
    let hSource = sources[ReadinessMetric.hrvSDNN.rawValue]?.sourceKey
    let rSource = sources[ReadinessMetric.restingHeartRate.rawValue]?.sourceKey
    let exclusions = interventions + rows.filter { $0.metric == .mindfulSession }.map { ReadinessInterval(start: $0.start, end: $0.end) }
    let h = sleep.episode.map { CurrentMetricExtractor.extract(metric: .hrvSDNN, samples: rows,
      sourceKey: hSource, episode: $0, now: now, interventions: exclusions, configuration: configuration) }
    let r = sleep.episode.map { CurrentMetricExtractor.extract(metric: .restingHeartRate, samples: rows,
      sourceKey: rSource, episode: $0, now: now, usedRestingIDs: usedRestingIDs, configuration: configuration) }
    let baseline = sleep.episode.map { BaselineBuilder.build(episodes: built.episodes, samples: rows, beforeEpisode: $0,
      hrvSource: hSource, rhrSource: rSource, currentSampleIDs: Set((h?.sampleIDs ?? [])+(r?.sampleIDs ?? [])),
      calendar: calendar, interventions: exclusions, configuration: configuration) }
    return ReadinessPreparedInput(input: ReadinessInput(sleep: sleep, hrv: h, rhr: r, baselines: baseline,
      sourceDetails: Dictionary(uniqueKeysWithValues: sources.compactMap { key, selected in
        rows.filter { $0.sourceKey == selected.sourceKey }.max { $0.end < $1.end }.map { (key, $0.source) }
      }), sources: sources, configuration: configuration, now: now, queriedAt: rows.map(\.queriedAt).max(),
      timeZoneID: calendar.timeZone.identifier, readFailure: readFailure, cacheInvalidated: cacheInvalidated,
      dependencySampleIDs: samples.filter { [.sleep,.hrvSDNN,.restingHeartRate,.mindfulSession].contains($0.metric) }
        .map(\.id).sorted { $0.uuidString < $1.uuidString },
      evidenceContextVersion: try? StableDigest.encoded(EvidenceContext(calendar: calendar,
        interventions: exclusions.sorted { $0.start == $1.start ? $0.end < $1.end : $0.start < $1.start }))),
      episodes: built.episodes)
  }
}

public struct ReadinessMetricEvidence: Codable, Sendable {
  public var feature: ReadinessMetricFeature
  public var baseline: ReadinessMetricBaseline?
  public var deviation: Double?
}

public struct ReadinessAssessment: Codable, Sendable {
  public var assessmentID: String
  public var recoveryCycleID: String?
  public var revision: Int
  public var supersedesID: String?
  public var configuration: ReadinessConfiguration
  public var algorithmVersion: String { configuration.algorithmVersion }
  public var configurationVersion: String { configuration.version }
  public var featureSchemaVersion: Int { configuration.featureSchemaVersion }
  public var qualityPolicyVersion: String? { configuration.qualityPolicyVersion }
  public var sleepQuality: ReadinessSleepQuality?
  public var sleepDurationUsable: Bool { sleepQuality?.sleepDurationUsable ?? (actualSleepSeconds != nil && !qualityFlags.contains(.conflictingSleep)) }
  public var asleepIntervalsUsableForHRV: Bool { sleepQuality?.asleepIntervalsUsableForHRV ?? sleepDurationUsable }
  public var sleepStageBreakdownUsable: Bool { sleepQuality?.sleepStageBreakdownUsable ?? false }
  public var inputFingerprint: String
  public var sleepEpisodeID: String?
  public var sleepStartAt: Date?
  public var sleepEndAt: Date?
  public var actualSleepSeconds: TimeInterval?
  public var evidenceWindowStart: Date?
  public var evidenceWindowEnd: Date?
  public var computedAt: Date
  public var queriedAt: Date?
  public var latestMeasuredAt: Date?
  public var currentUntil: Date?
  public var validUntil: Date?
  public var timeZoneID: String
  public var availability: ReadinessAvailability
  public var level: ReadinessLevel?
  public var freshness: ReadinessFreshness
  public var syncState: ReadinessSyncState = .local
  public var evidence: [ReadinessMetricEvidence]
  public var missingReasons: [ReadinessReason]
  public var qualityFlags: [ReadinessReason]
  public var sourceDetails: [String: ReadinessSource]
  public var sources: [String: SelectedReadinessSource]
  public var manuallySelectedSleep: Bool
  public var autonomicSeverity: Int?
  public var sleepSeverity: Int?
  public var refreshFailure: ReadinessReadFailure?
  public var contributingSampleIDs: [UUID]
  public var dependencyVersion: Int?
  public var evidenceContextVersion: String?
}

public enum AssessmentFreshness {
  public static func resolve(_ assessment: ReadinessAssessment, now: Date, newerSleepEnd: Date? = nil) -> ReadinessFreshness {
    guard let end = assessment.sleepEndAt else { return .stale }
    let elapsed = now.timeIntervalSince(end)
    if elapsed < 0 || elapsed > assessment.configuration.historicalHours*3600 { return .stale }
    if elapsed > assessment.configuration.currentHours*3600 || (newerSleepEnd.map { $0 > end } ?? false) { return .historical }
    return .current
  }
}

public enum EvidenceQualityEvaluator {
  public static func evaluate(_ input: ReadinessInput, highHRV: Bool) -> ReadinessAvailability {
    if input.readFailure != nil { return .failed }
    if input.sleep.awaitingData { return .awaitingData }
    guard input.sleep.episode != nil, input.hrv?.value != nil || input.rhr?.value != nil else { return .insufficient }
    let sleepBlockers = Set(input.sleep.flags).subtracting([.manualSleepSelection, .sleepStageOverlap, .sourceIdentityIncomplete])
    guard input.configuration.isValid, sleepBlockers.isEmpty, input.sleep.episode?.sleepDurationUsable == true, input.hrv?.reliable == true,
      input.rhr?.reliable == true, !highHRV, let baselines = input.baselines,
      baselines.hrv.validDays >= input.configuration.provisionalDays,
      baselines.rhr.validDays >= input.configuration.provisionalDays else { return .limited }
    return min(baselines.hrv.validDays, baselines.rhr.validDays) < input.configuration.matureDays ? .provisional : .assessable
  }
}

public enum ReadinessEngine {
  public static func evaluate(_ input: ReadinessInput, cached: ReadinessAssessment? = nil) -> ReadinessAssessment {
    if input.readFailure != nil, !input.cacheInvalidated, let cached, cached.level != nil,
      cached.sources == input.sources, cached.configuration == input.configuration,
      input.evidenceContextVersion != nil, cached.evidenceContextVersion == input.evidenceContextVersion,
      AssessmentFreshness.resolve(cached, now: input.now, newerSleepEnd: input.sleep.episode?.end) != .stale,
      !(input.sleep.episode.map { $0.end > (cached.sleepEndAt ?? .distantPast) } ?? false) {
      var retained = cached
      retained.refreshFailure = input.readFailure
      retained.freshness = AssessmentFreshness.resolve(cached, now: input.now)
      return retained
    }
    let c = input.configuration
    let h = deviation(input.hrv?.value, baseline: input.baselines?.hrv, inverse: true)
    let r = deviation(input.rhr?.value, baseline: input.baselines?.rhr, inverse: false)
    // Tolerance only compensates floating point round trips at exact fixture boundaries.
    let high = h.map { $0 < -c.highHRVDeviation - 1e-12 } ?? false
    let availability = EvidenceQualityEvaluator.evaluate(input, highHRV: high)
    var reasons = Set(input.sleep.flags + (input.hrv?.reasons ?? [.hrvMissing]) + (input.rhr?.reasons ?? [.rhrMissing]))
    if !c.isValid { reasons.insert(.invalidConfiguration) }
    if input.readFailure != nil { reasons.insert(.refreshFailed) }
    if high { reasons.insert(.hrvAtypicallyHigh) }
    if (input.baselines?.hrv.validDays ?? 0) < c.provisionalDays || (input.baselines?.rhr.validDays ?? 0) < c.provisionalDays { reasons.insert(.baselineBuilding) }
    if input.hrv?.value == nil && input.rhr?.value == nil { reasons.insert(.currentDataMissing) }
    var a: Int?, s: Int?, level: ReadinessLevel?
    let sleep = input.sleep.episode
    if (availability == .assessable || availability == .provisional), let h, let r, let sleep {
      let hs = severity(h, configuration: c), rs = severity(r, configuration: c)
      a = hs == 2 || rs == 2 || (hs == 1 && rs == 1) ? 2 : max(hs, rs)
      let deficit = max(0, c.sleepTargetHours*60-sleep.asleepDuration/60)
      s = deficit + 1e-12 >= c.severeSleepDeficitMinutes ? 2 : deficit + 1e-12 >= c.mildSleepDeficitMinutes ? 1 : 0
      level = a == 0 && s == 0 ? .usual : (a == 2 && s! >= 1) || (s == 2 && a! >= 1) ? .low : .reduced
      if hs > 0 { reasons.insert(.hrvBelowBaseline) }
      if rs > 0 { reasons.insert(.rhrAboveBaseline) }
      if s! > 0 { reasons.insert(.sleepBelowTarget) }
    }
    let evidence = [input.hrv.map { ReadinessMetricEvidence(feature: $0, baseline: input.baselines?.hrv, deviation: h) },
      input.rhr.map { ReadinessMetricEvidence(feature: $0, baseline: input.baselines?.rhr, deviation: r) }].compactMap { $0 }
    var identity = input
    // Re-reading identical evidence does not create a new revision or extend its anchor.
    identity.now = Date(timeIntervalSince1970: 0); identity.queriedAt = nil
    identity.cacheInvalidated = false
    // Conservative invalidation dependencies are not themselves displayed evidence.
    identity.dependencySampleIDs = nil
    // Identity uses the logical RHR window; evidence still reports the actual min(now, deadline) cutoff.
    if let sleep = input.sleep.episode { identity.rhr?.window.end = sleep.end.addingTimeInterval(3*3600) }
    let fingerprint = (try? StableDigest.encoded(identity)) ?? "invalid-input"
    let id = StableDigest.text((sleep?.recoveryCycleID ?? "no-cycle") + fingerprint)
    let allIDs = (input.dependencySampleIDs ?? []) + (sleep?.sampleIDs ?? [])
      + evidence.flatMap { $0.feature.sampleIDs + ($0.baseline?.sampleIDs ?? []) }
    let missing: Set<ReadinessReason> = [.currentDataMissing,.sleepMissing,.hrvMissing,.rhrMissing,.baselineBuilding,.sparseHRV,.narrowHRVCoverage]
    var result = ReadinessAssessment(assessmentID: id, recoveryCycleID: sleep?.recoveryCycleID, revision: 1, supersedesID: nil,
      configuration: c, sleepQuality: sleep?.quality, inputFingerprint: fingerprint, sleepEpisodeID: sleep?.id, sleepStartAt: sleep?.start, sleepEndAt: sleep?.end,
      actualSleepSeconds: sleep?.sleepDurationUsable == true ? sleep?.asleepDuration : nil, evidenceWindowStart: evidence.map(\.feature.window.start).min() ?? sleep?.start,
      evidenceWindowEnd: evidence.map(\.feature.window.end).max() ?? sleep?.end, computedAt: input.now, queriedAt: input.queriedAt,
      latestMeasuredAt: (evidence.compactMap(\.feature.latestMeasuredAt) + [sleep?.end].compactMap { $0 }).max(),
      currentUntil: sleep?.end.addingTimeInterval(c.currentHours*3600), validUntil: sleep?.end.addingTimeInterval(c.historicalHours*3600),
      timeZoneID: input.timeZoneID, availability: availability, level: level, freshness: .stale, evidence: evidence,
      missingReasons: reasons.intersection(missing).sorted { $0.rawValue < $1.rawValue },
      qualityFlags: reasons.subtracting(missing).sorted { $0.rawValue < $1.rawValue }, sourceDetails: input.sourceDetails, sources: input.sources,
      manuallySelectedSleep: input.sleep.manuallySelected, autonomicSeverity: a, sleepSeverity: s,
      refreshFailure: input.readFailure, contributingSampleIDs: Array(Set(allIDs)).sorted { $0.uuidString < $1.uuidString },
      dependencyVersion: input.dependencySampleIDs == nil ? nil : 1,
      evidenceContextVersion: input.evidenceContextVersion)
    result.freshness = AssessmentFreshness.resolve(result, now: input.now)
    return result
  }

  private static func deviation(_ current: Double?, baseline: ReadinessMetricBaseline?, inverse: Bool) -> Double? {
    guard let current, let center = baseline?.center, let scale = baseline?.scale,
      current.isFinite, center.isFinite, scale.isFinite, scale > 0 else { return nil }
    let result = (inverse ? center-current : current-center)/scale
    return result.isFinite ? result : nil
  }
  private static func severity(_ deviation: Double, configuration: ReadinessConfiguration) -> Int {
    deviation + 1e-12 >= configuration.severeDeviation ? 2 : deviation + 1e-12 >= configuration.mildDeviation ? 1 : 0
  }
}
