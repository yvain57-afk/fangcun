import Foundation
import InnerBalanceCore
import Observation

@MainActor
@Observable
final class PracticeCompletionSaveController {
  private let coordinator: PracticeCompletionCoordinator
  private let diagnostics: any LocalDiagnosticsRecording
  private let onSaved: (PracticeCompletionRecord, StateOfMindRecord?) -> Void
  private let sessionID: String
  private var completionSaved = false
  private var completionDiagnosticRecorded = false

  private(set) var isSaving = false
  private(set) var healthWriteNeedsAttention = false
  private(set) var hasSavedFeedback = false
  var saveErrorMessage: String?

  init(
    coordinator: PracticeCompletionCoordinator,
    diagnostics: any LocalDiagnosticsRecording,
    sessionID: String = UUID().uuidString,
    onSaved: @escaping (PracticeCompletionRecord, StateOfMindRecord?) -> Void
  ) {
    self.coordinator = coordinator
    self.diagnostics = diagnostics
    self.sessionID = sessionID
    self.onSaved = onSaved
  }

  func saveCompletion(viewModel: PracticeSessionViewModel) async {
    guard !isSaving, !completionSaved,
      let record = viewModel.makeCompletion(sessionID: sessionID)
    else { return }

    isSaving = true
    saveErrorMessage = nil
    defer { isSaving = false }
    do {
      let outcome = try await coordinator.saveCompletion(record)
      acceptCompletion(record, outcome: outcome)
      if PracticeCompletionMode.for(viewModel.plan.kind) == .completionOnly {
        viewModel.markSaved()
      }
    } catch {
      saveErrorMessage = Self.localSaveError
    }
  }

  func save(
    viewModel: PracticeSessionViewModel,
    afterRating: Double,
    postValence: Double,
    postArousal: Double,
    hasPostPosition: Bool
  ) async {
    guard !isSaving else { return }
    let mode = PracticeCompletionMode.for(viewModel.plan.kind)
    guard mode == .subjectiveComparison, hasPostPosition,
      let record = viewModel.makeCompletion(
        afterRating: Int(afterRating.rounded()),
        sessionID: sessionID
      )
    else { return }

    isSaving = true
    saveErrorMessage = nil
    defer { isSaving = false }
    do {
      if !completionSaved,
        let initialRecord = viewModel.makeCompletion(sessionID: sessionID)
      {
        let initialOutcome = try await coordinator.saveCompletion(initialRecord)
        acceptCompletion(initialRecord, outcome: initialOutcome)
      }
      let outcome = try await coordinator.saveFeedback(
        record,
        postValence: postValence,
        postArousal: postArousal
      )
      healthWriteNeedsAttention = outcome.needsHealthAttention
      hasSavedFeedback = true
      let savedRecord = outcome.savedRecord ?? record
      if savedRecord.hasSubjectiveComparison {
        diagnostics.record(.subjectiveComparisonAvailable)
      }
      viewModel.markSaved()
      onSaved(savedRecord, outcome.postCheckIn)
    } catch {
      saveErrorMessage = Self.localSaveError
    }
  }

  func skipFeedback(viewModel: PracticeSessionViewModel) async {
    guard !isSaving else { return }
    isSaving = true
    saveErrorMessage = nil
    defer { isSaving = false }
    do {
      if !completionSaved,
        let record = viewModel.makeCompletion(sessionID: sessionID)
      {
        let outcome = try await coordinator.saveCompletion(record)
        acceptCompletion(record, outcome: outcome)
      }
      guard completionSaved else { return }
      viewModel.markSaved()
    } catch {
      saveErrorMessage = Self.localSaveError
    }
  }

  private func acceptCompletion(
    _ record: PracticeCompletionRecord,
    outcome: PracticeCompletionOutcome
  ) {
    completionSaved = true
    healthWriteNeedsAttention = outcome.needsHealthAttention
    if !completionDiagnosticRecorded {
      diagnostics.record(.practiceCompleted)
      completionDiagnosticRecorded = true
    }
    onSaved(outcome.savedRecord ?? record, nil)
  }

  private static let localSaveError =
    "本地存储失败，方寸没有把本次练习标记为已保存。请释放设备空间后重试。"
}
