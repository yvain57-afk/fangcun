import Foundation

/// Quality is tied to the feature policy, not to medical severity. Legacy episodes retain
/// conservative flag-based semantics until rebuilt from their original records.
public struct ReadinessSleepQuality: Codable, Equatable, Sendable {
  public var policyVersion: String
  public var sleepDurationUsable: Bool
  public var asleepIntervalsUsableForHRV: Bool
  public var sleepStageBreakdownUsable: Bool
  public var internalReasons: [ReadinessReason]
  public var userBlockingReasons: [ReadinessReason]
}

public struct ReadinessSleepEpisode: Codable, Equatable, Sendable {
  public var id: String
  public var sourceKey: String
  public var intervals: [ReadinessInterval]
  public var sampleIDs: [UUID]
  public var flags: [ReadinessReason]
  public var quality: ReadinessSleepQuality?
  public var recordedStartAt: Date?
  public var recordedEndAt: Date?
  public var start: Date { recordedStartAt ?? intervals.first!.start }
  public var end: Date { recordedEndAt ?? intervals.last!.end }
  public var sleepDurationUsable: Bool { quality?.sleepDurationUsable ?? flags.isEmpty }
  public var asleepIntervalsUsableForHRV: Bool { quality?.asleepIntervalsUsableForHRV ?? flags.isEmpty }
  public var sleepStageBreakdownUsable: Bool { quality?.sleepStageBreakdownUsable ?? false }
  public var asleepDuration: TimeInterval { intervals.reduce(0) { $0 + $1.duration } }
  public var recoveryCycleID: String { "sleep-" + id }
}

public struct SleepEpisodeBuild: Sendable {
  public var episodes: [ReadinessSleepEpisode]
  public var flags: [ReadinessReason]
}

public struct ReadinessSleepSelection: Codable, Sendable {
  public var episode: ReadinessSleepEpisode?
  public var manuallySelected: Bool
  public var awaitingData: Bool
  public var flags: [ReadinessReason]
}

public enum SleepEpisodeBuilder {
  public static func build(samples: [ReadinessSample], sourceKey: String?, calendar: Calendar,
    now: Date, configuration: ReadinessConfiguration = .init(),
    lookback: TimeInterval = 48 * 3600, previous: [ReadinessSleepEpisode] = []) -> SleepEpisodeBuild {
    guard let sourceKey else { return SleepEpisodeBuild(episodes: [], flags: [.sleepMissing]) }
    let rows = SampleNormalizer.deduplicate(samples).filter {
      $0.metric == .sleep && $0.sourceKey == sourceKey && $0.end >= now.addingTimeInterval(-lookback)
    }
    var global: Set<ReadinessReason> = []
    if rows.contains(where: { $0.end > now || $0.start > now }) { global.insert(.futureSleep) }
    if rows.contains(where: { $0.end <= $0.start || $0.stage == .unknown }) { global.insert(.conflictingSleep) }
    let valid = rows.filter { $0.end > $0.start && $0.end <= now }
    let asleep = valid.filter { $0.stage?.isAsleep == true }.sorted {
      $0.start == $1.start ? $0.end < $1.end : $0.start < $1.start
    }
    var groups: [[ReadinessSample]] = []
    for row in asleep {
      if let last = groups.last, let end = last.map(\.end).max(),
        row.start.timeIntervalSince(end) <= configuration.episodeGapMinutes * 60 {
        groups[groups.count - 1].append(row)
      } else { groups.append([row]) }
    }
    var episodes = groups.map { group -> ReadinessSleepEpisode in
      let claimedIntervals = union(group.map { ReadinessInterval(start: $0.start, end: $0.end) })
      let start = group.map(\.start).min()!, end = group.map(\.end).max()!
      let related = rows.filter { min($0.end, end) > max($0.start, start)
        || ($0.end <= $0.start && $0.start >= start && $0.start <= end) }
      let awake = valid.filter { $0.stage == .awake && min($0.end, end) > max($0.start, start) }
      let intervals = subtract(claimedIntervals, excluding: awake.map { .init(start: $0.start, end: $0.end) })
      var flags: Set<ReadinessReason> = []
      let duration = claimedIntervals.reduce(0) { $0 + $1.duration }
      if duration < configuration.minimumSleepHours * 3600 { flags.insert(.shortSleep) }
      if duration > configuration.reviewSleepHours * 3600 { flags.insert(.excessiveSleep) }
      if group.contains(where: \.manuallyEntered) { flags.insert(.manuallyEntered) }
      if group.contains(where: { $0.source.identityAmbiguous }) { flags.insert(.sourceAmbiguous) }
      if group.contains(where: { $0.source.bundleID.isEmpty }) { flags.insert(.sourceUnknown) }
      if group.contains(where: { $0.source.identityIncomplete }) { flags.insert(.sourceIdentityIncomplete) }
      if related.contains(where: { $0.end <= $0.start || $0.stage == .unknown }) { flags.insert(.conflictingSleep) }
      if related.contains(where: { $0.end > now }) { flags.insert(.futureSleep) }
      for row in group {
        for other in valid where other.id != row.id && min(row.end, other.end) > max(row.start, other.start) {
          if other.stage == .awake { flags.insert(.conflictingSleep) }
          let specific: [SleepStage] = [.core,.deep,.rem]
          if specific.contains(row.stage ?? .unknown) && specific.contains(other.stage ?? .unknown)
            && row.stage != other.stage { flags.insert(.sleepStageOverlap) }
        }
      }
      let blockers = flags.subtracting([.sleepStageOverlap, .sourceIdentityIncomplete])
      let quality = ReadinessSleepQuality(policyVersion: configuration.qualityPolicyVersion ?? "sleep-quality-v2",
        sleepDurationUsable: blockers.isEmpty, asleepIntervalsUsableForHRV: blockers.isEmpty,
        sleepStageBreakdownUsable: blockers.isEmpty && !flags.contains(.sleepStageOverlap)
          && group.allSatisfy { [.core,.deep,.rem].contains($0.stage ?? .unknown) },
        internalReasons: flags.sorted { $0.rawValue < $1.rawValue },
        userBlockingReasons: blockers.sorted { $0.rawValue < $1.rawValue })
      let ids = Array(Set((group + related).map(\.id))).sorted { $0.uuidString < $1.uuidString }
      let identityIDs = group.map(\.id).sorted { $0.uuidString < $1.uuidString }
      let id = StableDigest.text(sourceKey + "|" + identityIDs.map(\.uuidString).joined(separator: ","))
      return ReadinessSleepEpisode(id: id, sourceKey: sourceKey, intervals: intervals,
        sampleIDs: ids, flags: flags.sorted { $0.rawValue < $1.rawValue }, quality: quality,
        recordedStartAt: start, recordedEndAt: end)
    }
    let matches = episodes.map { episode in previous.filter { old in
      let overlap = min(old.end, episode.end).timeIntervalSince(max(old.start, episode.start))
      let span = max(old.end.timeIntervalSince(old.start), episode.end.timeIntervalSince(episode.start))
      return old.sourceKey == episode.sourceKey && span > 0 && overlap / span > configuration.revisionOverlapFraction
        && abs(old.end.timeIntervalSince(episode.end)) <= configuration.revisionEndGapHours * 3600
    } }
    for index in episodes.indices {
      if matches[index].count == 1, let match = matches[index].first,
        matches.filter({ $0.contains(where: { $0.id == match.id }) }).count == 1 {
        episodes[index].id = match.id
      } else if !matches[index].isEmpty {
        episodes[index].flags.append(.ambiguousRevision)
        episodes[index].quality?.internalReasons.append(.ambiguousRevision)
        episodes[index].quality?.userBlockingReasons.append(.ambiguousRevision)
        episodes[index].quality?.sleepDurationUsable = false
        episodes[index].quality?.asleepIntervalsUsableForHRV = false
        episodes[index].quality?.sleepStageBreakdownUsable = false
      }
    }
    return SleepEpisodeBuild(episodes: episodes, flags: global.sorted { $0.rawValue < $1.rawValue })
  }

  public static func select(_ build: SleepEpisodeBuild, now: Date,
    manualEpisodeID: String? = nil, configuration: ReadinessConfiguration = .init()) -> ReadinessSleepSelection {
    let recent = build.episodes.filter { $0.end <= now && now.timeIntervalSince($0.end) <= 24 * 3600 }
    var flags = build.flags
    let awaiting = recent.map(\.end).max().map { now.timeIntervalSince($0) < configuration.arrivalBufferMinutes * 60 } ?? false
    if awaiting { flags.append(.awaitingArrival) }
    let manual = manualEpisodeID.flatMap { id in recent.first { $0.id == id } }
    let candidates = recent.filter { $0.asleepDuration >= configuration.minimumSleepHours * 3600
      || ($0.flags.contains(.conflictingSleep) && $0.end.timeIntervalSince($0.start) >= configuration.minimumSleepHours * 3600) }
    let selected = manual ?? candidates.max {
      $0.asleepDuration == $1.asleepDuration ? $0.end < $1.end : $0.asleepDuration < $1.asleepDuration
    }
    if manual != nil { flags.append(.manualSleepSelection) }
    if manual == nil {
      let long = candidates.filter { $0.asleepDuration >= configuration.ambiguousSleepHours * 3600 }
      if long.contains(where: { a in long.contains { b in a.id != b.id && abs(a.end.timeIntervalSince(b.end)) > configuration.ambiguousEndGapHours * 3600 } }) {
        flags.append(.ambiguousSleep)
      }
    }
    flags += selected?.flags ?? [.sleepMissing]
    return ReadinessSleepSelection(episode: selected, manuallySelected: manual != nil,
      awaitingData: awaiting, flags: Array(Set(flags)).sorted { $0.rawValue < $1.rawValue })
  }

  /// Only confirmed asleep segments survive. A removed conflict interval is not an
  /// estimate of total sleep; sleepDurationUsable stays false until the conflict resolves.
  public static func subtract(_ intervals: [ReadinessInterval], excluding: [ReadinessInterval]) -> [ReadinessInterval] {
    var result = union(intervals)
    for cut in union(excluding) {
      result = result.flatMap { part -> [ReadinessInterval] in
        guard min(part.end, cut.end) > max(part.start, cut.start) else { return [part] }
        var kept: [ReadinessInterval] = []
        if part.start < cut.start { kept.append(.init(start: part.start, end: cut.start)) }
        if part.end > cut.end { kept.append(.init(start: cut.end, end: part.end)) }
        return kept
      }
    }
    return result
  }

  public static func union(_ input: [ReadinessInterval]) -> [ReadinessInterval] {
    let sorted = input.filter { $0.end > $0.start }.sorted { $0.start < $1.start }
    var result: [ReadinessInterval] = []
    for next in sorted {
      if let last = result.last, next.start <= last.end {
        result[result.count - 1].end = max(last.end, next.end)
      } else { result.append(next) }
    }
    return result
  }
}
