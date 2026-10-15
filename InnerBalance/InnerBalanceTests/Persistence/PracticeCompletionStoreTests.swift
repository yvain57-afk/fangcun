import Foundation
import InnerBalanceCore
import SwiftData
import Testing

@testable import InnerBalance

@Suite("Practice completion persistence")
struct PracticeCompletionStoreTests {
  @Test("The latest completed practice is restored for home evidence")
  @MainActor
  func latestCompletionRoundTrips() throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: StoredPracticeCompletion.self,
      configurations: configuration
    )
    let store = PracticeCompletionStore(modelContext: container.mainContext)
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let record = PracticeCompletionRecord(
      sessionID: "practice-persisted",
      practiceKind: .pacedBreathing,
      plannedDuration: 300,
      actualDuration: 298,
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(300),
      beforeRating: 7,
      afterRating: 4
    )

    try store.save(record, mindfulWriteResult: .queued)

    #expect(try store.latestRecord() == record)
    #expect(try store.latestMindfulWriteResult() == .queued)
  }

  @Test("Kegel saves locally without being written as a Mindful Session")
  @MainActor
  func kegelNeverWritesMindfulSession() async throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: StoredPracticeCompletion.self, PendingHealthWrite.self, CachedCheckIn.self,
      configurations: configuration
    )
    let writer = PracticeRecordingHealthWriter()
    let coordinator = PracticeCompletionCoordinator(
      store: PracticeCompletionStore(modelContext: container.mainContext),
      feedbackStore: PracticeFeedbackStore(modelContainer: container),
      healthWriter: HealthWriteCoordinator(
        writer: writer,
        modelContext: container.mainContext
      )
    )
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let record = PracticeCompletionRecord(
      sessionID: "kegel-local-only",
      practiceKind: .kegel,
      plannedDuration: 180,
      actualDuration: 180,
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(180),
      beforeRating: 3,
      afterRating: 3
    )

    let result = try await coordinator.save(record, postValence: 0, postArousal: 0)

    #expect(result.mindfulWriteResult == nil)
    #expect(writer.mindfulSessions.isEmpty)
    #expect(writer.stateOfMindRecords.isEmpty)
    #expect(!record.hasSubjectiveComparison)
    #expect(try coordinator.latestRecord() == record)
  }

  @Test("Completed breathing is saved locally and as one Mindful Session")
  @MainActor
  func breathingWritesMindfulSessionOnce() async throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: StoredPracticeCompletion.self, PendingHealthWrite.self, CachedCheckIn.self,
      configurations: configuration
    )
    let writer = PracticeRecordingHealthWriter()
    let coordinator = PracticeCompletionCoordinator(
      store: PracticeCompletionStore(modelContext: container.mainContext),
      feedbackStore: PracticeFeedbackStore(modelContainer: container),
      healthWriter: HealthWriteCoordinator(
        writer: writer,
        modelContext: container.mainContext
      )
    )
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let record = PracticeCompletionRecord(
      sessionID: "breathing-complete",
      practiceKind: .pacedBreathing,
      plannedDuration: 180,
      actualDuration: 178,
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(178),
      beforeRating: 8,
      afterRating: 5
    )

    let result = try await coordinator.save(record, postValence: 0.2, postArousal: -0.4)

    #expect(result.mindfulWriteResult == .saved)
    #expect(result.postWriteResult == .saved)
    #expect(writer.mindfulSessions.count == 1)
    #expect(writer.mindfulSessions.first?.sessionID == record.sessionID)
    #expect(writer.mindfulSessions.first?.practiceType == PracticeKind.pacedBreathing.rawValue)
    #expect(writer.mindfulSessions.first?.endDate == record.endedAt)
    #expect(
      writer.mindfulSessions.first?.startDate
        == record.endedAt.addingTimeInterval(-record.actualDuration)
    )
    #expect(
      writer.stateOfMindRecords.first?.syncIdentifier
        == "com.yvainair.innerbalance.state.post.\(record.sessionID)")
    #expect(writer.stateOfMindRecords.first?.sessionID == record.sessionID)
    #expect(writer.stateOfMindRecords.first?.valence == 0.2)
    #expect(writer.stateOfMindRecords.first?.arousal == -0.4)
    #expect(try coordinator.latestRecord() == record)
  }

  @Test("Local persistence failure never writes HealthKit or reports success")
  @MainActor
  func localFailureStopsCompletion() async throws {
    let writer = PracticeRecordingHealthWriter()
    let container = try ModelContainer(
      for: PendingHealthWrite.self, CachedCheckIn.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let coordinator = PracticeCompletionCoordinator(
      store: FailingPracticeCompletionStore(),
      feedbackStore: PracticeFeedbackStore(modelContainer: container),
      healthWriter: HealthWriteCoordinator(
        writer: writer,
        modelContext: container.mainContext
      )
    )
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let record = PracticeCompletionRecord(
      sessionID: "local-failure",
      practiceKind: .meditation,
      plannedDuration: 300,
      actualDuration: 300,
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(300),
      beforeRating: 4,
      afterRating: 3
    )

    await #expect(throws: PracticeCompletionSaveError.localPersistenceFailed) {
      try await coordinator.save(record, postValence: 0, postArousal: -0.2)
    }
    #expect(writer.mindfulSessions.isEmpty)
    #expect(writer.stateOfMindRecords.isEmpty)
  }

  @Test("A health-status update failure preserves a successfully saved completion")
  @MainActor
  func finalStatusFailurePreservesCompletion() async throws {
    let writer = PracticeRecordingHealthWriter()
    let store = FinalStatusFailingPracticeCompletionStore()
    let container = try ModelContainer(
      for: PendingHealthWrite.self, CachedCheckIn.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let coordinator = PracticeCompletionCoordinator(
      store: store,
      feedbackStore: PracticeFeedbackStore(modelContainer: container),
      healthWriter: HealthWriteCoordinator(
        writer: writer,
        modelContext: container.mainContext
      )
    )
    let endedAt = Date(timeIntervalSince1970: 1_786_320_300)
    let record = PracticeCompletionRecord(
      sessionID: "status-update-failure",
      practiceKind: .meditation,
      plannedDuration: 300,
      actualDuration: 300,
      startedAt: endedAt.addingTimeInterval(-300),
      endedAt: endedAt,
      beforeRating: 4,
      afterRating: 3
    )

    let result = try await coordinator.saveCompletion(record.withoutFeedback)

    #expect(result.savedRecord == record.withoutFeedback)
    #expect(result.healthStatusNeedsRetry)
    #expect(result.needsHealthAttention)
    #expect(try coordinator.latestRecord() == record.withoutFeedback)
    #expect(store.saveCount == 2)
    #expect(writer.mindfulSessions.count == 1)
    #expect(writer.stateOfMindRecords.isEmpty)
  }
  @Test("V4 optional protocol metadata preserves legacy nil and actual health intervals")
  @MainActor
  func v4MetadataAndPausedHealthIntervals() async throws {
    let container = try ModelContainer(for: StoredPracticeCompletion.self, PendingHealthWrite.self, CachedCheckIn.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let writer = PracticeRecordingHealthWriter()
    let store = PracticeCompletionStore(modelContext: container.mainContext)
    let coordinator = PracticeCompletionCoordinator(store: store, feedbackStore: PracticeFeedbackStore(modelContainer: container), healthWriter: HealthWriteCoordinator(writer: writer, modelContext: container.mainContext))
    let start = Date(timeIntervalSince1970: 10000)
    let metadata = PracticeSessionMetadata(timelineVariantID: "easy_4_4", sceneID: "duo_settled_breath", completionStatus: "endedEarly", completedCycles: 2, activeIntervals: [.init(start: start, end: start.addingTimeInterval(10)), .init(start: start.addingTimeInterval(100), end: start.addingTimeInterval(110))])
    let record = PracticeCompletionRecord(sessionID: "v4-active-intervals", practiceKind: .balancedBreathing, plannedDuration: 300, actualDuration: 20, startedAt: start, endedAt: start.addingTimeInterval(110), beforeRating: nil, afterRating: nil, metadata: metadata)
    _ = try await coordinator.saveCompletion(record)
    _ = try await coordinator.saveCompletion(record)
    #expect(writer.mindfulSessions.count == 2)
    #expect(writer.mindfulSessions.map { $0.endDate.timeIntervalSince($0.startDate) } == [10, 10])
    #expect(writer.mindfulSessions.map(\.startDate) == [start, start.addingTimeInterval(100)])
    #expect(Set(writer.mindfulSessions.map(\.syncIdentifier)).count == 2)
    #expect(writer.mindfulSessions.allSatisfy { $0.sessionID == record.sessionID && $0.protocolVersion == 4 })
    #expect(try store.latestRecord() == record)
    _ = try await coordinator.saveSelectedFeedback(record, feedback: "不舒服")
    #expect(try store.latestRecord()?.metadata?.subjectiveFeedback == "不舒服")
    #expect(writer.stateOfMindRecords.isEmpty)
    #expect(writer.mindfulSessions.count == 2)
    #expect(try store.latestRecord()?.beforeRating == nil)

    let legacy = PracticeCompletionRecord(sessionID: "legacy", practiceKind: .pacedBreathing, plannedDuration: 180, actualDuration: 80, startedAt: start, endedAt: start.addingTimeInterval(150), beforeRating: 7, afterRating: 4)
    try store.save(legacy, mindfulWriteResult: .saved)
    #expect(try store.completion(sessionID: "legacy")?.record.metadata == nil)
    #expect(try store.completion(sessionID: "legacy")?.record == legacy)
  }

  @Test("Corrupt optional metadata preserves bytes and cannot become a legacy health rewrite")
  @MainActor
  func corruptMetadataDoesNotInventLegacySemantics() {
    let start = Date(timeIntervalSince1970: 1000)
    let record = PracticeCompletionRecord(sessionID: "corrupt", practiceKind: .boxBreathing, plannedDuration: 180, actualDuration: 20, startedAt: start, endedAt: start.addingTimeInterval(100), beforeRating: nil, afterRating: nil)
    let stored = StoredPracticeCompletion(record: record, mindfulWriteResult: .failedToQueue, postWriteResult: .failedToQueue)
    let bytes = Data("broken-new-metadata".utf8)
    stored.protocolMetadata = bytes
    #expect(stored.record == nil)
    #expect(stored.protocolMetadata == bytes)
    #expect(stored.actualDuration == 20)
    #expect(stored.sessionID == "corrupt")
  }

  @Test("Concurrent completion events coalesce one local session and one health write")
  @MainActor
  func concurrentV4CompletionIsIdempotent() async throws {
    let container = try ModelContainer(for: StoredPracticeCompletion.self, PendingHealthWrite.self, CachedCheckIn.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let writer = PracticeRecordingHealthWriter()
    writer.yieldsBeforeSaving = true
    let store = PracticeCompletionStore(modelContext: container.mainContext)
    let coordinator = PracticeCompletionCoordinator(store: store, feedbackStore: PracticeFeedbackStore(modelContainer: container), healthWriter: HealthWriteCoordinator(writer: writer, modelContext: container.mainContext))
    let start = Date(timeIntervalSince1970: 1000)
    let record = PracticeCompletionRecord(sessionID: "v4-concurrent", practiceKind: .boxBreathing, plannedDuration: 180, actualDuration: 12, startedAt: start, endedAt: start.addingTimeInterval(12), beforeRating: nil, afterRating: nil, metadata: .init(timelineVariantID: "box_3", sceneID: "cat_four_corners", completionStatus: "endedEarly", completedCycles: 1, activeIntervals: [.init(start: start, end: start.addingTimeInterval(12))]))
    let first = Task { try await coordinator.saveCompletion(record) }
    let second = Task { try await coordinator.saveCompletion(record) }
    _ = try await first.value
    _ = try await second.value
    #expect(writer.mindfulSessions.count == 1)
    #expect(try container.mainContext.fetchCount(FetchDescriptor<StoredPracticeCompletion>()) == 1)
    #expect(try store.completion(sessionID: record.sessionID)?.record == record)
  }

}

@MainActor
private final class PracticeRecordingHealthWriter: HealthWriting {
  private(set) var mindfulSessions: [MindfulSessionRecord] = []
  private(set) var stateOfMindRecords: [StateOfMindRecord] = []
  var yieldsBeforeSaving = false

  func saveStateOfMind(_ record: StateOfMindRecord) async throws {
    stateOfMindRecords.append(record)
  }

  func saveMindfulSession(_ record: MindfulSessionRecord) async throws {
    if yieldsBeforeSaving { await Task.yield() }
    mindfulSessions.append(record)
  }
}

@MainActor
private final class FailingPracticeCompletionStore: PracticeCompletionStoring {
  func save(
    _ record: PracticeCompletionRecord,
    mindfulWriteResult: HealthWriteResult,
    postWriteResult: HealthWriteResult
  ) throws {
    throw CocoaError(.fileWriteOutOfSpace)
  }

  func latestRecord() throws -> PracticeCompletionRecord? { nil }
}

@MainActor
private final class FinalStatusFailingPracticeCompletionStore: PracticeCompletionStoring {
  private(set) var saveCount = 0
  private var snapshot: PracticeCompletionSnapshot?

  func save(
    _ record: PracticeCompletionRecord,
    mindfulWriteResult: HealthWriteResult,
    postWriteResult: HealthWriteResult
  ) throws {
    saveCount += 1
    if saveCount == 2 {
      throw CocoaError(.fileWriteOutOfSpace)
    }
    snapshot = PracticeCompletionSnapshot(
      record: record,
      mindfulWriteResult: mindfulWriteResult,
      postWriteResult: postWriteResult
    )
  }

  func latestRecord() throws -> PracticeCompletionRecord? { snapshot?.record }

  func completion(sessionID: String) throws -> PracticeCompletionSnapshot? {
    snapshot?.record.sessionID == sessionID ? snapshot : nil
  }
}
