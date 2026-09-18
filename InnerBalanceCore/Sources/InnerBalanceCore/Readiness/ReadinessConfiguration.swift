import Foundation

/// Engineering defaults awaiting calibration. Not medical thresholds.
public struct ReadinessConfiguration: Codable, Equatable, Sendable {
  public var algorithmVersion = "readiness-v1-engineering"
  public var featureSchemaVersion = 1
  public var sleepTargetHours = 8.0
  public var episodeGapMinutes = 90.0
  public var minimumSleepHours = 2.0
  public var reviewSleepHours = 14.0
  public var arrivalBufferMinutes = 30.0
  public var interventionBufferMinutes = 30.0
  public var minimumHRVSamples = 3
  public var minimumHRVHours = 2
  public var baselineDays = 28
  public var provisionalDays = 7
  public var matureDays = 14
  public var madMultiplier = 1.4826
  public var hrvScaleFloor = 0.10
  public var rhrScaleFloor = 3.0
  public var currentHours = 18.0
  public var historicalHours = 24.0
  public var maximumHRVMS = 10_000.0
  public var maximumRestingBPM = 1_000.0
  public init(sleepTargetHours: Double = 8) { self.sleepTargetHours = sleepTargetHours }
  public var version: String { (try? StableDigest.encoded(self)) ?? "invalid-configuration" }
  public var isValid: Bool {
    (7...10).contains(sleepTargetHours) && episodeGapMinutes > 0 && minimumSleepHours > 0
      && reviewSleepHours > minimumSleepHours && arrivalBufferMinutes >= 0 && interventionBufferMinutes >= 0
      && minimumHRVSamples >= 3 && minimumHRVHours >= 2 && baselineDays == 28
      && provisionalDays == 7 && matureDays == 14 && madMultiplier > 0
      && hrvScaleFloor > 0 && rhrScaleFloor > 0 && currentHours == 18 && historicalHours == 24
      && [sleepTargetHours,episodeGapMinutes,minimumSleepHours,reviewSleepHours,arrivalBufferMinutes,
          interventionBufferMinutes,madMultiplier,hrvScaleFloor,rhrScaleFloor,maximumHRVMS,maximumRestingBPM].allSatisfy { $0.isFinite }
  }
}

public enum ReadinessReason: String, Codable, Hashable, Sendable {
  case currentDataMissing, sleepMissing, hrvMissing, rhrMissing, baselineBuilding, sparseHRV, narrowHRVCoverage
  case invalidValue, extremeValue, unitMismatch, sourceUnknown, sourceAmbiguous, sourceIdentityIncomplete
  case manuallyEntered, interventionExcluded, restingSampleReused, shortSleep, excessiveSleep, futureSleep
  case conflictingSleep, ambiguousSleep, ambiguousRevision, awaitingArrival, manualSleepSelection
  case hrvAtypicallyHigh, hrvBelowBaseline, rhrAboveBaseline, sleepBelowTarget, dataStale
  case invalidConfiguration, refreshFailed, sourceChanged, sourceDeleted
}

public struct ReadinessInterval: Codable, Equatable, Sendable {
  public var start: Date
  public var end: Date
  public init(start: Date, end: Date) { self.start = start; self.end = end }
  public var duration: TimeInterval { max(0, end.timeIntervalSince(start)) }
  public func overlaps(_ other: Self) -> Bool { start <= other.end && end >= other.start }
}
