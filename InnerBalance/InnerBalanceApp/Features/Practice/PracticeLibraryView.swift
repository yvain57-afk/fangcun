import InnerBalanceCore
import SwiftUI
import SwiftData

struct PracticeLaunch: Identifiable, Equatable {
  let kind: PracticeKind
  let duration: TimeInterval
  var startsImmediately = false
  var variantID: String? = nil
  var restoredCheckpoint: PracticeSessionCheckpoint? = nil
  let id = UUID()
}

/// Preferences are additive; V3 display, sound, drink and score preferences stay untouched.
enum PracticeHubPreferences {
  static func resumableCheckpoint() -> PracticeSessionCheckpoint? { PracticeSessionDraftStore.load() }
  static let quickKindKey = "fangcun.practice.v4.quickKind"
  static func hasLearned(_ kind: PracticeKind) -> Bool {
    UserDefaults.standard.bool(forKey: "fangcun.practice.v4.learned." + kind.rawValue)
  }
  static func markLearned(_ kind: PracticeKind) {
    UserDefaults.standard.set(true, forKey: "fangcun.practice.v4.learned." + kind.rawValue)
  }
}

struct PracticeLibraryView: View {
  let onStart: (PracticeLaunch) -> Void
  var onRecords: () -> Void = {}
  var latestPractice: PracticeCompletionRecord? = nil
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.careOwner) private var care
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @AppStorage("fangcun.reduceMotion") private var reduceMotion = false
  @AppStorage("fangcun.motionMode") private var motionMode = "standard"
  @AppStorage(PracticeHubPreferences.quickKindKey) private var quickKind = ""
  @State private var filter = "全部"
  @State private var mainVisible = false
  @State private var previewStartedAt = Date.now
  @State private var checkpoint: PracticeSessionCheckpoint?
  private let filters = ["全部", "放松", "专注", "休息", "身体训练"]
  private let order: [PracticeKind] = [.physiologicalSigh, .pacedBreathing, .nsdr, .meditation,
    .balancedBreathing, .boxBreathing, .diaphragmaticBreathing, .alternateNostrilBreathing, .kegel, .progressiveMuscleRelaxation]
  private var featured: PracticeKind {
    if let pinned = PracticeKind(rawValue: quickKind), order.contains(pinned) { return pinned }
    if !PracticeHubPreferences.hasLearned(.physiologicalSigh) { return .physiologicalSigh }
    let now = Date.now
    let plannedNight = care?.preferences.sleepPlanConfirmed == true &&
      care!.preferences.sleepCycles(now: now, calendar: .current).contains {
        now >= $0.start.addingTimeInterval(-90 * 60) && now < $0.end
      }
    let hour = Calendar.current.component(.hour, from: now)
    return plannedNight || (care?.preferences.sleepPlanConfirmed != true && (hour >= 22 || hour < 6))
      ? .pacedBreathing : .physiologicalSigh
  }
  private var filtered: [PracticeKind] { order.filter { filter == "全部" || $0.v4Tags.contains(filter) } }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          HStack(spacing: 10) {
            FangcunBrandMark(size: 36)
            VStack(alignment: .leading, spacing: 3) {
              Text("方寸").font(.title3.weight(.semibold)).tracking(2)
              Text("呼吸与身心练习").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
            }
            Spacer()
            Button(action: onRecords) { Image(systemName: "clock.arrow.circlepath").frame(width: 44, height: 44) }
              .accessibilityLabel("练习记录").accessibilityIdentifier("hub.records")
          }.padding(.vertical, 4)
          if let checkpoint {
            VStack(alignment: .leading, spacing: 12) {
              Text(checkpoint.endedAt == nil ? "继续上次练习" : "保留上次练习").font(.title2.weight(.semibold))
              Text(checkpoint.kind.title + " · 剩余 " + PracticeDurationFormatter.clock(max(0, checkpoint.duration - checkpoint.actualDuration)))
                .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
              Text("离开期间不计时。回来后，先自然呼吸。").font(.caption)
              Button("回到练习") {
                onStart(.init(kind: checkpoint.kind, duration: checkpoint.duration, variantID: checkpoint.variantID,
                  restoredCheckpoint: checkpoint))
              }.buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("hub.resume")
            }.fangcunPaperCard()
          } else { featuredCard }
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(filters, id: \.self) { item in
                Button(item) { filter = item }
                  .font(.subheadline.weight(.medium)).padding(.horizontal, 15).frame(minHeight: 44)
                  .foregroundStyle(filter == item ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink)
                  .background(filter == item ? InnerBalanceTheme.strongFill : InnerBalanceTheme.surface, in: Capsule())
                  .accessibilityAddTraits(filter == item ? .isSelected : [])
                  .accessibilityIdentifier("hub.filter." + item)
              }
            }
          }
          HStack {
            Text(filter == "全部" ? "10 项呼吸与身心练习" : filter + "练习").font(.headline)
            Spacer()
          }
          LazyVStack(spacing: 14) { ForEach(filtered, id: \.rawValue) { methodCard($0) } }
          if let latestPractice {
            Button(action: onRecords) {
              HStack {
                Image(systemName: "checkmark.circle")
                Text("最近练习 · " + latestPractice.practiceKind.title)
                Spacer()
                Image(systemName: "chevron.right")
              }.font(.subheadline).padding(.vertical, 14)
            }.accessibilityIdentifier("hub.latestPractice")
          }
          Text("用呼吸放松，用练习找回专注与身体控制。")
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk).padding(.vertical, 8)
        }.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 24)
      }
      .background(InnerBalanceTheme.canvas).foregroundStyle(InnerBalanceTheme.ink)
      .accessibilityIdentifier("practice.hub")
      .safeAreaInset(edge: .bottom) {
        if typeSize.isAccessibilitySize && checkpoint == nil {
          quickStartButton.padding(.horizontal, 20).padding(.vertical, 8).background(InnerBalanceTheme.canvas)
        }
      }
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { checkpoint = PracticeHubPreferences.resumableCheckpoint() }
    }
  }

  private var featuredCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      if typeSize.isAccessibilitySize {
        featuredText
        featuredButtons
      } else {
        HStack(alignment: .center, spacing: 8) {
          featuredText.frame(maxWidth: .infinity, alignment: .leading)
          featuredArtwork.frame(width: 140)
        }
        featuredButtons
      }
    }.padding(18).background(InnerBalanceTheme.surface, in: RoundedRectangle(cornerRadius: 24))
      .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(InnerBalanceTheme.hairline) }
  }
  private var featuredText: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("给自己，\n一次慢呼吸").font(.title2.weight(.semibold))
      NavigationLink { PracticeMethodDetailView(kind: featured, onStart: onStart) } label: {
        HStack(spacing: 4) {
          Text(featured.title + " · " + PracticeDurationFormatter.text(featured.v4DefaultDuration))
          Image(systemName: "info.circle").font(.caption)
        }.font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk).frame(minHeight: 44)
      }.accessibilityLabel(featured.title + "，方法说明")
      Text(featured.useContext).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
    }
  }
  private var previewIsAnimating: Bool {
    mainVisible && scenePhase == .active && !systemReduceMotion && !reduceMotion && motionMode != "static" && !ProcessInfo.processInfo.isLowPowerModeEnabled
  }

  private var featuredArtwork: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !previewIsAnimating)) { context in
      PracticeCompanionV4(kind: featured, elapsed: max(0, context.date.timeIntervalSince(previewStartedAt)), duration: featured.v4DefaultDuration,
        variantID: nil, isActive: previewIsAnimating)
        .frame(height: 145).frame(maxWidth: .infinity)
    }.onAppear { previewStartedAt = .now }
      .onScrollVisibilityChange(threshold: 0.1) { mainVisible = $0 }
      .onDisappear { mainVisible = false }
  }
  @ViewBuilder private var featuredButtons: some View {
    if typeSize.isAccessibilitySize { minuteExperienceButton }
    else { HStack(spacing: 10) { quickStartButton; minuteExperienceButton } }
  }
  private var quickStartButton: some View {
    Button("开始" + PracticeDurationFormatter.text(featured.v4DefaultDuration)) {
      onStart(.init(kind: featured, duration: featured.v4DefaultDuration,
        startsImmediately: PracticeHubPreferences.hasLearned(featured)))
    }.buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("hub.quickStart")
  }
  @ViewBuilder private var minuteExperienceButton: some View {
    if featured == .physiologicalSigh {
      Button("体验 1 分钟") { onStart(.init(kind: .physiologicalSigh, duration: 60)) }
        .font(.subheadline.weight(.medium)).frame(minWidth: 88, minHeight: 44)
        .accessibilityIdentifier("practice.physiologicalSigh.60")
    }
  }

  private func methodCard(_ kind: PracticeKind) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      NavigationLink { PracticeMethodDetailView(kind: kind, onStart: onStart) } label: {
        HStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 7) {
            Text(kind.title).font(.headline)
            Text(kind.useContext).font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
              .fixedSize(horizontal: false, vertical: true)
          }.frame(maxWidth: .infinity, alignment: .leading)
          if !typeSize.isAccessibilitySize {
            PracticeCompanionV4(kind: kind, elapsed: 0, duration: kind.v4DefaultDuration, isActive: false)
              .frame(width: 86, height: 80).accessibilityHidden(true)
          }
          Image(systemName: "chevron.right").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        }.contentShape(Rectangle())
      }.buttonStyle(.plain).accessibilityIdentifier("hub.method." + kind.rawValue)
        .accessibilityLabel(kind.outcomeTitle + "，" + kind.title)
      ProportionalPhaseBar(kind: kind, compact: true)
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 8) { durationButtons(kind) }
        VStack(spacing: 8) { durationButtons(kind) }
      }
    }.fangcunPaperCard()
  }
  @ViewBuilder private func durationButtons(_ kind: PracticeKind) -> some View {
    ForEach(PracticeCatalog.protocol(for: kind)?.durationOptions ?? [], id: \.self) { seconds in
      Button {
        onStart(.init(kind: kind, duration: seconds, startsImmediately: PracticeHubPreferences.hasLearned(kind)))
      } label: {
        Text(PracticeDurationFormatter.text(seconds)).font(.subheadline.weight(.medium))
          .frame(maxWidth: .infinity, minHeight: 44)
          .background(InnerBalanceTheme.elevatedSurface, in: Capsule())
      }.buttonStyle(.plain).accessibilityIdentifier("hub.start." + kind.rawValue + "." + String(Int(seconds)))
    }
  }

}

struct PracticeMethodDetailView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @AppStorage("fangcun.reduceMotion") private var reduceMotion = false
  @AppStorage("fangcun.motionMode") private var motionMode = "standard"
  @State private var demoVisible = false
  let kind: PracticeKind
  let onStart: (PracticeLaunch) -> Void
  @State private var duration: TimeInterval = 0
  @State private var variantID = "equal_5_5"
  @State private var pmrEnding = "pmr_day"
  @State private var skipsIntro = false
  private var chosenVariant: String? {
    kind == .balancedBreathing ? variantID : kind == .progressiveMuscleRelaxation ? pmrEnding : nil
  }
  @State private var demonstration = true
  @State private var demoStartedAt = Date.now
  @State private var sound = PracticeSoundPreferences()
  @AppStorage(PracticeHubPreferences.quickKindKey) private var quickKind = ""
  private var demoIsAnimating: Bool {
    demonstration && demoVisible && scenePhase == .active && !systemReduceMotion && !reduceMotion && motionMode != "static" && !ProcessInfo.processInfo.isLowPowerModeEnabled
  }
  private var chosenDuration: TimeInterval { duration == 0 ? kind.v4DefaultDuration : duration }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(kind.useContext).font(.title2.weight(.semibold))
        Label(kind.positionNote, systemImage: "figure.mind.and.body").font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !demoIsAnimating)) { context in
          let time = demonstration ? max(0, context.date.timeIntervalSince(demoStartedAt)) : 0
          PracticeCompanionV4(kind: kind, elapsed: time, duration: chosenDuration,
            variantID: chosenVariant, isActive: demoIsAnimating)
            .frame(height: 190)
            .frame(maxWidth: kind == .progressiveMuscleRelaxation ? 300 : .infinity)
            .frame(maxWidth: .infinity)

        }
        .onScrollVisibilityChange(threshold: 0.1) { demoVisible = $0 }
        Button(demonstration ? "停止示范" : "看看动作示范") { demoStartedAt = .now; demonstration.toggle() }
          .font(.subheadline).frame(minHeight: 44).accessibilityIdentifier("practice.demo")
        if demonstration { Text("动作示范 · 不计入练习时长").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk) }
        ProportionalPhaseBar(kind: kind, variantID: chosenVariant, compact: true)
        Picker("练习时长", selection: Binding(get: { chosenDuration }, set: { duration = $0 })) {
          ForEach(PracticeCatalog.protocol(for: kind)?.durationOptions ?? [], id: \.self) { value in
            Text(PracticeDurationFormatter.text(value)).tag(value)
          }
        }.pickerStyle(.segmented).accessibilityIdentifier("practice.duration")
        if kind == .balancedBreathing {
          Picker("舒适节拍", selection: $variantID) {
            Text("吸 5 秒 / 呼 5 秒").tag("equal_5_5")
            Text("吸 4 秒 / 呼 4 秒").tag("easy_4_4")
          }.pickerStyle(.segmented).accessibilityIdentifier("practice.variant")
        }
        if kind == .progressiveMuscleRelaxation {
          Picker("结束方式", selection: $pmrEnding) {
            Text("日间 · 慢慢回来").tag("pmr_day")
            Text("睡前 · 安静休息").tag("pmr_sleep")
          }.pickerStyle(.segmented).accessibilityIdentifier("practice.pmr.ending")
          Text("同样 10 分钟，只改变最后一分钟的引导。全程自然呼吸，不跟吸呼节拍。")
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        DisclosureGroup("开场说明") {
          Text(PracticeGuidanceContent.introduction(for: kind, variantID: chosenVariant))
            .font(.body).lineSpacing(5).padding(.top, 12)
          Toggle("下次跳过这项说明", isOn: Binding(
            get: { skipsIntro },
            set: { skipsIntro = $0; PracticeIntroductionPreferences.setSkips($0, for: kind) }))
            .font(.subheadline).tint(InnerBalanceTheme.strongFill)
        }.fangcunPaperCard()
        DisclosureGroup("动作要领与注意事项") {
          VStack(alignment: .leading, spacing: 12) {
            Text(kind.steps).font(.body)
            Text(kind.preparation).font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
            PracticeHumanInstruction(kind: kind)
          }.padding(.top, 12)
        }.fangcunPaperCard()
        DisclosureGroup("引导设置") {
          PracticeSoundControls(mode: Binding(get: { sound.mode(hasVoiceAssets: PracticeVoiceAssets.isAvailable(for: kind)) }, set: { sound.preferredMode = $0 }),
            ambienceEnabled: Binding(get: { sound.ambienceEnabled }, set: { sound.ambienceEnabled = $0 }),
            voiceAvailable: PracticeVoiceAssets.isAvailable(for: kind))
        }
        if kind == .alternateNostrilBreathing {
          Text("仅节奏或静音时，请看左右文字提示；相似的轻触不能代替换边教学。")
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        Toggle("设为首页快捷练习", isOn: Binding(get: { quickKind == kind.rawValue }, set: { selected in
          quickKind = selected ? kind.rawValue : ""
        })).tint(InnerBalanceTheme.strongFill).accessibilityIdentifier("practice.pin")
      }.padding(20).padding(.bottom, 16)
    }.background(InnerBalanceTheme.canvas).foregroundStyle(InnerBalanceTheme.ink)
      .navigationTitle(kind.title).navigationBarTitleDisplayMode(.inline)
      .safeAreaInset(edge: .bottom) {
        Button("开始" + PracticeDurationFormatter.text(chosenDuration)) {
          demonstration = false
          // The detail contains the method's movement and safety teaching; no second questionnaire.
          PracticeHubPreferences.markLearned(kind)
          onStart(.init(kind: kind, duration: chosenDuration, startsImmediately: true,
            variantID: chosenVariant))
        }.buttonStyle(InnerBalancePrimaryButtonStyle())
          .accessibilityIdentifier("practice." + kind.rawValue + "." + String(Int(chosenDuration)))
          .padding(.horizontal, 20).padding(.vertical, 10).background(InnerBalanceTheme.canvas)
      }
      .onAppear { skipsIntro = PracticeIntroductionPreferences.skips(kind) }
      .onDisappear { demonstration = false }
  }
}

struct PracticeRecordsView: View {
  @Query(sort: \StoredPracticeCompletion.startedAt, order: .reverse) private var stored: [StoredPracticeCompletion]
  @Environment(\.recoveryOwner) private var recovery
  @State private var selectedMethod = "all"
  private var records: [PracticeCompletionRecord] {
    stored.compactMap(\.record).filter { selectedMethod == "all" || $0.practiceKind.rawValue == selectedMethod }
  }
  var body: some View {
    List {
      Section {
        Picker("按方法查看", selection: $selectedMethod) {
          Text("全部方法").tag("all")
          ForEach(PracticeKind.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
        }
      }
      if records.isEmpty {
        VStack(spacing: 12) {
          PracticeCompanionV4(kind: .meditation, elapsed: 0, duration: 300, isActive: false).frame(height: 150)
          Text("练习过的时间，会留在这里。").foregroundStyle(InnerBalanceTheme.mutedInk)
        }.frame(maxWidth: .infinity).listRowBackground(InnerBalanceTheme.surface)
      }
      ForEach(records, id: \.sessionID) { record in
        VStack(alignment: .leading, spacing: 8) {
          Text(record.startedAt, format: .dateTime.month().day().weekday()).font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
          Text(record.practiceKind.title).font(.headline)
          Text(PracticeDurationFormatter.clock(record.actualDuration) + " · " + (record.actualDuration >= record.plannedDuration - 1 ? "完成" : "提前结束"))
            .font(.subheadline)
          if let feedback = record.metadata?.subjectiveFeedback { Text(feedback).font(.caption.weight(.semibold)).padding(.horizontal, 12).padding(.vertical, 7).background(Color("FangcunExhale").opacity(0.10), in: Capsule()).foregroundStyle(Color("FangcunExhale")) }
        }.padding(.vertical, 5)
          .accessibilityElement(children: .combine)
          .accessibilityIdentifier("practice.history.record").accessibilityValue(record.sessionID)
      }
      if let recovery { Section { NavigationLink("轻行动与旧记录") { RecoveryHistoryView(owner: recovery) } } }
    }.navigationTitle("练习记录").scrollContentBackground(.hidden).background(InnerBalanceTheme.canvas)
      .accessibilityIdentifier("practice.history")
  }
}
