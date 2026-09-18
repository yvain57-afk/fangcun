import Foundation

/// Foreign SDK blocks have no Sendable annotation. This adapter owns only that completion block;
/// the lock protects take-and-clear, and the block is invoked once, after releasing the lock.
/// No application state or HealthKit query object crosses isolation through this adapter.
nonisolated final class ReadinessObserverCompletion: @unchecked Sendable {
  private let lock = NSLock()
  private var action: (() -> Void)?
  init(_ action: @escaping () -> Void) { self.action = action }
  func call() {
    lock.lock()
    let callback = action
    action = nil
    lock.unlock()
    callback?()
  }
}
