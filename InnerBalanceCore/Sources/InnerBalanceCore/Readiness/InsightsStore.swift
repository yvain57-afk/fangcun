import Foundation

public enum InsightsStoreError: Error, Equatable {
  case corrupt, unsupportedSchema, staleTransaction, injectedFailure, invalidTransaction
}
public enum InsightsStoreFault: Sendable { case none, beforePublish, afterPrivacy, afterPublish }

extension ReadinessAssessment {
  var hasCompleteDependencies: Bool { dependencyVersion == 1 }
}

public struct DeletedAssessmentAudit: Codable, Sendable {
  public var assessmentID: String
  public var recoveryCycleID: String?
  public var revision: Int
  public var reason: ReadinessReason = .sourceDeleted
}

public struct InsightsSnapshot: Codable, Sendable {
  public var generation: Int = 0
  public var ledger = ReadinessSampleLedger()
  public var sources: [String: SelectedReadinessSource] = [:]
  public var episodes: [ReadinessSleepEpisode] = []
  public var assessments: [ReadinessAssessment] = []
  public var deletionAudit: [DeletedAssessmentAudit] = []
  public var currentAssessmentID: String?
  public var requiresResync = false
  public var manualSleepID: String?
  public init() {}
  public var current: ReadinessAssessment? { assessments.first { $0.assessmentID == currentAssessmentID } }

  public mutating func record(_ proposed: ReadinessAssessment) {
    var result = proposed
    if let same = current, same.inputFingerprint == result.inputFingerprint,
      same.recoveryCycleID == result.recoveryCycleID, same.availability == result.availability {
      result.assessmentID = same.assessmentID
      result.revision = same.revision; result.supersedesID = same.supersedesID
    } else {
      let previous = assessments.filter { $0.recoveryCycleID == result.recoveryCycleID }.max { $0.revision < $1.revision }
      let removed = deletionAudit.filter { $0.recoveryCycleID == result.recoveryCycleID }.max { $0.revision < $1.revision }
      result.revision = max(previous?.revision ?? 0, removed?.revision ?? 0) + 1
      result.supersedesID = (previous?.revision ?? 0) >= (removed?.revision ?? 0) ? previous?.assessmentID : removed?.assessmentID
      result.assessmentID = StableDigest.text((result.recoveryCycleID ?? "no-cycle") + result.inputFingerprint + "|revision-\(result.revision)")
    }
    assessments.removeAll { $0.assessmentID == result.assessmentID }
    assessments.append(result); currentAssessmentID = result.assessmentID
  }

  mutating func redact(_ tombstones: Set<String>) {
    ledger.tombstones.formUnion(tombstones)
    ledger.samples = ledger.samples.filter { !tombstones.contains($0.key) }
    episodes.removeAll { $0.sampleIDs.contains { tombstones.contains($0.uuidString) } }
    let affected = assessments.filter {
      // Pre-R01 files have incomplete dependency coverage. Any deletion invalidates them conservatively.
      (!$0.hasCompleteDependencies && !tombstones.isEmpty)
        || $0.contributingSampleIDs.contains { tombstones.contains($0.uuidString) }
    }
    for old in affected where !deletionAudit.contains(where: { $0.assessmentID == old.assessmentID }) {
      deletionAudit.append(DeletedAssessmentAudit(assessmentID: old.assessmentID, recoveryCycleID: old.recoveryCycleID, revision: old.revision))
    }
    let removed = Set(affected.map(\.assessmentID))
    assessments.removeAll { removed.contains($0.assessmentID) }
    if currentAssessmentID.map(removed.contains) == true { currentAssessmentID = nil }
  }
}

/// One app-owned actor per directory. Independent from the existing SwiftData / diary store.
/// Snapshot + anchored cursors publish atomically. A monotonic deletion journal takes priority over backups.
public actor InsightsStore {
  private struct Envelope: Codable { var schemaVersion: Int; var checksum: String; var payload: Data }
  private struct PrivacyJournal: Codable { var epoch: Int = 0; var deletedIDs: Set<String> = [] }
  private let directory: URL
  private var state: InsightsSnapshot
  private var privacy: PrivacyJournal
  private var nextFault: InsightsStoreFault = .none

  public init(directory: URL) throws {
    self.directory = directory
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
    let primary = directory.appendingPathComponent("insights-v1.json")
    let backup = directory.appendingPathComponent("insights-v1.previous.json")
    let journal = directory.appendingPathComponent("deletions-v1.json")
    let hasData = FileManager.default.fileExists(atPath: primary.path) || FileManager.default.fileExists(atPath: backup.path)
    if FileManager.default.fileExists(atPath: journal.path) {
      privacy = try Self.read(PrivacyJournal.self, at: journal)
    } else {
      guard !hasData else { throw InsightsStoreError.corrupt }
      privacy = PrivacyJournal(); try Self.write(privacy, to: journal)
    }
    if hasData {
      do { state = try Self.read(InsightsSnapshot.self, at: primary) }
      catch InsightsStoreError.unsupportedSchema { throw InsightsStoreError.unsupportedSchema }
      catch {
        state = try Self.read(InsightsSnapshot.self, at: backup)
        state.requiresResync = true
        state.ledger.cursors = [:]
        state.currentAssessmentID = nil
      }
    } else { state = InsightsSnapshot() }
    // clear() journals a newer epoch before publishing an empty snapshot.
    if privacy.epoch > state.generation { state = InsightsSnapshot(); state.generation = privacy.epoch; state.requiresResync = true }
    state.redact(privacy.deletedIDs)
    let needsDeletionCleanup = !privacy.deletedIDs.isEmpty
    if hasData && needsDeletionCleanup {
      // Complete interrupted deletion cleanup on disk as well as in memory.
      try Self.write(state, to: backup)
      try Self.write(state, to: primary)
    }
  }

  public func snapshot() -> InsightsSnapshot { state }
  public func injectNextFault(_ fault: InsightsStoreFault) { nextFault = fault }

  @discardableResult
  public func commit(_ candidate: InsightsSnapshot, expectedGeneration: Int) throws -> InsightsSnapshot {
    guard state.generation == expectedGeneration else { throw InsightsStoreError.staleTransaction }
    guard candidate.generation == expectedGeneration else { throw InsightsStoreError.invalidTransaction }
    let fault = nextFault; nextFault = .none
    if fault == .beforePublish { throw InsightsStoreError.injectedFailure }
    var next = candidate
    // Commit the privacy barrier first. On interruption we may lose data, never resurrect it.
    privacy.deletedIDs.formUnion(candidate.ledger.tombstones)
    try Self.write(privacy, to: directory.appendingPathComponent("deletions-v1.json"))
    state.redact(privacy.deletedIDs)
    if fault == .afterPrivacy { throw InsightsStoreError.injectedFailure }
    next.redact(privacy.deletedIDs)
    next.generation = expectedGeneration + 1
    try Self.write(state, to: directory.appendingPathComponent("insights-v1.previous.json"))
    do { try Self.write(next, to: directory.appendingPathComponent("insights-v1.json")) }
    catch {
      // Atomic replacement may have succeeded before an attribute write failed.
      if let disk = try? Self.read(InsightsSnapshot.self, at: directory.appendingPathComponent("insights-v1.json")),
        disk.generation == next.generation { state = disk; state.redact(privacy.deletedIDs) }
      throw error
    }
    state = next
    if fault == .afterPublish { throw InsightsStoreError.injectedFailure }
    return state
  }

  public func selectSource(_ sourceKey: String, for metric: ReadinessMetric, now: Date, calendar: Calendar) throws {
    var next = state
    next.sources[metric.rawValue] = StableSourceSelector.select(metric: metric, samples: next.ledger.normalizedSamples,
      existing: next.sources[metric.rawValue], requested: sourceKey, calendar: calendar, now: now)
    next.currentAssessmentID = nil
    try commit(next, expectedGeneration: state.generation)
  }

  public func selectSleep(_ episodeID: String) throws {
    guard state.episodes.contains(where: { $0.id == episodeID }) else { throw InsightsStoreError.invalidTransaction }
    var next = state; next.manualSleepID = episodeID; next.currentAssessmentID = nil
    try commit(next, expectedGeneration: state.generation)
  }

  public func deleteSamples(_ ids: Set<UUID>) throws {
    var next = state; next.ledger.tombstones.formUnion(ids.map(\.uuidString))
    try commit(next, expectedGeneration: state.generation)
  }

  public func removeSource(_ key: String) throws {
    var next = state
    next.ledger.tombstones.formUnion(next.ledger.samples.values.filter { $0.sourceKey == key }.map { $0.id.uuidString })
    // Keep the explicit selection: disappearance is missing data, never automatic fallback.
    try commit(next, expectedGeneration: state.generation)
  }

  public func clear() throws {
    privacy.epoch = state.generation + 1
    privacy.deletedIDs.formUnion(state.ledger.samples.keys)
    try Self.write(privacy, to: directory.appendingPathComponent("deletions-v1.json"))
    var empty = InsightsSnapshot(); empty.generation = privacy.epoch
    empty.ledger.tombstones = privacy.deletedIDs
    state = empty
    try Self.write(empty, to: directory.appendingPathComponent("insights-v1.previous.json"))
    try Self.write(empty, to: directory.appendingPathComponent("insights-v1.json"))
    state = empty
  }

  private static func read<T: Decodable>(_ type: T.Type, at url: URL) throws -> T {
    let envelope: Envelope
    do { envelope = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: url)) }
    catch { throw InsightsStoreError.corrupt }
    guard envelope.schemaVersion == 1 else { throw InsightsStoreError.unsupportedSchema }
    guard StableDigest.data(envelope.payload) == envelope.checksum else { throw InsightsStoreError.corrupt }
    let decoder = JSONDecoder()
    decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
    do { return try decoder.decode(type, from: envelope.payload) }
    catch { throw InsightsStoreError.corrupt }
  }
  private static func write<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
    encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
    let payload = try encoder.encode(value)
    let data = try encoder.encode(Envelope(schemaVersion: 1, checksum: StableDigest.data(payload), payload: payload))
    #if os(iOS) || os(watchOS)
    try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    #else
    try data.write(to: url, options: .atomic)
    #endif
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    var resource = url; var values = URLResourceValues(); values.isExcludedFromBackup = true
    try resource.setResourceValues(values)
  }
}
