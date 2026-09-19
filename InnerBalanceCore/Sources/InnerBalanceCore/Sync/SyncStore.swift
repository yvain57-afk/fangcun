import Foundation

public struct SyncQueueItem: Codable, Sendable {
  public var event: SyncEvent
  public var attempts = 0
  public var retryAfter = Date.distantPast
}
public struct SyncArchive: Codable, Sendable {
  public var schemaVersion = 1
  public var installationID = UUID().uuidString
  public var peerInstallationID: String?
  public var retiredPeers: Set<String> = []
  public var entities: [String: SyncEvent] = [:]
  public var received: [String: SyncAcknowledgement] = [:]
  public var outbox: [String: SyncQueueItem] = [:]
  public var quarantined: [String: Data] = [:]
  public var summary: ReadinessSummaryDTO?
  public var summarySequence = 0
}
/// Business payload + deduplication + receipt are one atomic transaction. Never writes HealthKit.
public actor SyncStore {
  public enum Failure: Error { case schema, corrupt, injected, peer, invalid, unknownProtocol }
  private struct Envelope: Codable { var digest: String; var payload: Data }
  private var state: SyncArchive
  private let file: URL
  private var failNext = false
  public init(directory: URL) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    file = directory.appendingPathComponent("sync-v1.json")
    if FileManager.default.fileExists(atPath: file.path) {
      let e = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: file))
      guard StableDigest.data(e.payload) == e.digest else { throw Failure.corrupt }
      state = try JSONDecoder().decode(SyncArchive.self, from: e.payload)
      guard state.schemaVersion == 1 else { throw Failure.schema }
    } else {
      state = SyncArchive()
      try Self.write(state, file: file)
    }
  }
  public func snapshot() -> SyncArchive { state }
  public func injectWriteFailure() { failNext = true }
  public func acceptPeer(_ id: String) throws {
    guard !state.retiredPeers.contains(id), id != state.installationID else { throw Failure.peer }
    guard id != state.peerInstallationID else { return }
    var next = state
    if let previous = next.peerInstallationID { next.retiredPeers.insert(previous) }
    next.peerInstallationID = id
    if next.summary?.originInstallationID != next.installationID { next.summary = nil }
    try publish(next)
  }
  @discardableResult public func enqueue(kind: SyncEntityKind, id: String, payload: Data, deleted: Bool = false) throws -> SyncEvent? {
    let key = kind.rawValue + ":" + id
    let old = state.entities[key]
    if old?.payload == payload && old?.deleted == deleted { return nil }
    let event = SyncEvent(entityID: id, kind: kind, revision: (old?.revision ?? 0)+1,
      originInstallationID: state.installationID, deleted: deleted, explicitRestore: old?.deleted == true && !deleted, payload: payload)
    try validate(event)
    var next = state; next.entities[key] = event; next.outbox[event.eventID] = .init(event: event)
    try publish(next); return event
  }
  public func receive(_ event: SyncEvent) throws -> SyncAcknowledgement {
    guard event.originInstallationID == state.peerInstallationID else { throw Failure.peer }
    try validate(event)
    let ack = try SyncAcknowledgement(event: event)
    if let old = state.received[event.eventID] {
      guard old == ack else { throw Failure.invalid }
      return old
    }
    var next = state
    let previous = next.entities[event.entityKey]
    let shouldApply: Bool
    if let previous {
      shouldApply = (event.revision > previous.revision || (event.revision == previous.revision && event.deleted && !previous.deleted))
        && (!previous.deleted || event.deleted || event.explicitRestore)
    } else { shouldApply = true }
    if shouldApply { next.entities[event.entityKey] = event }
    next.received[event.eventID] = ack
    try publish(next) // Only a durable commit can produce an ACK.
    return ack
  }
  public func acknowledge(_ ack: SyncAcknowledgement) throws {
    guard ack.originInstallationID == state.installationID,
      let queued = state.outbox[ack.eventID], try SyncAcknowledgement(event: queued.event) == ack else { return }
    var next = state; next.outbox[ack.eventID] = nil; try publish(next)
  }
  public func pending(now: Date, manual: Bool = false) -> [SyncEvent] {
    state.outbox.values.filter { manual || ($0.attempts < 8 && $0.retryAfter <= now) }
      .sorted { $0.event.eventID < $1.event.eventID }.prefix(20).map(\.event)
  }
  public func attempted(_ id: String, now: Date) throws {
    guard var item = state.outbox[id] else { return }
    item.attempts += 1; item.retryAfter = now.addingTimeInterval(min(3600, pow(2, Double(item.attempts))))
    var next = state; next.outbox[id] = item; try publish(next)
  }
  public func quarantine(_ data: Data) throws {
    var next = state; next.quarantined[StableDigest.data(data)] = data; try publish(next)
  }
  public func makeSummary(_ assessment: ReadinessAssessment?, now: Date) throws -> ReadinessSummaryDTO {
    var next = state; next.summarySequence += 1
    let summary = ReadinessSummaryDTO(assessment: assessment, installationID: state.installationID, sequence: next.summarySequence, now: now)
    next.summary = summary; try publish(next); return summary
  }
  public func receiveSummary(_ value: ReadinessSummaryDTO) throws {
    guard value.schemaVersion == 1, value.originInstallationID == state.peerInstallationID else { throw Failure.peer }
    if let old = state.summary, old.originInstallationID == value.originInstallationID, old.sequence >= value.sequence { return }
    var next = state; next.summary = value; try publish(next)
  }
  private func validate(_ event: SyncEvent) throws {
    guard event.schemaVersion == 1, event.revision > 0, !event.entityID.isEmpty else { throw Failure.unknownProtocol }
    if event.deleted { return }
    switch event.kind {
    case .session:
      let value = try JSONDecoder().decode(RecoverySession.self, from: event.payload)
      guard value.protocolVersion == 1 else { throw Failure.unknownProtocol }
      guard value.sessionID == event.entityID, value.activeDuration.isFinite, value.activeDuration >= 0 else { throw Failure.invalid }
    case .drink:
      let value = try JSONDecoder().decode(SyncedDrink.self, from: event.payload)
      guard value.id == event.entityID, value.volumeML >= 0, value.caffeineMG.map({ $0 >= 0 }) ?? (value.beverageDetails != nil), [1, 2].contains(value.estimateVersion),
        ["water", "coffee", "sweetCoffee", "beer", "soda", "tea", "milk", "alcohol", "other"].contains(value.kind),
        value.sugarServings.isFinite, value.sugarServings >= 0,
        value.alcoholGrams.map({ $0.isFinite && $0 >= 0 }) ?? true,
        value.sugarGrams.map({ $0.isFinite && $0 >= 0 }) ?? true else { throw Failure.invalid }
    }
  }
  private func publish(_ next: SyncArchive) throws {
    if failNext { failNext = false; throw Failure.injected }
    try Self.write(next, file: file); state = next
  }
  private static func write(_ value: SyncArchive, file: URL) throws {
    let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
    let payload = try encoder.encode(value)
    try encoder.encode(Envelope(digest: StableDigest.data(payload), payload: payload))
      .write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }
}
