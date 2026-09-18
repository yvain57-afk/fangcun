import Foundation
import CryptoKit

public enum ReadinessMetric: String, Codable, CaseIterable, Sendable {
  case hrvSDNN, hrvRMSSD, restingHeartRate, sleep, workout, mindfulSession
}

public struct ReadinessSource: Codable, Equatable, Sendable {
  public var bundleID: String
  public var name: String
  public var productType: String?
  public var deviceModel: String?
  public var deviceIdentity: String?
  public var revision: String
  public var samplingMethod: String
  public var compatibilitySegment: String
  public var isOriginalDeviceRecord: Bool
  public var identityAmbiguous: Bool
  public var identityIncomplete: Bool { deviceIdentity == nil }

  public init(bundleID: String, name: String = "", productType: String? = nil,
    deviceModel: String? = nil, deviceIdentity: String? = nil, revision: String = "",
    samplingMethod: String, compatibilitySegment: String = "v1",
    isOriginalDeviceRecord: Bool = false, identityAmbiguous: Bool = false) {
    self.bundleID = bundleID; self.name = name; self.productType = productType
    self.deviceModel = deviceModel; self.deviceIdentity = deviceIdentity; self.revision = revision
    self.samplingMethod = samplingMethod; self.compatibilitySegment = compatibilitySegment
    self.isOriginalDeviceRecord = isOriginalDeviceRecord; self.identityAmbiguous = identityAmbiguous
  }

  public func key(for metric: ReadinessMetric) -> String {
    let parts = [metric.rawValue, bundleID, productType ?? "", deviceModel ?? "",
      deviceIdentity ?? "", samplingMethod, compatibilitySegment]
    return StableDigest.text(parts.map { "\($0.utf8.count):\($0)" }.joined())
  }
}

public enum SleepStage: String, Codable, Sendable {
  case asleep, core, deep, rem, awake, inBed, unknown
  public var isAsleep: Bool { [.asleep, .core, .deep, .rem].contains(self) }
}

public struct ReadinessSample: Codable, Equatable, Sendable {
  public var id: UUID
  public var metric: ReadinessMetric
  public var value: Double?
  public var unit: String
  public var stage: SleepStage?
  public var start: Date
  public var end: Date
  public var source: ReadinessSource
  public var manuallyEntered: Bool
  public var syncIdentifier: String?
  public var syncVersion: Int
  public var activityType: UInt?
  public var metadata: [String: String]
  public var queriedAt: Date
  public var normalizationVersion: Int
  public var sourceKey: String { source.key(for: metric) }

  public init(id: UUID, metric: ReadinessMetric, value: Double? = nil, unit: String = "",
    stage: SleepStage? = nil, start: Date, end: Date, source: ReadinessSource,
    manuallyEntered: Bool = false, syncIdentifier: String? = nil, syncVersion: Int = 0,
    activityType: UInt? = nil, metadata: [String: String] = [:], queriedAt: Date,
    normalizationVersion: Int = 1) {
    self.id = id; self.metric = metric; self.value = value; self.unit = unit
    self.stage = stage; self.start = start; self.end = end; self.source = source
    self.manuallyEntered = manuallyEntered; self.syncIdentifier = syncIdentifier
    self.syncVersion = syncVersion; self.activityType = activityType; self.metadata = metadata
    self.queriedAt = queriedAt; self.normalizationVersion = normalizationVersion
  }
}

public enum StableDigest {
  public static func data(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
  public static func text(_ text: String) -> String { data(Data(text.utf8)) }
  public static func encoded<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
    encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
    return data(try encoder.encode(value))
  }
}

/// Cross-application mirror deduplication is opt-in and never inferred from equal values alone.
public struct SampleMirrorPolicy: Codable, Sendable {
  public var sourcePairs: [Set<String>]
  public init(sourcePairs: [Set<String>] = []) { self.sourcePairs = sourcePairs }
  func permits(_ lhs: String, _ rhs: String) -> Bool {
    lhs != rhs && sourcePairs.contains { $0.contains(lhs) && $0.contains(rhs) }
  }
}

public enum SampleNormalizer {
  public static func deduplicate(_ samples: [ReadinessSample], mirrors: SampleMirrorPolicy = .init()) -> [ReadinessSample] {
    let ordered = samples.sorted {
      if $0.syncVersion != $1.syncVersion { return $0.syncVersion > $1.syncVersion }
      if $0.source.isOriginalDeviceRecord != $1.source.isOriginalDeviceRecord { return $0.source.isOriginalDeviceRecord }
      if $0.queriedAt != $1.queriedAt { return $0.queriedAt > $1.queriedAt }
      return $0.id.uuidString < $1.id.uuidString
    }
    var result: [ReadinessSample] = []
    var ids: Set<UUID> = [], synced: Set<String> = []
    for sample in ordered {
      let syncKey = sample.syncIdentifier.map { sample.sourceKey + "|" + $0 }
      guard !ids.contains(sample.id), syncKey.map({ !synced.contains($0) }) ?? true else { continue }
      let mirrored = !mirrors.sourcePairs.isEmpty && result.contains { retained in
        guard sample.metric == retained.metric, mirrors.permits(sample.sourceKey, retained.sourceKey) else { return false }
        if sample.metric == .workout {
          guard sample.activityType == retained.activityType else { return false }
          let overlap = min(sample.end, retained.end).timeIntervalSince(max(sample.start, retained.start))
          return overlap > 0 && overlap >= 0.8 * min(sample.end.timeIntervalSince(sample.start), retained.end.timeIntervalSince(retained.start))
        }
        return sample.start == retained.start && sample.end == retained.end
          && sample.value == retained.value && sample.stage == retained.stage
      }
      guard !mirrored else { continue }
      ids.insert(sample.id)
      if let syncKey { synced.insert(syncKey) }
      result.append(sample)
    }
    return result.sorted { $0.id.uuidString < $1.id.uuidString }
  }
}

public struct SelectedReadinessSource: Codable, Equatable, Sendable {
  public var sourceKey: String
  public var segmentID: String
  public var manuallySelected: Bool
  public init(sourceKey: String, segmentID: String, manuallySelected: Bool = false) {
    self.sourceKey = sourceKey; self.segmentID = segmentID; self.manuallySelected = manuallySelected
  }
}

public enum StableSourceSelector {
  public static func select(metric: ReadinessMetric, samples: [ReadinessSample],
    existing: SelectedReadinessSource?, requested: String? = nil, calendar: Calendar,
    now: Date) -> SelectedReadinessSource? {
    if let requested {
      if existing?.sourceKey == requested { return existing }
      return SelectedReadinessSource(sourceKey: requested,
        segmentID: StableDigest.text("\(existing?.segmentID ?? "initial")|\(requested)"), manuallySelected: true)
    }
    // A temporary gap must not cause silent source switching.
    if let existing { return existing }
    let valid = samples.filter {
      $0.metric == metric && !$0.manuallyEntered && !$0.source.identityAmbiguous
        && !$0.source.bundleID.isEmpty && $0.end <= now
        && $0.end >= now.addingTimeInterval(-35 * 86_400)
        && ($0.value.map { $0.isFinite && $0 > 0 } ?? ($0.stage?.isAsleep == true || metric == .workout))
    }
    let groups = Dictionary(grouping: valid, by: \.sourceKey)
    let keys = groups.keys.sorted { lhs, rhs in
      let a = groups[lhs]!, b = groups[rhs]!
      let da = Set(a.map { calendar.startOfDay(for: $0.end) }).count
      let db = Set(b.map { calendar.startOfDay(for: $0.end) }).count
      if da != db { return da > db }
      let originalA = a.contains { $0.source.isOriginalDeviceRecord }
      let originalB = b.contains { $0.source.isOriginalDeviceRecord }
      return originalA != originalB ? originalA : lhs < rhs
    }
    return keys.first.map { SelectedReadinessSource(sourceKey: $0, segmentID: StableDigest.text("initial|\($0)")) }
  }
}

public struct HealthReadCursor: Codable, Equatable, Sendable {
  public var anchor: Data?
  public var windowStart: Date
  public init(anchor: Data? = nil, windowStart: Date) { self.anchor = anchor; self.windowStart = windowStart }
}

public struct ReadinessChangeBatch: Sendable {
  public var metric: ReadinessMetric
  public var samples: [ReadinessSample]
  public var deletedIDs: [UUID]
  public var cursor: HealthReadCursor
  public var hasMore: Bool
  public init(metric: ReadinessMetric, samples: [ReadinessSample], deletedIDs: [UUID] = [],
    cursor: HealthReadCursor, hasMore: Bool = false) {
    self.metric = metric; self.samples = samples; self.deletedIDs = deletedIDs
    self.cursor = cursor; self.hasMore = hasMore
  }
}

public enum ReadinessReadFailure: String, Error, Codable, Sendable {
  case queryFailed, protectedDataUnavailable, healthDataUnavailable, invalidAnchor, unsupportedMetric
}

public struct ReadinessSampleLedger: Codable, Sendable {
  public var samples: [String: ReadinessSample] = [:]
  public var cursors: [String: HealthReadCursor] = [:]
  public var tombstones: Set<String> = []
  public init() {}
  /// Apply on a transaction-local copy. Persist this copy together with its cursors.
  public mutating func apply(_ batch: ReadinessChangeBatch, now: Date) {
    tombstones.formUnion(batch.deletedIDs.map(\.uuidString))
    for sample in batch.samples where sample.metric == batch.metric && !tombstones.contains(sample.id.uuidString) {
      if let previous = samples[sample.id.uuidString], previous.syncVersion > sample.syncVersion { continue }
      samples[sample.id.uuidString] = sample
    }
    samples = samples.filter { !tombstones.contains($0.key) && $0.value.end >= now.addingTimeInterval(-35 * 86_400) }
    cursors[batch.metric.rawValue] = batch.cursor
  }
  public var normalizedSamples: [ReadinessSample] { SampleNormalizer.deduplicate(Array(samples.values)) }
}
