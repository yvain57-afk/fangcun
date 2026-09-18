import HealthKit
import Testing

@testable import InnerBalance

@Suite("Health metadata")
struct HealthMetadataTests {
  @Test("State of Mind metadata carries stable sync identity and typed fields")
  func stateOfMindMetadataIsStableAndTyped() {
    let metadata = HealthMetadataKeys.stateOfMind(
      syncIdentifier: "check-in-123",
      syncVersion: 2,
      arousal: 0.75,
      bodySensationCodes: ["shoulder_tension", "shallow_breath"],
      unclassified: true,
      origin: .iPhone,
      sessionID: "practice-456",
      phase: .post
    )

    #expect(metadata[HKMetadataKeySyncIdentifier] as? String == "check-in-123")
    #expect(metadata[HKMetadataKeySyncVersion] as? Int == 2)
    #expect(metadata[HealthMetadataKeys.schemaVersion] as? Int == 1)
    #expect(metadata[HealthMetadataKeys.arousal] as? Double == 0.75)
    #expect(
      metadata[HealthMetadataKeys.bodySensationCodes] as? String
        == "shallow_breath,shoulder_tension")
    #expect(metadata[HealthMetadataKeys.unclassified] as? Int == 1)
    #expect(metadata[HealthMetadataKeys.origin] as? String == "iphone")
    #expect(metadata[HealthMetadataKeys.sessionID] as? String == "practice-456")
    #expect(metadata[HealthMetadataKeys.phase] as? String == "post")
  }

  @Test("压力来源保留用户选择的主次顺序")
  func associationOrderIsPreserved() {
    let metadata = HealthMetadataKeys.stateOfMind(
      syncIdentifier: "check-in-sources",
      syncVersion: 2,
      arousal: 0.6,
      bodySensationCodes: [],
      associationCodes: ["work", "sleep"],
      unclassified: false,
      origin: .iPhone,
      sessionID: nil,
      phase: .standalone
    )

    #expect(metadata[HealthMetadataKeys.associationCodes] as? String == "work,sleep")
  }

  @Test("Mindful Session metadata stores only an eligible heart-rate summary")
  func mindfulSessionMetadataStoresEligibleSummary() {
    let metadata = HealthMetadataKeys.mindfulSession(
      syncIdentifier: "mindful-123",
      syncVersion: 1,
      sessionID: "session-123",
      practiceType: "meditation",
      protocolVersion: 2,
      origin: .watch,
      evidenceMode: .heartRate,
      heartRateEvidence: HeartRateEvidenceSummary(
        start: 78,
        end: 69,
        sampleCount: 24,
        quality: .sufficient
      )
    )

    #expect(metadata[HKMetadataKeySyncIdentifier] as? String == "mindful-123")
    #expect(metadata[HealthMetadataKeys.practiceType] as? String == "meditation")
    #expect(metadata[HealthMetadataKeys.protocolVersion] as? Int == 2)
    #expect(metadata[HealthMetadataKeys.evidenceMode] as? String == "heart_rate")
    #expect(metadata[HealthMetadataKeys.heartRateStart] as? Double == 78)
    #expect(metadata[HealthMetadataKeys.heartRateEnd] as? Double == 69)
    #expect(metadata[HealthMetadataKeys.heartRateSampleCount] as? Int == 24)
    #expect(metadata[HealthMetadataKeys.evidenceQuality] as? String == "sufficient")
  }
}
