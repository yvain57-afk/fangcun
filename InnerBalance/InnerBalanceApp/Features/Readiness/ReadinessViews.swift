import SwiftUI
import InnerBalanceCore

struct ReadinessEvidenceLink: View {
  let owner: ReadinessCoordinator
  var body: some View {
    NavigationLink { ReadinessDetailView(assessment: owner.current, snapshot: owner.snapshot) } label: {
      VStack(alignment: .leading, spacing: 12) {
        Text(FangcunCopy.text("readiness.evidence")).font(.headline)
        if let a = owner.current {
          ForEach(a.evidence, id: \.feature.metric) { evidence in
            Text(ReadinessDisplay.metric(evidence)).font(.subheadline)
          }
          Text(FangcunCopy.text("readiness.sleepEnd", FangcunCopy.timestamp(a.sleepEndAt)))
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        } else { Text(FangcunCopy.text(owner.errorKey ?? "readiness.summary.insufficient")) }
        HStack { Text(FangcunCopy.text("readiness.why")); Spacer(); Image(systemName: "chevron.right") }.font(.caption)
      }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
    }.buttonStyle(.plain).accessibilityIdentifier("today.evidence")
  }
}

enum ReadinessDisplay {
  static func baselineValues(_ evidence: ReadinessMetricEvidence) -> [Double]? {
    guard let center = evidence.baseline?.center, let scale = evidence.baseline?.scale else { return nil }
    let values = [center, center - scale, center + scale]
    return evidence.feature.metric == .hrvSDNN ? values.map { exp($0) } : values
  }
  static func metric(_ evidence: ReadinessMetricEvidence) -> String {
    let f = evidence.feature
    let value = f.displayValue.map { String(format: "%.1f", $0) } ?? FangcunCopy.text("readiness.unknown")
    return FangcunCopy.text("readiness.metric", FangcunCopy.text("readiness.metric." + f.metric.rawValue),
      value, f.metric == .hrvSDNN ? "ms" : "bpm", evidence.baseline?.validDays ?? 0)
  }
}

struct ReadinessDetailView: View {
  let assessment: ReadinessAssessment?
  let snapshot: InsightsSnapshot
  var body: some View {
    List {
      Section {
        Text(FangcunCopy.text("readiness.boundary"))
        if let a = assessment {
          LabeledContent(FangcunCopy.text("readiness.identity"), value: String(a.assessmentID.prefix(12)) + " / v\(a.revision)")
            .accessibilityIdentifier("readiness.identity").accessibilityValue(a.assessmentID)
          Text(FangcunCopy.text("readiness.state." + a.availability.rawValue))
          if let level = a.level { Text(FangcunCopy.text("readiness.recordedLevel", FangcunCopy.text("readiness.level." + level.rawValue))) }
          Text(FangcunCopy.text("readiness.freshness." + a.freshness.rawValue))
          if a.refreshFailure != nil { Text(FangcunCopy.text("readiness.refreshError")) }
          if let duration = a.actualSleepSeconds {
            Text(FangcunCopy.text("readiness.sleepActual", duration / 3600, a.configuration.sleepTargetHours))
              .accessibilityIdentifier("readiness.sleep.actual")
          } else { Text(FangcunCopy.text("readiness.reason.sleepMissing")) }
          Text(a.sourceDetails[ReadinessMetric.sleep.rawValue]?.name ?? FangcunCopy.text("readiness.unknown"))
          ForEach(a.evidence, id: \.feature.metric) { e in
            VStack(alignment: .leading, spacing: 6) {
              Text(ReadinessDisplay.metric(e))
              Text(FangcunCopy.text(e.feature.metric == .hrvSDNN ? "readiness.stat.hrv" : "readiness.stat.rhr", e.feature.sampleCount, e.feature.coveredHours))
              if let values = ReadinessDisplay.baselineValues(e) {
                Text(FangcunCopy.text("readiness.baseline.reference", values[0], values[1], values[2], e.feature.metric == .hrvSDNN ? "ms" : "bpm"))
                  .accessibilityIdentifier("readiness.baseline.reference")
              }
              Text(FangcunCopy.text("readiness.window", FangcunCopy.timestamp(e.feature.window.start), FangcunCopy.timestamp(e.feature.window.end)))
              Text(FangcunCopy.text("readiness.measured", FangcunCopy.timestamp(e.feature.latestMeasuredAt)))
              Text(a.sourceDetails[e.feature.metric.rawValue]?.name ?? FangcunCopy.text("readiness.unknown"))
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          ForEach(Array(Set(a.missingReasons + a.qualityFlags)).sorted { $0.rawValue < $1.rawValue }, id: \.self) { reason in
            Text(FangcunCopy.text("readiness.reason." + reason.rawValue))
          }
          time("sleepEnd", a.sleepEndAt)
          time("measured", a.latestMeasuredAt)
          time("queried", a.queriedAt)
          time("computed", a.computedAt)
          time("validUntil", a.validUntil)
        } else { Text(FangcunCopy.text("readiness.summary.insufficient")) }
        time("attempt", snapshot.lastRefreshAttemptAt)
        time("success", snapshot.lastSuccessfulRefreshAt)
      }
      if let a = assessment {
        Section(FangcunCopy.text("readiness.context")) {
          ReadinessDayContext(date: a.sleepEndAt ?? a.computedAt, snapshot: snapshot)
          Text(FangcunCopy.text("readiness.contextBoundary"))
        }
      }
    }.navigationTitle(FangcunCopy.text("readiness.why"))
      .scrollContentBackground(.hidden).background(InnerBalanceTheme.canvas)
  }
  private func time(_ key: String, _ date: Date?) -> some View {
    Text(FangcunCopy.text("readiness." + key, FangcunCopy.timestamp(date)))
      .accessibilityIdentifier("readiness.time." + key).accessibilityValue(date?.ISO8601Format() ?? "none")
  }
}

struct ReadinessHistoryView: View {
  @Environment(\.recoveryOwner) private var recovery
  let owner: ReadinessCoordinator
  @Environment(FangcunDiary.self) private var diary
  @State private var span = 7
  @State private var selected = Calendar.current.startOfDay(for: Date.now)
  private var days: [Date] { (0..<span).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Calendar.current.startOfDay(for: owner.now)) } }
  private func records(_ date: Date) -> [ReadinessAssessment] {
    owner.snapshot.assessments.filter { Calendar.current.isDate($0.sleepEndAt ?? $0.computedAt, inSameDayAs: date) }
      .sorted { $0.computedAt > $1.computedAt }
  }
  private func marker(_ date: Date) -> String {
    guard let a = records(date).first else {
      return diary.allSnapshots.contains { Calendar.current.isDate($0.date, inSameDayAs: date) } ? "square.dashed" : "circle"
    }
    switch a.availability {
    case .assessable:
      switch a.level {
      case .usual: return "equal.circle"
      case .reduced: return "arrow.down.right.circle"
      case .low: return "arrow.down.circle"
      case nil: return "minus.circle"
      }
    case .provisional: return "circle.lefthalf.filled"
    case .limited: return "circle.dotted"
    case .awaitingData: return "clock"
    case .failed: return "exclamationmark.circle"
    case .insufficient: return "minus.circle"
    }
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Picker(FangcunCopy.text("readiness.range"), selection: $span) {
          Text(FangcunCopy.text("readiness.seven")).tag(7)
          Text(FangcunCopy.text("readiness.twentyEight")).tag(28)
        }.pickerStyle(.segmented).accessibilityIdentifier("readiness.history.range")
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
          ForEach(days, id: \.self) { date in
            Button { selected = date } label: {
              VStack {
                Text(date, format: .dateTime.day())
                Image(systemName: marker(date))
                  .frame(width: 20, height: 20)
              }.frame(minHeight: 50).frame(maxWidth: .infinity)
                .background(Calendar.current.isDate(date, inSameDayAs: selected) ? InnerBalanceTheme.subtleFill : .clear, in: RoundedRectangle(cornerRadius: 10))
            }.accessibilityIdentifier(records(date).isEmpty ? "readiness.history.day.empty" : "readiness.history.day.recorded")
              .accessibilityLabel(date.formatted(date: .abbreviated, time: .omitted) + " · " + (records(date).first.map { a in FangcunCopy.text("readiness.state." + a.availability.rawValue) + (a.level.map { " · " + FangcunCopy.text("readiness.level." + $0.rawValue) } ?? "") } ?? FangcunCopy.text(diary.allSnapshots.contains { Calendar.current.isDate($0.date, inSameDayAs: date) } ? "readiness.history.legacy" : "readiness.history.blank")))
          }
        }
        if let recovery { NavigationLink(FangcunCopy.text("recovery.history")) { RecoveryHistoryView(owner: recovery) } }
        Text(selected, format: .dateTime.year().month().day()).font(.headline)
        if records(selected).isEmpty { Text(FangcunCopy.text("readiness.history.blank")) }
        ForEach(records(selected), id: \.assessmentID) { a in
          NavigationLink { ReadinessDetailView(assessment: a, snapshot: owner.snapshot) } label: {
            VStack(alignment: .leading) {
              Text(FangcunCopy.text("readiness.state." + a.availability.rawValue))
              if let level = a.level { Text(FangcunCopy.text("readiness.recordedLevel", FangcunCopy.text("readiness.level." + level.rawValue))) }
              Text(FangcunCopy.text("readiness.sleepEnd", FangcunCopy.timestamp(a.sleepEndAt)))
              Text("v\(a.revision) · \(a.assessmentID.prefix(8))").font(.caption)
            }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
          }.accessibilityIdentifier("readiness.history.assessment")
        }
        ForEach(diary.allSnapshots.filter { Calendar.current.isDate($0.date, inSameDayAs: selected) }, id: \.date) { old in
          VStack(alignment: .leading) {
            Text(FangcunCopy.text("readiness.history.legacy")).font(.caption)
            Text(old.summary)
            Text(old.sleep)
          }.fangcunPaperCard()
        }
        let totals = FangcunDrinkTotals(diary.entries(on: selected))
        Text(FangcunCopy.text("readiness.history.drinks", totals.fluid, totals.caffeine))
        if totals.hasUnknownAlcohol { Text(FangcunCopy.text("diary.alcoholUnknown")) }
        ReadinessDayContext(date: selected, snapshot: owner.snapshot)
        Button(FangcunCopy.text("readiness.refresh")) { Task { await owner.refresh() } }
      }.padding(20)
    }.background(InnerBalanceTheme.canvas).navigationTitle(FangcunCopy.text("readiness.history"))
  }
}

/// Context is a dated record, never an input that rewards or rewrites an assessment.
struct ReadinessDayContext: View {
  let date: Date
  let snapshot: InsightsSnapshot
  @Environment(FangcunDiary.self) private var diary
  @Environment(\.recoveryOwner) private var recovery
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      let workouts = snapshot.ledger.normalizedSamples.filter { $0.metric == .workout && Calendar.current.isDate($0.end, inSameDayAs: date) }
      Text(FangcunCopy.text("readiness.context.workouts", workouts.count))
      ForEach(workouts, id: \.id) { row in
        Text(FangcunCopy.text("readiness.context.workout", FangcunCopy.timestamp(row.start), Int(row.end.timeIntervalSince(row.start) / 60), row.source.name))
      }
      ForEach(diary.entries(on: date), id: \.id) { drink in
        Text(FangcunCopy.text("readiness.context.drink", FangcunCopy.timestamp(drink.consumedAt), drink.kind.title, drink.volumeML))
      }
      if let recovery {
        ForEach(recovery.records.filter { $0.endedAt != nil && Calendar.current.isDate($0.startedAt, inSameDayAs: date) }, id: \.sessionID) { record in
          VStack(alignment: .leading) {
            Text(FangcunCopy.text("recovery.title." + record.action.id))
            Text(FangcunCopy.text("recovery.duration", Int(record.activeDuration)))
            Text(FangcunCopy.text("recovery.feedback.current", FangcunCopy.text("recovery.feedback." + (record.feedback?.helpfulness?.rawValue ?? "skipped"))))
          }
        }
      }
    }.accessibilityIdentifier("readiness.day.context")
  }
}

struct ReadinessSettingsView: View {
  let owner: ReadinessCoordinator
  @State private var clearConfirmation = false
  var body: some View {
    List {
      Toggle(FangcunCopy.text("readiness.enabled"), isOn: Binding(get: { owner.enabled }, set: { value in Task { await owner.setEnabled(value) } }))
      if owner.enabled {
        Stepper(value: Binding(get: { owner.configuration.sleepTargetHours }, set: { value in Task { await owner.setTarget(value) } }), in: 7...10, step: 0.5) {
          Text(FangcunCopy.text("readiness.target", owner.configuration.sleepTargetHours))
        }.accessibilityIdentifier("readiness.target")
        Section(FangcunCopy.text("readiness.sources")) {
          ForEach([ReadinessMetric.sleep, .hrvSDNN, .restingHeartRate], id: \.self) { metric in
            let samples = owner.snapshot.ledger.normalizedSamples.filter { $0.metric == metric }
            let sources = Dictionary(grouping: samples, by: \.sourceKey)
            ForEach(sources.keys.sorted(), id: \.self) { key in
              Button { Task { await owner.selectSource(key, metric: metric) } } label: {
                VStack(alignment: .leading) {
                  Text(FangcunCopy.text("readiness.metric." + metric.rawValue))
                  Text(sources[key]?.first?.source.name ?? key)
                  if owner.snapshot.sources[metric.rawValue]?.sourceKey == key { Image(systemName: "checkmark") }
                }
              }
            }
          }
        }
        Section(FangcunCopy.text("readiness.mainSleep")) {
          ForEach(owner.snapshot.episodes.filter { $0.end >= owner.now.addingTimeInterval(-48*3600) }, id: \.id) { episode in
            Button(FangcunCopy.timestamp(episode.start) + " – " + FangcunCopy.timestamp(episode.end)) {
              Task { await owner.selectSleep(episode.id) }
            }
          }
        }
        Button(FangcunCopy.text(owner.reading ? "readiness.stop" : "readiness.resume")) {
          Task { if owner.reading { await owner.stop() } else { await owner.resume() } }
        }
        Button(FangcunCopy.text("readiness.clear"), role: .destructive) { clearConfirmation = true }
        if let error = owner.errorKey { Text(FangcunCopy.text(error)) }
        Text(FangcunCopy.text("readiness.boundary"))
      }
    }.navigationTitle(FangcunCopy.text("readiness.settings"))
      .confirmationDialog(FangcunCopy.text("readiness.clearExplanation"), isPresented: $clearConfirmation, titleVisibility: .visible) {
        Button(FangcunCopy.text("readiness.clear"), role: .destructive) { Task { await owner.stop(clear: true) } }
      }
  }
}
