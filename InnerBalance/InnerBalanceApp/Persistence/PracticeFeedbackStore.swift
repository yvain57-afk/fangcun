import Foundation
import SwiftData

struct PracticeFeedbackSnapshot: Equatable, Sendable {
  let completion: PracticeCompletionSnapshot
  let postCheckIn: StateOfMindRecord
}

@MainActor
protocol PracticeFeedbackStoring: AnyObject {
  func saveFeedback(
    _ record: PracticeCompletionRecord,
    postCheckIn: StateOfMindRecord
  ) throws -> PracticeFeedbackSnapshot
  func updatePostWriteResult(sessionID: String, result: HealthWriteResult) throws
}

@MainActor
final class PracticeFeedbackStore: PracticeFeedbackStoring {
  private let modelContainer: ModelContainer
  private let commit: (ModelContext) throws -> Void

  init(
    modelContainer: ModelContainer,
    commit: @escaping (ModelContext) throws -> Void = { try $0.save() }
  ) {
    self.modelContainer = modelContainer
    self.commit = commit
  }

  func saveFeedback(
    _ record: PracticeCompletionRecord,
    postCheckIn: StateOfMindRecord
  ) throws -> PracticeFeedbackSnapshot {
    let context = makeContext()
    let sessionID = record.sessionID
    let completionQuery = FetchDescriptor<StoredPracticeCompletion>(
      predicate: #Predicate { $0.sessionID == sessionID }
    )
    guard let stored = try context.fetch(completionQuery).first,
      let completion = stored.snapshot
    else { throw PracticeCompletionSaveError.localPersistenceFailed }

    let syncIdentifier = postCheckIn.syncIdentifier
    let cacheQuery = FetchDescriptor<CachedCheckIn>(
      predicate: #Predicate { $0.syncIdentifier == syncIdentifier }
    )
    if let cached = try context.fetch(cacheQuery).first {
      return PracticeFeedbackSnapshot(
        completion: completion,
        postCheckIn: try JSONDecoder().decode(StateOfMindRecord.self, from: cached.payload)
      )
    }

    let payload = try JSONEncoder().encode(postCheckIn)
    context.insert(
      CachedCheckIn(
        syncIdentifier: postCheckIn.syncIdentifier,
        syncVersion: postCheckIn.syncVersion,
        date: postCheckIn.date,
        payload: payload
      )
    )
    stored.update(
      record: record,
      mindfulWriteResult: completion.mindfulWriteResult,
      postWriteResult: .failedToQueue
    )
    // Both user inputs share one commit; a failed attempt cannot become the home state.
    try commit(context)
    return PracticeFeedbackSnapshot(
      completion: PracticeCompletionSnapshot(
        record: record,
        mindfulWriteResult: completion.mindfulWriteResult,
        postWriteResult: .failedToQueue
      ),
      postCheckIn: postCheckIn
    )
  }

  func updatePostWriteResult(sessionID: String, result: HealthWriteResult) throws {
    let context = makeContext()
    let descriptor = FetchDescriptor<StoredPracticeCompletion>(
      predicate: #Predicate { $0.sessionID == sessionID }
    )
    guard let stored = try context.fetch(descriptor).first else {
      throw PracticeCompletionSaveError.localPersistenceFailed
    }
    stored.updateHealthWriteResults(
      mindfulWriteResult: stored.mindfulWriteResult,
      postWriteResult: result
    )
    try commit(context)
  }

  private func makeContext() -> ModelContext {
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false
    return context
  }
}
