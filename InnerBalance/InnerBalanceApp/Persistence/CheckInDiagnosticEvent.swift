import Foundation
import SwiftData

@Model
final class CheckInDiagnosticEvent {
  @Attribute(.unique) var id: UUID
  var startedAt: Date
  var completedAt: Date
  var duration: TimeInterval
  var unclassified: Bool

  init(
    id: UUID = UUID(),
    startedAt: Date,
    completedAt: Date,
    unclassified: Bool
  ) {
    self.id = id
    self.startedAt = startedAt
    self.completedAt = completedAt
    duration = max(0, completedAt.timeIntervalSince(startedAt))
    self.unclassified = unclassified
  }
}

@MainActor
protocol CheckInDiagnosticsRecording {
  func recordCompletion(startedAt: Date, completedAt: Date, unclassified: Bool)
  func recordStage(_ stage: CheckInDiagnosticStage, at date: Date)
}

enum CheckInDiagnosticStage: Sendable {
  case opened
  case compassCompleted
  case emotionWordSelected
  case optionalSupplementCompleted
}

extension CheckInDiagnosticsRecording {
  func recordStage(_ stage: CheckInDiagnosticStage, at date: Date) {}
}

@MainActor
final class SwiftDataCheckInDiagnosticsRecorder: CheckInDiagnosticsRecording {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func recordCompletion(startedAt: Date, completedAt: Date, unclassified: Bool) {
    modelContext.insert(
      CheckInDiagnosticEvent(
        startedAt: startedAt,
        completedAt: completedAt,
        unclassified: unclassified
      )
    )
    try? modelContext.save()
  }

  func recordStage(_ stage: CheckInDiagnosticStage, at date: Date) {
    let kind: LocalDiagnosticKind =
      switch stage {
      case .opened: .checkInOpened
      case .compassCompleted: .compassCompleted
      case .emotionWordSelected: .emotionWordSelected
      case .optionalSupplementCompleted: .optionalSupplementCompleted
      }
    modelContext.insert(LocalDiagnosticEvent(kind: kind, occurredAt: date))
    try? modelContext.save()
  }
}
