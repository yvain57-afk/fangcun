import Foundation

public enum PendingRetryPolicy {
  public static func delay(afterAttempt attempt: Int) -> TimeInterval {
    let exponent = max(0, min(attempt - 1, 20))
    return min(pow(2, Double(exponent)) * 60, 86_400)
  }
}
