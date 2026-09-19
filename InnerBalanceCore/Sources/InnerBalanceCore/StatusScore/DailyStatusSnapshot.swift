import Foundation

public struct ScoreFeatureBundle: Codable, Equatable, Sendable {
  public var input: StatusScoreInput
  public var cycleID: String
  public var asOf: Date
  public var sleepStart: Date?
  public var sleepEnd: Date?
  public var basisSampleIDs: [UUID]
  public var sourceSegments: [String: String]
  public var manual: Bool
  public var windowPolicy: String
  public var displayValues: [String: Double]
  public var measuredAt: [String: Date]
  public var fingerprint: String
}
public struct DailyStatusSnapshot: Codable, Equatable, Sendable {
  public var scoreID: String
  public var cycleID: String
  public var revision: Int
  public var supersedes: String?
  public var rawScore: Double
  public var displayScore: Int
  public var band: StatusBand
  public var modelVersion: String
  public var qualityPolicyVersion: String
  public var scoreBasisProfile: String
  public var components: [StatusScoreComponent]
  public var sleepSubscores: [String: Double]
  public var features: ScoreFeatureBundle
  public var configuration: StatusScoreConfiguration
  public var asOf: Date
  public var currentUntil: Date
  public var validUntil: Date
  public var createdAt: Date
  public var inputFingerprint: String
  public var compositionUpdated: Bool
  public var isValid: Bool {
    rawScore.isFinite && (0...100).contains(rawScore) && StatusBand.resolve(displayScore) == band
      && Int(floor(rawScore+0.5+1e-10)) == displayScore && modelVersion == "fangcun-status-3.0"
      && !components.isEmpty && components.allSatisfy { $0.score.isFinite && (0...100).contains($0.score) && $0.normalizedWeight.isFinite && $0.normalizedWeight > 0 }
      && abs(components.reduce(0) { $0 + $1.normalizedWeight } - 1) < 1e-8 && currentUntil > asOf && validUntil > currentUntil
  }
}
public struct DeletedStatusAudit: Codable, Sendable {
  public var scoreID: String
  public var cycleID: String
  public var revision: Int
}
extension InsightsSnapshot {
  public var currentStatus: DailyStatusSnapshot? { statusScores?.first { $0.scoreID == currentStatusID && $0.isValid } }
  public mutating func recordStatus(_ features: ScoreFeatureBundle, configuration: StatusScoreConfiguration, now: Date) throws {
    let result = try DailyStatusScoreEngine.evaluate(features.input, configuration: configuration)
    guard let raw = result.rawScore, let score = result.displayScore, let band = result.band else { currentStatusID = nil; return }
    let previous = statusScores?.filter { $0.cycleID == features.cycleID }.max { $0.revision < $1.revision }
    if let previous, previous.inputFingerprint == features.fingerprint { currentStatusID = previous.scoreID; return }
    let deleted = statusDeletionAudit?.filter { $0.cycleID == features.cycleID }.max { $0.revision < $1.revision }
    let revision = max(previous?.revision ?? 0, deleted?.revision ?? 0) + 1
    let profile = result.components.map(\.name).joined(separator: "+")
    let value = DailyStatusSnapshot(scoreID: StableDigest.text(features.cycleID+features.fingerprint+"|\(revision)"), cycleID: features.cycleID,
      revision: revision, supersedes: (previous?.revision ?? 0) >= (deleted?.revision ?? 0) ? previous?.scoreID : deleted?.scoreID,
      rawScore: raw, displayScore: score, band: band, modelVersion: configuration.modelVersion, qualityPolicyVersion: configuration.qualityPolicyVersion,
      scoreBasisProfile: profile, components: result.components, sleepSubscores: result.sleepSubscores, features: features, configuration: configuration,
      asOf: features.asOf, currentUntil: features.asOf.addingTimeInterval(configuration.currentHours*3600),
      validUntil: features.asOf.addingTimeInterval(configuration.validHours*3600), createdAt: now, inputFingerprint: features.fingerprint,
      compositionUpdated: previous.map { $0.scoreBasisProfile != profile } ?? false)
    guard value.isValid else { throw StatusScoreError.invalidInput }
    statusScores = (statusScores ?? []) + [value]; currentStatusID = value.scoreID
  }
}
