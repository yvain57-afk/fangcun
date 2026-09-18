import Foundation
import Testing

@testable import InnerBalanceCore

@Suite("Watch practice completion recovery")
struct WatchPracticeCompletionTests {
  @Test("A delayed retry reuses the first frozen completion window")
  func retryReusesFirstSnapshot() throws {
    let firstEnd = Date(timeIntervalSince1970: 1_786_320_060)
    var freezer = WatchPracticeCompletionFreezer()

    let first = freezer.freeze(
      sessionID: "watch-session",
      endedAt: firstEnd,
      activeDuration: 60,
      heartRateEvidenceRequested: true
    )
    let retry = freezer.freeze(
      sessionID: "watch-session",
      endedAt: firstEnd.addingTimeInterval(90),
      activeDuration: 150,
      heartRateEvidenceRequested: true
    )

    #expect(retry == first)
    #expect(retry.endedAt == firstEnd)
    #expect(retry.activeDuration == 60)

    let evidence = HeartRateEvidence(
      startBeatsPerMinute: 72,
      endBeatsPerMinute: 64,
      sampleCount: 8
    )
    let completedValue = freezer.completeHeartRateEvidenceCapture(evidence)
    let completed = try #require(completedValue)
    let retryAfterCapture = freezer.freeze(
      sessionID: "watch-session",
      endedAt: firstEnd.addingTimeInterval(180),
      activeDuration: 240,
      heartRateEvidenceRequested: true
    )

    #expect(completed.heartRateEvidenceCaptureCompleted)
    #expect(completed.heartRateEvidence == evidence)
    #expect(retryAfterCapture == completed)
  }

  @Test("Old payloads infer an evidence request only when evidence exists")
  func oldEvidencePayloadRemainsEligible() {
    let evidence = HeartRateEvidence(
      startBeatsPerMinute: 72,
      endBeatsPerMinute: 64,
      sampleCount: 8
    )

    #expect(
      HeartRateEvidenceRequestCompatibility.resolved(
        explicitRequest: nil,
        evidence: evidence
      )
    )
    #expect(
      HeartRateEvidenceRequestCompatibility.resolved(
        explicitRequest: nil,
        evidence: nil
      ) == false
    )
    #expect(
      HeartRateEvidenceRequestCompatibility.resolved(
        explicitRequest: false,
        evidence: evidence
      ) == false
    )
  }

  @Test("A legacy mindful payload decodes without the request field")
  func legacyMindfulPayloadDecodes() throws {
    let evidence = HeartRateEvidence(
      startBeatsPerMinute: 72,
      endBeatsPerMinute: 64,
      sampleCount: 8
    )
    let current = WatchMindfulPayload(
      syncIdentifier: "legacy.mindful",
      sessionID: "legacy-session",
      practiceKind: .pacedBreathing,
      startDate: Date(timeIntervalSince1970: 1_786_320_000),
      endDate: Date(timeIntervalSince1970: 1_786_320_300),
      heartRateEvidenceRequested: true,
      heartRateEvidence: evidence
    )
    let encoded = try JSONEncoder().encode(current)
    var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    object.removeValue(forKey: "heartRateEvidenceRequested")
    let legacyData = try JSONSerialization.data(withJSONObject: object)

    let decoded = try JSONDecoder().decode(WatchMindfulPayload.self, from: legacyData)

    #expect(decoded.heartRateEvidenceRequested == nil)
    #expect(decoded.heartRateEvidence == evidence)
    #expect(
      HeartRateEvidenceRequestCompatibility.resolved(
        explicitRequest: decoded.heartRateEvidenceRequested,
        evidence: decoded.heartRateEvidence
      )
    )
  }
}
