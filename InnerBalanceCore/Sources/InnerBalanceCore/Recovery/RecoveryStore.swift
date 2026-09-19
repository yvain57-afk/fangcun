import Foundation

/// Local action/feedback facts only. This store has no HealthKit dependency or readiness write path.
public actor RecoveryStore {
  public enum Failure: Error { case corrupt, schema, injected, invalid }
  private struct Archive: Codable { var schema = 1; var sessions: [String: RecoverySession] = [:] }
  private struct Envelope: Codable { var digest: String; var payload: Data }
  private let file: URL
  private var archive: Archive
  private var failNext = false
  public init(directory: URL) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    file = directory.appendingPathComponent("recovery-v1.json")
    if FileManager.default.fileExists(atPath: file.path) {
      let e = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: file))
      guard StableDigest.data(e.payload) == e.digest else { throw Failure.corrupt }
      archive = try JSONDecoder().decode(Archive.self, from: e.payload)
      guard archive.schema == 1 else { throw Failure.schema }
    } else { archive = Archive() }
  }
  public func injectWriteFailure() { failNext = true }
  public func records() -> [RecoverySession] { archive.sessions.values.sorted { $0.startedAt > $1.startedAt } }
  public func save(_ record: RecoverySession) throws {
    guard record.activeDuration >= 0, record.activeDuration <= record.plannedDuration else { throw Failure.invalid }
    if let old = archive.sessions[record.sessionID], old.revision >= record.revision { return }
    var next = archive; next.sessions[record.sessionID] = record
    try publish(next)
  }
  public func feedback(sessionID: String, helpfulness: RecoveryHelpfulness?, now: Date, note: String? = nil) throws {
    guard var record = archive.sessions[sessionID], record.endedAt != nil else { throw Failure.invalid }
    if let old = record.feedback { record.feedbackHistory.append(old) }
    record.feedback = .init(helpfulness: helpfulness, revision: (record.feedback?.revision ?? 0) + 1, updatedAt: now, localNote: note)
    record.revision += 1
    var next = archive; next.sessions[sessionID] = record; try publish(next)
  }
  public func recoverInterrupted(now: Date) throws {
    var next = archive
    for (key, var value) in next.sessions where value.endedAt == nil {
      value.endedAt = now; value.endReason = .interrupted; value.revision += 1
      next.sessions[key] = value
    }
    try publish(next)
  }
  private func publish(_ next: Archive) throws {
    if failNext { failNext = false; throw Failure.injected }
    let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
    let payload = try encoder.encode(next)
    try encoder.encode(Envelope(digest: StableDigest.data(payload), payload: payload))
      .write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    archive = next
  }
}
