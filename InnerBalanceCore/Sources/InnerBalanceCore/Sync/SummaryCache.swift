import Foundation

public struct SummaryCache: Sendable {
  public enum State: Equatable { case unavailable, neutral, current(ReadinessSummaryDTO) }
  public let file: URL?
  public init(directory: URL?) { file = directory?.appendingPathComponent("readiness-summary-v1.json") }
  public func write(_ summary: ReadinessSummaryDTO) throws {
    guard let file else { return }
    try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    let data = try JSONEncoder().encode(summary)
    guard data.count < 4096 else { throw SyncStore.Failure.invalid }
    try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }
  public func read(now: Date, peer: String?) -> State {
    guard let file else { return .unavailable }
    guard let data = try? Data(contentsOf: file), data.count < 4096,
      let value = try? JSONDecoder().decode(ReadinessSummaryDTO.self, from: data), value.usable(now: now, peer: peer) else { return .neutral }
    return .current(value)
  }
  public func revoke() throws { if let file, FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) } }
}
