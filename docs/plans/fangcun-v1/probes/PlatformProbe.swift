// M0 compile-only probes; not included in the shipping application.
import Foundation
import UserNotifications
import WatchConnectivity
#if os(watchOS)
import WatchKit

final class RuntimeProbe: NSObject, WKExtendedRuntimeSessionDelegate {
  let session = WKExtendedRuntimeSession()
  func prepare() { session.delegate = self }
  // Call only while active, after validating the mindfulness background mode.
  func start() { session.start() }
  func stop() { session.invalidate() }
  func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {}
  func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {}
  func extendedRuntimeSession(_ session: WKExtendedRuntimeSession,
    didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {}
}
#endif

func notificationProbe() -> UNNotificationCategory {
  let action = UNNotificationAction(identifier: "probe.open", title: "Probe", options: .foreground)
  return UNNotificationCategory(identifier: "probe.break", actions: [action], intentIdentifiers: [])
}

func connectivityProbe(_ session: WCSession, payload: [String: Any]) throws {
  guard session.activationState == .activated else { return }
  try session.updateApplicationContext(payload)
  session.transferUserInfo(payload)
  if session.isReachable { session.sendMessage(payload, replyHandler: nil) }
}
