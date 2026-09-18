import Foundation
import InnerBalanceCore
import SwiftData
import Testing

@testable import InnerBalance

@Suite("Fangcun response loop")
struct FangcunResponseLoopTests {
  @Test("Quick then detailed makes the detailed check-in the only current state")
  func quickThenDetailedUsesDetailedState() {
    let detailed = CurrentMomentDetailedState(
      valence: -0.8,
      arousal: 0.8,
      emotion: .anxious,
      recordedAt: date(hour: 11)
    )

    let state = coordinator.makeViewState(
      quick: CurrentMomentQuickState(state: .calm, recordedAt: date(hour: 10)),
      detailed: detailed,
      bodyContext: .steady,
      latestPractice: nil,
      now: date(hour: 12)
    )

    #expect(state.currentSource == .detailed(detailed))
    #expect(state.currentStateTitle == "焦虑")
    #expect(state.selectedQuickState == nil)
    #expect(state.isStressIdentified)
    #expect(state.stressProfile == CurrentStressProfile(level: .high, source: .physicalTension))
    #expect(state.stressLevelTitle == "压力较高")
    #expect(state.stressSourceRoleTitle == "主要表现")
    #expect(state.stressSourceTitle == "身体持续紧绷")
    #expect(state.recommendedPractice == .physiologicalSigh)
    #expect(
      state.reflection
        == DailyReflectionSelector.reflection(
          on: date(hour: 12),
          stressProfile: state.stressProfile,
          calendar: calendar
        )
    )
  }

  @Test("Detailed then quick makes the quick state current again")
  func detailedThenQuickUsesQuickState() {
    let state = coordinator.makeViewState(
      quick: CurrentMomentQuickState(state: .calm, recordedAt: date(hour: 11)),
      detailed: CurrentMomentDetailedState(
        valence: -0.8,
        arousal: 0.8,
        emotion: .anxious,
        recordedAt: date(hour: 10)
      ),
      bodyContext: .steady,
      latestPractice: nil,
      now: date(hour: 12)
    )

    #expect(state.currentSource == .quick(.calm))
    #expect(state.currentStateTitle == "平静")
    #expect(state.selectedQuickState == .calm)
    #expect(state.isStressIdentified)
    #expect(state.stressProfile == CurrentStressProfile(level: .low, source: .none))
    #expect(state.stressSourceTitle == "没有明显来源")
    #expect(state.recommendedPractice == nil)
    #expect(state.recoveryAction == .continueNormally)
    #expect(
      state.reflection
        == DailyReflectionSelector.reflection(on: date(hour: 12), echo: .calm, calendar: calendar)
    )
  }

  @Test("2026 年每天六种快捷状态都呈现不同的一句，包括 9 月 8 日")
  func quickStateReflectionsStayDistinctThroughoutTheYear() throws {
    let firstDay = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))
    )
    for dayOffset in 0..<365 {
      let day = try #require(calendar.date(byAdding: .day, value: dayOffset, to: firstDay))
      let reflections = DailyEchoState.allCases.map { quickState in
        let state = coordinator.makeViewState(
          quick: CurrentMomentQuickState(state: quickState, recordedAt: day),
          detailed: nil,
          bodyContext: .steady,
          latestPractice: nil,
          now: day
        )
        #expect(
          state.reflection == DailyReflectionSelector.reflection(
            on: day, echo: quickState, calendar: calendar
          )
        )
        return state.reflection
      }

      #expect(
        Set(reflections.map(\.id)).count == DailyEchoState.allCases.count,
        "Quick-state reflection IDs repeated on day offset \(dayOffset)"
      )
      #expect(
        Set(reflections.map(\.text)).count == DailyEchoState.allCases.count,
        "Quick-state reflection text repeated on day offset \(dayOffset)"
      )
    }
  }

  @Test("快捷状态附带明确来源时仍按来源选择回应句")
  func quickStateWithExplicitSourceKeepsTheTargetedReflection() {
    let state = coordinator.makeViewState(
      quick: CurrentMomentQuickState(state: .tense, recordedAt: date(hour: 11)),
      detailed: nil,
      bodyContext: .steady,
      bodyStressSource: .work,
      latestPractice: nil,
      now: date(hour: 12)
    )

    #expect(state.stressProfile == CurrentStressProfile(level: .high, source: .work))
    #expect(state.reflectionContextTitle == "给「工作」的一句")
    #expect(
      state.reflection == DailyReflectionSelector.reflection(
        on: date(hour: 12), stressProfile: state.stressProfile, calendar: calendar
      )
    )
  }

  @Test("The same persisted inputs rebuild the same response after relaunch")
  func relaunchRebuildsTheSameResponse() {
    let quick = CurrentMomentQuickState(state: .tired, recordedAt: date(hour: 9))
    let detailed = CurrentMomentDetailedState(
      valence: 0.5,
      arousal: -0.5,
      emotion: .peaceful,
      recordedAt: date(hour: 10)
    )

    let first = coordinator.makeViewState(
      quick: quick,
      detailed: detailed,
      bodyContext: .watch,
      latestPractice: nil,
      now: date(hour: 12)
    )
    let relaunched = coordinator.makeViewState(
      quick: quick,
      detailed: detailed,
      bodyContext: .watch,
      latestPractice: nil,
      now: date(hour: 12)
    )

    #expect(relaunched == first)
    #expect(relaunched.ruleVersion == "fangcun-stress-response-v2")
  }

  @Test("读取中、无权限和数据不足不会被伪装成低压力")
  func uncertainBodyContextsAskForOneLowEffortInput() {
    let contexts: [TodayBodyContext] = [
      .loading, .unavailable, .buildingBaseline, .insufficientEvidence,
    ]
    for context in contexts {
      let state = coordinator.makeViewState(
        quick: nil,
        detailed: nil,
        bodyContext: context,
        latestPractice: nil,
        now: date(hour: 12)
      )

      #expect(!state.isStressIdentified)
      #expect(state.stressLevelTitle == "还没判断")
      #expect(state.stressSourceTitle == "来源待确认")
      #expect(state.recommendedPractice == nil)
      #expect(state.recoveryAction == .needsInput)
      #expect(state.explanation == "选一下现在的状态，我马上给你结论。")
      #expect(!state.explanation.contains("数据"))
      #expect(!state.explanation.contains("参考"))
    }
  }

  @Test("用户已明确选择时，压力等级不被传感器改写")
  func selfReportKeepsItsStressLevel() {
    let quick = CurrentMomentQuickState(state: .calm, recordedAt: date(hour: 11))
    let steady = coordinator.makeViewState(
      quick: quick,
      detailed: nil,
      bodyContext: .steady,
      latestPractice: nil,
      now: date(hour: 12)
    )
    let elevated = coordinator.makeViewState(
      quick: quick,
      detailed: nil,
      bodyContext: .elevated,
      latestPractice: nil,
      now: date(hour: 12)
    )

    #expect(steady.stressProfile.level == .low)
    #expect(elevated.stressProfile.level == .low)
    #expect(steady.recommendedPractice == nil)
    #expect(elevated.recommendedPractice == nil)
    #expect(steady.recoveryAction == .continueNormally)
    #expect(elevated.recoveryAction == .continueNormally)
    #expect(elevated.explanation == "现在状态稳，照常往下走。")
  }

  @Test("低压时各来源的说明和行动一致，不增加练习任务", arguments: CurrentStressSource.allCases)
  func lowStressWithSourceContinuesNormally(source: CurrentStressSource) {
    let state = coordinator.makeViewState(
      quick: nil,
      detailed: CurrentMomentDetailedState(
        valence: 0.8,
        arousal: -0.8,
        emotion: .peaceful,
        recordedAt: date(hour: 11),
        stressSources: [source]
      ),
      bodyContext: .steady,
      latestPractice: nil,
      now: date(hour: 12)
    )

    #expect(state.stressProfile == CurrentStressProfile(level: .low, source: source))
    #expect(state.recommendedPractice == nil)
    #expect(state.recoveryAction == .continueNormally)
    #expect(state.explanation == "现在状态稳，照常往下走。")
  }

  @Test("一个压力档案同时驱动来源、名言和练习")
  func oneProfileDrivesTheWholeResponse() {
    let state = coordinator.makeViewState(
      quick: nil,
      detailed: CurrentMomentDetailedState(
        valence: -0.8,
        arousal: 0.8,
        emotion: .anxious,
        recordedAt: date(hour: 11),
        stressSources: [.work],
        bodySensationCodes: []
      ),
      bodyContext: .elevated,
      bodyStressSource: .sleep,
      latestPractice: nil,
      now: date(hour: 12)
    )

    #expect(state.stressProfile == CurrentStressProfile(level: .high, source: .work))
    #expect(state.stressSourceRoleTitle == "主要来自")
    #expect(state.stressSourceTitle == "工作")
    #expect(state.recommendedPractice == .physiologicalSigh)
    #expect(state.reflectionContextTitle == "给「工作」的一句")
    #expect(
      state.reflection
        == DailyReflectionSelector.reflection(
          on: date(hour: 12),
          stressProfile: state.stressProfile,
          calendar: calendar
        )
    )
    #expect(!state.explanation.contains(state.recommendedPractice?.title ?? ""))
  }

  @Test("Only today's latest completion is assembled into the response")
  func onlyTodaysCompletionIsIncluded() {
    let completion = PracticeCompletionRecord(
      sessionID: "today-session",
      practiceKind: .pacedBreathing,
      plannedDuration: 180,
      actualDuration: 175,
      startedAt: date(hour: 11),
      endedAt: date(hour: 11, minute: 3),
      beforeRating: 7,
      afterRating: 4
    )

    let today = coordinator.makeViewState(
      quick: nil,
      detailed: nil,
      bodyContext: .buildingBaseline,
      latestPractice: completion,
      now: date(hour: 12)
    )
    let tomorrow = coordinator.makeViewState(
      quick: nil,
      detailed: nil,
      bodyContext: .buildingBaseline,
      latestPractice: completion,
      now: date(day: 30, hour: 12)
    )

    #expect(today.latestPractice == completion)
    #expect(tomorrow.latestPractice == nil)
  }

  @Test("Finishing without feedback saves locally, writes one Mindful Session and no post state")
  @MainActor
  func completionIsSavedBeforeOptionalFeedback() async throws {
    let harness = try completionHarness()
    let record = completionRecord(sessionID: "completion-first")

    let outcome = try await harness.coordinator.saveCompletion(record)

    #expect(outcome.mindfulWriteResult == .saved)
    #expect(outcome.postWriteResult == nil)
    #expect(harness.writer.mindfulSessions.count == 1)
    #expect(harness.writer.stateOfMindRecords.isEmpty)
    #expect(try harness.store.latestRecord() == record)
  }

  @Test("Saving completion repeatedly keeps one row and one Mindful Session")
  @MainActor
  func repeatedCompletionIsIdempotent() async throws {
    let harness = try completionHarness()
    let record = completionRecord(sessionID: "completion-idempotent")

    _ = try await harness.coordinator.saveCompletion(record)
    _ = try await harness.coordinator.saveCompletion(record)

    let stored = try harness.container.mainContext.fetch(
      FetchDescriptor<StoredPracticeCompletion>())
    #expect(stored.count == 1)
    #expect(stored.first?.sessionID == record.sessionID)
    #expect(harness.writer.mindfulSessions.count == 1)
  }

  @Test("Feedback updates the same session without writing another Mindful Session")
  @MainActor
  func feedbackUpdatesTheExistingCompletion() async throws {
    let harness = try completionHarness()
    let completion = completionRecord(sessionID: "feedback-same-session")
    let feedback = completionRecord(
      sessionID: completion.sessionID,
      beforeRating: 8,
      afterRating: 4
    )

    _ = try await harness.coordinator.saveCompletion(completion)
    let outcome = try await harness.coordinator.saveFeedback(
      feedback,
      postValence: 0.4,
      postArousal: -0.6
    )

    let stored = try harness.container.mainContext.fetch(
      FetchDescriptor<StoredPracticeCompletion>())
    #expect(stored.count == 1)
    #expect(try harness.store.latestRecord() == feedback)
    #expect(outcome.mindfulWriteResult == .saved)
    #expect(outcome.postWriteResult == .saved)
    #expect(harness.writer.mindfulSessions.count == 1)
    #expect(harness.writer.stateOfMindRecords.count == 1)
  }

  @Test("A skipped response has no invented before or after comparison")
  func skippedFeedbackHasNoSubjectiveDifference() {
    let record = completionRecord(sessionID: "feedback-skipped")

    #expect(record.beforeRating == nil)
    #expect(record.afterRating == nil)
    #expect(record.hasSubjectiveComparison == false)
  }

  @Test("The unselected starting default is not treated as user input")
  @MainActor
  func unselectedStartingValueStaysAbsent() throws {
    let clock = FangcunTestClock(
      values: [
        Date(timeIntervalSince1970: 1_788_000_000),
        Date(timeIntervalSince1970: 1_788_000_030),
      ])
    let viewModel = PracticeSessionViewModel(
      plan: PracticeCatalog.protocol(for: .physiologicalSigh)!,
      duration: 60,
      now: { clock.next() }
    )

    viewModel.start(beforeRating: nil)
    viewModel.finish()
    let record = try #require(viewModel.makeCompletion(sessionID: "no-default-rating"))

    #expect(record.beforeRating == nil)
    #expect(record.afterRating == nil)
    #expect(record.hasSubjectiveComparison == false)
  }

  @Test("Post feedback can be kept without inventing a missing pre-practice comparison")
  @MainActor
  func postStateDoesNotTurnTheDefaultIntoAComparison() async throws {
    let harness = try completionHarness()
    let completion = completionRecord(sessionID: "post-without-pre")

    _ = try await harness.coordinator.saveCompletion(completion)
    _ = try await harness.coordinator.saveFeedback(
      completion,
      postValence: 0.7,
      postArousal: -0.7
    )

    let latestRecord = try harness.store.latestRecord()
    let restored = try #require(latestRecord)
    #expect(restored.hasSubjectiveComparison == false)
    #expect(restored.beforeRating == nil)
    #expect(restored.afterRating == nil)
    #expect(harness.writer.stateOfMindRecords.count == 1)
    #expect(harness.writer.mindfulSessions.count == 1)
  }

  private var coordinator: TodayCoordinator {
    TodayCoordinator(calendar: calendar)
  }

  private var calendar: Calendar {
    var value = Calendar(identifier: .gregorian)
    value.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return value
  }

  private func date(day: Int = 29, hour: Int, minute: Int = 0) -> Date {
    calendar.date(
      from: DateComponents(
        year: 2026,
        month: 8,
        day: day,
        hour: hour,
        minute: minute
      )
    )!
  }

  @MainActor
  private func completionHarness() throws -> FangcunCompletionHarness {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: StoredPracticeCompletion.self, PendingHealthWrite.self, CachedCheckIn.self,
      configurations: configuration
    )
    let writer = FangcunRecordingHealthWriter()
    let store = PracticeCompletionStore(modelContext: container.mainContext)
    return FangcunCompletionHarness(
      container: container,
      store: store,
      writer: writer,
      coordinator: PracticeCompletionCoordinator(
        store: store,
        feedbackStore: PracticeFeedbackStore(modelContainer: container),
        healthWriter: HealthWriteCoordinator(
          writer: writer,
          modelContext: container.mainContext
        )
      )
    )
  }

  private func completionRecord(
    sessionID: String,
    beforeRating: Int? = nil,
    afterRating: Int? = nil
  ) -> PracticeCompletionRecord {
    let endedAt = Date(timeIntervalSince1970: 1_788_000_060)
    return PracticeCompletionRecord(
      sessionID: sessionID,
      practiceKind: .physiologicalSigh,
      plannedDuration: 60,
      actualDuration: 58,
      startedAt: endedAt.addingTimeInterval(-58),
      endedAt: endedAt,
      beforeRating: beforeRating,
      afterRating: afterRating
    )
  }
}

@MainActor
private struct FangcunCompletionHarness {
  let container: ModelContainer
  let store: PracticeCompletionStore
  let writer: FangcunRecordingHealthWriter
  let coordinator: PracticeCompletionCoordinator
}

@MainActor
private final class FangcunRecordingHealthWriter: HealthWriting {
  private(set) var mindfulSessions: [MindfulSessionRecord] = []
  private(set) var stateOfMindRecords: [StateOfMindRecord] = []

  func saveStateOfMind(_ record: StateOfMindRecord) async throws {
    stateOfMindRecords.append(record)
  }

  func saveMindfulSession(_ record: MindfulSessionRecord) async throws {
    mindfulSessions.append(record)
  }
}

private final class FangcunTestClock: @unchecked Sendable {
  private var values: [Date]

  init(values: [Date]) {
    self.values = values
  }

  func next() -> Date {
    values.removeFirst()
  }
}
