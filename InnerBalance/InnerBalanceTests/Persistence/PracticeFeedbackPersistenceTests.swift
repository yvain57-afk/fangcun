import Foundation
import InnerBalanceCore
import SwiftData
import Testing

@testable import InnerBalance

@Suite("Practice feedback local response loop")
@MainActor
struct PracticeFeedbackPersistenceTests {
  @Test("Feedback is local before HealthKit and survives a new context without a health read")
  func feedbackIsPersistedBeforeTheHealthWrite() async throws {
    let harness = try FeedbackHarness()
    let record = completion()
    let cache = harness.cache
    harness.writer.onStateWrite = { post in
      let persisted = try? cache.record(syncIdentifier: post.syncIdentifier)
      #expect(persisted != nil)
      #expect(persisted == post)
    }

    let result = try await harness.coordinator.saveFeedback(
      record, postValence: 0.6, postArousal: -0.7
    )

    let restoredCache = CheckInCacheStore(modelContext: ModelContext(harness.container))
    let restored = try #require(try restoredCache.latestRecord())
    #expect(restored == result.postCheckIn)
    #expect(restored.syncIdentifier == "com.yvainair.innerbalance.state.post.\(record.sessionID)")
    #expect(restored.sessionID == record.sessionID)
    #expect(restored.phase == .post)
    #expect(restored.valence == 0.6)
    #expect(restored.arousal == -0.7)
    #expect(restored.date == record.endedAt)
  }

  @Test("Repeated feedback keeps one local row and one health write", arguments: [false, true])
  func repeatedFeedbackIsIdempotent(healthWriteFails: Bool) async throws {
    let harness = try FeedbackHarness()
    harness.writer.shouldFailStateWrite = healthWriteFails
    let record = completion()
    _ = try await harness.coordinator.saveCompletion(record.withoutFeedback)
    let before = try harness.store.completion(sessionID: record.sessionID)
    #expect(before?.record.afterRating == nil)
    let mainContextRecord = try #require(
      try harness.container.mainContext.fetch(FetchDescriptor<StoredPracticeCompletion>()).first
    )
    #expect(mainContextRecord.afterRating == nil)

    let first = try await harness.coordinator.saveFeedback(
      record, postValence: 0.6, postArousal: -0.7
    )
    let repeated = try await harness.coordinator.saveFeedback(
      record, postValence: -0.5, postArousal: 0.8
    )

    let reloaded = try harness.store.completion(sessionID: record.sessionID)
    #expect(reloaded?.record == record)
    #expect(reloaded?.postWriteResult == (healthWriteFails ? .queued : .saved))
    #expect(try harness.store.latestRecord() == record)
    #expect(first.postWriteResult == (healthWriteFails ? .queued : .saved))
    #expect(repeated.postCheckIn == first.postCheckIn)
    #expect(try harness.cache.latestRecord() == first.postCheckIn)
    #expect(try harness.container.mainContext.fetch(FetchDescriptor<CachedCheckIn>()).count == 1)
    #expect(harness.writer.states.count == 1)
    #expect(harness.writer.mindfulSessions.count == 1)
    let pending = try harness.container.mainContext.fetch(FetchDescriptor<PendingHealthWrite>())
    #expect(pending.count == (healthWriteFails ? 1 : 0))
  }

  @Test("Feedback is delivered to home only after a successful local save", arguments: [false, true])
  func savedCallbackCarriesThePersistedState(hasBeforeRating: Bool) async throws {
    let harness = try FeedbackHarness()
    let diagnostics = FeedbackDiagnostics()
    let viewModel = finishedViewModel(beforeRating: hasBeforeRating ? 8 : nil)
    var deliveredPost: StateOfMindRecord?
    var deliveredCompletion: PracticeCompletionRecord?
    let controller = PracticeCompletionSaveController(
      coordinator: harness.coordinator,
      diagnostics: diagnostics,
      sessionID: "feedback-to-home"
    ) { record, post in
      deliveredCompletion = record
      if let post {
        let cached = try? harness.cache.record(syncIdentifier: post.syncIdentifier)
        #expect(cached == post)
        deliveredPost = post
      }
    }

    await controller.save(
      viewModel: viewModel,
      afterRating: 4,
      postValence: 0.7,
      postArousal: -0.6,
      hasPostPosition: true
    )

    #expect(controller.hasSavedFeedback)
    #expect(controller.saveErrorMessage == nil)
    #expect(viewModel.phase == .saved)
    #expect(deliveredPost?.valence == 0.7)
    #expect(deliveredPost?.arousal == -0.6)
    #expect(deliveredCompletion?.hasSubjectiveComparison == hasBeforeRating)
    #expect(diagnostics.events.filter { $0 == .practiceCompleted }.count == 1)
    #expect(
      diagnostics.events.filter { $0 == .subjectiveComparisonAvailable }.count
        == (hasBeforeRating ? 1 : 0)
    )
  }

  @Test("A failed feedback transaction publishes neither input; an edited retry keeps both consistent")
  func failedTransactionCanRetryWithChangedInput() async throws {
    let gate = FeedbackCommitGate()
    gate.failUserCommit = true
    let harness = try FeedbackHarness(commit: gate.commit)
    let viewModel = finishedViewModel(beforeRating: 8)
    let diagnostics = FeedbackDiagnostics()
    var postCallbacks = 0
    var deliveredRecord: PracticeCompletionRecord?
    var deliveredPost: StateOfMindRecord?
    let controller = PracticeCompletionSaveController(
      coordinator: harness.coordinator,
      diagnostics: diagnostics
    ) { record, post in
      if let post {
        postCallbacks += 1
        deliveredRecord = record
        deliveredPost = post
      }
    }
    await controller.saveCompletion(viewModel: viewModel)
    let mainContext = harness.container.mainContext
    mainContext.autosaveEnabled = false
    let unrelated = LocalDiagnosticEvent(kind: .checkInOpened)
    mainContext.insert(unrelated)

    await controller.save(
      viewModel: viewModel, afterRating: 4,
      postValence: 0.4, postArousal: -0.6, hasPostPosition: true
    )

    #expect(controller.saveErrorMessage != nil)
    #expect(!controller.hasSavedFeedback)
    #expect(viewModel.phase == .comparison)
    #expect(postCallbacks == 0)
    #expect(try harness.cache.latestRecord() == nil)
    #expect(harness.writer.states.isEmpty)
    #expect(try harness.store.latestRecord()?.hasSubjectiveComparison == false)
    #expect(gate.stagedFeedback?.completion.record.afterRating == 4)
    #expect(gate.stagedFeedback?.postCheckIn.valence == 0.4)
    #expect(try ModelContext(harness.container).fetch(FetchDescriptor<CachedCheckIn>()).isEmpty)

    gate.failUserCommit = false
    await controller.save(
      viewModel: viewModel, afterRating: 9,
      postValence: -0.7, postArousal: 0.8, hasPostPosition: true
    )

    #expect(controller.saveErrorMessage == nil)
    #expect(controller.hasSavedFeedback)
    #expect(viewModel.phase == .saved)
    #expect(postCallbacks == 1)
    #expect(harness.writer.states.count == 1)
    #expect(harness.writer.mindfulSessions.count == 1)
    #expect(diagnostics.events.filter { $0 == .practiceCompleted }.count == 1)
    #expect(deliveredRecord?.afterRating == 9)
    #expect(deliveredPost?.valence == -0.7)
    #expect(deliveredPost?.arousal == 0.8)
    #expect(try harness.store.latestRecord() == deliveredRecord)
    #expect(try harness.cache.latestRecord() == deliveredPost)
    #expect(harness.writer.states.first == deliveredPost)
    #expect(mainContext.hasChanges)
    #expect(try mainContext.fetch(FetchDescriptor<LocalDiagnosticEvent>()).contains { $0.id == unrelated.id })
    #expect(try ModelContext(harness.container).fetch(FetchDescriptor<LocalDiagnosticEvent>()).isEmpty)
  }

  @Test("Skipping after a failed feedback transaction leaves no partial post state")
  func skipAfterFailedTransactionHasNoPostState() async throws {
    let gate = FeedbackCommitGate()
    gate.failUserCommit = true
    let harness = try FeedbackHarness(commit: gate.commit)
    let viewModel = finishedViewModel(beforeRating: 8)
    let controller = PracticeCompletionSaveController(
      coordinator: harness.coordinator,
      diagnostics: FeedbackDiagnostics()
    ) { _, post in
      #expect(post == nil)
    }

    await controller.save(
      viewModel: viewModel, afterRating: 4,
      postValence: 0.4, postArousal: -0.6, hasPostPosition: true
    )
    await controller.skipFeedback(viewModel: viewModel)

    #expect(viewModel.phase == .saved)
    #expect(controller.saveErrorMessage == nil)
    #expect(!controller.hasSavedFeedback)
    #expect(try harness.cache.latestRecord() == nil)
    #expect(try harness.store.latestRecord()?.afterRating == nil)
    #expect(harness.writer.states.isEmpty)
  }

  @Test("A post-sync status failure leaves the committed feedback saved and home available")
  func feedbackStatusFailureDoesNotReopenEditing() async throws {
    let gate = FeedbackCommitGate()
    gate.failStatusCommit = true
    let harness = try FeedbackHarness(commit: gate.commit)
    let viewModel = finishedViewModel(beforeRating: 8)
    var deliveredRecord: PracticeCompletionRecord?
    var deliveredPost: StateOfMindRecord?
    let controller = PracticeCompletionSaveController(
      coordinator: harness.coordinator,
      diagnostics: FeedbackDiagnostics()
    ) { record, post in
      if let post {
        deliveredRecord = record
        deliveredPost = post
      }
    }

    await controller.save(
      viewModel: viewModel, afterRating: 4,
      postValence: 0.4, postArousal: -0.6, hasPostPosition: true
    )

    #expect(viewModel.phase == .saved)
    #expect(controller.hasSavedFeedback)
    #expect(controller.saveErrorMessage == nil)
    #expect(controller.healthWriteNeedsAttention)
    #expect(deliveredRecord?.afterRating == 4)
    #expect(deliveredPost?.valence == 0.4)
    #expect(try harness.store.latestRecord() == deliveredRecord)
    #expect(try harness.cache.latestRecord() == deliveredPost)
  }

  @Test("The legacy save entry also preserves feedback when only sync status fails")
  func legacySaveUsesTheSameLocalSuccessBoundary() async throws {
    let gate = FeedbackCommitGate()
    gate.failStatusCommit = true
    let harness = try FeedbackHarness(commit: gate.commit)
    let record = completion()

    let result = try await harness.coordinator.save(
      record, postValence: 0.5, postArousal: -0.6
    )

    #expect(result.healthStatusNeedsRetry)
    #expect(result.savedRecord == record)
    #expect(result.postCheckIn?.valence == 0.5)
    #expect(try harness.store.latestRecord() == record)
    #expect(try harness.cache.latestRecord() == result.postCheckIn)
    #expect(harness.writer.states.count == 1)
  }

  @Test("Skipping feedback saves completion without creating a check-in or a comparison")
  func skippedFeedbackHasNoPostState() async throws {
    let harness = try FeedbackHarness()
    let viewModel = finishedViewModel(beforeRating: 8)
    let diagnostics = FeedbackDiagnostics()
    var callbackCount = 0
    let controller = PracticeCompletionSaveController(
      coordinator: harness.coordinator,
      diagnostics: diagnostics
    ) { record, post in
      callbackCount += 1
      #expect(post == nil)
      #expect(!record.hasSubjectiveComparison)
    }

    await controller.saveCompletion(viewModel: viewModel)
    await controller.skipFeedback(viewModel: viewModel)

    #expect(viewModel.phase == .saved)
    #expect(!controller.hasSavedFeedback)
    #expect(callbackCount == 1)
    #expect(try harness.cache.latestRecord() == nil)
    #expect(harness.writer.states.isEmpty)
    #expect(harness.writer.mindfulSessions.count == 1)
    #expect(!diagnostics.events.contains(.subjectiveComparisonAvailable))
  }

  private func completion() -> PracticeCompletionRecord {
    let end = Date(timeIntervalSince1970: 1_788_000_060)
    return PracticeCompletionRecord(
      sessionID: "practice-feedback-local", practiceKind: .physiologicalSigh,
      plannedDuration: 60, actualDuration: 58,
      startedAt: end.addingTimeInterval(-58), endedAt: end,
      beforeRating: 8, afterRating: 4
    )
  }

  private func finishedViewModel(beforeRating: Int?) -> PracticeSessionViewModel {
    var now = Date(timeIntervalSince1970: 1_788_000_000)
    let viewModel = PracticeSessionViewModel(
      plan: PracticeCatalog.protocol(for: .physiologicalSigh)!, duration: 60,
      now: { now }
    )
    viewModel.start(beforeRating: beforeRating)
    now.addTimeInterval(58)
    viewModel.finish()
    return viewModel
  }
}

@MainActor
private struct FeedbackHarness {
  let container: ModelContainer
  let cache: CheckInCacheStore
  let store: PracticeCompletionStore
  let writer: FeedbackHealthWriter
  let healthWriter: HealthWriteCoordinator
  let coordinator: PracticeCompletionCoordinator

  init(commit: @escaping (ModelContext) throws -> Void = { try $0.save() }) throws {
    container = try ModelContainer(
      for: StoredPracticeCompletion.self, CachedCheckIn.self,
      PendingHealthWrite.self, LocalDiagnosticEvent.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    cache = CheckInCacheStore(modelContext: container.mainContext)
    store = PracticeCompletionStore(modelContext: container.mainContext)
    writer = FeedbackHealthWriter()
    healthWriter = HealthWriteCoordinator(writer: writer, modelContext: container.mainContext)
    coordinator = PracticeCompletionCoordinator(
      store: store,
      feedbackStore: PracticeFeedbackStore(modelContainer: container, commit: commit),
      healthWriter: healthWriter
    )
  }
}

@MainActor
private final class FeedbackHealthWriter: HealthWriting {
  var shouldFailStateWrite = false
  var onStateWrite: ((StateOfMindRecord) throws -> Void)?
  private(set) var states: [StateOfMindRecord] = []
  private(set) var mindfulSessions: [MindfulSessionRecord] = []

  func saveStateOfMind(_ record: StateOfMindRecord) async throws {
    try onStateWrite?(record)
    states.append(record)
    if shouldFailStateWrite { throw CocoaError(.fileWriteNoPermission) }
  }

  func saveMindfulSession(_ record: MindfulSessionRecord) async throws {
    mindfulSessions.append(record)
  }
}

@MainActor
private final class FeedbackCommitGate {
  var failUserCommit = false
  var failStatusCommit = false
  private(set) var stagedFeedback: PracticeFeedbackSnapshot?

  func commit(_ context: ModelContext) throws {
    let stored = try context.fetch(FetchDescriptor<StoredPracticeCompletion>()).first
    let cached = try context.fetch(FetchDescriptor<CachedCheckIn>()).first
    if let completion = stored?.snapshot, let cached {
      stagedFeedback = PracticeFeedbackSnapshot(
        completion: completion,
        postCheckIn: try JSONDecoder().decode(StateOfMindRecord.self, from: cached.payload)
      )
    }
    if stored?.postWriteResult == .failedToQueue ? failUserCommit : failStatusCommit {
      throw CocoaError(.fileWriteOutOfSpace)
    }
    try context.save()
  }
}

@MainActor
private final class FeedbackDiagnostics: LocalDiagnosticsRecording {
  private(set) var events: [LocalDiagnosticKind] = []

  func record(_ kind: LocalDiagnosticKind, at date: Date) {
    events.append(kind)
  }
}
