import Foundation
import InnerBalanceCore

struct FangcunDiaryArchive: Codable {
  var entries: [FangcunDrinkEntry] = []
  var snapshots: [FangcunDaySnapshot] = []
  var syncRevisions: [String: Int] = [:]
  var commands: [String: DrinkCommitReceipt] = [:]
  var localRevisions: [String: Int] = [:]
  var migrationDigests: [String: String] = [:]
  enum CodingKeys: String, CodingKey { case entries, snapshots, migrationDigests, syncRevisions, commands, localRevisions }
  init() {}
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    entries = try c.decode([FangcunDrinkEntry].self, forKey: .entries)
    snapshots = try c.decode([FangcunDaySnapshot].self, forKey: .snapshots)
    commands = try c.decodeIfPresent([String: DrinkCommitReceipt].self, forKey: .commands) ?? [:]
    localRevisions = try c.decodeIfPresent([String: Int].self, forKey: .localRevisions) ?? [:]
    syncRevisions = try c.decodeIfPresent([String: Int].self, forKey: .syncRevisions) ?? [:]
    migrationDigests = try c.decodeIfPresent([String: String].self, forKey: .migrationDigests) ?? [:]
  }
}

/// One MainActor owner. Backup verification precedes decoding and target publication.
/// A failed target write leaves both the in-memory state and the legacy bytes unchanged.
@MainActor final class FangcunDiaryStorage {
  enum Fault { case none, afterBackup, beforePublish, afterPublish }
  enum Failure: Error { case corrupt, schema, injected, backupMismatch }
  private struct Envelope: Codable { var schemaVersion = 2; var digest: String; var payload: Data }
  let directory: URL
  var nextFault = Fault.none
  init(directory: URL) throws {
    self.directory = directory
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
  }
  static func directory(defaults: UserDefaults) throws -> URL {
    let key = "fangcun.native.diary.namespace"
    let id = defaults.string(forKey: key) ?? UUID().uuidString
    if defaults.string(forKey: key) == nil { defaults.set(id, forKey: key) }
    return try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true).appendingPathComponent("FangcunDiary/\(id)", isDirectory: true)
  }
  func load(defaults: UserDefaults) throws -> FangcunDiaryArchive {
    let target = directory.appendingPathComponent("diary-v2.json")
    if FileManager.default.fileExists(atPath: target.path) { return try read(target) }
    var result = FangcunDiaryArchive()
    let sources = ["fangcun.native.diary.v1", "fangcun.native.diary.preM1"]
    // Save all input bytes even when the first input cannot decode.
    for key in sources {
      guard let data = defaults.data(forKey: key) else { continue }
      let url = directory.appendingPathComponent(key + ".backup")
      if FileManager.default.fileExists(atPath: url.path) {
        guard try Data(contentsOf: url) == data else { throw Failure.backupMismatch }
      } else { try protectedWrite(data, to: url) }
      guard try StableDigest.data(Data(contentsOf: url)) == StableDigest.data(data) else { throw Failure.backupMismatch }
    }
    if nextFault == .afterBackup { nextFault = .none; throw Failure.injected }
    for key in sources {
      guard let data = defaults.data(forKey: key) else { continue }
      let legacy = try JSONDecoder().decode(FangcunDiaryArchive.self, from: data)
      // The current v1 list is authoritative; preM1 must not resurrect subsequently removed drinks.
      for entry in legacy.entries where key == "fangcun.native.diary.v1" && !result.entries.contains(where: { $0.id == entry.id }) {
        result.entries.append(entry.migrated())
      }
      for var snapshot in legacy.snapshots {
        snapshot.migrationOrigin = "legacyDailySnapshot"
        let identity = try StableDigest.encoded(snapshot)
        if try !result.snapshots.contains(where: { try StableDigest.encoded($0) == identity }) {
          result.snapshots.append(snapshot)
        }
      }
      result.migrationDigests[key] = StableDigest.data(data)
    }
    let interruptedAfterPublish = nextFault == .afterPublish
    if interruptedAfterPublish { nextFault = .none }
    try save(result) // Marker and imported records share one atomic target commit.
    if interruptedAfterPublish { throw Failure.injected }
    if defaults.data(forKey: "fangcun.native.diary.preM1") == nil,
      let original = defaults.data(forKey: "fangcun.native.diary.v1") {
      defaults.set(original, forKey: "fangcun.native.diary.preM1")
    }
    return result
  }
  func save(_ archive: FangcunDiaryArchive) throws {
    let payload = try JSONEncoder().encode(archive)
    let data = try JSONEncoder().encode(Envelope(digest: StableDigest.data(payload), payload: payload))
    if nextFault == .beforePublish { nextFault = .none; throw Failure.injected }
    try protectedWrite(data, to: directory.appendingPathComponent("diary-v2.json"))

  }
  private func read(_ url: URL) throws -> FangcunDiaryArchive {
    let envelope = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: url))
    guard envelope.schemaVersion == 2 else { throw Failure.schema }
    guard StableDigest.data(envelope.payload) == envelope.digest else { throw Failure.corrupt }
    return try JSONDecoder().decode(FangcunDiaryArchive.self, from: envelope.payload)
  }
  private func protectedWrite(_ data: Data, to url: URL) throws {
    try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }
}
