import InnerBalanceCore
import SwiftData
import SwiftUI

struct LatestCheckInViewState: Equatable {
  let record: StateOfMindRecord?

  var date: Date? { record?.date }

  var title: String? {
    guard let record else { return nil }
    return record.labels.first?.displayName ?? "已记录 · 未分类"
  }
}

struct RootView: View {
  private enum Tab: Hashable {
    case now
    case practice
    case settings
  }

  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  @State private var diary: FangcunDiary
  @State private var homeViewModel: HomeViewModel
  @State private var selectedTab = Tab.now
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
    let isUITesting = arguments.contains("--ui-testing")
    self.isUITesting = isUITesting
    _diary = State(initialValue: FangcunDiary(defaults: isUITesting ? UserDefaults(suiteName: "fangcun.ui." + UUID().uuidString)! : .standard))
    shouldFailPracticeSaveForUITesting = arguments.contains(
      "--ui-testing-practice-save-failure"
    )
    authorizationCoordinator = HealthAuthorizationCoordinator()

    #if DEBUG
      if isUITesting {
        let service = UITestingHealthService()
        _homeViewModel = State(initialValue: HomeViewModel(provider: service))
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
      FangcunTodayView(
        model: homeViewModel,
        authorization: authorizationCoordinator,
        latestPractice: latestPractice,
        isUITesting: isUITesting,
        onStart: {
          selectedPracticeWasRecommended = true
          selectedPractice = PracticeLaunch(kind: .physiologicalSigh, duration: 300, startsImmediately: true)
        },
        onCheckIn: { isShowingCheckIn = true }
      )
      .tabItem { Label("今日", systemImage: "house") }
      .tag(Tab.now)

      PracticeLibraryView(onStart: {
        selectedPracticeWasRecommended = false
        selectedPractice = $0
      })
      .tabItem {
        Label("练习", systemImage: "wind")
      }
      .tag(Tab.practice)

      SettingsView(
        authorizationCoordinator: authorizationCoordinator,
        homeViewModel: homeViewModel,
        healthRepository: healthRepository,
        isUITesting: isUITesting,
        diagnosticsAvailable: Self.diagnosticsAvailable
      )
      .tabItem {
        Label("设置", systemImage: "gearshape.fill")
      }
      .tag(Tab.settings)
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
        onReturnToHome: { selectedTab = .now }
      ) { record, postCheckIn in
        latestPractice = record
        if let postCheckIn {
          latestCheckIn = LatestCheckInViewState(record: postCheckIn)
        }
      }
    }
    .task {
      await refreshLocalState()
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else { return }
      Task { await refreshLocalState() }
    }
  }

  private func refreshLocalState() async {
    let cacheStore = CheckInCacheStore(modelContext: modelContext)
    latestCheckIn = LatestCheckInViewState(record: try? cacheStore.latestRecord())
    latestStressContext = try? cacheStore.latestContextRecord()

    latestPractice = try? PracticeCompletionStore(modelContext: modelContext).latestRecord()

    let writeCoordinator = HealthWriteCoordinator(
      writer: healthWriter,
      modelContext: modelContext
    )
    await writeCoordinator.retryPending()

    guard let healthRepository else { return }
    let syncCoordinator = CheckInSyncCoordinator(
      repository: healthRepository,
      cacheStore: cacheStore
    )
    latestCheckIn = LatestCheckInViewState(record: await syncCoordinator.refresh())
    latestStressContext = try? cacheStore.latestContextRecord()
  }

  private func startPractice(_ kind: PracticeKind) {
    guard let plan = PracticeCatalog.protocol(for: kind) else { return }
    selectedPracticeWasRecommended = true
    selectedPractice = PracticeLaunch(kind: kind, duration: plan.defaultDuration)
  }

  private func makePracticeCompletionStore() -> any PracticeCompletionStoring {
    #if DEBUG
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
    func fetchBodyHealthData(now: Date) async -> BodyHealthDataSnapshot {
      .empty(at: now)
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
