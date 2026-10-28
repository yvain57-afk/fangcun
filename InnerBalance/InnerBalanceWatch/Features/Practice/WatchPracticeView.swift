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
    .navigationTitle("Take a pause")
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
          Label("Stop if painful or uncomfortable", systemImage: "exclamationmark.triangle")
            .font(.caption2)
            .foregroundStyle(.yellow)
        }
      }
      Section("Choose your time") {
        ForEach(plan.durationOptions, id: \.self) { duration in
          NavigationLink {
            WatchPracticeSessionView(
              plan: plan,
              duration: duration,
              coordinator: coordinator
            )
          } label: {
            Label("Begin · \(max(1, Int(duration / 60))) min", systemImage: "play.fill")
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
        Text("Practice saved")
          .font(.headline)
          .multilineTextAlignment(.center)
        Button("Done") { dismiss() }
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
            Toggle("Haptic rhythm", isOn: $hapticCadenceEnabled)
              .tint(.mint)
              .accessibilityHint("Gentle taps at transitions")
              .accessibilityIdentifier("watch.practice.haptics")
            if isEvidenceEligible {
              Toggle("Heart rate during practice", isOn: $evidenceRequested)
                .tint(.mint)
              Text("Uses a workout session to read heart rate. The workout is discarded at the end; no workout record is created.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            if evidenceUnavailable {
              Text("Heart rate is unavailable. Your practice can continue without it.")
                .font(.caption2)
                .foregroundStyle(.yellow)
                .multilineTextAlignment(.center)
            }
            Button(isStarting ? "Getting ready…" : "Start") {
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
                Text(pausedAt == nil ? cue(at: context.date) : "Paused")
                  .font(.headline)
                  .multilineTextAlignment(.center)
                  .frame(minHeight: 42)
              }
              if let heartRate = evidenceSession.latestBeatsPerMinute {
                Label("\(Int(heartRate.rounded())) bpm", systemImage: "heart.fill")
                  .font(.caption2.monospacedDigit())
                  .foregroundStyle(.mint)
                  .accessibilityLabel("Current heart rate, \(Int(heartRate.rounded())) beats per minute")
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
          .accessibilityLabel(pausedAt == nil ? "Pause" : "Continue")
          Button {
            Task { await finish() }
          } label: {
            Image(systemName: "stop.fill")
          }
          .accessibilityLabel("End and save")
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
      "Couldn't save",
      isPresented: Binding(
        get: { saveErrorMessage != nil },
        set: { if !$0 { saveErrorMessage = nil } }
      )
    ) {
      Button("Try again") {
        saveErrorMessage = nil
        Task { await finish() }
      }
      Button("Later", role: .cancel) {}
    } message: {
      Text(saveErrorMessage ?? "Please try again.")
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
      Text(pausedAt == nil ? state.phase.title : "Paused")
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
          Text("\(state.remainingWholeSeconds) sec")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: 82, height: 82)
      Text("\(clock(remaining(at: date))) remaining")
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
      case 0..<3: "Gently in"
      case 3..<5: "A little more"
      default: "Slowly out"
      }
    case .pacedBreathing: return Int(elapsed) % 10 < 4 ? "Breathe in" : "A longer exhale"
    case .meditation: return "Notice an ordinary breath"
    case .nsdr: return "Feel your support"
    case .kegel: return Int(elapsed) % 12 < 4 ? "Gently lift" : "Release fully"
    default: return "Try this practice on your iPhone"
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
    guard !isStarting, plan.kind.isLegacyWatchExecutable else { return }
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
      saveErrorMessage = "Keep going a little longer before saving."
      isSaving = false
      return
    }
    guard
      persistLocalCompletion(
        snapshot,
        healthWriteStatus: plan.kind == .kegel ? "local_only" : "local_pending"
      )
    else {
      saveErrorMessage = "This practice hasn't been saved because device storage failed."
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
      saveErrorMessage = "Saved on your Watch. Apple Health couldn't be queued for retry. Try again in Sync status."
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
    case .physiologicalSigh: "A little sigh"
    case .pacedBreathing: "Longer exhale"
    case .meditation: "A quiet moment"
    case .nsdr: "NSDR"
    case .kegel: "Pelvic floor"
    case .balancedBreathing: "Even breathing"
    case .boxBreathing: "Box breathing"
    case .diaphragmaticBreathing: "Belly breathing"
    case .alternateNostrilBreathing: "Alternate nostril"
    case .progressiveMuscleRelaxation: "Muscle relaxation"
    }
  }

  fileprivate var watchDetail: String {
    switch self {
    case .physiologicalSigh: "1 min · A little pause"
    case .pacedBreathing: "3 / 5 min"
    case .meditation: "5 / 10 min"
    case .nsdr: "10 / 20 min · Rest"
    case .kegel: "Pelvic floor lift and release · 3 min"
    default: "Practice on iPhone"
    }
  }

  fileprivate var watchPreparation: String {
    switch self {
    case .physiologicalSigh: "Sit or stand steadily. Keep each breath gentle."
    case .pacedBreathing: "Find an easy breathing rhythm."
    case .meditation: "Notice your breath and the support beneath you."
    case .nsdr: "Lie down or recline safely. Never practice while driving."
    case .kegel: "Breathe naturally. Don't practice while urinating."
    default: "This practice is available on your iPhone."
    }
  }

  fileprivate var watchSystemImage: String {
    switch self {
    case .physiologicalSigh: "wind"
    case .pacedBreathing: "circle.dotted.circle"
    case .meditation: "figure.mind.and.body"
    case .nsdr: "bed.double.fill"
    case .kegel: "figure.core.training"
    default: "iphone"
    }
  }
}
