import Foundation
import SwiftData

enum LocalDiagnosticKind: String, Codable, CaseIterable, Sendable {
  case checkInOpened
  case compassCompleted
  case emotionWordSelected
  case optionalSupplementCompleted
  case recommendationAccepted
  case practiceStarted
  case practiceCompleted
  case subjectiveComparisonAvailable
  case notificationScheduled
  case notificationResponded
  case syncError
}

@Model
final class LocalDiagnosticEvent {
  @Attribute(.unique) var id: UUID
  var kindRawValue: String
  var occurredAt: Date
  var categoryCode: String?

  init(
    id: UUID = UUID(),
    kind: LocalDiagnosticKind,
    occurredAt: Date = .now,
    categoryCode: String? = nil
  ) {
    self.id = id
    kindRawValue = kind.rawValue
    self.occurredAt = occurredAt
    self.categoryCode = categoryCode
  }

  var kind: LocalDiagnosticKind? {
    LocalDiagnosticKind(rawValue: kindRawValue)
  }
}

@MainActor
protocol LocalDiagnosticsRecording {
  func record(_ kind: LocalDiagnosticKind, at date: Date)
}

extension LocalDiagnosticsRecording {
  func record(_ kind: LocalDiagnosticKind) {
    record(kind, at: .now)
  }
}

@MainActor
final class SwiftDataLocalDiagnosticsRecorder: LocalDiagnosticsRecording {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func record(_ kind: LocalDiagnosticKind, at date: Date) {
    modelContext.insert(LocalDiagnosticEvent(kind: kind, occurredAt: date))
    try? modelContext.save()
  }
}
