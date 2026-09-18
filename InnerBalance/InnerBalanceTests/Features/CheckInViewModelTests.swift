import Foundation
import InnerBalanceCore
import Testing

@testable import InnerBalance

@Suite("Two-step emotion check-in")
struct CheckInViewModelTests {
  @Test("没有选择位置时罗盘不显示默认中心点")
  func compassHasNoVisualPreset() {
    #expect(EmotionCompassPresentation.orbOpacity(hasSelectedPosition: false) == 0)
    #expect(EmotionCompassPresentation.orbOpacity(hasSelectedPosition: true) == 1)
  }

  @Test("罗盘只在用户确认落点时触发一次触觉")
  func compassHapticCommitsOnce() {
    #expect(!EmotionCompassPresentation.shouldPlayHaptic(for: .changing))
    #expect(EmotionCompassPresentation.shouldPlayHaptic(for: .committed))
  }

  @Test("情绪词淡入在减少动态效果时不使用缩放时长")
  func compassWordTransitionPolicy() {
    #expect(EmotionCompassPresentation.wordTransitionDuration(reduceMotion: false) == 0.32)
    #expect(EmotionCompassPresentation.wordTransitionDuration(reduceMotion: true) == 0)
  }

  @Test("罗盘坐标保持中心、方向与圆形边界")
  func compassCoordinates() {
    let center = CompassGeometry.coordinates(for: CGPoint(x: 100, y: 100), size: 200)
    #expect(center.valence == 0)
    #expect(center.arousal == 0)

    let upperLeft = CompassGeometry.coordinates(for: CGPoint(x: 50, y: 50), size: 200)
    #expect(upperLeft.valence < 0)
    #expect(upperLeft.arousal > 0)

    let touch = CGPoint(x: 80, y: 120)
    let touchCoordinates = CompassGeometry.coordinates(for: touch, size: 320)
    let renderedPosition = CompassGeometry.position(
      valence: touchCoordinates.valence,
      arousal: touchCoordinates.arousal,
      size: 320
    )
    #expect(abs(renderedPosition.x - touch.x) < 0.000_001)
    #expect(abs(renderedPosition.y - touch.y) < 0.000_001)

    let outside = CompassGeometry.coordinates(for: CGPoint(x: 1_000, y: -1_000), size: 200)
    #expect((-1.0...1.0).contains(outside.valence))
    #expect((-1.0...1.0).contains(outside.arousal))
    #expect(hypot(outside.valence, outside.arousal) <= 1.000_001)
  }

  @Test("Every compass position offers four to six labels without changing coordinates")
  @MainActor
  func neutralPositionHasEnoughSuggestions() {
    let viewModel = CheckInViewModel(
      saver: RecordingCheckInSaver(),
      diagnostics: RecordingCheckInDiagnostics()
    )
    viewModel.select(valence: 0.05, arousal: 0.05)

    #expect((4...6).contains(viewModel.suggestedLabels.count))
    #expect(viewModel.valence == 0.05)
    #expect(viewModel.arousal == 0.05)
  }

  @Test("Selecting a suggested word immediately saves the primary record")
  @MainActor
  func suggestedWordSavesImmediately() async {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let saver = RecordingCheckInSaver()
    let diagnostics = RecordingCheckInDiagnostics()
    let viewModel = CheckInViewModel(
      saver: saver,
      diagnostics: diagnostics,
      now: { now },
      makeIdentifier: { "check-in-test" }
    )
    viewModel.select(valence: -0.7, arousal: 0.8)
    viewModel.continueToWords()

    await viewModel.select(label: .anxious)

    #expect(viewModel.step == .saved)
    #expect(saver.records.count == 1)
    #expect(saver.records.first?.labels == [.anxious])
    #expect(saver.records.first?.valence == -0.7)
    #expect(saver.records.first?.arousal == 0.8)
    #expect(saver.records.first?.unclassified == false)
    #expect(diagnostics.completions.count == 1)
  }

  @Test("Unclassified saves the selected coordinates with no labels")
  @MainActor
  func unclassifiedStillSaves() async {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let saver = RecordingCheckInSaver()
    let viewModel = CheckInViewModel(
      saver: saver,
      diagnostics: RecordingCheckInDiagnostics(),
      now: { now },
      makeIdentifier: { "check-in-unclassified" }
    )
    viewModel.select(valence: 0.6, arousal: -0.7)
    viewModel.continueToWords()

    await viewModel.selectUnclassified()

    #expect(viewModel.step == .saved)
    #expect(saver.records.first?.labels.isEmpty == true)
    #expect(saver.records.first?.valence == 0.6)
    #expect(saver.records.first?.unclassified == true)
  }

  @Test("Optional context failure does not roll back the primary save")
  @MainActor
  func optionalFailureKeepsPrimarySaved() async {
    let saver = RecordingCheckInSaver(results: [.saved, .failedToQueue])
    let viewModel = CheckInViewModel(
      saver: saver,
      diagnostics: RecordingCheckInDiagnostics(),
      makeIdentifier: { "check-in-context" }
    )
    viewModel.select(valence: -0.5, arousal: -0.6)
    viewModel.continueToWords()
    await viewModel.select(label: .drained)

    await viewModel.saveOptionalContext(
      bodySensationCodes: ["fatigue"],
      associations: [.sleep, .work]
    )

    #expect(viewModel.step == .saved)
    #expect(viewModel.optionalContextFailed)
    #expect(saver.records.count == 2)
    #expect(saver.records.last?.syncVersion == 2)
    #expect(saver.records.last?.associations == [.sleep, .work])
  }

  @Test("Completion time is captured after the primary write finishes")
  @MainActor
  func completionIncludesPrimaryWriteTime() async throws {
    let startedAt = Date(timeIntervalSince1970: 1_786_320_000)
    let compassAt = startedAt.addingTimeInterval(3)
    let selectedAt = startedAt.addingTimeInterval(4)
    let savedAt = startedAt.addingTimeInterval(9)
    let clock = SequenceClock([startedAt, compassAt, selectedAt, savedAt])
    let diagnostics = RecordingCheckInDiagnostics()
    let viewModel = CheckInViewModel(
      saver: RecordingCheckInSaver(),
      diagnostics: diagnostics,
      now: { clock.now() },
      makeIdentifier: { "check-in-timing" }
    )
    viewModel.select(valence: -0.7, arousal: 0.8)
    viewModel.continueToWords()

    await viewModel.select(label: .anxious)

    let completion = try #require(diagnostics.completions.first)
    #expect(viewModel.savedRecord?.date == selectedAt)
    #expect(completion.completedAt == savedAt)
  }

  @Test("Hopeless check-ins expose static support guidance")
  @MainActor
  func hopelessCheckInShowsSupportGuidance() async {
    let viewModel = CheckInViewModel(
      saver: RecordingCheckInSaver(),
      diagnostics: RecordingCheckInDiagnostics()
    )
    viewModel.select(valence: -0.8, arousal: -0.7)
    viewModel.continueToWords()

    await viewModel.select(label: .hopeless)

    #expect(viewModel.showsSupportGuidance)
  }
}

@MainActor
private final class SequenceClock {
  private var dates: [Date]

  init(_ dates: [Date]) {
    self.dates = dates
  }

  func now() -> Date {
    dates.removeFirst()
  }
}

@MainActor
private final class RecordingCheckInSaver: CheckInSaving {
  private var results: [HealthWriteResult]
  private(set) var records: [StateOfMindRecord] = []

  init(results: [HealthWriteResult] = [.saved]) {
    self.results = results
  }

  func saveCheckIn(_ record: StateOfMindRecord) async -> HealthWriteResult {
    records.append(record)
    return results.isEmpty ? .saved : results.removeFirst()
  }
}

@MainActor
private final class RecordingCheckInDiagnostics: CheckInDiagnosticsRecording {
  private(set) var completions: [(startedAt: Date, completedAt: Date, unclassified: Bool)] = []

  func recordCompletion(startedAt: Date, completedAt: Date, unclassified: Bool) {
    completions.append((startedAt, completedAt, unclassified))
  }
}
