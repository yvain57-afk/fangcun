import InnerBalanceCore
import SwiftData
import SwiftUI

enum HomeStressContextResolver {
  static func resolve(
    latestCheckIn: StateOfMindRecord?,
    latestContext: StateOfMindRecord?,
    now: Date,
    calendar: Calendar = .current
  ) -> StateOfMindRecord? {
    let sameDayContext = latestContext.flatMap {
      calendar.isDate($0.date, inSameDayAs: now) ? $0 : nil
    }
    guard let latestCheckIn,
      calendar.isDate(latestCheckIn.date, inSameDayAs: now)
    else {
      return sameDayContext
    }

    if !latestCheckIn.associations.isEmpty || !latestCheckIn.bodySensationCodes.isEmpty {
      return latestCheckIn
    }
    guard latestCheckIn.phase == .post,
      let sameDayContext,
      sameDayContext.date <= latestCheckIn.date
    else {
      return nil
    }
    return sameDayContext
  }
}

struct HomeView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  @State private var echo = HomeEchoController()
  @State private var authorization = HealthAuthorizationSnapshot(
    state: .notRequested,
    deniedWriteTypeIdentifiers: []
  )
  @State private var isRequestingAuthorization = false
  @State private var showSleepReview = false
  @State private var showEchoHistory = false
  @State private var hasEntered = false

  let viewModel: HomeViewModel
  let authorizationCoordinator: HealthAuthorizationCoordinator
  let latestCheckIn: StateOfMindRecord?
  let latestStressContext: StateOfMindRecord?
  let latestPractice: PracticeCompletionRecord?
  let isUITesting: Bool
  let onCheckIn: () -> Void
  let onStartPractice: (PracticeKind) -> Void

  var body: some View {
    let state = today
    NavigationStack {
      ZStack {
        InnerBalanceTheme.canvas.ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            FangcunHomeHeader(date: echo.currentDate)
              .fangcunEntrance(index: 0, isPresented: hasEntered)
            stateSelector(selection: state.selectedQuickState)
            pressureCard(state: state)
            if state.isStressIdentified {
              dailyWord(state: state)
            }

            if !isUITesting,
              authorization.state == .notRequested || authorization.state == .partial
            {
              HealthAuthorizationInvitation(isRequesting: isRequestingAuthorization) {
                Task { await requestAuthorization() }
              }
              .padding(.top, FangcunLayout.spacing(4))
            }

          }
          .padding(.horizontal, FangcunLayout.pageHorizontalPadding)
          .padding(.top, FangcunLayout.spacing(3))
          .padding(.bottom, FangcunLayout.spacing(6))
        }
        .refreshable { await refresh() }
      }
      .toolbar(.hidden, for: .navigationBar)
    }
    .onAppear {
      guard !hasEntered else { return }
      hasEntered = true
    }
    .task {
      echo.moveToCurrentDay(modelContext: modelContext)
      if !isUITesting {
        authorization = await authorizationCoordinator.status(for: .initialBodyStatus)
      }
      await viewModel.refresh()
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else { return }
      moveToCurrentDay()
    }
    .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
      moveToCurrentDay()
    }
    .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
      moveToCurrentDay()
    }
    .sheet(isPresented: $showSleepReview) {
      SleepReviewSheet(details: viewModel.sleepReviewDetails)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showEchoHistory) {
      EchoHistorySheet(records: echo.history)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
  }

  private func pressureCard(state: TodayViewState) -> some View {
    BodyLoadCard(
      viewModel: viewModel,
      today: state,
      onReviewSleep: { showSleepReview = true },
      onCheckIn: onCheckIn,
      onStartPractice: onStartPractice
    )
    .padding(.top, FangcunLayout.spacing(5))
    .fangcunEntrance(index: 2, isPresented: hasEntered)
  }

  private func stateSelector(selection: DailyEchoState?) -> some View {
    EchoArcSelector(
      selection: selection,
      historyAvailable: !echo.history.isEmpty,
      saveMessage: echo.saveMessage,
      onSelect: { echo.save(state: $0, modelContext: modelContext) },
      onShowHistory: { showEchoHistory = true }
    )
    .fangcunEntrance(index: 1, isPresented: hasEntered)
  }

  private func dailyWord(state: TodayViewState) -> some View {
    DailyWordField(
      reflection: state.reflection,
      contextTitle: state.reflectionContextTitle
    )
    .fangcunEntrance(index: 3, isPresented: hasEntered)
  }

  private var today: TodayViewState {
    let now = Date.now
    let activeCheckIn = latestCheckIn.flatMap {
      Calendar.current.isDate($0.date, inSameDayAs: now) ? $0 : nil
    }
    let context = HomeStressContextResolver.resolve(
      latestCheckIn: activeCheckIn,
      latestContext: latestStressContext,
      now: now
    )
    return TodayCoordinator().makeViewState(
      quick: echo.savedEcho.map {
        CurrentMomentQuickState(state: $0.state, recordedAt: $0.updatedAt)
      },
      detailed: activeCheckIn.map {
        CurrentMomentDetailedState(
          valence: $0.valence,
          arousal: $0.arousal,
          emotion: $0.labels.first,
          recordedAt: $0.date,
          stressSources: context?.associations.map(\.stressSource) ?? [],
          bodySensationCodes: context?.bodySensationCodes ?? []
        )
      },
      bodyContext: TodayBodyContext.resolve(
        accessState: authorization.state,
        isLoading: viewModel.isLoading,
        level: viewModel.assessment.level,
        hasReliableEvidence: BodyLoadCardPresentation.hasReliableEvidence(viewModel.evidence)
      ),
      bodyStressSource: contextStressSource(from: context)
        ?? BodyLoadCardPresentation.inferredStressSource(
          evidence: viewModel.evidence,
          recentWorkoutProtection: viewModel.recentWorkoutProtection
        ),
      latestPractice: latestPractice,
      now: now
    )
  }

  private func contextStressSource(from record: StateOfMindRecord?) -> CurrentStressSource? {
    if let association = record?.associations.first {
      return association.stressSource
    }
    let sensations = Set(record?.bodySensationCodes ?? [])
    if !sensations.isDisjoint(with: ["fatigue", "heavy_head"]) {
      return .lowEnergy
    }
    if !sensations.isDisjoint(
      with: ["shoulders_tight", "chest_tight", "stomach_discomfort", "shallow_breath"]
    ) {
      return .physicalTension
    }
    return nil
  }

  private func refresh() async {
    if !isUITesting {
      authorization = await authorizationCoordinator.status(for: .initialBodyStatus)
    }
    await viewModel.refresh()
    echo.load(modelContext: modelContext)
  }

  private func moveToCurrentDay() {
    echo.moveToCurrentDay(modelContext: modelContext)
    Task { await refresh() }
  }

  private func requestAuthorization() async {
    isRequestingAuthorization = true
    authorization = await authorizationCoordinator.request(.initialBodyStatus)
    await viewModel.refresh()
    isRequestingAuthorization = false
  }
}

private struct EchoHistorySheet: View {
  @Environment(\.dismiss) private var dismiss
  let records: [DailyEchoRecord]

  var body: some View {
    NavigationStack {
      Group {
        if records.isEmpty {
          ContentUnavailableView("还没有过去的状态", systemImage: "text.quote")
        } else {
          List(records) { record in
            VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
              Text(record.displayDay().formatted(.dateTime.year().month().day().weekday()))
                .font(.caption.weight(.semibold))
                .foregroundStyle(InnerBalanceTheme.strongFill)
              Text(record.reflectionText)
                .font(.system(.callout, design: .default))
                .foregroundStyle(InnerBalanceTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
              if let attribution = record.attribution {
                Text(
                  record.reflectionWork.map { "\(attribution) · \($0)" }
                    ?? attribution
                )
                .font(.caption2)
                .foregroundStyle(InnerBalanceTheme.mutedInk)
              }
              Label(record.state.title, systemImage: record.state.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(InnerBalanceTheme.strongFill)
              Divider()
              if !record.text.isEmpty {
                Text(record.text)
                  .font(.body)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
            .padding(.vertical, FangcunLayout.spacing(2))
          }
          .scrollContentBackground(.hidden)
        }
      }
      .background(InnerBalanceTheme.canvas)
      .navigationTitle("过去的状态")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("完成") { dismiss() }
        }
      }
    }
  }
}

private struct SleepReviewSheet: View {
  @Environment(\.dismiss) private var dismiss
  let details: SleepReviewDetails?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: FangcunLayout.spacing(5)) {
          Label("这次睡眠未参与判断", systemImage: "moon.zzz")
            .font(.title3.weight(.semibold))
          Text("睡眠阶段可能来自多个来源。方寸已经去除重叠并拆分午睡；如果主睡眠仍少于 2 小时或超过 12 小时，会标记为需要确认，而不会把它解释成身体负荷。")
            .font(.body)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
          if let details {
            VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
              detailRow("开始", details.startDate.formatted(date: .abbreviated, time: .shortened))
              detailRow("结束", details.endDate.formatted(date: .abbreviated, time: .shortened))
              detailRow("去重后睡眠", HomeViewModel.durationText(details.asleepDuration))
              detailRow("阶段样本", "\(details.sampleCount) 条")
              detailRow("来源", details.sourceNames.joined(separator: "、"))
              detailRow("Apple Watch", details.includesAppleWatch ? "包含" : "未识别到")
            }
            .padding(FangcunLayout.spacing(4))
            .fangcunLevelOneSurface(cornerRadius: FangcunSurface.compactCornerRadius)
          }
          Text("你可以在 Apple 健康中查看和修正睡眠记录，之后回到方寸下拉刷新。")
            .font(.subheadline)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        .padding(FangcunLayout.spacing(6))
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(InnerBalanceTheme.canvas.ignoresSafeArea())
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("知道了") { dismiss() }
        }
      }
    }
  }

  private func detailRow(_ label: String, _ value: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(label)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
      Spacer(minLength: FangcunLayout.spacing(4))
      Text(value)
        .multilineTextAlignment(.trailing)
    }
    .font(.subheadline)
  }
}
