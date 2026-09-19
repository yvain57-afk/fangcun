import Foundation

/// Cross-device contract. Deliberately excludes sample identifiers, readings, source details and notes.
public struct DailyStatusSummaryDTO: Codable, Equatable, Sendable {
  public var schemaVersion = 3
  public var originInstallationID: String
  public var sequence: Int
  public var scoreID: String?
  public var revision: Int?
  public var score: Int?
  public var band: StatusBand?
  public var modelVersion: String?
  public var basisProfile: String?
  public var asOf: Date?
  public var currentUntil: Date?
  public var validUntil: Date?
  public var issuedAt: Date
  public var revoked: Bool
  public init(snapshot: DailyStatusSnapshot?, installationID: String, sequence: Int, now: Date) {
    let value = snapshot.flatMap { $0.isValid && now < $0.validUntil ? $0 : nil }
    originInstallationID = installationID; self.sequence = sequence; issuedAt = now; revoked = value == nil
    scoreID = value?.scoreID; revision = value?.revision; score = value?.displayScore; band = value?.band
    modelVersion = value?.modelVersion; basisProfile = value?.scoreBasisProfile
    asOf = value?.asOf; currentUntil = value?.currentUntil; validUntil = value?.validUntil
  }
  public var isValid: Bool {
    guard schemaVersion == 3, sequence > 0, !originInstallationID.isEmpty else { return false }
    if revoked { return score == nil && band == nil && scoreID == nil && revision == nil && modelVersion == nil && basisProfile == nil && asOf == nil && currentUntil == nil && validUntil == nil }
    guard let score, let band, let asOf, let currentUntil, let validUntil,
      let revision, revision > 0, let scoreID, !scoreID.isEmpty, let basisProfile, !basisProfile.isEmpty else { return false }
    return StatusBand.resolve(score) == band && modelVersion == "fangcun-status-3.0"
      && currentUntil > asOf && validUntil > currentUntil
      && Set(basisProfile.components(separatedBy: "+")).isSubset(of: ["sleep","hrv","rhr"])
  }
  public func usable(now: Date, peer: String?) -> Bool {
    isValid && !revoked && originInstallationID == peer && validUntil.map { now < $0 } == true && now >= issuedAt.addingTimeInterval(-300)
  }
}
public struct StatusSummaryCache: Sendable {
  public let file: URL?
  public init(directory: URL?) { file = directory?.appendingPathComponent("status-summary-v3.json") }
  public func write(_ value: DailyStatusSummaryDTO) throws {
    guard value.isValid else { throw SyncStore.Failure.invalid }
    guard let file else { return }
    try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    let data = try JSONEncoder().encode(value)
    guard data.count < 4096 else { throw SyncStore.Failure.invalid }
    try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }
  public func read(now: Date, peer: String?) -> DailyStatusSummaryDTO? {
    guard let file, let data = try? Data(contentsOf: file), data.count < 4096,
      let value = try? JSONDecoder().decode(DailyStatusSummaryDTO.self, from: data), value.usable(now: now, peer: peer) else { return nil }
    return value
  }
  public func revoke() throws { if let file, FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) } }
}
