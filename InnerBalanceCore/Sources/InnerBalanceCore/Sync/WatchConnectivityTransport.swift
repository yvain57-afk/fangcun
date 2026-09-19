#if canImport(WatchConnectivity)
import Foundation
import WatchConnectivity

/// WC is only a delivery opportunity. `transferUserInfo` completion is never treated as business ACK.
@MainActor public final class WatchConnectivityTransport: NSObject, SyncTransport, WCSessionDelegate {
  public var onReceive: (@MainActor @Sendable (Data) async -> Data?)?
  public var onOpportunity: (@MainActor @Sendable () async -> Void)?
  private let session: WCSession
  public override init() { session = .default; super.init() }
  public func activate() {
    guard WCSession.isSupported() else { return }
    session.delegate = self; session.activate()
  }
  public func deliver(_ data: Data) async throws -> Data? {
    guard session.activationState == .activated else { throw SyncStore.Failure.peer }
    guard session.isReachable else { session.transferUserInfo(["wire": data]); return nil }
    do {
      return try await withCheckedThrowingContinuation { continuation in
        session.sendMessageData(data, replyHandler: { continuation.resume(returning: $0) }, errorHandler: { continuation.resume(throwing: $0) })
      }
    } catch {
      session.transferUserInfo(["wire": data])
      throw error // The persisted outbox remains until the receiver's ACK arrives.
    }
  }
  public func updateContext(_ data: Data) throws {
    guard session.activationState == .activated else { throw SyncStore.Failure.peer }
    try session.updateApplicationContext(["summary": data])
  }
  nonisolated public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    guard activationState == .activated, error == nil else { return }
    Task { @MainActor in await onOpportunity?() }
  }
  nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
    Task { @MainActor in await onOpportunity?() }
  }
  nonisolated public func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
    let reply = SyncReply(replyHandler)
    Task { @MainActor in reply.send(await onReceive?(messageData) ?? Data()) }
  }
  nonisolated public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    guard let data = userInfo["wire"] as? Data else { return }
    Task { @MainActor in
      if let ack = await onReceive?(data) { self.session.transferUserInfo(["wire": ack]) }
    }
  }
  nonisolated public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    guard let data = applicationContext["summary"] as? Data else { return }
    Task { @MainActor in _ = await onReceive?(data) }
  }
  #if os(iOS)
  nonisolated public func sessionDidBecomeInactive(_ session: WCSession) { }
  nonisolated public func sessionDidDeactivate(_ session: WCSession) {
    Task { @MainActor in self.session.activate() }
  }
  #endif
}
private final class SyncReply: @unchecked Sendable {
  private let block: (Data) -> Void
  init(_ block: @escaping (Data) -> Void) { self.block = block }
  // Each delegate call owns one wrapper; it is invoked exactly once by its single Task.
  func send(_ data: Data) { block(data) }
}
#endif
