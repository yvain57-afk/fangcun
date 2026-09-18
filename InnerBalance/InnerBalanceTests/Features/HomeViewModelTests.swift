import Foundation
import InnerBalanceCore
import Testing

@testable import InnerBalance

@Suite("Cold-start home")
struct HomeViewModelTests {
  @Test("压力来源只在同日且记录语义允许时沿用")
  func stressContextNeverLeaksIntoANewIndependentCheckIn() {
    let calendar = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_788_259_200)
    let work = stateRecord(
      date: now.addingTimeInterval(-3_600),
      associations: [.work]
    )
    let standalone = stateRecord(
      date: now.addingTimeInterval(-60),
      phase: .standalone
    )
    let postPractice = stateRecord(
      date: now.addingTimeInterval(-60),
      phase: .post
    )
    let yesterday = stateRecord(
      date: now.addingTimeInterval(-86_400),
      associations: [.family]
    )

    #expect(
      HomeStressContextResolver.resolve(
        latestCheckIn: standalone,
        latestContext: work,
        now: now,
        calendar: calendar
      ) == nil
    )
    #expect(
      HomeStressContextResolver.resolve(
        latestCheckIn: postPractice,
        latestContext: work,
        now: now,
        calendar: calendar
      ) == work
    )
    #expect(
      HomeStressContextResolver.resolve(
        latestCheckIn: nil,
        latestContext: yesterday,
        now: now,
        calendar: calendar
      ) == nil
    )
  }

  @Test("自动来源优先识别睡眠、训练和其他身体信号")
  func bodyStressSourceUsesConcreteEvidence() {
    let measuredAt = Date(timeIntervalSince1970: 1_786_320_000)
    let sleep = HomeHealthEvidence(
      kind: .sleep,
      valueText: "5 小时",
      sourceName: "Apple Watch",
      measuredAt: measuredAt,
      reliability: .reliable,
      deviation: .elevated
    )
    let hrv = HomeHealthEvidence(
      kind: .heartRateVariability,
      valueText: "24 ms",
      sourceName: "Apple Watch",
      measuredAt: measuredAt,
      reliability: .reliable,
      deviation: .elevated
    )

    #expect(
      BodyLoadCardPresentation.inferredStressSource(
        evidence: [sleep, hrv],
        recentWorkoutProtection: true
      ) == .sleep
    )
    #expect(
      BodyLoadCardPresentation.inferredStressSource(
        evidence: [hrv],
        recentWorkoutProtection: true
      ) == .training
    )
    #expect(
      BodyLoadCardPresentation.inferredStressSource(
        evidence: [hrv],
        recentWorkoutProtection: false
      ) == .bodySignals
    )
    #expect(
      BodyLoadCardPresentation.inferredStressSource(
        evidence: [],
        recentWorkoutProtection: false
      ) == nil
    )
  }

  @Test("没有可靠身体证据时仍给出明确且保守的日程动作")
  func steadyWithoutCurrentEvidenceKeepsTheDayOnCourse() {
    #expect(
      BodyLoadCardPresentation.actionTitle(for: .steady, evidence: []) == "照常安排"
    )
    #expect(!BodyLoadCardPresentation.hasReliableEvidence([]))
  }

  @Test("Evidence that only needs review cannot produce a steady display")
  func reviewOnlyEvidenceIsUnavailable() {
    let evidence = HomeHealthEvidence(
      kind: .sleep,
      valueText: "13 小时",
      sourceName: "Apple Watch",
      measuredAt: Date(timeIntervalSince1970: 1_786_320_000),
      reliability: .needsReview,
      deviation: .withinRange
    )

    #expect(
      BodyLoadCardPresentation.actionTitle(for: .steady, evidence: [evidence])
        == "照常安排"
    )
    #expect(!BodyLoadCardPresentation.hasReliableEvidence([evidence]))
  }

  @Test("Workout-sensitive deviations are shown as protected after recent training")
  func recentWorkoutProtectsTrainingSensitiveDeviations() {
    let evidence = HomeHealthEvidence(
      kind: .heartRateVariability,
      valueText: "24 ms",
      sourceName: "Apple Watch",
      measuredAt: Date(timeIntervalSince1970: 1_786_320_000),
      reliability: .reliable,
      deviation: .elevated
    )

    #expect(
      BodyLoadCardPresentation.isWorkoutProtected(
        level: .steady,
        recentWorkoutProtection: true,
        evidence: [evidence]
      )
    )
    #expect(
      BodyLoadCardPresentation.actionTitle(
        for: .steady,
        evidence: [evidence],
        recentWorkoutProtection: true
      ) == "训练后先恢复"
    )
  }

  @Test("Recent training never hides an independent sleep deviation")
  func recentWorkoutKeepsIndependentSleepConclusion() {
    let measuredAt = Date(timeIntervalSince1970: 1_786_320_000)
    let evidence = [
      HomeHealthEvidence(
        kind: .heartRateVariability,
        valueText: "24 ms",
        sourceName: "Apple Watch",
        measuredAt: measuredAt,
        reliability: .reliable,
        deviation: .elevated
      ),
      HomeHealthEvidence(
        kind: .sleep,
        valueText: "5 小时 20 分",
        sourceName: "Apple Watch",
        measuredAt: measuredAt,
        reliability: .reliable,
        deviation: .elevated
      ),
    ]

    #expect(
      !BodyLoadCardPresentation.isWorkoutProtected(
        level: .watch,
        recentWorkoutProtection: true,
        evidence: evidence
      )
    )
    #expect(
      BodyLoadCardPresentation.actionTitle(
        for: .watch,
        evidence: evidence,
        recentWorkoutProtection: true
      ) == "今天收着一点"
    )
  }

  @Test("两项独立可靠异常会给出优先恢复的行动结论")
  func elevatedLoadPrioritizesRecovery() {
    let evidence = [
      HomeHealthEvidence(
        kind: .sleep,
        valueText: "5 小时",
        sourceName: "Apple Watch",
        measuredAt: .now,
        reliability: .reliable,
        deviation: .elevated
      ),
      HomeHealthEvidence(
        kind: .respiratoryRate,
        valueText: "19 次/分",
        sourceName: "Apple Watch",
        measuredAt: .now,
        reliability: .reliable,
        deviation: .elevated
      ),
    ]

    #expect(
      BodyLoadCardPresentation.actionTitle(for: .elevated, evidence: evidence)
        == "优先恢复"
    )
  }

  @Test("重叠刷新只让最新请求更新数据和结束读取状态", arguments: [true, false])
  @MainActor
  func overlappingRefreshesKeepTheNewestRequest(olderFinishesFirst: Bool) async {
    let olderDate = Date(timeIntervalSince1970: 1_786_320_000)
    let newerDate = olderDate.addingTimeInterval(60)
    let source = HealthSourceDescriptor(
      name: "Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let newerSnapshot = BodyHealthDataSnapshot(
      heartRateVariability: [HealthQuantityRecord(value: 52, date: newerDate, source: source)],
      restingHeartRate: [],
      sleep: [],
      workouts: [],
      unavailableKinds: [.sleep],
      fetchedAt: newerDate
    )
    let provider = ControlledBodyHealthProvider()
    let viewModel = HomeViewModel(provider: provider)
    let olderRequest = Task { await viewModel.refresh(now: olderDate) }
    await provider.waitForRequest(at: olderDate)
    let newerRequest = Task { await viewModel.refresh(now: newerDate) }
    await provider.waitForRequest(at: newerDate)

    #expect(viewModel.isLoading)
    if olderFinishesFirst {
      provider.completeRequest(at: olderDate, with: .empty(at: olderDate))
      await olderRequest.value

      #expect(viewModel.isLoading)
      #expect(viewModel.lastUpdated == nil)
      #expect(viewModel.evidence.isEmpty)
    }

    provider.completeRequest(at: newerDate, with: newerSnapshot)
    await newerRequest.value

    #expect(!viewModel.isLoading)
    #expect(viewModel.lastUpdated == newerDate)
    #expect(viewModel.evidence.first?.valueText == "52 ms")
    #expect(viewModel.unavailableKinds == [.sleep])

    if !olderFinishesFirst {
      provider.completeRequest(at: olderDate, with: .empty(at: olderDate))
      await olderRequest.value

      #expect(!viewModel.isLoading)
      #expect(viewModel.lastUpdated == newerDate)
      #expect(viewModel.evidence.first?.valueText == "52 ms")
      #expect(viewModel.unavailableKinds == [.sleep])
    }
  }

  @Test("Day zero still shows raw Watch readings without inferring deviation")
  @MainActor
  func dayZeroShowsRawReadings() async {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let source = HealthSourceDescriptor(
      name: "Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: [HealthQuantityRecord(value: 52, date: now, source: source)],
      restingHeartRate: [HealthQuantityRecord(value: 61, date: now, source: source)],
      sleep: [],
      workouts: [],
      unavailableKinds: [],
      fetchedAt: now
    )
    let viewModel = HomeViewModel(provider: StubBodyHealthProvider(snapshot: snapshot))

    await viewModel.refresh(now: now)

    #expect(viewModel.baselineDays == 0)
    #expect(viewModel.evidence.count == 2)
    #expect(viewModel.evidence.allSatisfy { $0.reliability == .buildingBaseline })
    #expect(viewModel.evidence.allSatisfy { $0.deviation == .withinRange })
  }

  @Test("Home displays the newest Watch reading with its own measurement time")
  @MainActor
  func homeUsesNewestReadingInsteadOfMedian() async throws {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let source = HealthSourceDescriptor(
      name: "Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let latestDate = now.addingTimeInterval(-300)
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: [
        HealthQuantityRecord(value: 42, date: now.addingTimeInterval(-1_800), source: source),
        HealthQuantityRecord(value: 64, date: latestDate, source: source),
      ],
      restingHeartRate: [],
      sleep: [],
      workouts: [],
      unavailableKinds: [],
      fetchedAt: now
    )
    let viewModel = HomeViewModel(provider: StubBodyHealthProvider(snapshot: snapshot))

    await viewModel.refresh(now: now)

    let hrv = try #require(viewModel.evidence.first(where: { $0.kind == .heartRateVariability }))
    #expect(hrv.valueText == "64 ms")
    #expect(hrv.measuredAt == latestDate)
    #expect(hrv.assessmentValueText == "近 36 小时中位数 53 ms · 来源 Apple Watch")
  }

  @Test("超过当前评估窗口的 Watch 最新读数仍显示真实测量时间")
  @MainActor
  func latestWatchReadingRemainsVisibleOutsideAssessmentWindow() async throws {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let source = HealthSourceDescriptor(
      name: "杨迦易的 Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let measuredAt = now.addingTimeInterval(-37 * 3_600)
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: [
        HealthQuantityRecord(value: 58, date: measuredAt, source: source)
      ],
      restingHeartRate: [],
      sleep: [],
      workouts: [],
      unavailableKinds: [],
      fetchedAt: now
    )
    let viewModel = HomeViewModel(provider: StubBodyHealthProvider(snapshot: snapshot))

    await viewModel.refresh(now: now)

    let hrv = try #require(viewModel.evidence.first(where: { $0.kind == .heartRateVariability }))
    #expect(hrv.valueText == "58 ms")
    #expect(hrv.measuredAt == measuredAt)
    #expect(hrv.sourceName == "杨迦易的 Apple Watch")
    #expect(hrv.reliability == .stale)
    #expect(hrv.assessmentValueText == nil)
  }

  @Test("同时间的混合来源不会把 Watch 数值配上第三方来源")
  @MainActor
  func latestReadingPreservesItsOriginalSourceIdentity() async throws {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let thirdParty = HealthSourceDescriptor(
      name: "第三方 App",
      bundleIdentifier: "example.third-party",
      isAppleWatch: false
    )
    let watch = HealthSourceDescriptor(
      name: "杨迦易的 Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: [
        HealthQuantityRecord(value: 99, date: now, source: thirdParty),
        HealthQuantityRecord(value: 47, date: now, source: watch),
      ],
      restingHeartRate: [],
      sleep: [],
      workouts: [],
      unavailableKinds: [],
      fetchedAt: now
    )
    let viewModel = HomeViewModel(provider: StubBodyHealthProvider(snapshot: snapshot))

    await viewModel.refresh(now: now)

    let hrv = try #require(viewModel.evidence.first(where: { $0.kind == .heartRateVariability }))
    #expect(hrv.valueText == "47 ms")
    #expect(hrv.sourceName == "杨迦易的 Apple Watch")
  }

  @Test("旧 Watch 读数不会与当前第三方读数混成可靠结论")
  @MainActor
  func oldWatchReadingDoesNotMixWithCurrentThirdPartyAssessment() async throws {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let watch = HealthSourceDescriptor(
      name: "Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let thirdParty = HealthSourceDescriptor(
      name: "第三方 App",
      bundleIdentifier: "example.third-party",
      isAppleWatch: false
    )
    let watchBaseline = (2...6).map { day in
      HealthQuantityRecord(
        value: 60,
        date: now.addingTimeInterval(-Double(day) * 86_400),
        source: watch
      )
    }
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: watchBaseline + [
        HealthQuantityRecord(value: 48, date: now.addingTimeInterval(-37 * 3_600), source: watch),
        HealthQuantityRecord(value: 80, date: now.addingTimeInterval(-300), source: thirdParty),
      ],
      restingHeartRate: [],
      sleep: [],
      workouts: [],
      unavailableKinds: [],
      fetchedAt: now
    )
    let viewModel = HomeViewModel(provider: StubBodyHealthProvider(snapshot: snapshot))

    await viewModel.refresh(now: now)

    let hrv = try #require(viewModel.evidence.first(where: { $0.kind == .heartRateVariability }))
    #expect(hrv.valueText == "48 ms")
    #expect(hrv.sourceName == "Apple Watch")
    #expect(hrv.reliability == .buildingBaseline)
    #expect(hrv.assessmentValueText == "近 36 小时中位数 80 ms · 来源 第三方 App")
  }

  @Test("Four baseline days show progress and raw evidence without an elevated conclusion")
  @MainActor
  func fourDaysStayInBaselineBuilding() async {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let source = HealthSourceDescriptor(
      name: "Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let priorDays = (1...4).map { day in
      now.addingTimeInterval(-Double(day) * 86_400)
    }
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: priorDays.map {
        HealthQuantityRecord(value: 60, date: $0, source: source)
      } + [HealthQuantityRecord(value: 30, date: now, source: source)],
      restingHeartRate: priorDays.map {
        HealthQuantityRecord(value: 60, date: $0, source: source)
      } + [HealthQuantityRecord(value: 78, date: now, source: source)],
      sleep: [],
      workouts: [],
      unavailableKinds: [],
      fetchedAt: now
    )
    let viewModel = HomeViewModel(provider: StubBodyHealthProvider(snapshot: snapshot))

    await viewModel.refresh(now: now)

    #expect(viewModel.baselineDays == 4)
    #expect(viewModel.assessment.level == .buildingBaseline)
    #expect(viewModel.assessment.elevatedEvidenceIDs.isEmpty)
    #expect(viewModel.evidence.filter { $0.deviation == .elevated }.count == 2)
    #expect(viewModel.evidence.allSatisfy { $0.sourceName == "Apple Watch" })
  }

  @Test("An implausibly long main sleep is marked for confirmation and excluded")
  @MainActor
  func abnormalSleepNeedsReview() async {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let source = HealthSourceDescriptor(
      name: "Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let sleep = HealthSleepRecord(
      startDate: now.addingTimeInterval(-14 * 3_600),
      endDate: now.addingTimeInterval(-3_600),
      source: source
    )
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: [],
      restingHeartRate: [],
      sleep: [sleep],
      workouts: [],
      unavailableKinds: [],
      fetchedAt: now
    )
    let viewModel = HomeViewModel(provider: StubBodyHealthProvider(snapshot: snapshot))

    await viewModel.refresh(now: now)

    #expect(viewModel.sleepNeedsReview)
    #expect(viewModel.evidence.first(where: { $0.kind == .sleep })?.reliability == .needsReview)
    #expect(viewModel.assessment.elevatedEvidenceIDs.contains("sleep") == false)
    #expect(viewModel.sleepReviewDetails?.startDate == sleep.startDate)
    #expect(viewModel.sleepReviewDetails?.endDate == sleep.endDate)
    #expect(viewModel.sleepReviewDetails?.sampleCount == 1)
    #expect(viewModel.sleepReviewDetails?.sourceNames == ["Apple Watch"])
    #expect(viewModel.sleepReviewDetails?.includesAppleWatch == true)
  }

  @Test("身体来信汇总近二十四小时训练并保留最近一次类型和来源")
  @MainActor
  func recentTrainingCreatesAVisibleSummary() async throws {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let watch = HealthSourceDescriptor(
      name: "杨迦易的 Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let workouts = [
      HealthWorkoutRecord(
        startDate: now.addingTimeInterval(-3_900),
        endDate: now.addingTimeInterval(-300),
        duration: 3_600,
        source: watch,
        activityName: "户外跑步"
      ),
      HealthWorkoutRecord(
        startDate: now.addingTimeInterval(-12 * 3_600),
        endDate: now.addingTimeInterval(-11.5 * 3_600),
        duration: 1_800,
        source: watch,
        activityName: "力量训练"
      ),
      HealthWorkoutRecord(
        startDate: now.addingTimeInterval(-31 * 3_600),
        endDate: now.addingTimeInterval(-30 * 3_600),
        duration: 3_600,
        source: watch,
        activityName: "步行"
      ),
    ]
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: [],
      restingHeartRate: [],
      sleep: [],
      workouts: workouts,
      unavailableKinds: [],
      fetchedAt: now
    )
    let viewModel = HomeViewModel(provider: StubBodyHealthProvider(snapshot: snapshot))

    await viewModel.refresh(now: now)

    let summary = try #require(viewModel.trainingSummary)
    #expect(summary.count == 2)
    #expect(summary.totalDuration == 5_400)
    #expect(summary.latestActivityName == "户外跑步")
    #expect(summary.latestSourceName == "杨迦易的 Apple Watch")
    #expect(summary.latestEndDate == now.addingTimeInterval(-300))
  }

  @Test("同一训练被 Watch 和第三方重复记录时只计算一次并优先 Watch")
  @MainActor
  func mirroredTrainingIsDeduplicated() async throws {
    let now = Date(timeIntervalSince1970: 1_786_320_000)
    let watch = HealthSourceDescriptor(
      name: "Apple Watch",
      bundleIdentifier: "com.apple.health",
      isAppleWatch: true
    )
    let thirdParty = HealthSourceDescriptor(
      name: "训练 App",
      bundleIdentifier: "com.example.training",
      isAppleWatch: false
    )
    let workouts = [
      HealthWorkoutRecord(
        startDate: now.addingTimeInterval(-3_900),
        endDate: now.addingTimeInterval(-300),
        duration: 3_600,
        source: thirdParty,
        activityName: "跑步"
      ),
      HealthWorkoutRecord(
        startDate: now.addingTimeInterval(-3_890),
        endDate: now.addingTimeInterval(-290),
        duration: 3_600,
        source: watch,
        activityName: "跑步"
      ),
    ]
    let snapshot = BodyHealthDataSnapshot(
      heartRateVariability: [],
      restingHeartRate: [],
      sleep: [],
      workouts: workouts,
      unavailableKinds: [],
      fetchedAt: now
    )
    let viewModel = HomeViewModel(provider: StubBodyHealthProvider(snapshot: snapshot))

    await viewModel.refresh(now: now)

    let summary = try #require(viewModel.trainingSummary)
    #expect(summary.count == 1)
    #expect(summary.totalDuration == 3_600)
    #expect(summary.latestSourceName == "Apple Watch")
  }

  @Test("训练摘要用可扫读的次数和总时长呈现")
  func trainingSummaryHasAReadableHeadline() {
    let summary = HomeTrainingSummary(
      count: 2,
      totalDuration: 5_400,
      latestActivityName: "户外跑步",
      latestDuration: 3_600,
      latestEndDate: Date(timeIntervalSince1970: 1_786_320_000),
      latestSourceName: "Apple Watch"
    )

    #expect(BodyLoadCardPresentation.trainingHeadline(summary) == "近 24 小时 · 2 次 · 1 小时 30 分")
  }

  @Test("空训练查询只说明未读到记录")
  func emptyTrainingCopyDoesNotClaimThereWasNoWorkout() {
    #expect(BodyLoadCardPresentation.emptyTrainingMessage == "近 24 小时未读到训练记录")
  }

  @Test("今日推荐和练习结果只使用当前自然日记录")
  func todayRecordsOnlyIncludeTheCurrentLocalDay() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3_600)!
    let now = Date(timeIntervalSince1970: 1_786_320_000)

    #expect(
      TodayRecordPresentation.includes(
        eventDate: now.addingTimeInterval(-60),
        now: now,
        calendar: calendar
      )
    )
    #expect(
      TodayRecordPresentation.includes(
        eventDate: calendar.startOfDay(for: now).addingTimeInterval(-60),
        now: now,
        calendar: calendar
      ) == false
    )
  }
}

private func stateRecord(
  date: Date,
  associations: [CheckInAssociation] = [],
  phase: HealthRecordPhase = .standalone
) -> StateOfMindRecord {
  StateOfMindRecord(
    syncIdentifier: UUID().uuidString,
    syncVersion: 1,
    date: date,
    valence: 0,
    arousal: 0,
    labels: [],
    associations: associations,
    bodySensationCodes: [],
    unclassified: true,
    origin: .iPhone,
    sessionID: phase == .post ? UUID().uuidString : nil,
    phase: phase
  )
}

@MainActor
private struct StubBodyHealthProvider: BodyHealthDataProviding {
  let snapshot: BodyHealthDataSnapshot

  func fetchBodyHealthData(now: Date) async -> BodyHealthDataSnapshot {
    snapshot
  }
}

@MainActor
private final class ControlledBodyHealthProvider: BodyHealthDataProviding {
  private var requests: [Date: CheckedContinuation<BodyHealthDataSnapshot, Never>] = [:]
  private var requestWaiters: [Date: CheckedContinuation<Void, Never>] = [:]

  func fetchBodyHealthData(now: Date) async -> BodyHealthDataSnapshot {
    await withCheckedContinuation { continuation in
      requests[now] = continuation
      requestWaiters.removeValue(forKey: now)?.resume()
    }
  }

  func waitForRequest(at date: Date) async {
    if requests[date] != nil { return }
    await withCheckedContinuation { continuation in
      requestWaiters[date] = continuation
    }
  }

  func completeRequest(at date: Date, with snapshot: BodyHealthDataSnapshot) {
    let continuation = requests.removeValue(forKey: date)
    precondition(continuation != nil, "The test must wait for a request before completing it")
    continuation?.resume(returning: snapshot)
  }
}
