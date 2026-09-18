import Foundation
import InnerBalanceCore
import SwiftData
import Testing

@testable import InnerBalance

@Suite("Pending HealthKit writes")
struct PendingHealthWriteTests {
  @Test("A failed State of Mind save is queued with its stable sync identity")
  @MainActor
  func failedWriteIsQueued() async throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: PendingHealthWrite.self,
      configurations: configuration
    )
    let coordinator = HealthWriteCoordinator(
      writer: FailingHealthWriter(),
      modelContext: container.mainContext
    )
    let record = StateOfMindRecord(
      syncIdentifier: "check-in-queue-123",
      syncVersion: 1,
      date: Date(timeIntervalSince1970: 1_786_296_600),
      valence: -0.3,
      arousal: 0.8,
      labels: [.anxious],
      associations: [],
      bodySensationCodes: [],
      unclassified: false,
      origin: .iPhone,
      sessionID: nil,
      phase: .standalone
    )

    let result = await coordinator.saveStateOfMind(record)
    let pending = try container.mainContext.fetch(FetchDescriptor<PendingHealthWrite>())

    #expect(result == .queued)
    #expect(pending.count == 1)
    #expect(pending.first?.syncIdentifier == "check-in-queue-123")
    #expect(pending.first?.syncVersion == 1)
    #expect(pending.first?.kind == .stateOfMind)
  }

  @Test("Repeated failures for the same HealthKit identity create one pending write")
  @MainActor
  func repeatedFailureIsDeduplicated() async throws {
    let container = try makeContainer()
    let coordinator = HealthWriteCoordinator(
      writer: FailingHealthWriter(),
      modelContext: container.mainContext
    )
    let record = makeStateOfMindRecord(syncIdentifier: "check-in-deduplicated")

    let firstResult = await coordinator.saveStateOfMind(record)
    let secondResult = await coordinator.saveStateOfMind(record)
    let pending = try container.mainContext.fetch(FetchDescriptor<PendingHealthWrite>())

    #expect(firstResult == .queued)
    #expect(secondResult == .queued)
    #expect(pending.count == 1)
  }

  @Test("A lower sync version cannot replace a newer pending payload")
  @MainActor
  func lowerVersionDoesNotReplaceNewerPendingWrite() async throws {
    let container = try makeContainer()
    let coordinator = HealthWriteCoordinator(
      writer: FailingHealthWriter(),
      modelContext: container.mainContext
    )
    let current = makeStateOfMindRecord(
      syncIdentifier: "check-in-versioned",
      syncVersion: 2,
      labels: [.stressed]
    )
    let stale = makeStateOfMindRecord(
      syncIdentifier: "check-in-versioned",
      syncVersion: 1,
      labels: [.anxious]
    )

    _ = await coordinator.saveStateOfMind(current)
    _ = await coordinator.saveStateOfMind(stale)

    let pending = try container.mainContext.fetch(FetchDescriptor<PendingHealthWrite>())
    let payload = try #require(pending.first?.payload)
    let decoded = try JSONDecoder().decode(StateOfMindRecord.self, from: payload)
    #expect(pending.first?.syncVersion == 2)
    #expect(decoded.labels == [.stressed])
  }

  @Test("A successful retry removes the pending HealthKit write")
  @MainActor
  func successfulRetryRemovesPendingWrite() async throws {
    let container = try makeContainer()
    let record = makeStateOfMindRecord(syncIdentifier: "check-in-retry")
    let failingCoordinator = HealthWriteCoordinator(
      writer: FailingHealthWriter(),
      modelContext: container.mainContext
    )
    _ = await failingCoordinator.saveStateOfMind(record)
    let writer = RecordingHealthWriter()
    let retryingCoordinator = HealthWriteCoordinator(
      writer: writer,
      modelContext: container.mainContext
    )

    await retryingCoordinator.retryPending(now: .distantFuture)
    let pending = try container.mainContext.fetch(FetchDescriptor<PendingHealthWrite>())

    #expect(pending.isEmpty)
    #expect(writer.savedStateOfMindIdentifiers == ["check-in-retry"])
  }

  @MainActor
  private func makeContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
      for: PendingHealthWrite.self,
      configurations: configuration
    )
  }

  private func makeStateOfMindRecord(
    syncIdentifier: String,
    syncVersion: Int = 1,
    labels: [EmotionLabel] = [.anxious]
  ) -> StateOfMindRecord {
    StateOfMindRecord(
      syncIdentifier: syncIdentifier,
      syncVersion: syncVersion,
      date: Date(timeIntervalSince1970: 1_786_296_600),
      valence: -0.3,
      arousal: 0.8,
      labels: labels,
      associations: [],
      bodySensationCodes: [],
      unclassified: false,
      origin: .iPhone,
      sessionID: nil,
      phase: .standalone
    )
  }
}

@MainActor
private struct FailingHealthWriter: HealthWriting {
  struct WriteFailure: Error {}

  func saveStateOfMind(_ record: StateOfMindRecord) async throws {
    throw WriteFailure()
  }

  func saveMindfulSession(_ record: MindfulSessionRecord) async throws {
    throw WriteFailure()
  }
}

@MainActor
private final class RecordingHealthWriter: HealthWriting {
  private(set) var savedStateOfMindIdentifiers: [String] = []

  func saveStateOfMind(_ record: StateOfMindRecord) async throws {
    savedStateOfMindIdentifiers.append(record.syncIdentifier)
  }

  func saveMindfulSession(_ record: MindfulSessionRecord) async throws {}
}
