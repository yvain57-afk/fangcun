import InnerBalanceCore
import SwiftUI

struct FangcunTodayView: View {
  let model: HomeViewModel
  let authorization: HealthAuthorizationCoordinator
  let latestPractice: PracticeCompletionRecord?
  let isUITesting: Bool
  let onStart: () -> Void
  let onCheckIn: () -> Void
  @Environment(FangcunDiary.self) private var diary
  @Environment(\.scenePhase) private var phase
  @Environment(\.dynamicTypeSize) private var typeSize
  @AppStorage("fangcun.dark") private var dark = false
  @AppStorage("fangcun.largeType") private var largeType = false
  @State private var drinks = false
  @State private var companion = false
  @State private var replay = 0
  @State private var askingHealth = false

  private var state: FangcunDayState {
    #if DEBUG
    if isUITesting, let flag = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--preview-state=") }),
      let value = FangcunDayState(rawValue: String(flag.dropFirst("--preview-state=".count))) { return value }
    #endif
    return FangcunDayState.resolve(model)
  }
  private var summary: String {
    if !model.assessment.workoutExcludedEvidenceIDs.isEmpty {
      return FangcunCopy.text("body.workout.summary")
    }
    if model.assessment.availability == .buildingBaseline && state == .limited {
      return FangcunCopy.text("body.baseline.summary", model.baselineDays)
    }
    return FangcunCopy.text("body.state.\(state.rawValue).summary")
  }
  private var evidenceLine: String {
    if !model.assessment.workoutExcludedEvidenceIDs.isEmpty {
      return FangcunCopy.text("body.workout.evidence")
    }
    return FangcunCopy.text("body.state.\(state.rawValue).evidence")
  }
  private var sleepText: String {
    guard let sleep = model.evidence.first(where: { $0.kind == .sleep }) else {
      return FangcunCopy.text("body.metric.unavailable")
    }
    return FangcunCopy.text("body.sleep.value", FangcunCopy.timestamp(sleep.measuredAt), sleep.valueText)
  }
  private var cardiovascular: HomeHealthEvidence? {
    model.evidence.filter { $0.kind == .restingHeartRate || $0.kind == .heartRateVariability }
      .max { $0.measuredAt < $1.measuredAt }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          header
          HStack {
            Text(Date.now, format: .dateTime.month().day().weekday(.wide)).font(.caption)
            Spacer()
            Text(model.isLoading ? "正在更新" : "Apple 健康 · 身体线索").font(.caption2)
          }.foregroundStyle(InnerBalanceTheme.mutedInk)
          hero
          Button(action: onStart) {
            HStack(spacing: 14) {
              Image(systemName: "wind").font(.title2)
              VStack(alignment: .leading, spacing: 5) {
                Text("开始 5 分钟呼吸").font(.headline)
                Text("双吸一呼 · 留一点时间给自己").font(.caption)
              }
              Spacer(minLength: 0)
              Image(systemName: "arrow.up.right")
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 18)
          }.buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("today.start")
          evidenceCard
          Button { drinks = true } label: {
            HStack(spacing: 14) {
              Image(systemName: "drop").font(.title2).foregroundStyle(InnerBalanceTheme.strongFill)
              VStack(alignment: .leading, spacing: 5) {
                Text("今天喝了什么？").font(.headline)
                Text(diary.entries().isEmpty ? "水、咖啡，或是别的什么" : "已记 \(diary.entries().count) 杯 · 总液体 \(FangcunDrinkTotals(diary.entries()).fluid) ml")
                  .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
              }
              Spacer(minLength: 0)
              Image(systemName: "plus").frame(width: 34, height: 34).background(InnerBalanceTheme.subtleFill, in: Circle())
            }.fangcunPaperCard()
          }.buttonStyle(.plain).accessibilityIdentifier("today.drinks")
          if !diary.entries().isEmpty { drinkContext }
          if let latestPractice, Calendar.current.isDateInToday(latestPractice.endedAt) {
            Label("今天，已经为自己留了片刻。", systemImage: "checkmark.circle")
              .font(.subheadline).foregroundStyle(InnerBalanceTheme.strongFill)
          }
          NavigationLink { FangcunTrendsView() } label: {
            HStack { Text("看看这一周的节奏"); Spacer(); Image(systemName: "arrow.right") }.font(.subheadline).padding(.vertical, 10)
          }.accessibilityIdentifier("today.trends")
          Button("想补充一下自己的感受") { onCheckIn() }
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk).frame(minHeight: 44)
          Text("不必把每一天，都过得很用力。")
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk).padding(.bottom, 18)
        }.padding(.horizontal, 20).padding(.top, 14)
      }
      .background(InnerBalanceTheme.canvas)
      .foregroundStyle(InnerBalanceTheme.ink)
      .toolbar(.hidden, for: .navigationBar)
      .refreshable { await refresh() }
      .sheet(isPresented: $drinks) { FangcunDrinkSheet() }
      .sheet(isPresented: $companion) {
        VStack(spacing: 22) {
          FangcunCompanion(scene: state.scene, reaction: replay).frame(maxWidth: 300)
          Text(state == .elevated ? "先靠一会儿。" : state == .insufficient ? "慢慢认识你的节奏。" : "就这样，待一会儿。")
            .font(.title2.weight(.semibold))
          Button("再看一次动作") { replay += 1 }.frame(minHeight: 44)
          Button("回到今日") { companion = false }.frame(minHeight: 44)
        }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(InnerBalanceTheme.canvas).presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
      }
    }
    .task { await refresh() }
    .onChange(of: phase) { _, value in if value == .active { Task { await refresh() } } }
    .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in Task { await refresh() } }
  }

  private var header: some View {
    HStack {
      HStack(spacing: 10) {
        FangcunBrandMark(size: 34)
        VStack(alignment: .leading, spacing: 2) {
          Text("方寸").font(.title3.weight(.semibold)).tracking(2)
          Text("FANGCUN").font(.system(size: 8)).tracking(1.5)
        }
      }.accessibilityElement(children: .combine).accessibilityIdentifier("home.brandPoint")
      Spacer()
      Button { largeType.toggle() } label: { Image(systemName: "textformat.size").frame(width: 44, height: 44) }.accessibilityLabel("切换大字号")
      Button { dark.toggle() } label: { Image(systemName: dark ? "sun.max" : "moon").frame(width: 44, height: 44) }.accessibilityLabel("切换深浅色模式")
    }.foregroundStyle(InnerBalanceTheme.strongFill)
  }
  private var hero: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Label(state.shortTitle, systemImage: "circle.fill").font(.caption).labelStyle(.titleAndIcon)
          .foregroundStyle(state == .elevated ? InnerBalanceTheme.emphasis : InnerBalanceTheme.strongFill)
          .padding(.horizontal, 10).padding(.vertical, 6).background(InnerBalanceTheme.subtleFill, in: Capsule())
        Spacer()
      }
      Text(state.title).font(.title2.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("today.conclusion").accessibilityValue(state.rawValue)
      Text(model.latestMeasuredAt.map { FangcunCopy.text("body.time.measured", FangcunCopy.timestamp($0)) }
        ?? FangcunCopy.text("body.time.noMeasurement"))
        .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        .accessibilityIdentifier("today.measuredAt")
        .accessibilityValue(model.latestMeasuredAt?.ISO8601Format() ?? "none")
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 10) { Text(summary).font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk).fixedSize(horizontal: false, vertical: true); character.frame(width: 142) }
        VStack(alignment: .leading, spacing: 10) { Text(summary).font(.subheadline); character.frame(maxWidth: 180).frame(maxWidth: .infinity) }
      }
      Divider()
      Text(evidenceLine).font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk).fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("today.evidenceSummary")
    }.fangcunPaperCard()
  }
  private var character: some View {
    Button { companion = true } label: {
      VStack(spacing: 2) {
        FangcunCompanion(scene: state.scene, paused: drinks || companion)
        Text(state == .steady ? "看看它们 ↗" : "看看它 ↗").font(.system(size: 10)).foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }.buttonStyle(.plain).accessibilityLabel(state.scene.label)
  }
  private var evidenceCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack { Text("身体给的线索").font(.headline); Spacer(); Text("真实数据").font(.caption2).foregroundStyle(InnerBalanceTheme.mutedInk) }
      NavigationLink { FangcunEvidenceDetail(model: model, authorization: authorization) } label: {
        VStack(spacing: 16) {
          HStack(alignment: .top) {
            metric(FangcunCopy.text("body.sleep.title"), sleepText, "moon")
            Spacer(minLength: 8); Divider(); Spacer(minLength: 8)
            metric(FangcunCopy.text(cardiovascular?.kind == .heartRateVariability ? "body.metric.hrv" : "body.metric.rhr"),
              cardiovascular?.valueText ?? FangcunCopy.text("body.metric.unavailable"), "heart",
              detail: cardiovascular.map { FangcunCopy.text("body.time.measured", FangcunCopy.timestamp($0.measuredAt)) })
          }.fixedSize(horizontal: false, vertical: true)
          Divider()
          HStack { Text("为什么这样判断"); Spacer(); Image(systemName: "chevron.right") }.font(.caption)
        }.fangcunPaperCard()
      }.buttonStyle(.plain).accessibilityIdentifier("today.evidence")
    }
  }
  private func metric(_ title: String, _ value: String, _ icon: String, detail: String? = nil) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: icon).font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
      Text(value).font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
      if let detail { Text(detail).font(.caption2).foregroundStyle(InnerBalanceTheme.mutedInk) }
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
  private var drinkContext: some View {
    let total = FangcunDrinkTotals(diary.entries())
    return VStack(alignment: .leading, spacing: 8) {
      Text("今天的生活线索").font(.subheadline.weight(.semibold))
      Text(total.caffeine > 0 ? "已记录约 \(total.caffeine) mg 咖啡因；可以留意摄入时间和今晚的入睡感受。" : "饮品已记下，按自己的节奏补充水分。")
      if total.alcohol > 0 { Text("已记录酒精摄入；观察今晚睡眠和明早恢复，不用单次摄入推断压力。") }
      if total.sugar > 0 { Text("今天含糖饮品 \(total.sugar) 份，已单独记录。") }
    }.font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk).frame(maxWidth: .infinity, alignment: .leading)
  }
  private func refresh() async {
    await model.refresh()
    guard !isUITesting else { return }
    diary.record(FangcunDaySnapshot(date: .now, state: state, summary: evidenceLine, sleep: sleepText,
      training: model.trainingSummary.map { "近 24 小时 \($0.count) 次 · \(Int($0.totalDuration / 60)) 分钟" } ?? "近 24 小时暂无训练记录"))
  }
}

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
