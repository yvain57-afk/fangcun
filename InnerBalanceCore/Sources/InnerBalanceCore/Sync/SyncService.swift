import Foundation

@MainActor public protocol SyncTransport: AnyObject {
  var onReceive: (@MainActor @Sendable (Data) async -> Data?)? { get set }
  var onOpportunity: (@MainActor @Sendable () async -> Void)? { get set }
  func activate()
  func deliver(_ data: Data) async throws -> Data?
  func updateContext(_ data: Data) throws
}
@MainActor public final class SyncService {
  public let store: SyncStore
  public let role: String
  public let localCache: SummaryCache
  public let sharedCache: SummaryCache
  public private(set) var lastError: String?
  public var currentAssessment: (@MainActor () -> ReadinessAssessment?)?
  public var onRecordsChanged: (@MainActor (SyncArchive) async throws -> Void)?
  private let transport: any SyncTransport
  private var flushing = false
  private var summaryIntent = 0
  public init(store: SyncStore, transport: any SyncTransport, role: String, localDirectory: URL, sharedDirectory: URL? = nil) {
    self.store = store; self.transport = transport; self.role = role
    localCache = .init(directory: localDirectory); sharedCache = .init(directory: sharedDirectory)
    transport.onReceive = { [weak self] data in await self?.receive(data) }
    transport.onOpportunity = { [weak self] in await self?.handshake(); await self?.flush(); await self?.sendStoredSummary() }
  }
  public func activate() { transport.activate() }
  public func reconcile() async {
    do { try await onRecordsChanged?(await store.snapshot()) } catch { lastError = "projection" }
  }
  public func enqueue(_ record: RecoverySession) async throws {
    guard record.endedAt != nil, record.originDevice != "HealthKit" else { return }
    var value = record
    value.feedback?.localNote = nil
    for index in value.feedbackHistory.indices { value.feedbackHistory[index].localNote = nil }
    let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
    try await store.enqueue(kind: .session, id: value.sessionID, payload: encoder.encode(value))
  }
  public func enqueue(_ drink: SyncedDrink) async throws {
    let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
    try await store.enqueue(kind: .drink, id: drink.id, payload: encoder.encode(drink))
  }
  public func delete(kind: SyncEntityKind, id: String) async throws {
    try await store.enqueue(kind: kind, id: id, payload: Data(), deleted: true)
  }
  public func handshake() async {
    let state = await store.snapshot()
    let packet = SyncPacket(origin: state.installationID, role: role, hello: true)
    do {
      if let response = try await transport.deliver(JSONEncoder().encode(packet)), !response.isEmpty { _ = await receive(response) }
    } catch { lastError = "disconnected" }
  }
  public func flush(manual: Bool = false, now: Date = .now) async {
    guard !flushing else { return }; flushing = true; defer { flushing = false }
    let state = await store.snapshot()
    for event in await store.pending(now: now, manual: manual) {
      do {
        try await store.attempted(event.eventID, now: now)
        let packet = SyncPacket(origin: state.installationID, role: role, event: event)
        if let response = try await transport.deliver(JSONEncoder().encode(packet)), !response.isEmpty { _ = await receive(response) }
      } catch { lastError = "disconnected" }
    }
  }
  public func publish(_ assessment: ReadinessAssessment?, now: Date = .now) async {
    guard role == "phone" else { return }
    summaryIntent += 1; let intent = summaryIntent
    do {
      if assessment == nil { try localCache.revoke(); try sharedCache.revoke() }
      let summary = try await store.makeSummary(assessment, now: now)
      guard intent == summaryIntent else { return }
      try localCache.write(summary); try sharedCache.write(summary)
      try transport.updateContext(JSONEncoder().encode(SyncPacket(origin: summary.originInstallationID, role: role, summary: summary, hello: true)))
    } catch {
      lastError = "summary_unavailable"
      // Revocation is privacy-critical even if protected storage cannot accept a new sequence.
      if assessment == nil, intent == summaryIntent {
        let state = await store.snapshot()
        let revoked = ReadinessSummaryDTO(assessment: nil, installationID: state.installationID,
          sequence: state.summarySequence + 1, now: now)
        if let data = try? JSONEncoder().encode(SyncPacket(origin: state.installationID, role: role, summary: revoked, hello: true)) {
          try? transport.updateContext(data)
        }
      }
    }
  }
  private func sendStoredSummary() async {
    guard role == "phone" else { return }
    if let currentAssessment { await publish(currentAssessment()); return }
    guard let summary = await store.snapshot().summary else { return }
    do { try transport.updateContext(JSONEncoder().encode(SyncPacket(origin: summary.originInstallationID, role: role, summary: summary, hello: true))) }
    catch { lastError = "disconnected" }
  }
  @discardableResult public func receive(_ data: Data) async -> Data? {
    do {
      let packet = try JSONDecoder().decode(SyncPacket.self, from: data)
      guard packet.schemaVersion == 1, packet.role != role,
        ["phone", "watch"].contains(packet.role) else { throw SyncStore.Failure.unknownProtocol }
      let before = await store.snapshot()
      if packet.hello || before.peerInstallationID == nil {
        try await store.acceptPeer(packet.originInstallationID)
        if role == "watch", before.peerInstallationID != packet.originInstallationID {
          try localCache.revoke(); try sharedCache.revoke()
        }
      }
      guard await store.snapshot().peerInstallationID == packet.originInstallationID else { throw SyncStore.Failure.peer }
      if let event = packet.event {
        guard event.originInstallationID == packet.originInstallationID else { throw SyncStore.Failure.peer }
        let ack = try await store.receive(event)
        try await onRecordsChanged?(await store.snapshot())
        return try JSONEncoder().encode(SyncPacket(origin: (await store.snapshot()).installationID, role: role, acknowledgement: ack))
      }
      if let ack = packet.acknowledgement { try await store.acknowledge(ack) }
      if let summary = packet.summary {
        guard packet.role == "phone", summary.originInstallationID == packet.originInstallationID else { throw SyncStore.Failure.peer }
        try await store.receiveSummary(summary)
        if let accepted = await store.snapshot().summary { try localCache.write(accepted); try sharedCache.write(accepted) }
      }
      lastError = nil
    } catch {
      lastError = String(describing: error)
      try? await store.quarantine(data)
    }
    return nil
  }
}
