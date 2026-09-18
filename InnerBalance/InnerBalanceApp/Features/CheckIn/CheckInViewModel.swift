import Foundation
import InnerBalanceCore
import Observation

enum CheckInStep: Equatable, Sendable {
  case compass
  case words
  case saved
}

enum CheckInSaveState: Equatable, Sendable {
  case idle
  case saving
  case saved
  case failed
}

@MainActor
protocol CheckInSaving {
  func saveCheckIn(_ record: StateOfMindRecord) async -> HealthWriteResult
}

extension HealthWriteCoordinator: CheckInSaving {
  func saveCheckIn(_ record: StateOfMindRecord) async -> HealthWriteResult {
    await saveStateOfMind(record)
  }
}

@MainActor
@Observable
final class CheckInViewModel {
  private let saver: any CheckInSaving
  private let diagnostics: any CheckInDiagnosticsRecording
  private let now: () -> Date
  private let makeIdentifier: () -> String
  private let startedAt: Date
  private var recordedCompassCompletion = false
  private var recordedEmotionWord = false
  private var recordedOptionalSupplement = false

  private(set) var step = CheckInStep.compass
  private(set) var hasSelectedPosition = false
  private(set) var saveState = CheckInSaveState.idle
  private(set) var savedRecord: StateOfMindRecord?
  private(set) var optionalContextFailed = false
  private(set) var primaryWriteResult: HealthWriteResult?
  var valence = 0.0
  var arousal = 0.0

  init(
    saver: any CheckInSaving,
    diagnostics: any CheckInDiagnosticsRecording,
    now: @escaping () -> Date = { .now },
    makeIdentifier: @escaping () -> String = { UUID().uuidString.lowercased() }
  ) {
    self.saver = saver
    self.diagnostics = diagnostics
    self.now = now
    self.makeIdentifier = makeIdentifier
    startedAt = now()
    diagnostics.recordStage(.opened, at: startedAt)
  }

  var suggestedLabels: [EmotionLabel] {
    let quadrant = EmotionCatalog.quadrant(valence: valence, arousal: arousal)
    if case .neutral = quadrant {
      return [.indifferent, .calm, .content, .worried, .drained, .surprised]
    }
    return Array(
      EmotionCatalog.labels(for: quadrant).prefix(6)
    )
  }

  var showsSupportGuidance: Bool {
    savedRecord?.labels.contains(.hopeless) == true
  }

  func select(valence: Double, arousal: Double) {
    self.valence = min(max(valence, -1), 1)
    self.arousal = min(max(arousal, -1), 1)
    hasSelectedPosition = true
  }

  func continueToWords() {
    guard hasSelectedPosition else { return }
    step = .words
    if !recordedCompassCompletion {
      recordedCompassCompletion = true
      diagnostics.recordStage(.compassCompleted, at: now())
    }
  }

  func returnToCompass() {
    guard saveState != .saving else { return }
    step = .compass
  }

  func select(label: EmotionLabel) async {
    await savePrimary(label: label, unclassified: false)
  }

  func selectUnclassified() async {
    await savePrimary(label: nil, unclassified: true)
  }

  func saveOptionalContext(
    bodySensationCodes: [String],
    associations: [CheckInAssociation]
  ) async {
    guard let primary = savedRecord else { return }
    optionalContextFailed = false
    let updated = StateOfMindRecord(
      syncIdentifier: primary.syncIdentifier,
      syncVersion: primary.syncVersion + 1,
      date: primary.date,
      valence: primary.valence,
      arousal: primary.arousal,
      labels: primary.labels,
      associations: Array(associations.prefix(2)),
      bodySensationCodes: Array(Set(bodySensationCodes)).sorted(),
      unclassified: primary.unclassified,
      origin: primary.origin,
      sessionID: primary.sessionID,
      phase: primary.phase
    )
    let result = await saver.saveCheckIn(updated)
    if result == .failedToQueue {
      optionalContextFailed = true
    } else {
      savedRecord = updated
      if !recordedOptionalSupplement,
        !bodySensationCodes.isEmpty || !associations.isEmpty
      {
        recordedOptionalSupplement = true
        diagnostics.recordStage(.optionalSupplementCompleted, at: now())
      }
    }
  }

  private func savePrimary(label: EmotionLabel?, unclassified: Bool) async {
    guard step == .words, saveState != .saving else { return }
    saveState = .saving
    let selectedAt = now()
    if label != nil, !recordedEmotionWord {
      recordedEmotionWord = true
      diagnostics.recordStage(.emotionWordSelected, at: selectedAt)
    }
    let record = StateOfMindRecord(
      syncIdentifier: "com.yvainair.innerbalance.checkin.\(makeIdentifier())",
      syncVersion: 1,
      date: selectedAt,
      valence: valence,
      arousal: arousal,
      labels: label.map { [$0] } ?? [],
      associations: [],
      bodySensationCodes: [],
      unclassified: unclassified,
      origin: .iPhone,
      sessionID: nil,
      phase: .standalone
    )
    let result = await saver.saveCheckIn(record)
    primaryWriteResult = result
    guard result != .failedToQueue else {
      saveState = .failed
      return
    }

    savedRecord = record
    saveState = .saved
    step = .saved
    let completedAt = now()
    diagnostics.recordCompletion(
      startedAt: startedAt,
      completedAt: completedAt,
      unclassified: unclassified
    )
  }
}
