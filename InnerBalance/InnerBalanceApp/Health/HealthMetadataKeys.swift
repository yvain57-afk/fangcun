import HealthKit

enum HealthRecordOrigin: String, Codable, Sendable {
  case iPhone = "iphone"
  case watch
}

enum HealthRecordPhase: String, Codable, Sendable {
  case pre
  case post
  case standalone
}

enum HealthEvidenceMode: String, Codable, Sendable {
  case subjective
  case heartRate = "heart_rate"
}

enum HeartRateEvidenceQuality: String, Codable, Sendable {
  case insufficient
  case sufficient
}

struct HeartRateEvidenceSummary: Equatable, Codable, Sendable {
  let start: Double
  let end: Double
  let sampleCount: Int
  let quality: HeartRateEvidenceQuality
}

enum HealthMetadataKeys {
  static let schemaVersion = "com.yvainair.innerbalance.schemaVersion"
  static let arousal = "com.yvainair.innerbalance.arousal"
  static let bodySensationCodes = "com.yvainair.innerbalance.bodySensationCodes"
  static let associationCodes = "com.yvainair.innerbalance.associationCodes"
  static let unclassified = "com.yvainair.innerbalance.unclassified"
  static let origin = "com.yvainair.innerbalance.origin"
  static let sessionID = "com.yvainair.innerbalance.sessionID"
  static let phase = "com.yvainair.innerbalance.phase"
  static let practiceType = "com.yvainair.innerbalance.practiceType"
  static let protocolVersion = "com.yvainair.innerbalance.protocolVersion"
  static let evidenceMode = "com.yvainair.innerbalance.evidenceMode"
  static let heartRateStart = "com.yvainair.innerbalance.heartRateStart"
  static let heartRateEnd = "com.yvainair.innerbalance.heartRateEnd"
  static let heartRateSampleCount = "com.yvainair.innerbalance.heartRateSampleCount"
  static let heartRateEvidenceRequested =
    "com.yvainair.innerbalance.heartRateEvidenceRequested"
  static let evidenceQuality = "com.yvainair.innerbalance.evidenceQuality"

  static func stateOfMind(
    syncIdentifier: String,
    syncVersion: Int,
    arousal: Double,
    bodySensationCodes: [String],
    associationCodes: [String] = [],
    unclassified: Bool,
    origin: HealthRecordOrigin,
    sessionID: String?,
    phase: HealthRecordPhase
  ) -> [String: Any] {
    var metadata: [String: Any] = [
      HKMetadataKeySyncIdentifier: syncIdentifier,
      HKMetadataKeySyncVersion: syncVersion,
      schemaVersion: 1,
      self.arousal: arousal,
      self.bodySensationCodes: bodySensationCodes.sorted().joined(separator: ","),
      self.associationCodes: associationCodes.joined(separator: ","),
      self.unclassified: unclassified ? 1 : 0,
      self.origin: origin.rawValue,
      self.phase: phase.rawValue,
    ]
    if let sessionID {
      metadata[self.sessionID] = sessionID
    }
    return metadata
  }

  static func mindfulSession(
    syncIdentifier: String,
    syncVersion: Int,
    sessionID: String,
    practiceType: String,
    protocolVersion: Int,
    origin: HealthRecordOrigin,
    evidenceMode: HealthEvidenceMode,
    heartRateEvidence: HeartRateEvidenceSummary?
  ) -> [String: Any] {
    var metadata: [String: Any] = [
      HKMetadataKeySyncIdentifier: syncIdentifier,
      HKMetadataKeySyncVersion: syncVersion,
      schemaVersion: 1,
      self.sessionID: sessionID,
      self.practiceType: practiceType,
      self.protocolVersion: protocolVersion,
      self.origin: origin.rawValue,
      self.evidenceMode: evidenceMode.rawValue,
    ]

    if let evidence = heartRateEvidence,
      evidence.quality == .sufficient,
      evidence.start.isFinite,
      evidence.start > 0,
      evidence.end.isFinite,
      evidence.end > 0,
      evidence.sampleCount > 0
    {
      metadata[heartRateStart] = evidence.start
      metadata[heartRateEnd] = evidence.end
      metadata[heartRateSampleCount] = evidence.sampleCount
      metadata[evidenceQuality] = evidence.quality.rawValue
    }
    return metadata
  }
}
