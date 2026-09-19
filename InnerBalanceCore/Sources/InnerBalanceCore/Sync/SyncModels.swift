import Foundation

public enum SyncEntityKind: String, Codable, Sendable { case session, drink }
public struct SyncedDrink: Codable, Equatable, Sendable {
  public var id: String
  public var kind: String
  public var consumedAt: Date
  public var recordedAt: Date?
  public var volumeML: Int
  public var caffeineMG: Int?
  public var alcoholGrams: Double?
  public var sugarServings: Double
  public var sugarGrams: Double?
  public var estimateMethod: String
  public var beverageDetails: BeverageDetails? = nil
  public var estimateVersion: Int
  public init(id: String, kind: String, consumedAt: Date, recordedAt: Date?, volumeML: Int,
    caffeineMG: Int?, alcoholGrams: Double?, sugarServings: Double, sugarGrams: Double?, estimateMethod: String, estimateVersion: Int, beverageDetails: BeverageDetails? = nil) {
    self.beverageDetails = beverageDetails
    self.id = id; self.kind = kind; self.consumedAt = consumedAt; self.recordedAt = recordedAt
    self.volumeML = volumeML; self.caffeineMG = caffeineMG; self.alcoholGrams = alcoholGrams
    self.sugarServings = sugarServings; self.sugarGrams = sugarGrams; self.estimateMethod = estimateMethod; self.estimateVersion = estimateVersion
  }
}
public struct SyncEvent: Codable, Equatable, Sendable {
  public var schemaVersion = 1
  public var eventID: String
  public var entityID: String
  public var kind: SyncEntityKind
  public var revision: Int
  public var originInstallationID: String
  public var deleted: Bool
  public var explicitRestore: Bool
  public var payload: Data
  public var entityKey: String { kind.rawValue + ":" + entityID }
  public init(eventID: String = UUID().uuidString, entityID: String, kind: SyncEntityKind,
    revision: Int, originInstallationID: String, deleted: Bool = false, explicitRestore: Bool = false, payload: Data) {
    self.eventID = eventID; self.entityID = entityID; self.kind = kind; self.revision = revision
    self.originInstallationID = originInstallationID; self.deleted = deleted; self.explicitRestore = explicitRestore; self.payload = payload
  }
}
public struct SyncAcknowledgement: Codable, Equatable, Sendable {
  public var eventID: String
  public var originInstallationID: String
  public var digest: String
  public init(event: SyncEvent) throws {
    eventID = event.eventID; originInstallationID = event.originInstallationID; digest = try StableDigest.encoded(event)
  }
}
/// The phone's minimal result, without raw values, sources, personal notes or HealthKit identifiers.
public struct ReadinessSummaryDTO: Codable, Equatable, Sendable {
  public var schemaVersion = 1
  public var originInstallationID: String
  public var sequence: Int
  public var assessmentID: String?
  public var assessmentRevision: Int?
  public var availability: ReadinessAvailability?
  public var level: ReadinessLevel?
  public var sleepEndAt: Date?
  public var validUntil: Date?
  public var issuedAt: Date
  public var revoked: Bool
  public init(assessment: ReadinessAssessment?, installationID: String, sequence: Int, now: Date) {
    originInstallationID = installationID; self.sequence = sequence; issuedAt = now
    assessmentID = assessment?.assessmentID; assessmentRevision = assessment?.revision
    availability = assessment?.availability; sleepEndAt = assessment?.sleepEndAt
    validUntil = assessment?.currentUntil
    level = assessment.flatMap { AssessmentFreshness.resolve($0, now: now) == .current ? $0.level : nil }
    revoked = assessment == nil
  }
  public func usable(now: Date, peer: String?) -> Bool {
    schemaVersion == 1 && !revoked && originInstallationID == peer
      && validUntil.map { now <= $0 } == true && now >= issuedAt.addingTimeInterval(-300)
  }
}
public struct SyncPacket: Codable, Sendable {
  public var schemaVersion = 1
  public var originInstallationID: String
  public var role: String
  public var event: SyncEvent?
  public var acknowledgement: SyncAcknowledgement?
  public var summary: ReadinessSummaryDTO?
  public var capabilities: [String]? = ["beverage-v2"]
  public var hello = false
  public init(origin: String, role: String, event: SyncEvent? = nil, acknowledgement: SyncAcknowledgement? = nil,
    summary: ReadinessSummaryDTO? = nil, hello: Bool = false) {
    originInstallationID = origin; self.role = role; self.event = event
    self.acknowledgement = acknowledgement; self.summary = summary; self.hello = hello
  }
}
