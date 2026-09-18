import Foundation
import Testing

@testable import InnerBalanceCore

@Suite("Pending write retry policy")
struct PendingRetryPolicyTests {
  @Test("Retry delay backs off and is capped at one day")
  func exponentialBackoff() {
    #expect(PendingRetryPolicy.delay(afterAttempt: 1) == 60)
    #expect(PendingRetryPolicy.delay(afterAttempt: 2) == 120)
    #expect(PendingRetryPolicy.delay(afterAttempt: 20) == 86_400)
  }
}
