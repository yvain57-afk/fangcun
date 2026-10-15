import Foundation
import InnerBalanceCore
import SwiftData

struct PracticeCompletionRecord: Equatable, Sendable {
  let sessionID: String
  let practiceKind: PracticeKind
  let plannedDuration: TimeInterval
  let actualDuration: TimeInterval
  let startedAt: Date
  let endedAt: Date
  let beforeRating: Int?
  let afterRating: Int?
  var metadata: PracticeSessionMetadata?

  nonisolated init(sessionID: String, practiceKind: PracticeKind, plannedDuration: TimeInterval, actualDuration: TimeInterval, startedAt: Date, endedAt: Date, beforeRating: Int?, afterRating: Int?, metadata: PracticeSessionMetadata? = nil) {
    self.sessionID = sessionID; self.practiceKind = practiceKind
    self.plannedDuration = plannedDuration; self.actualDuration = actualDuration
    self.startedAt = startedAt; self.endedAt = endedAt
    self.beforeRating = beforeRating; self.afterRating = afterRating
    self.metadata = metadata
  }

  var subjectiveChange: Int {
    guard let beforeRating, let afterRating else { return 0 }
    return afterRating - beforeRating
  }

  var hasSubjectiveComparison: Bool {
    practiceKind != .kegel && beforeRating != nil && afterRating != nil
  }

  var withoutFeedback: PracticeCompletionRecord {
    PracticeCompletionRecord(
      sessionID: sessionID, practiceKind: practiceKind,
      plannedDuration: plannedDuration, actualDuration: actualDuration,
      startedAt: startedAt, endedAt: endedAt,
      beforeRating: nil, afterRating: nil, metadata: metadata
    )
  }
}

struct PracticeCompletionOutcome: Equatable, Sendable {
  let mindfulWriteResult: HealthWriteResult?
  let postWriteResult: HealthWriteResult?
  let postCheckIn: StateOfMindRecord?
  let savedRecord: PracticeCompletionRecord?
  let healthStatusNeedsRetry: Bool

  init(
    mindfulWriteResult: HealthWriteResult?,
    postWriteResult: HealthWriteResult?,
    postCheckIn: StateOfMindRecord? = nil,
    savedRecord: PracticeCompletionRecord? = nil,
    healthStatusNeedsRetry: Bool = false
  ) {
    self.mindfulWriteResult = mindfulWriteResult
    self.postWriteResult = postWriteResult
    self.postCheckIn = postCheckIn
    self.savedRecord = savedRecord
    self.healthStatusNeedsRetry = healthStatusNeedsRetry
  }

  var needsHealthAttention: Bool {
    healthStatusNeedsRetry
      || mindfulWriteResult == .failedToQueue || postWriteResult == .failedToQueue
  }
}

enum PracticeCompletionSaveError: Error, Equatable {
  case localPersistenceFailed
}

@Model
final class StoredPracticeCompletion {
  @Attribute(.unique) var sessionID: String
  var practiceKindRawValue: String
  var plannedDuration: TimeInterval
  var actualDuration: TimeInterval
  var startedAt: Date
  var endedAt: Date
  var beforeRating: Int?
  var afterRating: Int?
  var protocolMetadata: Data?
  var mindfulWriteResultRawValue: String
  var postWriteResultRawValue: String = "failed_to_queue"

  init(
    record: PracticeCompletionRecord,
    mindfulWriteResult: HealthWriteResult,
    postWriteResult: HealthWriteResult
  ) {
    sessionID = record.sessionID
    practiceKindRawValue = record.practiceKind.rawValue
    plannedDuration = record.plannedDuration
    actualDuration = record.actualDuration
    startedAt = record.startedAt
    endedAt = record.endedAt
    beforeRating = record.beforeRating
    afterRating = record.afterRating
    protocolMetadata = record.metadata.flatMap { try? JSONEncoder().encode($0) }
    mindfulWriteResultRawValue = Self.rawValue(for: mindfulWriteResult)
    postWriteResultRawValue = Self.rawValue(for: postWriteResult)
  }

  func update(
    record: PracticeCompletionRecord,
    mindfulWriteResult: HealthWriteResult,
    postWriteResult: HealthWriteResult
  ) {
    practiceKindRawValue = record.practiceKind.rawValue
    plannedDuration = record.plannedDuration
    actualDuration = record.actualDuration
    startedAt = record.startedAt
    endedAt = record.endedAt
    beforeRating = record.beforeRating
    afterRating = record.afterRating
    protocolMetadata = record.metadata.flatMap { try? JSONEncoder().encode($0) }
    mindfulWriteResultRawValue = Self.rawValue(for: mindfulWriteResult)
    postWriteResultRawValue = Self.rawValue(for: postWriteResult)
  }

  var record: PracticeCompletionRecord? {
    guard let practiceKind = PracticeKind(rawValue: practiceKindRawValue) else { return nil }
    let metadata: PracticeSessionMetadata?
    if let protocolMetadata {
      // Preserve unreadable bytes; never reinterpret a damaged V4 record as legacy and
      // fabricate one continuous HealthKit interval spanning its pauses.
      guard let decoded = try? JSONDecoder().decode(PracticeSessionMetadata.self, from: protocolMetadata),
        decoded.protocolVersion == PracticeTimeline.protocolVersion else { return nil }
      metadata = decoded
    } else { metadata = nil }
    return PracticeCompletionRecord(
      sessionID: sessionID,
      practiceKind: practiceKind,
      plannedDuration: plannedDuration,
      actualDuration: actualDuration,
      startedAt: startedAt,
      endedAt: endedAt,
      beforeRating: beforeRating,
      afterRating: afterRating,
      metadata: metadata
    )
  }

  var mindfulWriteResult: HealthWriteResult {
    Self.writeResult(from: mindfulWriteResultRawValue)
  }

  var postWriteResult: HealthWriteResult {
    Self.writeResult(from: postWriteResultRawValue)
  }

  var snapshot: PracticeCompletionSnapshot? {
    guard let record else { return nil }
    return PracticeCompletionSnapshot(
      record: record,
      mindfulWriteResult: mindfulWriteResult,
      postWriteResult: postWriteResult
    )
  }

  func updateHealthWriteResults(
    mindfulWriteResult: HealthWriteResult,
    postWriteResult: HealthWriteResult
  ) {
    mindfulWriteResultRawValue = Self.rawValue(for: mindfulWriteResult)
    postWriteResultRawValue = Self.rawValue(for: postWriteResult)
  }

  private static func writeResult(from rawValue: String) -> HealthWriteResult {
    switch rawValue {
    case "saved": .saved
    case "queued": .queued
    default: .failedToQueue
    }
  }

  private static func rawValue(for result: HealthWriteResult) -> String {
    switch result {
    case .saved: "saved"
    case .queued: "queued"
    case .failedToQueue: "failed_to_queue"
    }
  }
}

struct PracticeCompletionSnapshot: Equatable, Sendable {
  let record: PracticeCompletionRecord
  let mindfulWriteResult: HealthWriteResult
  let postWriteResult: HealthWriteResult
}

@MainActor
protocol PracticeCompletionStoring: AnyObject {
  func save(
    _ record: PracticeCompletionRecord,
    mindfulWriteResult: HealthWriteResult,
    postWriteResult: HealthWriteResult
  ) throws
  func latestRecord() throws -> PracticeCompletionRecord?
  func completion(sessionID: String) throws -> PracticeCompletionSnapshot?
}

extension PracticeCompletionStoring {
  func completion(sessionID: String) throws -> PracticeCompletionSnapshot? {
    guard let record = try latestRecord(), record.sessionID == sessionID else { return nil }
    return PracticeCompletionSnapshot(
      record: record,
      mindfulWriteResult: .failedToQueue,
      postWriteResult: .failedToQueue
    )
  }
}

@MainActor
final class PracticeCompletionStore: PracticeCompletionStoring {
  private let modelContainer: ModelContainer

  init(modelContext: ModelContext) {
    modelContainer = modelContext.container
  }

  func save(
    _ record: PracticeCompletionRecord,
    mindfulWriteResult: HealthWriteResult,
    postWriteResult: HealthWriteResult = .saved
  ) throws {
    let modelContext = makeContext()
    let sessionID = record.sessionID
    let descriptor = FetchDescriptor<StoredPracticeCompletion>(
      predicate: #Predicate { $0.sessionID == sessionID }
    )
    if let existing = try modelContext.fetch(descriptor).first {
      guard existing.protocolMetadata == nil || existing.record != nil else {
        throw CocoaError(.fileReadCorruptFile)
      }
      existing.update(
        record: record,
        mindfulWriteResult: mindfulWriteResult,
        postWriteResult: postWriteResult
      )
    } else {
      modelContext.insert(
        StoredPracticeCompletion(
          record: record,
          mindfulWriteResult: mindfulWriteResult,
          postWriteResult: postWriteResult
        )
      )
    }
    try modelContext.save()
  }

  func latestRecord() throws -> PracticeCompletionRecord? {
    try latest()?.record
  }

  func latestMindfulWriteResult() throws -> HealthWriteResult? {
    try latest()?.mindfulWriteResult
  }

  func completion(sessionID: String) throws -> PracticeCompletionSnapshot? {
    let modelContext = makeContext()
    let descriptor = FetchDescriptor<StoredPracticeCompletion>(
      predicate: #Predicate { $0.sessionID == sessionID }
    )
    return try modelContext.fetch(descriptor).first?.snapshot
  }

  private func latest() throws -> PracticeCompletionSnapshot? {
    let modelContext = makeContext()
    var descriptor = FetchDescriptor<StoredPracticeCompletion>(
      sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first?.snapshot
  }

  private func makeContext() -> ModelContext {
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false
    return context
  }
}

@MainActor
final class PracticeCompletionCoordinator {
  private let store: any PracticeCompletionStoring
  private let feedbackStore: any PracticeFeedbackStoring
  private let healthWriter: HealthWriteCoordinator
  private var inFlightCompletions: [String: Task<PracticeCompletionOutcome, Error>] = [:]

  init(
    store: any PracticeCompletionStoring,
    feedbackStore: any PracticeFeedbackStoring,
    healthWriter: HealthWriteCoordinator
  ) {
    self.store = store
    self.feedbackStore = feedbackStore
    self.healthWriter = healthWriter
  }

  func saveCompletion(
    _ record: PracticeCompletionRecord
  ) async throws -> PracticeCompletionOutcome {
    if let task = inFlightCompletions[record.sessionID] { return try await task.value }
    let task = Task { @MainActor in try await self.persistCompletion(record) }
    inFlightCompletions[record.sessionID] = task
    defer { inFlightCompletions[record.sessionID] = nil }
    return try await task.value
  }

  private func persistCompletion(_ record: PracticeCompletionRecord) async throws -> PracticeCompletionOutcome {
    if let existing = try store.completion(sessionID: record.sessionID),
      record.practiceKind == .kegel || existing.mindfulWriteResult != .failedToQueue
    {
      return PracticeCompletionOutcome(
        mindfulWriteResult: record.practiceKind == .kegel ? nil : existing.mindfulWriteResult,
        postWriteResult: nil,
        savedRecord: existing.record
      )
    }

    let initialMindfulResult: HealthWriteResult =
      record.practiceKind == .kegel ? .saved : .failedToQueue
    do {
      try store.save(
        record,
        mindfulWriteResult: initialMindfulResult,
        postWriteResult: .failedToQueue
      )
    } catch {
      throw PracticeCompletionSaveError.localPersistenceFailed
    }

    guard record.practiceKind != .kegel else {
      return PracticeCompletionOutcome(
        mindfulWriteResult: nil,
        postWriteResult: nil,
        savedRecord: record
      )
    }

    var mindfulResult: HealthWriteResult = .saved
    for interval in mindfulSessions(for: record) {
      let result = await healthWriter.saveMindfulSession(interval)
      if result == .failedToQueue { mindfulResult = .failedToQueue }
      else if result == .queued && mindfulResult != .failedToQueue { mindfulResult = .queued }
    }
    do {
      try store.save(
        record,
        mindfulWriteResult: mindfulResult,
        postWriteResult: .failedToQueue
      )
    } catch {
      return PracticeCompletionOutcome(
        mindfulWriteResult: mindfulResult,
        postWriteResult: nil,
        savedRecord: record,
        healthStatusNeedsRetry: true
      )
    }
    return PracticeCompletionOutcome(
      mindfulWriteResult: mindfulResult,
      postWriteResult: nil,
      savedRecord: record
    )
  }

  func saveFeedback(
    _ record: PracticeCompletionRecord,
    postValence: Double,
    postArousal: Double
  ) async throws -> PracticeCompletionOutcome {
    if record.practiceKind == .kegel {
      return try await saveCompletion(record)
    }

    if try store.completion(sessionID: record.sessionID) == nil {
      _ = try await saveCompletion(record.withoutFeedback)
    }

    let feedback: PracticeFeedbackSnapshot
    do {
      feedback = try feedbackStore.saveFeedback(
        record,
        postCheckIn: postState(for: record, valence: postValence, arousal: postArousal)
      )
    } catch {
      throw PracticeCompletionSaveError.localPersistenceFailed
    }

    if feedback.completion.postWriteResult != .failedToQueue {
      return PracticeCompletionOutcome(
        mindfulWriteResult: feedback.completion.mindfulWriteResult,
        postWriteResult: feedback.completion.postWriteResult,
        postCheckIn: feedback.postCheckIn,
        savedRecord: feedback.completion.record
      )
    }

    let postResult = await healthWriter.saveStateOfMind(feedback.postCheckIn)
    do {
      try feedbackStore.updatePostWriteResult(
        sessionID: feedback.completion.record.sessionID,
        result: postResult
      )
    } catch {
      // The user data is already committed. A sync-status failure must not reopen editing.
      return PracticeCompletionOutcome(
        mindfulWriteResult: feedback.completion.mindfulWriteResult,
        postWriteResult: postResult,
        postCheckIn: feedback.postCheckIn,
        savedRecord: feedback.completion.record,
        healthStatusNeedsRetry: true
      )
    }
    return PracticeCompletionOutcome(
      mindfulWriteResult: feedback.completion.mindfulWriteResult,
      postWriteResult: postResult,
      postCheckIn: feedback.postCheckIn,
      savedRecord: feedback.completion.record
    )
  }

  func save(
    _ record: PracticeCompletionRecord,
    postValence: Double,
    postArousal: Double
  ) async throws -> PracticeCompletionOutcome {
    try await saveFeedback(
      record,
      postValence: postValence,
      postArousal: postArousal
    )
  }

  func saveCompletionOnly(
    _ record: PracticeCompletionRecord
  ) throws -> PracticeCompletionOutcome {
    do {
      try store.save(
        record,
        mindfulWriteResult: .saved,
        postWriteResult: .saved
      )
    } catch {
      throw PracticeCompletionSaveError.localPersistenceFailed
    }
    return PracticeCompletionOutcome(
      mindfulWriteResult: nil,
      postWriteResult: nil
    )
  }

  func latestRecord() throws -> PracticeCompletionRecord? {
    try store.latestRecord()
  }

  /// V4 writes each confirmed active interval. Stable IDs make queued retries idempotent.
  private func mindfulSessions(for record: PracticeCompletionRecord) -> [MindfulSessionRecord] {
    let legacy = record.metadata == nil
    let intervals = record.metadata?.activeIntervals ?? [
      PracticeActiveInterval(start: record.endedAt.addingTimeInterval(-record.actualDuration), end: record.endedAt)
    ]
    return intervals.enumerated().compactMap { index, interval in
      guard interval.duration > 0 else { return nil }
      return MindfulSessionRecord(
        syncIdentifier: "com.yvainair.innerbalance.mindful.\(record.sessionID)" + (legacy ? "" : ".interval.\(index)"),
        syncVersion: 1, sessionID: record.sessionID, practiceType: record.practiceKind.rawValue,
        protocolVersion: legacy ? 1 : 4,
        startDate: interval.start, endDate: interval.end, origin: .iPhone,
        evidenceMode: .subjective, heartRateEvidence: nil
      )
    }
  }

  func saveSelectedFeedback(_ record: PracticeCompletionRecord, feedback: String) async throws -> PracticeCompletionOutcome {
    _ = try await saveCompletion(record.withoutFeedback)
    guard let snapshot = try store.completion(sessionID: record.sessionID) else {
      throw PracticeCompletionSaveError.localPersistenceFailed
    }
    var updated = snapshot.record
    updated.metadata?.subjectiveFeedback = feedback
    try store.save(updated, mindfulWriteResult: snapshot.mindfulWriteResult, postWriteResult: snapshot.postWriteResult)
    return PracticeCompletionOutcome(mindfulWriteResult: snapshot.mindfulWriteResult, postWriteResult: nil, savedRecord: updated)
  }

  private func postState(
    for record: PracticeCompletionRecord,
    valence: Double,
    arousal: Double
  ) -> StateOfMindRecord {
    StateOfMindRecord(
      syncIdentifier: "com.yvainair.innerbalance.state.post.\(record.sessionID)",
      syncVersion: 1,
      date: record.endedAt,
      valence: min(max(valence, -1), 1),
      arousal: min(max(arousal, -1), 1),
      labels: [],
      associations: [],
      bodySensationCodes: [],
      unclassified: true,
      origin: .iPhone,
      sessionID: record.sessionID,
      phase: .post
    )
  }
}
