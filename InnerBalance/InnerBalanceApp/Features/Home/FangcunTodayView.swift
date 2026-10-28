import InnerBalanceCore
import SwiftUI

struct FangcunTodayView: View {
  let model: HomeViewModel
  let authorization: HealthAuthorizationCoordinator
  let latestPractice: PracticeCompletionRecord?
  let isUITesting: Bool
  var onSettings: () -> Void = {}
  var onRecords: () -> Void = {}
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
  @State private var bodyContextExpanded = false
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
          Button(action: onCheckIn) {
            VStack(alignment: .leading, spacing: 8) {
              Text("How has your day felt?").font(.title2.weight(.medium))
              Text("A small check-in, in your own time.").font(.subheadline)
                .foregroundStyle(InnerBalanceTheme.mutedInk)
              Label("Leave a note", systemImage: "plus").font(.subheadline.weight(.semibold))
                .padding(.top, 4)
            }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
          }.buttonStyle(.plain).accessibilityIdentifier("home.checkIn")
          Button(action: onRecords) {
            HStack { Label("Your practice", systemImage: "clock.arrow.circlepath"); Spacer(); Image(systemName: "chevron.right") }
              .font(.headline).fangcunPaperCard()
          }.buttonStyle(.plain).accessibilityIdentifier("daily.records")
          VStack(alignment: .leading, spacing: 12) {
          Button { drinks = true } label: {
            HStack(spacing: 14) {
              Image(systemName: "drop").font(.title2).foregroundStyle(InnerBalanceTheme.strongFill)
              VStack(alignment: .leading, spacing: 5) {
                Text("What have you been sipping?").font(.headline)
                Text(diary.entries().isEmpty ? "Water, coffee, or something else" : "\(diary.entries().count) entries · \(FangcunDrinkTotals(diary.entries()).fluid) ml logged")
                  .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
              }
              Spacer(minLength: 0)
              Image(systemName: "plus").frame(width: 34, height: 34).background(InnerBalanceTheme.subtleFill, in: Circle())
            }.fangcunPaperCard()
          }.buttonStyle(.plain).accessibilityIdentifier("today.drinks")
          if let care { BeverageCareCard(owner: care).padding(.horizontal, 12) }
          }
          if let latestPractice, Calendar.current.isDateInToday(latestPractice.endedAt) {
            Label("You made a little space for yourself today.", systemImage: "checkmark.circle")
              .accessibilityIdentifier("today.latestPractice")
              .accessibilityValue(latestPractice.sessionID)
              .font(.subheadline).foregroundStyle(InnerBalanceTheme.strongFill)
          }
          DisclosureGroup(isExpanded: $bodyContextExpanded) {
          Text("Body context").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
          HStack {
            Text(statusNow, format: .dateTime.month().day().weekday(.wide)).font(.caption)
            Spacer()
            if status != nil && readiness?.errorKey != nil {
              Button("Retry sync") { Task { await readiness?.refresh() } }.font(.caption).accessibilityIdentifier("status.refresh")
            } else { Text(readiness?.loading == true ? "Updating" : "Daily index").font(.caption2) }
          }.foregroundStyle(InnerBalanceTheme.mutedInk)
          hero
          if !typeSize.isAccessibilitySize { primaryButton }
          if status == nil, readiness?.enabled == true, readiness?.reading == true {
            Button("Add sleep manually") { manualSleep = true }.font(.subheadline).accessibilityIdentifier("status.manual")
          }
          if let status {
            NavigationLink { DailyStatusDetailView(score: status, onStart: startPrimary, actionTitle: primaryAction.title, lastQueryAt: readiness?.snapshot.lastRefreshAttemptAt) } label: {
              VStack(alignment: .leading, spacing: 12) {
                ForEach(status.components, id: \.name) { part in
                  HStack { Text(DailyStatusPresentation.componentName(part.name)); Spacer(); Text("\(Int(part.score.rounded())) points").monospacedDigit() }.font(.subheadline)
                }
                HStack { Text("What goes into this number?"); Spacer(); Image(systemName: "chevron.right") }.font(.caption)
              }.fangcunPaperCard()
            }.buttonStyle(.plain).accessibilityIdentifier("today.evidence")
          }
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              Text("Body context").font(.headline)
              Text("Optional clues from sleep and Apple Health").font(.caption)
                .foregroundStyle(InnerBalanceTheme.mutedInk)
            }.accessibilityIdentifier("daily.bodyContext")
          }.tint(InnerBalanceTheme.ink).padding(.vertical, 12)
          NavigationLink { if let readiness, readiness.enabled { DailyStatusHistoryView(owner: readiness) } else { FangcunTrendsView() } } label: {
            HStack { Text("Your week, gently"); Spacer(); Image(systemName: "arrow.right") }.font(.subheadline).padding(.vertical, 10)
          }.accessibilityIdentifier("today.trends")
          if let recentFeeling, Calendar.current.isDateInToday(recentFeeling.date) {
            Text("Your latest check-in: " + (recentFeeling.labels.first?.displayName ?? (recentFeeling.phase == .post ? PostPracticeFeelingNames.title(valence:recentFeeling.valence,arousal:recentFeeling.arousal) : nil) ?? "A feeling without a label")
              + (recentFeeling.associations.isEmpty ? "" : " · " + recentFeeling.associations.map(\.displayName).joined(separator:"、")))
              .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
              .accessibilityIdentifier("today.feeling").accessibilityValue(recentFeeling.syncIdentifier)
          }
          if let recentFeeling, Calendar.current.isDateInToday(recentFeeling.date),
             !recentFeeling.bodySensationCodes.isEmpty {
            Button { onSuggestedPractice(.physiologicalSigh, 60) } label: {
              HStack(spacing: 12) {
                Image(systemName: "wind")
                VStack(alignment: .leading, spacing: 5) {
                  Text("A minute for you, too").font(.headline)
                  Text("Try a little sigh, if it feels right. You can also leave things as they are.").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
              }.fangcunPaperCard()
            }.buttonStyle(.plain).accessibilityIdentifier("daily.feeling.practice")
          }
          Button { choosing = true } label: {
            HStack { Label("Small acts of care", systemImage: "leaf"); Spacer(); Text("Rest · Stretch").font(.caption); Image(systemName: "chevron.right") }.fangcunPaperCard()
          }.buttonStyle(.plain).accessibilityIdentifier("daily.lightActions")
          Text("You don't have to make every day a big effort.")
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk).padding(.bottom, 18)
        }.padding(.horizontal, 20).padding(.top, 14)
          .accessibilityHidden(hasOngoingPractice || localAction != nil)
      }
      .background(InnerBalanceTheme.canvas)
      .foregroundStyle(InnerBalanceTheme.ink)
      .safeAreaInset(edge: .bottom) {
        if typeSize.isAccessibilitySize && bodyContextExpanded {
          primaryButton.padding(.horizontal, 20).padding(.vertical, 8).background(InnerBalanceTheme.canvas)
        }
      }
      .toolbar(.hidden, for: .navigationBar)
      .refreshable { await refresh() }
      .onChange(of: care?.pendingRoute, initial: true) { _, route in
        if route == "record", !hasOngoingPractice { drinks = true; care?.pendingRoute = nil }
      }
      .onChange(of: hasOngoingPractice) { _, ongoing in
        if !ongoing, care?.pendingRoute == "record" { drinks = true; care?.pendingRoute = nil }
      }
      .sheet(isPresented: $manualSleep) { if let readiness { ManualStatusSleepView(owner:readiness) } }
      .sheet(isPresented: $choosing) { actionChoices }
      .sheet(isPresented: $drinks) { FangcunDrinkSheet() }
      .fullScreenCover(item: $localAction) { launch in
        if let recovery, let plan = RecoveryProtocol.local(launch.action) { RecoverySessionView(owner: recovery, plan: plan, environment: recovery.environment) }
      }
      .sheet(isPresented: $safety) {
        VStack(spacing: 20) { Text("Seek help from someone nearby or contact local emergency services now. Don't stay alone or drive.").font(.title3); Button("Close") { safety = false } }.padding(24)
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

  private var primaryButton: some View {
    Button(action: startPrimary) {
            HStack(spacing: 14) {
              if !typeSize.isAccessibilitySize { Image(systemName: "wind").font(.title2) }
              VStack(alignment: .leading, spacing: 5) {
                Text(primaryAction == .sync && readiness?.errorKey != nil ? "Retry sync" : primaryAction.title).font(.headline)
              }
              Spacer(minLength: 0)
              if !typeSize.isAccessibilitySize { Image(systemName: "arrow.up.right") }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 18)
          }.buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("today.start")
            .disabled(primaryAction == .unavailable || askingHealth)
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Daily").font(typeSize.isAccessibilitySize ? .headline : .title.weight(.semibold)).accessibilityIdentifier("daily.title")
        Text("Small things that make up your day.").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
      }
      Spacer()
      Button(action: onSettings) { Image(systemName: "gearshape").frame(width: 44, height: 44) }
        .accessibilityLabel("Settings").accessibilityIdentifier("daily.settings")
    }.foregroundStyle(InnerBalanceTheme.strongFill)
  }
  private var hero: some View {
    Group {
      if let status { DailyStatusHero(score: status, now: statusNow, night: isNight, covered: drinks || localAction != nil) }
      else {
        VStack(alignment: .leading, spacing: 12) {
          Text("Today's body context").font(.subheadline)
          Text(primaryAction == .resumeReading ? "Body context is paused" : "No usable data yet")
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
    diary.record(FangcunDaySnapshot(date: .now, state: state, summary: "Today's entries are synced", sleep: model.evidence.first(where: { $0.kind == .sleep })?.valueText ?? "No sleep record yet",
      training: model.trainingSummary.map { "Past 24 hours: \($0.count) workouts · \(Int($0.totalDuration / 60)) min" } ?? "No workouts in the past 24 hours"))
  }
  private var actionChoices: some View {
    NavigationStack {
      Form {
        if let recovery {
          Picker("Where are you right now?",selection:Binding(get:{ recovery.environment },set:{ recovery.environment = $0 })) {
            ForEach(RecoveryEnvironment.allCases,id:\.self) { Text(FangcunCopy.text("recovery.environment."+$0.rawValue)).tag($0) }
          }.accessibilityIdentifier("status.environment")
          Picker("What would feel useful?",selection:$goal) {
            ForEach(RecoveryGoal.allCases,id:\.self) { Text(FangcunCopy.text("recovery.goal."+$0.rawValue)).tag($0) }
          }
          Toggle("Skip breathing suggestions this time",isOn:$avoidBreathing)
          Picker("When things look steady, prefer",selection:$favorite) { Text("Breathe").tag("breath"); Text("Quiet rest").tag("rest") }
          Button("Breathe for 5 minutes") { choosing = false; onStart() }.disabled(!recovery.canStart || avoidBreathing)
          ForEach(RecoveryActionKind.localActions,id:\.id) { action in
            Button(FangcunCopy.text("recovery.title."+action.id)) { choosing = false; localAction = .init(action:action) }
              .disabled(!recovery.canStart || (action == .movementBreak && recovery.environment != .canMove))
              .accessibilityIdentifier("recovery.choose."+action.id)
          }
        }
      }.navigationTitle("Try another way").toolbar { Button("Done") { choosing = false } }
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
        Text("Useful context, with limits.").font(.title2.weight(.semibold))
        Text("Recovery measures and sleep are compared with your recent baseline. Body load isn't the same as how you feel. Missing data stays unknown.")
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
        if model.evidence.isEmpty { Text("No usable health data yet. Check access or wait for your device to sync.").fangcunPaperCard() }
        ForEach(model.evidence) { evidence in HealthEvidenceView(evidence: evidence).fangcunPaperCard() }
        VStack(alignment: .leading, spacing: 10) {
          Label("Activity in the past 24 hours", systemImage: "figure.walk").font(.headline)
          if let training = model.trainingSummary {
            Text("\(training.count) workouts · \(Int(training.totalDuration / 60)) min")
            Text("Latest: \(training.latestActivityName) · \(training.latestSourceName)").font(.caption)
          } else { Text("No recent workout data available").font(.subheadline) }
          if model.recentWorkoutProtection {
            Text(FangcunCopy.text("body.workout.detail")).font(.caption).accessibilityIdentifier("evidence.workoutProtection")
          }
        }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
        Text("Building your baseline: \(model.baselineDays)/5 days. Drinks add everyday context; they don't change the health assessment.")
          .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        Button(requesting ? "Connecting…" : "Check Apple Health access") {
          Task { requesting = true; _ = await authorization.request(.initialBodyStatus); await model.refresh(); requesting = false }
        }.buttonStyle(InnerBalancePrimaryButtonStyle()).disabled(requesting)
      }.padding(20)
    }.background(InnerBalanceTheme.canvas).foregroundStyle(InnerBalanceTheme.ink)
      .navigationTitle("What this is based on").navigationBarTitleDisplayMode(.inline)
  }
}
