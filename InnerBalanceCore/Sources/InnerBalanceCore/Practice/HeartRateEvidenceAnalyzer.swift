import Foundation

public struct HeartRateSample: Equatable, Sendable {
  public let date: Date
  public let beatsPerMinute: Double

  public init(date: Date, beatsPerMinute: Double) {
    self.date = date
    self.beatsPerMinute = beatsPerMinute
  }
}

public struct HeartRateEvidence: Codable, Equatable, Sendable {
  public let startBeatsPerMinute: Double
  public let endBeatsPerMinute: Double
  public let sampleCount: Int

  public init(
    startBeatsPerMinute: Double,
    endBeatsPerMinute: Double,
    sampleCount: Int
  ) {
    self.startBeatsPerMinute = startBeatsPerMinute
    self.endBeatsPerMinute = endBeatsPerMinute
    self.sampleCount = sampleCount
  }
}

public enum HeartRateEvidenceAnalyzer {
  public static func analyze(
    samples: [HeartRateSample],
    startDate: Date,
    endDate: Date,
    windowDuration: TimeInterval = 60,
    minimumSamplesPerWindow: Int = 3
  ) -> HeartRateEvidence? {
    guard endDate > startDate,
      windowDuration > 0,
      minimumSamplesPerWindow > 0,
      endDate.timeIntervalSince(startDate) >= windowDuration * 2
    else { return nil }

    let valid = samples.filter {
      $0.date >= startDate
        && $0.date <= endDate
        && $0.beatsPerMinute.isFinite
        && (30...220).contains($0.beatsPerMinute)
    }
    let startWindow = valid.filter { $0.date <= startDate.addingTimeInterval(windowDuration) }
    let endWindow = valid.filter { $0.date >= endDate.addingTimeInterval(-windowDuration) }
    guard startWindow.count >= minimumSamplesPerWindow,
      endWindow.count >= minimumSamplesPerWindow,
      let start = median(startWindow.map(\.beatsPerMinute)),
      let end = median(endWindow.map(\.beatsPerMinute))
    else { return nil }

    return HeartRateEvidence(
      startBeatsPerMinute: start,
      endBeatsPerMinute: end,
      sampleCount: startWindow.count + endWindow.count
    )
  }

  private static func median(_ values: [Double]) -> Double? {
    let sorted = values.sorted()
    guard !sorted.isEmpty else { return nil }
    let middle = sorted.count / 2
    return sorted.count.isMultiple(of: 2)
      ? (sorted[middle - 1] + sorted[middle]) / 2
      : sorted[middle]
  }
}
