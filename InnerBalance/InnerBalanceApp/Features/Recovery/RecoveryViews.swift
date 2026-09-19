import SwiftUI
import InnerBalanceCore

struct RecoverySuggestionView: View {
  let owner: RecoveryCoordinator
  let assessment: ReadinessAssessment?
  let onPractice: (PracticeKind, TimeInterval) -> Void
  @State private var goal: RecoveryGoal = .rest
  @State private var environment: RecoveryEnvironment = .seated
  @State private var seconds = 120.0
  @State private var choosing = false
  @State private var selected: LocalActionLaunch?
  private var recommendation: RecoveryRecommendation? {
    RecoveryRecommendationEngine.recommend(assessment: assessment, goal: goal, seconds: seconds,
      environment: environment, uncomfortable: owner.uncomfortable)
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let recommendation {
        Button { launch(recommendation.action, duration: recommendation.duration) } label: {
          Label(FangcunCopy.text("recovery.title." + recommendation.action.id), systemImage: "leaf")
        }.accessibilityIdentifier("recovery.suggestion")
      } else { Text(FangcunCopy.text("recovery.unavailable")) }
      Button(FangcunCopy.text("recovery.change")) { choosing = true }.accessibilityIdentifier("recovery.change")
    }.font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
      .onChange(of: environment) { _, value in owner.environment = value }
      .sheet(isPresented: $choosing) {
        NavigationStack {
          Form {
            Picker(FangcunCopy.text("recovery.goal"), selection: $goal) {
              ForEach(RecoveryGoal.allCases, id: \.self) { Text(FangcunCopy.text("recovery.goal." + $0.rawValue)).tag($0) }
            }
            Picker(FangcunCopy.text("recovery.environment"), selection: $environment) {
              ForEach(RecoveryEnvironment.allCases, id: \.self) { Text(FangcunCopy.text("recovery.environment." + $0.rawValue)).tag($0) }
            }
            Stepper(FangcunCopy.text("recovery.seconds", Int(seconds)), value: $seconds, in: 60...300, step: 60)
            ForEach(RecoveryActionKind.localActions, id: \.id) { action in
              Button(FangcunCopy.text("recovery.title." + action.id)) { choosing = false; launch(action, duration: RecoveryProtocol.local(action)!.duration) }
                .disabled(environment == .driving || environment == .unavailable || (action == .movementBreak && environment != .canMove))
                .accessibilityIdentifier("recovery.choose." + action.id)
            }
            Text(FangcunCopy.text("recovery.safety"))
          }.navigationTitle(FangcunCopy.text("recovery.change"))
        }.presentationDetents([.medium, .large])
      }
      .fullScreenCover(item: $selected) { launch in
        RecoverySessionView(owner: owner, plan: RecoveryProtocol.local(launch.action)!, environment: environment)
      }
  }
  private func launch(_ action: RecoveryActionKind, duration: TimeInterval) {
    if case .practice(let kind) = action { onPractice(kind, duration) }
    else { selected = LocalActionLaunch(action: action) }
  }
}
private struct LocalActionLaunch: Identifiable { let action: RecoveryActionKind; var id: String { action.id } }

struct RecoverySessionView: View {
  let owner: RecoveryCoordinator
  let environment: RecoveryEnvironment
  @State private var model: RecoverySessionModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  init(owner: RecoveryCoordinator, plan: RecoveryProtocol, environment: RecoveryEnvironment) {
    self.owner = owner; self.environment = environment; _model = State(initialValue: .init(plan: plan))
  }
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 22) {
          FangcunCompanion(scene: FangcunDayState.insufficient.scene, paused: true).frame(maxWidth: 180)
          Text(FangcunCopy.text("recovery.title." + model.plan.action.id)).font(.title2)
          Text(FangcunCopy.text(model.plan.safetyKey)).font(.subheadline).fixedSize(horizontal: false, vertical: true)
          switch model.phase {
          case .ready:
            Text(FangcunCopy.text(model.plan.preparationKey))
            Button(FangcunCopy.text("recovery.start")) { model.start(environment: environment) }
              .buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("recovery.start")
          case .running, .paused:
            Text(FangcunCopy.text(model.plan.stageKeys[model.elapsed < model.plan.duration/2 ? 0 : 1]))
            Text(FangcunCopy.text("recovery.remaining", Int(max(0, model.plan.duration - model.elapsed))))
              .monospacedDigit().accessibilityIdentifier("recovery.remaining")
            Button(FangcunCopy.text(model.phase == .running ? "recovery.pause" : "recovery.resume")) {
              if model.phase == .running { model.pause() } else { model.resume() }
            }.accessibilityIdentifier("recovery.pauseResume")
            Button(FangcunCopy.text("recovery.finish")) { Task { await model.finish(owner: owner) } }
              .accessibilityIdentifier("recovery.finish")
          case .saving:
            if model.failed {
              Text(FangcunCopy.text("recovery.storageError"))
              Button(FangcunCopy.text("recovery.retry")) { Task { await model.finish(owner: owner) } }.accessibilityIdentifier("recovery.retry")
            } else { ProgressView() }
          case .feedback:
            Text(FangcunCopy.text("recovery.saved"))
            ForEach(RecoveryHelpfulness.allCases, id: \.self) { value in
              Button(FangcunCopy.text("recovery.feedback." + value.rawValue)) { Task { await model.feedback(owner: owner, value: value) } }
                .accessibilityIdentifier("recovery.feedback." + value.rawValue)
            }
            Button(FangcunCopy.text("recovery.skip")) { Task { await model.feedback(owner: owner, value: nil) } }
              .accessibilityIdentifier("recovery.skip")
          case .done:
            Text(FangcunCopy.text("recovery.saved"))
            Button(FangcunCopy.text("recovery.done")) { dismiss() }.accessibilityIdentifier("recovery.done")
          }
          if let error = owner.errorKey { Text(FangcunCopy.text(error)) }
        }.padding(24).frame(maxWidth: .infinity)
      }.background(InnerBalanceTheme.canvas)
        .toolbar {
          if model.phase == .ready || model.phase == .done || model.phase == .feedback {
            Button(FangcunCopy.text("recovery.close")) { dismiss() }
          }
        }
    }.interactiveDismissDisabled(model.phase != .ready && model.phase != .done)
      .task(id: model.phase) {
        guard model.phase == .running else { return }
        await model.checkpoint(owner: owner)
        var ticks = 0
        while !Task.isCancelled && model.phase == .running {
          try? await Task.sleep(for: .seconds(1)); guard !Task.isCancelled else { return }
          model.tick(); ticks += 1
          if model.elapsed >= model.plan.duration { await model.finish(owner: owner); return }
          if ticks % 10 == 0 { await model.checkpoint(owner: owner) }
        }
      }
      .onChange(of: scenePhase) { _, phase in
        if phase != .active { model.pause(); Task { await model.checkpoint(owner: owner) } }
      }
  }
}

struct RecoveryHistoryView: View {
  let owner: RecoveryCoordinator
  var body: some View {
    List {
      ForEach(owner.records.filter { $0.endedAt != nil }, id: \.sessionID) { record in
        NavigationLink {
          List {
            Text(record.startedAt, format: .dateTime.month().day().hour().minute())
            Text(FangcunCopy.text("recovery.duration", Int(record.activeDuration)))
            Text(FangcunCopy.text("recovery.reason." + (record.endReason?.rawValue ?? "legacyUnknown")))
            Text(FangcunCopy.text("recovery.feedback.current", record.feedback.map { FangcunCopy.text("recovery.feedback." + ($0.helpfulness?.rawValue ?? "skipped")) } ?? FangcunCopy.text("recovery.feedback.skipped")))
              .accessibilityIdentifier("recovery.feedback.current")
            ForEach(RecoveryHelpfulness.allCases, id: \.self) { value in
              Button(FangcunCopy.text("recovery.feedback." + value.rawValue)) { Task { _ = await owner.feedback(record.sessionID, value) } }
            }
            Button(FangcunCopy.text("recovery.skip")) { Task { _ = await owner.feedback(record.sessionID, nil) } }
            if let counts = RecoveryFeedbackSummary.counts(owner.records, action: record.action) {
              Text(FangcunCopy.text("recovery.counts", counts[.helpful] ?? 0, counts[.unchanged] ?? 0, counts[.uncomfortable] ?? 0))
            }
            if let error = owner.errorKey { Text(FangcunCopy.text(error)) }
          }
        } label: {
          VStack(alignment: .leading) {
            Text(FangcunCopy.text("recovery.title." + record.action.id))
            Text(record.startedAt, format: .dateTime.month().day().hour().minute()).font(.caption)
          }
        }.accessibilityIdentifier("recovery.history.record")
      }
    }.navigationTitle(FangcunCopy.text("recovery.history"))
  }
}
