import HealthKit
import InnerBalanceCore
import Testing

@testable import InnerBalance

@Suite("State of Mind mapping")
struct StateOfMindMapperTests {
  @Test("A classified check-in maps coordinates, labels, associations and metadata")
  func classifiedCheckInMapsToHealthKit() throws {
    let date = Date(timeIntervalSince1970: 1_786_296_600)
    let record = StateOfMindRecord(
      syncIdentifier: "check-in-123",
      syncVersion: 1,
      date: date,
      valence: 0.4,
      arousal: -0.6,
      labels: [.calm],
      associations: [.work],
      bodySensationCodes: ["relaxed_shoulders"],
      unclassified: false,
      origin: .iPhone,
      sessionID: nil,
      phase: .standalone
    )

    let sample = try StateOfMindMapper.sample(from: record)

    #expect(sample.startDate == date)
    #expect(sample.valence == 0.4)
    #expect(sample.labels == [.calm])
    #expect(sample.associations == [.work])
    #expect(sample.metadata?[HKMetadataKeySyncIdentifier] as? String == "check-in-123")
    #expect(sample.metadata?[HealthMetadataKeys.arousal] as? Double == -0.6)
    #expect(StateOfMindMapper.record(from: sample) == record)
  }

  @Test("An unclassified sample round-trips with empty labels")
  func unclassifiedRoundTrip() throws {
    let record = StateOfMindRecord(
      syncIdentifier: "check-in-unclassified",
      syncVersion: 1,
      date: Date(timeIntervalSince1970: 1_786_296_600),
      valence: 0.55,
      arousal: -0.7,
      labels: [],
      associations: [],
      bodySensationCodes: [],
      unclassified: true,
      origin: .iPhone,
      sessionID: nil,
      phase: .standalone
    )

    let sample = try StateOfMindMapper.sample(from: record)

    #expect(sample.labels.isEmpty)
    #expect(StateOfMindMapper.record(from: sample) == record)
  }

  @Test("Optional sources are capped and custom-only sources survive in metadata")
  func optionalSourcesArePreserved() throws {
    let record = StateOfMindRecord(
      syncIdentifier: "check-in-context",
      syncVersion: 2,
      date: Date(timeIntervalSince1970: 1_786_296_600),
      valence: -0.2,
      arousal: -0.7,
      labels: [.drained],
      associations: [.work, .sleep, .family],
      bodySensationCodes: ["fatigue"],
      unclassified: false,
      origin: .iPhone,
      sessionID: nil,
      phase: .standalone
    )

    let sample = try StateOfMindMapper.sample(from: record)

    #expect(sample.associations == [.work])
    #expect(sample.metadata?[HealthMetadataKeys.associationCodes] as? String == "work,sleep")
    #expect(StateOfMindMapper.record(from: sample)?.associations == [.work, .sleep])
  }
}
