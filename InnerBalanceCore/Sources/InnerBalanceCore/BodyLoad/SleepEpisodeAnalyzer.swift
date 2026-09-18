import Foundation

public struct SleepSampleInterval: Equatable, Sendable {
  public let start: Date
  public let end: Date
  public let sourceName: String
  public let isAppleWatch: Bool

  public init(start: Date, end: Date, sourceName: String, isAppleWatch: Bool) {
    self.start = start
    self.end = end
    self.sourceName = sourceName
    self.isAppleWatch = isAppleWatch
  }
}

public enum SleepDataQuality: Equatable, Sendable {
  case reliable
  case needsReview
}

public struct SleepEpisode: Equatable, Sendable {
  public let start: Date
  public let end: Date
  public let asleepDuration: TimeInterval
  public let sampleCount: Int
  public let sourceNames: [String]
  public let usesAppleWatch: Bool
  public let quality: SleepDataQuality

  public var isUsableForBodyLoad: Bool {
    quality == .reliable
  }
}

public enum SleepEpisodeAnalyzer {
  public static func primarySleep(
    from samples: [SleepSampleInterval],
    now: Date,
    lookback: TimeInterval = 48 * 3_600,
    maximumEpisodeGap: TimeInterval = 90 * 60
  ) -> SleepEpisode? {
    let valid =
      samples
      .filter { $0.end > $0.start && $0.end <= now && $0.end >= now.addingTimeInterval(-lookback) }
      .sorted { $0.start < $1.start }
    guard !valid.isEmpty else { return nil }

    var groups: [[SleepSampleInterval]] = []
    for sample in valid {
      if let latestEnd = groups.last?.map(\.end).max(),
        sample.start.timeIntervalSince(latestEnd) <= maximumEpisodeGap
      {
        groups[groups.index(before: groups.endIndex)].append(sample)
      } else {
        groups.append([sample])
      }
    }

    let episodes = groups.map(makeEpisode)
    return episodes.max { left, right in
      if left.asleepDuration == right.asleepDuration {
        return left.end < right.end
      }
      return left.asleepDuration < right.asleepDuration
    }
  }

  private static func makeEpisode(from samples: [SleepSampleInterval]) -> SleepEpisode {
    let sorted = samples.sorted { $0.start < $1.start }
    var merged: [(start: Date, end: Date)] = []
    for sample in sorted {
      guard let last = merged.last else {
        merged.append((sample.start, sample.end))
        continue
      }

      if sample.start <= last.end {
        merged[merged.index(before: merged.endIndex)].end = max(last.end, sample.end)
      } else {
        merged.append((sample.start, sample.end))
      }
    }

    let duration = merged.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }
    return SleepEpisode(
      start: sorted.map(\.start).min()!,
      end: sorted.map(\.end).max()!,
      asleepDuration: duration,
      sampleCount: sorted.count,
      sourceNames: Array(Set(sorted.map(\.sourceName))).sorted(),
      usesAppleWatch: sorted.contains(where: \.isAppleWatch),
      quality: (2 * 3_600...12 * 3_600).contains(duration) ? .reliable : .needsReview
    )
  }
}
