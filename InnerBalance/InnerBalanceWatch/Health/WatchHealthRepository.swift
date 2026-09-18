import HealthKit
import InnerBalanceCore

struct WatchStateOfMindPayload: Codable, Equatable, Sendable {
  let syncIdentifier: String
  let date: Date
  let valence: Double
  let arousal: Double
  let label: EmotionLabel?
  let unclassified: Bool
}

enum WatchHealthPayload: Codable, Equatable, Sendable {
  case stateOfMind(WatchStateOfMindPayload)
  case mindful(WatchMindfulPayload)
}

@MainActor
final class WatchHealthRepository {
  private let healthStore = HKHealthStore()

  func requestBasicAuthorization() async -> Bool {
    guard HKHealthStore.isHealthDataAvailable() else { return false }
    do {
      try await healthStore.requestAuthorization(
        toShare: [HKObjectType.stateOfMindType(), HKCategoryType(.mindfulSession)],
        read: []
      )
      return true
    } catch {
      return false
    }
  }

  func save(_ payload: WatchHealthPayload) async throws {
    switch payload {
    case .stateOfMind(let record):
      try await saveStateOfMind(record)
    case .mindful(let record):
      try await saveMindful(record)
    }
  }

  func hasWriteAuthorization(for payload: WatchHealthPayload) -> Bool {
    let type: HKObjectType =
      switch payload {
      case .stateOfMind: HKObjectType.stateOfMindType()
      case .mindful: HKCategoryType(.mindfulSession)
      }
    return healthStore.authorizationStatus(for: type) == .sharingAuthorized
  }

  private func saveStateOfMind(_ record: WatchStateOfMindPayload) async throws {
    let metadata: [String: Any] = [
      HKMetadataKeySyncIdentifier: record.syncIdentifier,
      HKMetadataKeySyncVersion: 1,
      "com.yvainair.innerbalance.schemaVersion": 1,
      "com.yvainair.innerbalance.arousal": record.arousal,
      "com.yvainair.innerbalance.bodySensationCodes": "",
      "com.yvainair.innerbalance.associationCodes": "",
      "com.yvainair.innerbalance.unclassified": record.unclassified ? 1 : 0,
      "com.yvainair.innerbalance.origin": "watch",
      "com.yvainair.innerbalance.phase": "standalone",
    ]
    let sample = HKStateOfMind(
      date: record.date,
      kind: .momentaryEmotion,
      valence: record.valence,
      labels: record.label.map { [Self.healthKitLabel($0)] } ?? [],
      associations: [],
      metadata: metadata
    )
    try await healthStore.save(sample)
  }

  private func saveMindful(_ record: WatchMindfulPayload) async throws {
    guard record.practiceKindRawValue != PracticeKind.kegel.rawValue,
      record.endDate > record.startDate
    else { return }
    let heartRateEvidenceRequested = HeartRateEvidenceRequestCompatibility.resolved(
      explicitRequest: record.heartRateEvidenceRequested,
      evidence: record.heartRateEvidence
    )
    var metadata: [String: Any] = [
      HKMetadataKeySyncIdentifier: record.syncIdentifier,
      HKMetadataKeySyncVersion: 1,
      "com.yvainair.innerbalance.schemaVersion": 1,
      "com.yvainair.innerbalance.sessionID": record.sessionID,
      "com.yvainair.innerbalance.practiceType": record.practiceKindRawValue,
      "com.yvainair.innerbalance.protocolVersion": 1,
      "com.yvainair.innerbalance.origin": "watch",
      "com.yvainair.innerbalance.evidenceMode":
        record.heartRateEvidence == nil ? "subjective" : "heart_rate",
      "com.yvainair.innerbalance.heartRateEvidenceRequested":
        heartRateEvidenceRequested ? 1 : 0,
      "com.yvainair.innerbalance.evidenceQuality":
        record.heartRateEvidence == nil ? "insufficient" : "sufficient",
    ]
    if let evidence = record.heartRateEvidence {
      metadata["com.yvainair.innerbalance.heartRateStart"] = evidence.startBeatsPerMinute
      metadata["com.yvainair.innerbalance.heartRateEnd"] = evidence.endBeatsPerMinute
      metadata["com.yvainair.innerbalance.heartRateSampleCount"] = evidence.sampleCount
    }
    let sample = HKCategorySample(
      type: HKCategoryType(.mindfulSession),
      value: HKCategoryValue.notApplicable.rawValue,
      start: record.startDate,
      end: record.endDate,
      metadata: metadata
    )
    try await healthStore.save(sample)
  }

  private static func healthKitLabel(_ label: EmotionLabel) -> HKStateOfMind.Label {
    switch label {
    case .amazed: .amazed
    case .amused: .amused
    case .angry: .angry
    case .anxious: .anxious
    case .ashamed: .ashamed
    case .brave: .brave
    case .calm: .calm
    case .content: .content
    case .disappointed: .disappointed
    case .discouraged: .discouraged
    case .disgusted: .disgusted
    case .embarrassed: .embarrassed
    case .excited: .excited
    case .frustrated: .frustrated
    case .grateful: .grateful
    case .guilty: .guilty
    case .happy: .happy
    case .hopeless: .hopeless
    case .irritated: .irritated
    case .jealous: .jealous
    case .joyful: .joyful
    case .lonely: .lonely
    case .passionate: .passionate
    case .peaceful: .peaceful
    case .proud: .proud
    case .relieved: .relieved
    case .sad: .sad
    case .scared: .scared
    case .stressed: .stressed
    case .surprised: .surprised
    case .worried: .worried
    case .annoyed: .annoyed
    case .confident: .confident
    case .drained: .drained
    case .hopeful: .hopeful
    case .indifferent: .indifferent
    case .overwhelmed: .overwhelmed
    case .satisfied: .satisfied
    }
  }
}
