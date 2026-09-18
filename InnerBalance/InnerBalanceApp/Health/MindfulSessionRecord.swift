import Foundation

struct MindfulSessionRecord: Equatable, Codable, Sendable {
  let syncIdentifier: String
  let syncVersion: Int
  let sessionID: String
  let practiceType: String
  let protocolVersion: Int
  let startDate: Date
  let endDate: Date
  let origin: HealthRecordOrigin
  let evidenceMode: HealthEvidenceMode
  let heartRateEvidence: HeartRateEvidenceSummary?
}

@MainActor
protocol HealthWriting {
  func saveStateOfMind(_ record: StateOfMindRecord) async throws
  func saveMindfulSession(_ record: MindfulSessionRecord) async throws
}
