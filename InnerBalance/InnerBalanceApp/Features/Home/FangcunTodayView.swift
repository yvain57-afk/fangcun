import InnerBalanceCore
import SwiftUI

struct FangcunTodayView: View {
  let model: HomeViewModel
  let authorization: HealthAuthorizationCoordinator
  let latestPractice: PracticeCompletionRecord?
  let isUITesting: Bool
  let onStart: () -> Void
  let onCheckIn: () -> Void
  var onSuggestedPractice: (PracticeKind, TimeInterval) -> Void = { _, _ in }
  var hasOngoingPractice = false
  var recentFeeling: StateOfMindRecord?
  @Environment(\.careOwner) private var care
  @Environment(\.recoveryOwner) private var recovery
  @Environment(\.readinessOwner) private var readiness
  @Environment(FangcunDiary.self) private var diary
  @Environment(\.scenePhase) private var phase
  @Environment(\.dynamicTypeSize) private var typeSize
  @AppStorage("fangcun.dark") private var dark = false
  @AppStorage("fangcun.largeType") private var largeType = false
  @State private var drinks = false
  @State private var askingHealth = false
  @State private var localAction: StatusLocalLaunch?
  @State private var safety = false
  @State private var manualSleep = false
  @State private var choosing = false
  @State private var goal = RecoveryGoal.rest
  @AppStorage("status-v3.avoidBreathing") private var avoidBreathing = false
  @AppStorage("status-v3.favorite") private var favorite = "breath"
  private var status: DailyStatusSnapshot? { readiness?.statusScore }
  private var statusNow: Date { readiness?.now ?? .now }
  private var isNight: Bool {
    if let care, care.preferences.sleepPlanConfirmed {
      return care.preferences.sleepCycles(now: statusNow, calendar: .current).contains { statusNow >= $0.start.addingTimeInterval(-90*60) && statusNow < $0.end }
    }
    return Calendar.current.component(.hour, from: statusNow) >= 22 || Calendar.current.component(.hour, from: statusNow) < 6
  }
  private var primaryAction: StatusPrimaryAction {
    if hasOngoingPractice || localAction != nil { return .resume }
    if care?.selection?.candidate.category == .danger { return .safety }
    if readiness?.enabled == false || readiness?.reading == false { return .resumeReading }
    if status == nil { return readiness?.connected == false ? .connect : .sync }
    return StatusPresentationPolicy.action(score: status, night: isNight,
      driving: recovery?.environment == .driving || recovery?.environment == .unavailable,
      avoidBreathing: avoidBreathing || recovery?.uncomfortable.contains(.practice(.physiologicalSigh)) == true,
      tense: goal == .calm, avoidRest: recovery?.uncomfortable.contains(.quietRest) == true, favoriteBreathing: favorite == "breath")
  }

  private var state: FangcunDayState {
    if let readiness, readiness.enabled { return readiness.scene }
    #if DEBUG
    if isUITesting, let flag = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--preview-state=") }),
      let value = FangcunDayState(rawValue: String(flag.dropFirst("--preview-state=".count))) { return value }
    #endif
    return FangcunDayState.resolve(model)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          header
          HStack {
            Text(statusNow, format: .dateTime.month().day().weekday(.wide)).font(.caption)
            Spacer()
            if status != nil && readiness?.errorKey != nil {
              Button("重试同步") { Task { await readiness?.refresh() } }.font(.caption).accessibilityIdentifier("status.refresh")
            } else { Text(readiness?.loading == true ? "正在更新" : "方寸状态分").font(.caption2) }
          }.foregroundStyle(InnerBalanceTheme.mutedInk)
          hero
          Button(action: startPrimary) {
            HStack(spacing: 14) {
              Image(systemName: "wind").font(.title2)
              VStack(alignment: .leading, spacing: 5) {
                Text(primaryAction == .sync && readiness?.errorKey != nil ? "重试同步" : primaryAction.title).font(.headline)
              }
              Spacer(minLength: 0)
              Image(systemName: "arrow.up.right")
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 18)
          }.buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("today.start")
            .disabled(primaryAction == .unavailable || askingHealth)
          if status == nil, readiness?.enabled == true, readiness?.reading == true {
            Button("补记一次睡眠") { manualSleep = true }.font(.subheadline).accessibilityIdentifier("status.manual")
          }
          if let status {
            NavigationLink { DailyStatusDetailView(score: status, onStart: startPrimary, actionTitle: primaryAction.title, lastQueryAt: readiness?.snapshot.lastRefreshAttemptAt) } label: {
              VStack(alignment: .leading, spacing: 12) {
                ForEach(status.components, id: \.name) { part in
                  HStack { Text(DailyStatusPresentation.componentName(part.name)); Spacer(); Text("\(Int(part.score.rounded())) 分").monospacedDigit() }.font(.subheadline)
                }
                HStack { Text("看看分数构成"); Spacer(); Image(systemName: "chevron.right") }.font(.caption)
              }.fangcunPaperCard()
            }.buttonStyle(.plain).accessibilityIdentifier("today.evidence")
          }
          VStack(alignment: .leading, spacing: 12) {
          Button { drinks = true } label: {
            HStack(spacing: 14) {
              Image(systemName: "drop").font(.title2).foregroundStyle(InnerBalanceTheme.strongFill)
              VStack(alignment: .leading, spacing: 5) {
                Text("今天喝了什么？").font(.headline)
                Text(diary.entries().isEmpty ? "水、咖啡，或是别的什么" : "已记 \(diary.entries().count) 杯 · 已记录饮品 \(FangcunDrinkTotals(diary.entries()).fluid) ml")
                  .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
              }
              Spacer(minLength: 0)
              Image(systemName: "plus").frame(width: 34, height: 34).background(InnerBalanceTheme.subtleFill, in: Circle())
            }.fangcunPaperCard()
          }.buttonStyle(.plain).accessibilityIdentifier("today.drinks")
          if let care { BeverageCareCard(owner: care).padding(.horizontal, 12) }
          }
          if let latestPractice, Calendar.current.isDateInToday(latestPractice.endedAt) {
            Label("今天，已经为自己留了片刻。", systemImage: "checkmark.circle")
              .accessibilityIdentifier("today.latestPractice")
              .accessibilityValue(latestPractice.sessionID)
              .font(.subheadline).foregroundStyle(InnerBalanceTheme.strongFill)
          }
          NavigationLink { if let readiness, readiness.enabled { DailyStatusHistoryView(owner: readiness) } else { FangcunTrendsView() } } label: {
            HStack { Text("看看这一周的节奏"); Spacer(); Image(systemName: "arrow.right") }.font(.subheadline).padding(.vertical, 10)
          }.accessibilityIdentifier("today.trends")
          if let recentFeeling, Calendar.current.isDateInToday(recentFeeling.date) {
            Text("你最近记录：" + (recentFeeling.labels.first?.displayName ?? (recentFeeling.phase == .post ? PostPracticeFeelingNames.title(valence:recentFeeling.valence,arousal:recentFeeling.arousal) : nil) ?? "未分类的感受")
              + (recentFeeling.associations.isEmpty ? "" : " · " + recentFeeling.associations.map(\.displayName).joined(separator:"、")))
              .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
              .accessibilityIdentifier("today.feeling").accessibilityValue(recentFeeling.syncIdentifier)
          }
          Button("想补充一下自己的感受") { onCheckIn() }
            .accessibilityIdentifier("home.checkIn")
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk).frame(minHeight: 44)
          Text("不必把每一天，都过得很用力。")
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk).padding(.bottom, 18)
        }.padding(.horizontal, 20).padding(.top, 14)
          .accessibilityHidden(hasOngoingPractice || localAction != nil)
      }
      .background(InnerBalanceTheme.canvas)
      .foregroundStyle(InnerBalanceTheme.ink)
      .toolbar(.hidden, for: .navigationBar)
      .refreshable { await refresh() }
      .onChange(of: care?.pendingRoute, initial: true) { _, route in
        if route == "record" { drinks = true; care?.pendingRoute = nil }
      }
      .sheet(isPresented: $manualSleep) { if let readiness { ManualStatusSleepView(owner:readiness) } }
      .sheet(isPresented: $choosing) { actionChoices }
      .sheet(isPresented: $drinks) { FangcunDrinkSheet() }
      .fullScreenCover(item: $localAction) { launch in
        if let recovery, let plan = RecoveryProtocol.local(launch.action) { RecoverySessionView(owner: recovery, plan: plan, environment: recovery.environment) }
      }
      .sheet(isPresented: $safety) {
        VStack(spacing: 20) { Text("请立即寻求身边人的帮助或联系当地急救。不要独处或驾车。").font(.title3); Button("关闭") { safety = false } }.padding(24)
      }

    }
    .task {
      if readiness?.enabled != true { await refresh() }
      while !Task.isCancelled {
        readiness?.tick()
        try? await Task.sleep(for: .seconds(1))
      }
    }
    .onChange(of: phase) { _, value in if value == .active, readiness?.enabled != true { Task { await refresh() } } }
    .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in Task { await refresh() } }
  }

  private var header: some View {
    HStack {
      HStack(spacing: 10) {
        FangcunBrandMark(size: 34)
        VStack(alignment: .leading, spacing: 2) {
          // The wordmark and toolbar symbols are artwork; page text follows Dynamic Type.
          Text("方寸").font(.system(size: 20, weight: .semibold)).tracking(2)
          Text("FANGCUN").font(.system(size: 8)).tracking(1.5)
        }
      }.accessibilityElement(children: .combine).accessibilityIdentifier("home.brandPoint")
      Spacer()
      Button { largeType.toggle() } label: { Image(systemName: "textformat.size").frame(width: 44, height: 44) }.accessibilityLabel("切换大字号")
      Button { dark.toggle() } label: { Image(systemName: dark ? "sun.max" : "moon").frame(width: 44, height: 44) }.accessibilityLabel("切换深浅色模式")
      Menu {
        Button("开始 5 分钟呼吸", action: onStart).disabled(recovery?.canStart == false)
        Button("换个方式") { choosing = true }.accessibilityIdentifier("recovery.change")
      } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.accessibilityLabel("选择练习")
    }.font(.system(size: 20)).foregroundStyle(InnerBalanceTheme.strongFill)
  }
  private var hero: some View {
    Group {
      if let status { DailyStatusHero(score: status, now: statusNow, night: isNight, covered: drinks || localAction != nil) }
      else {
        VStack(alignment: .leading, spacing: 12) {
          Text("今日状态").font(.subheadline)
          Text(primaryAction == .resumeReading ? "状态分析已暂停" : readiness?.errorKey != nil ? "连接暂时中断" : readiness?.connected == false ? "连接 Apple 健康，查看今日状态" : "同步今日数据")
            .font(.title2.weight(.semibold)).accessibilityIdentifier("status.empty")
          FangcunCompanion(scene: .curious, paused: drinks).frame(width: 96, height: 80)
        }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
      }
    }
  }
  private func refresh() async {
    if let readiness, readiness.enabled { await readiness.refresh(); return }
    await model.refresh()
    guard !isUITesting else { return }
    diary.record(FangcunDaySnapshot(date: .now, state: state, summary: "已同步今日记录", sleep: model.evidence.first(where: { $0.kind == .sleep })?.valueText ?? "暂无睡眠记录",
      training: model.trainingSummary.map { "近 24 小时 \($0.count) 次 · \(Int($0.totalDuration / 60)) 分钟" } ?? "近 24 小时暂无训练记录"))
  }
  private var actionChoices: some View {
    NavigationStack {
      Form {
        if let recovery {
          Picker("现在的环境",selection:Binding(get:{ recovery.environment },set:{ recovery.environment = $0 })) {
            ForEach(RecoveryEnvironment.allCases,id:\.self) { Text(FangcunCopy.text("recovery.environment."+$0.rawValue)).tag($0) }
          }.accessibilityIdentifier("status.environment")
          Picker("这次想做什么",selection:$goal) {
            ForEach(RecoveryGoal.allCases,id:\.self) { Text(FangcunCopy.text("recovery.goal."+$0.rawValue)).tag($0) }
          }
          Toggle("这次不做呼吸练习",isOn:$avoidBreathing)
          Picker("状态良好时优先",selection:$favorite) { Text("呼吸").tag("breath"); Text("安静休息").tag("rest") }
          Button("开始 5 分钟呼吸") { choosing = false; onStart() }.disabled(!recovery.canStart || avoidBreathing)
          ForEach(RecoveryActionKind.localActions,id:\.id) { action in
            Button(FangcunCopy.text("recovery.title."+action.id)) { choosing = false; localAction = .init(action:action) }
              .disabled(!recovery.canStart || (action == .movementBreak && recovery.environment != .canMove))
              .accessibilityIdentifier("recovery.choose."+action.id)
          }
        }
      }.navigationTitle("换个方式").toolbar { Button("完成") { choosing = false } }
    }.presentationDetents([.medium,.large])
  }
  private func startPrimary() {
    switch primaryAction {
    case .breathing, .resume: onStart()
    case .shortBreathing: onSuggestedPractice(.physiologicalSigh, 120)
    case .seatedStretch: localAction = .init(action: .seatedReset)
    case .quietRest: localAction = .init(action: .quietRest)
    case .safety: safety = true
    case .resumeReading: Task { if readiness?.enabled == false { await readiness?.setEnabled(true) } else { await readiness?.resume() } }
    case .sync: Task { await readiness?.refresh() }
    case .connect: Task { askingHealth = true; _ = await authorization.request(.initialBodyStatus); await readiness?.refresh(); askingHealth = false }
    case .unavailable: break
    }
  }
}
private struct StatusLocalLaunch: Identifiable { let action: RecoveryActionKind; var id: String { action.id } }

struct FangcunEvidenceDetail: View {
  let model: HomeViewModel
  let authorization: HealthAuthorizationCoordinator
  @State private var requesting = false
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        Text("判断有依据，也有边界。").font(.title2.weight(.semibold))
        Text("与自己的近期基线比较，综合恢复指标和睡眠。身体负荷不等于你的主观感受；数据不足时保留未知。")
          .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
        VStack(alignment: .leading, spacing: 8) {
          if let fetchedAt = model.fetchedAt {
            Text(FangcunCopy.text("body.time.fetched", FangcunCopy.timestamp(fetchedAt)))
              .accessibilityIdentifier("evidence.fetchedAt").accessibilityValue(fetchedAt.ISO8601Format())
          }
          if let computedAt = model.computedAt {
            Text(FangcunCopy.text("body.time.computed", FangcunCopy.timestamp(computedAt)))
              .accessibilityIdentifier("evidence.computedAt").accessibilityValue(computedAt.ISO8601Format())
          }
          Text(FangcunCopy.text("body.time.explanation"))
          if !model.unavailableKinds.isEmpty { Text(FangcunCopy.text("body.query.unavailable")) }
        }.font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        if model.evidence.isEmpty { Text("还没有可用的健康数据。你可以检查授权，或等待设备同步。").fangcunPaperCard() }
        ForEach(model.evidence) { evidence in HealthEvidenceView(evidence: evidence).fangcunPaperCard() }
        VStack(alignment: .leading, spacing: 10) {
          Label("近 24 小时活动", systemImage: "figure.walk").font(.headline)
          if let training = model.trainingSummary {
            Text("\(training.count) 次训练 · \(Int(training.totalDuration / 60)) 分钟")
            Text("最近：\(training.latestActivityName) · \(training.latestSourceName)").font(.caption)
          } else { Text("没有可用的近期训练记录").font(.subheadline) }
          if model.recentWorkoutProtection {
            Text(FangcunCopy.text("body.workout.detail")).font(.caption).accessibilityIdentifier("evidence.workoutProtection")
          }
        }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
        Text("基线积累：\(model.baselineDays)/5 天。饮品记录作为生活线索展示，不会凭几杯饮品改写健康结论。")
          .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        Button(requesting ? "正在连接…" : "检查 Apple 健康授权") {
          Task { requesting = true; _ = await authorization.request(.initialBodyStatus); await model.refresh(); requesting = false }
        }.buttonStyle(InnerBalancePrimaryButtonStyle()).disabled(requesting)
      }.padding(20)
    }.background(InnerBalanceTheme.canvas).foregroundStyle(InnerBalanceTheme.ink)
      .navigationTitle("为什么这样判断").navigationBarTitleDisplayMode(.inline)
  }
}
