import InnerBalanceCore
import SwiftData
import SwiftUI
import WatchKit

struct WatchPracticeLibraryView: View {
  let coordinator: WatchHealthWriteCoordinator

  var body: some View {
    List(PracticeCatalog.buildOne, id: \.kind.rawValue) { plan in
      NavigationLink {
        WatchPracticeDurationView(plan: plan, coordinator: coordinator)
      } label: {
        VStack(alignment: .leading, spacing: 2) {
          Text(plan.kind.watchTitle)
            .font(.headline)
          Text(plan.kind.watchDetail)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
    }
    .navigationTitle("开始调节")
  }
}

private struct WatchPracticeDurationView: View {
  let plan: PracticeProtocol
  let coordinator: WatchHealthWriteCoordinator

  var body: some View {
    List {
      Section {
        Text(plan.kind.watchPreparation)
          .font(.footnote)
          .foregroundStyle(.secondary)
        if plan.kind == .kegel {
          Label("疼痛或不适立即停止", systemImage: "exclamationmark.triangle")
            .font(.caption2)
            .foregroundStyle(.yellow)
        }
      }
      Section("选择时长") {
        ForEach(plan.durationOptions, id: \.self) { duration in
          NavigationLink {
            WatchPracticeSessionView(
              plan: plan,
              duration: duration,
              coordinator: coordinator
            )
          } label: {
            Label("开始 \(max(1, Int(duration / 60))) 分钟", systemImage: "play.fill")
          }
        }
      }
    }
    .navigationTitle(plan.kind.watchTitle)
  }
}

private struct WatchPracticeSessionView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @State private var startedAt: Date?
  @State private var pausedAt: Date?
  @State private var pausedDuration: TimeInterval = 0
  @State private var isCompleted = false
  @State private var isSaving = false
  @State private var isStarting = false
  @State private var evidenceRequested = false
  @State private var hapticCadenceEnabled = true
  @State private var lastHapticCueID: Int?
  @State private var evidenceUnavailable = false
  @State private var evidenceSession = LiveHeartRateSession()
  @State private var saveErrorMessage: String?
  @State private var sessionID = UUID().uuidString
  @State private var completionFreezer = WatchPracticeCompletionFreezer()

  let plan: PracticeProtocol
  let duration: TimeInterval
  let coordinator: WatchHealthWriteCoordinator

  var body: some View {
    VStack(spacing: 9) {
      if isCompleted {
        Image(systemName: "checkmark.circle.fill")
          .font(.largeTitle)
          .foregroundStyle(.mint)
        Text("已保留本次练习")
          .font(.headline)
          .multilineTextAlignment(.center)
        Button("完成") { dismiss() }
          .buttonStyle(.borderedProminent)
          .tint(.mint)
      } else if startedAt == nil {
        ScrollView {
          VStack(spacing: 8) {
            Image(systemName: plan.kind.watchSystemImage)
              .font(.largeTitle)
              .foregroundStyle(.mint)
            Text(plan.kind.watchPreparation)
              .font(.footnote)
              .multilineTextAlignment(.center)
              .foregroundStyle(.secondary)
            Toggle("触觉节奏", isOn: $hapticCadenceEnabled)
              .tint(.mint)
              .accessibilityHint("在节奏切换时轻触提示")
              .accessibilityIdentifier("watch.practice.haptics")
            if isEvidenceEligible {
              Toggle("身体证据", isOn: $evidenceRequested)
                .tint(.mint)
              Text("开启后使用训练会话取得心率；结束时丢弃训练，不产生训练记录。")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            if evidenceUnavailable {
              Text("心率证据不可用，本次已退化为普通练习。")
                .font(.caption2)
                .foregroundStyle(.yellow)
                .multilineTextAlignment(.center)
            }
            Button(isStarting ? "正在准备…" : "开始") {
              Task { await startPractice() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
            .disabled(isStarting)
          }
          .padding(.vertical, 4)
        }
      } else {
        ScrollView {
          TimelineView(.periodic(from: .now, by: 0.5)) { context in
            VStack(spacing: 8) {
              if isBreathingPractice {
                watchBreathGuide(at: context.date)
              } else {
                Text(clock(remaining(at: context.date)))
                  .font(.system(.title, design: .rounded, weight: .semibold))
                  .monospacedDigit()
                Text(pausedAt == nil ? cue(at: context.date) : "已暂停")
                  .font(.headline)
                  .multilineTextAlignment(.center)
                  .frame(minHeight: 42)
              }
              if let heartRate = evidenceSession.latestBeatsPerMinute {
                Label("\(Int(heartRate.rounded())) 次/分", systemImage: "heart.fill")
                  .font(.caption2.monospacedDigit())
                  .foregroundStyle(.mint)
                  .accessibilityLabel("实时心率 \(Int(heartRate.rounded())) 次每分钟")
              }
            }
          }
        }
        HStack {
          Button {
            togglePause()
          } label: {
            Image(systemName: pausedAt == nil ? "pause.fill" : "play.fill")
          }
          .accessibilityLabel(pausedAt == nil ? "暂停" : "继续")
          Button {
            Task { await finish() }
          } label: {
            Image(systemName: "stop.fill")
          }
          .accessibilityLabel("结束并保存")
          .disabled(isSaving)
        }
      }
    }
    .navigationTitle(plan.kind.watchTitle)
    .navigationBarTitleDisplayMode(.inline)
    .task(id: startedAt) {
      while !Task.isCancelled, startedAt != nil, !isCompleted,
        completionFreezer.snapshot == nil
      {
        let now = Date.now
        if remaining(at: now) <= 0 {
          await finish()
          return
        }
        let elapsed = duration - remaining(at: now)
        if PracticeHapticCadence.consumeCue(
          for: plan.kind,
          elapsed: elapsed,
          isActive: pausedAt == nil,
          isEnabled: hapticCadenceEnabled,
          lastCueID: &lastHapticCueID
        ) {
          WKInterfaceDevice.current().play(.click)
        }
        try? await Task.sleep(for: .milliseconds(250))
      }
    }
    .onDisappear {
      guard evidenceRequested else { return }
      Task { _ = await evidenceSession.stopAndDiscard() }
    }
    .alert(
      "未能完成保存",
      isPresented: Binding(
        get: { saveErrorMessage != nil },
        set: { if !$0 { saveErrorMessage = nil } }
      )
    ) {
      Button("重试") {
        saveErrorMessage = nil
        Task { await finish() }
      }
      Button("稍后", role: .cancel) {}
    } message: {
      Text(saveErrorMessage ?? "请重试。")
    }
  }

  private var isEvidenceEligible: Bool {
    guard let minimum = plan.minimumEvidenceDuration else { return false }
    return duration >= minimum
  }

  private var isBreathingPractice: Bool {
    plan.kind == .physiologicalSigh || plan.kind == .pacedBreathing
  }

  @ViewBuilder
  private func watchBreathGuide(at date: Date) -> some View {
    let elapsed = duration - remaining(at: date)
    let state = PracticeBreathGuide.state(for: plan.kind, elapsed: elapsed)
    VStack(spacing: 5) {
      Text(pausedAt == nil ? state.phase.title : "已暂停")
        .font(.title2.weight(.semibold))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      ZStack {
        Circle()
          .stroke(Color.mint.opacity(0.18), lineWidth: 9)
        Circle()
          .trim(from: 0, to: pausedAt == nil ? state.progress : 0)
          .stroke(
            Color.mint,
            style: StrokeStyle(lineWidth: 5, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
        if pausedAt == nil {
          Text("\(state.remainingWholeSeconds) 秒")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: 82, height: 82)
      Text("整段还有 \(clock(remaining(at: date)))")
        .font(.caption2.monospacedDigit())
        .foregroundStyle(.secondary)
    }
  }

  private func remaining(at date: Date) -> TimeInterval {
    guard let startedAt else { return duration }
    let reference = pausedAt ?? date
    return max(0, duration - reference.timeIntervalSince(startedAt) + pausedDuration)
  }

  private func cue(at date: Date) -> String {
    let elapsed = duration - remaining(at: date)
    switch plan.kind {
    case .physiologicalSigh:
      return switch Int(elapsed) % 12 {
      case 0..<3: "轻吸一口"
      case 3..<5: "再补一小口"
      default: "缓慢呼出"
      }
    case .pacedBreathing: return Int(elapsed) % 10 < 4 ? "慢慢吸气" : "更慢地呼气"
    case .meditation: return "注意一次自然呼吸"
    case .nsdr: return "感受身体的支撑"
    case .kegel: return Int(elapsed) % 12 < 4 ? "轻轻收紧" : "完全放松"
    }
  }

  private func clock(_ interval: TimeInterval) -> String {
    let seconds = max(0, Int(interval.rounded(.up)))
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
  }

  private func togglePause() {
    if let pausedAt {
      pausedDuration += Date.now.timeIntervalSince(pausedAt)
      self.pausedAt = nil
      evidenceSession.resume()
    } else {
      pausedAt = .now
      evidenceSession.pause()
    }
  }

  private func startPractice() async {
    guard !isStarting else { return }
    isStarting = true
    if evidenceRequested {
      let startedEvidence = await evidenceSession.start()
      evidenceUnavailable = !startedEvidence
    }
    startedAt = evidenceSession.startDate ?? .now
    lastHapticCueID = PracticeHapticCadence.cueID(for: plan.kind, elapsed: 0)
    isStarting = false
    WKInterfaceDevice.current().play(.start)
  }

  private func finish() async {
    guard startedAt != nil, !isSaving else { return }
    isSaving = true
    let end = completionFreezer.snapshot?.endedAt ?? Date.now
    var snapshot = completionFreezer.freeze(
      sessionID: sessionID,
      endedAt: end,
      activeDuration: duration - remaining(at: end),
      heartRateEvidenceRequested: evidenceRequested
    )
    pausedAt = snapshot.endedAt
    if !snapshot.heartRateEvidenceCaptureCompleted {
      let evidence = await evidenceSession.stopAndDiscard()
      snapshot = completionFreezer.completeHeartRateEvidenceCapture(evidence) ?? snapshot
    }
    guard snapshot.activeDuration > 0 else {
      saveErrorMessage = "练习时间太短，请继续后再保存。"
      isSaving = false
      return
    }
    guard
      persistLocalCompletion(
        snapshot,
        healthWriteStatus: plan.kind == .kegel ? "local_only" : "local_pending"
      )
    else {
      saveErrorMessage = "本地存储失败，方寸没有把本次练习标记为已保存。"
      isSaving = false
      return
    }
    var healthSavedOrQueued = true
    if plan.kind != .kegel {
      healthSavedOrQueued = await coordinator.save(
        .mindful(
          WatchMindfulPayload(
            syncIdentifier: "com.yvainair.innerbalance.mindful.watch.\(snapshot.sessionID)",
            sessionID: snapshot.sessionID,
            practiceKind: plan.kind,
            startDate: snapshot.endedAt.addingTimeInterval(-snapshot.activeDuration),
            endDate: snapshot.endedAt,
            heartRateEvidenceRequested: snapshot.heartRateEvidenceRequested,
            heartRateEvidence: snapshot.heartRateEvidence
          )
        )
      )
    }
    isSaving = false
    guard healthSavedOrQueued else {
      _ = persistLocalCompletion(
        snapshot,
        healthWriteStatus: "health_attention"
      )
      saveErrorMessage = "练习已保存在手表，但 Apple 健康写入未能加入重试队列。请在「同步状态」中重试。"
      return
    }
    _ = persistLocalCompletion(
      snapshot,
      healthWriteStatus: plan.kind == .kegel ? "local_only" : "saved_or_queued"
    )
    isCompleted = true
    WKInterfaceDevice.current().play(.success)
  }

  private func persistLocalCompletion(
    _ snapshot: WatchPracticeCompletionSnapshot,
    healthWriteStatus: String
  ) -> Bool {
    let identifier = snapshot.sessionID
    let descriptor = FetchDescriptor<WatchPracticeCompletion>(
      predicate: #Predicate { $0.sessionID == identifier }
    )
    do {
      if let existing = try modelContext.fetch(descriptor).first {
        existing.activeDuration = snapshot.activeDuration
        existing.endedAt = snapshot.endedAt
        existing.healthWriteStatus = healthWriteStatus
      } else {
        modelContext.insert(
          WatchPracticeCompletion(
            sessionID: snapshot.sessionID,
            practiceKind: plan.kind,
            activeDuration: snapshot.activeDuration,
            endedAt: snapshot.endedAt,
            healthWriteStatus: healthWriteStatus
          )
        )
      }
      if let record = try modelContext.fetch(descriptor).first {
        record.startedAt = startedAt; record.plannedDuration = duration
      }
      try modelContext.save()
      if let startedAt {
        Task { await WatchSyncLifecycle.shared.completed(sessionID: snapshot.sessionID, kind: plan.kind,
          planned: duration, active: snapshot.activeDuration, started: startedAt, ended: snapshot.endedAt) }
      }
      return true
    } catch {
      return false
    }
  }
}

extension PracticeKind {
  fileprivate var watchTitle: String {
    switch self {
    case .physiologicalSigh: "生理性叹息"
    case .pacedBreathing: "节律呼吸"
    case .meditation: "冥想放松"
    case .nsdr: "NSDR"
    case .kegel: "凯格尔"
    }
  }

  fileprivate var watchDetail: String {
    switch self {
    case .physiologicalSigh: "1 分钟·高激活"
    case .pacedBreathing: "3 / 5 分钟"
    case .meditation: "5 / 10 分钟"
    case .nsdr: "10 / 20 分钟·疲惫"
    case .kegel: "盆底肌收紧与放松·3 分钟"
    }
  }

  fileprivate var watchPreparation: String {
    switch self {
    case .physiologicalSigh: "站稳或坐稳，呼吸不用很深。"
    case .pacedBreathing: "找到不费力的呼吸节律。"
    case .meditation: "把注意力放在呼吸和支撑感上。"
    case .nsdr: "请躺下或半躺，确保暂时不需要驾驶。"
    case .kegel: "保持自然呼吸，不在排尿时练习。"
    }
  }

  fileprivate var watchSystemImage: String {
    switch self {
    case .physiologicalSigh: "wind"
    case .pacedBreathing: "circle.dotted.circle"
    case .meditation: "figure.mind.and.body"
    case .nsdr: "bed.double.fill"
    case .kegel: "figure.core.training"
    }
  }
}
