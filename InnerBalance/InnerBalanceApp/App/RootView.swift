import InnerBalanceCore
import SwiftData
import SwiftUI

struct LatestCheckInViewState: Equatable {
  let record: StateOfMindRecord?

  var date: Date? { record?.date }

  var title: String? {
    guard let record else { return nil }
    return record.labels.first?.displayName ?? "Saved · Without a label"
  }
}

struct RootView: View {
  private enum Tab: Hashable {
    case now
    case practice
  }

  @Environment(\.careOwner) private var care
  @Environment(\.phoneSync) private var sync
  @Environment(\.recoveryOwner) private var recovery
  @Environment(\.readinessOwner) private var readiness
  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  @State private var diary: FangcunDiary
  @State private var homeViewModel: HomeViewModel
  @State private var selectedTab = Tab.practice
  @State private var hubGeneration = 0
  @State private var showingUnfinishedPractice = false
  @State private var showingSettings = false
  @State private var showingRecords = false
  @State private var deferredCareRoute = false
  @State private var isShowingCheckIn = false
  @State private var latestCheckIn = LatestCheckInViewState(record: nil)
  @State private var latestStressContext: StateOfMindRecord?
  @State private var latestPractice: PracticeCompletionRecord?
  @State private var selectedPractice: PracticeLaunch?
  @State private var selectedPracticeWasRecommended = false
  private let authorizationCoordinator: HealthAuthorizationCoordinator
  private let healthRepository: HealthKitRepository?
  private let healthWriter: any HealthWriting
  private let isUITesting: Bool
  private let shouldFailPracticeSaveForUITesting: Bool

  init() {
    let arguments = ProcessInfo.processInfo.arguments
    #if DEBUG
    let isUITesting = arguments.contains("--ui-testing")
    #else
    let isUITesting = false
    #endif
    self.isUITesting = isUITesting
    _diary = State(initialValue: FangcunDiary(defaults: isUITesting ? UserDefaults(suiteName: "fangcun.ui." + UUID().uuidString)! : .standard))
    shouldFailPracticeSaveForUITesting = arguments.contains(
      "--ui-testing-practice-save-failure"
    )
    authorizationCoordinator = HealthAuthorizationCoordinator()

    #if DEBUG
      if isUITesting {
        let fixture = arguments.first { $0.hasPrefix("--health-fixture=") }
          .flatMap { HomeHealthFixture(rawValue: String($0.dropFirst("--health-fixture=".count))) }
        let service = UITestingHealthService(fixture: fixture)
        _homeViewModel = State(initialValue: HomeViewModel(provider: service,
          clock: { fixture == nil ? .now : HomeHealthFixture.now }))
        healthRepository = nil
        healthWriter = service
        return
      }
    #endif

    let repository = HealthKitRepository()
    _homeViewModel = State(initialValue: HomeViewModel(provider: repository))
    healthRepository = repository
    healthWriter = repository
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      PracticeLibraryView(onStart: { launch in
        guard selectedPractice == nil else { return }
        selectedPracticeWasRecommended = false
        requestPractice(launch)
      }, onRecords: { selectedTab = .now; showingRecords = true }, latestPractice: latestPractice)
      .id(hubGeneration)
      .tabItem { Label("Breathe", systemImage: "wind") }
      .tag(Tab.practice)

      FangcunTodayView(
        model: homeViewModel,
        authorization: authorizationCoordinator,
        latestPractice: latestPractice,
        isUITesting: isUITesting,
        onSettings: { showingSettings = true },
        onRecords: { showingRecords = true },
        onStart: {
          guard recovery?.canStart != false, selectedPractice == nil else { return }
          selectedPracticeWasRecommended = true
          requestPractice(PracticeLaunch(kind: .physiologicalSigh, duration: 300, startsImmediately: true))
        },
        onCheckIn: { isShowingCheckIn = true },
        onSuggestedPractice: { kind, duration in
          guard recovery?.canStart != false else { return }
          requestPractice(PracticeLaunch(kind: kind, duration: duration, startsImmediately: true))
        },
        hasOngoingPractice: selectedPractice != nil,
        recentFeeling: latestCheckIn.record
      )
      .tabItem { Label("Daily", systemImage: "sun.max") }
      .tag(Tab.now)


    }
    .alert("A practice is still open", isPresented: $showingUnfinishedPractice) {
      Button("Return to the open practice") {
        if let checkpoint = PracticeHubPreferences.resumableCheckpoint() {
          selectedPractice = .init(kind: checkpoint.kind, duration: checkpoint.duration,
            variantID: checkpoint.variantID, restoredCheckpoint: checkpoint)
        }
      }
      Button("Not now", role: .cancel) {}
    } message: {
      Text("Your practiced time is safe. Continue or finish the open practice before starting another.")
    }
    .sheet(isPresented: $showingSettings) {
      SettingsView(authorizationCoordinator: authorizationCoordinator, homeViewModel: homeViewModel,
        healthRepository: healthRepository, isUITesting: isUITesting, diagnosticsAvailable: Self.diagnosticsAvailable)
    }
    .sheet(isPresented: $showingRecords) {
      NavigationStack {
        PracticeRecordsView()
          .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingRecords = false }.accessibilityIdentifier("practice.history.done") } }
      }
    }
    .environment(diary)
    .tint(InnerBalanceTheme.strongFill)
    .fullScreenCover(isPresented: $isShowingCheckIn) {
      CheckInFlowView(
        saver: HealthWriteCoordinator(writer: healthWriter, modelContext: modelContext),
        diagnostics: SwiftDataCheckInDiagnosticsRecorder(modelContext: modelContext)
      ) { record in
        let cacheStore = CheckInCacheStore(modelContext: modelContext)
        try? cacheStore.upsert(record)
        latestCheckIn = LatestCheckInViewState(record: record)
        if !record.associations.isEmpty || !record.bodySensationCodes.isEmpty {
          latestStressContext = record
        }
      }
    }
    .fullScreenCover(item: $selectedPractice) { launch in
      PracticeSessionView(
        launch: launch,
        coordinator: PracticeCompletionCoordinator(
          store: makePracticeCompletionStore(),
          feedbackStore: PracticeFeedbackStore(modelContainer: modelContext.container),
          healthWriter: HealthWriteCoordinator(
            writer: healthWriter,
            modelContext: modelContext
          )
        ),
        diagnostics: SwiftDataLocalDiagnosticsRecorder(modelContext: modelContext),
        wasRecommended: selectedPracticeWasRecommended,
        onReturnToHome: { hubGeneration += 1; selectedTab = deferredCareRoute ? .now : .practice }
      ) { record, postCheckIn in
        latestPractice = record
        Task { await recovery?.importPractice(record) }
        readiness?.interventions.append(.init(start: record.startedAt, end: record.endedAt))
        if let postCheckIn {
          latestCheckIn = LatestCheckInViewState(record: postCheckIn)
        }
      }
    }
    .task {
      await refreshLocalState()
    }
    .task { care?.refresh(events: diary.allEntries.map(\.beverage)) }
    .onChange(of: care?.pendingRoute) { _, route in
      guard route != nil else { return }
      if selectedPractice != nil { deferredCareRoute = true }
      else { selectedTab = .now }
    }
    .onChange(of: selectedPractice) { _, launch in
      if launch == nil, deferredCareRoute { selectedTab = .now; deferredCareRoute = false }
    }
    .onChange(of: diary.allEntries) { _, _ in
      care?.refresh(events: diary.allEntries.map(\.beverage))
      if let recovery { Task { await sync?.publishRecords(diary: diary, recovery: recovery) } }
    }
    .onChange(of: recovery?.records) { _, _ in
      updateKnownIntervals()
      if let recovery { Task { await sync?.publishRecords(diary: diary, recovery: recovery) } }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { care?.foreground() }
      guard phase == .active else { return }
      Task { await refreshLocalState() }
    }
  }

  private func requestPractice(_ launch: PracticeLaunch) {
    guard selectedPractice == nil else { return }
    if launch.restoredCheckpoint == nil, PracticeHubPreferences.resumableCheckpoint() != nil {
      showingUnfinishedPractice = true
    } else { selectedPractice = launch }
  }

  private func refreshLocalState() async {
    await recovery?.load()
    let cacheStore = CheckInCacheStore(modelContext: modelContext)
    latestCheckIn = LatestCheckInViewState(record: try? cacheStore.latestRecord())
    latestStressContext = try? cacheStore.latestContextRecord()

    latestPractice = try? PracticeCompletionStore(modelContext: modelContext).latestRecord()
    if let records = try? modelContext.fetch(FetchDescriptor<StoredPracticeCompletion>()) {
      readiness?.interventions = records.map { .init(start: $0.startedAt, end: $0.endedAt) }
      for record in records { if let value = record.record { await recovery?.importPractice(value) } }
    }
    if let recovery, let readiness {
      await sync?.start(diary: diary, recovery: recovery, readiness: readiness, context: modelContext)
    }
    updateKnownIntervals()
    await readiness?.refresh()
    if let recovery { await sync?.publishRecords(diary: diary, recovery: recovery) }

    let writeCoordinator = HealthWriteCoordinator(
      writer: healthWriter,
      modelContext: modelContext
    )
    await writeCoordinator.retryPending()

    guard let healthRepository else { return }
    if readiness?.reading == true {
      let access = await authorizationCoordinator.status(for: .initialBodyStatus)
      if access.state != .notRequested, let records = try? await healthRepository.ownedMindfulSessionsForMerge(now: .now), readiness?.reading == true {
        for record in records { try? await recovery?.store?.mergeHealthSession(record) }
        await recovery?.load()
      }
    }
    let syncCoordinator = CheckInSyncCoordinator(
      repository: healthRepository,
      cacheStore: cacheStore
    )
    latestCheckIn = LatestCheckInViewState(record: await syncCoordinator.refresh())
    latestStressContext = try? cacheStore.latestContextRecord()
  }

  private func updateKnownIntervals() {
    let original = (try? modelContext.fetch(FetchDescriptor<StoredPracticeCompletion>())) ?? []
    var intervals = original.map { ReadinessInterval(start: $0.startedAt, end: $0.endedAt) }
    for record in recovery?.records ?? [] {
      if case .practice = record.action, let end = record.endedAt {
        let interval = ReadinessInterval(start: record.startedAt, end: end)
        if !intervals.contains(interval) { intervals.append(interval) }
      }
    }
    readiness?.interventions = intervals
  }
  private func startPractice(_ kind: PracticeKind) {
    guard let plan = PracticeCatalog.protocol(for: kind) else { return }
    selectedPracticeWasRecommended = true
    selectedPractice = PracticeLaunch(kind: kind, duration: plan.defaultDuration)
  }

  private func makePracticeCompletionStore() -> any PracticeCompletionStoring {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("--ui-testing-practice-save-failure-once") {
        return UITestingFailOncePracticeCompletionStore(store: PracticeCompletionStore(modelContext: modelContext))
      }
      if shouldFailPracticeSaveForUITesting {
        return UITestingFailingPracticeCompletionStore()
      }
    #endif
    return PracticeCompletionStore(modelContext: modelContext)
  }

  private static var diagnosticsAvailable: Bool {
    #if DEBUG
      let isDebug = true
    #else
      let isDebug = false
    #endif
    return DiagnosticsAvailability.isAvailable(
      isDebug: isDebug,
      receiptName: Bundle.main.appStoreReceiptURL?.lastPathComponent
    )
  }
}

#if DEBUG
  @MainActor
  private final class UITestingHealthService: BodyHealthDataProviding, HealthWriting {
    let fixture: HomeHealthFixture?
    init(fixture: HomeHealthFixture?) { self.fixture = fixture }
    func fetchBodyHealthData(now: Date) async -> BodyHealthDataSnapshot {
      fixture?.snapshot(now: now) ?? .empty(at: now)
    }

    func saveStateOfMind(_ record: StateOfMindRecord) async throws {}

    func saveMindfulSession(_ record: MindfulSessionRecord) async throws {}
  }

  @MainActor
  private final class UITestingFailingPracticeCompletionStore: PracticeCompletionStoring {
    func save(
      _ record: PracticeCompletionRecord,
      mindfulWriteResult: HealthWriteResult,
      postWriteResult: HealthWriteResult
    ) throws {
      throw UITestingPracticeSaveError.forcedFailure
    }

    func latestRecord() throws -> PracticeCompletionRecord? { nil }
  }

  @MainActor
  private final class UITestingFailOncePracticeCompletionStore: PracticeCompletionStoring {
    private let store: any PracticeCompletionStoring
    private var didFail = false
    init(store: any PracticeCompletionStoring) { self.store = store }
    func save(_ record: PracticeCompletionRecord, mindfulWriteResult: HealthWriteResult, postWriteResult: HealthWriteResult) throws {
      if !didFail { didFail = true; throw UITestingPracticeSaveError.forcedFailure }
      try store.save(record, mindfulWriteResult: mindfulWriteResult, postWriteResult: postWriteResult)
    }
    func latestRecord() throws -> PracticeCompletionRecord? { try store.latestRecord() }
  }

  private enum UITestingPracticeSaveError: Error {
    case forcedFailure
  }
#endif

#Preview {
  RootView()
    .modelContainer(
      for: [
        PendingHealthWrite.self,
        CheckInDiagnosticEvent.self,
        LocalDiagnosticEvent.self,
        CachedCheckIn.self,
        StoredPracticeCompletion.self,
        StoredDailyEcho.self,
      ],
      inMemory: true
    )
}
