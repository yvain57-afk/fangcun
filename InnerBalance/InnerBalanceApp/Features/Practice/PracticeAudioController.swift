import Foundation
import InnerBalanceCore
import Observation

@MainActor
@Observable
final class PracticeAudioController {
  private let coordinator: any PracticeAudioCoordinating
  private var configuredKind: PracticeKind?
  private var configuredPlan: PracticeAudioPlan?
  private var lastMomentID: Int?
  private var lastTimelineGeneration: Int?
  private var generation = 0
  private var isRecoveringConfiguration = false
  private var configurationRecoveryTask: Task<Void, Never>?
  private(set) var canContinueInBackground = false

  var configurationChangeSource: AnyObject { coordinator.configurationChangeSource }

  init(coordinator: any PracticeAudioCoordinating = PracticeAudioCoordinator()) {
    self.coordinator = coordinator
  }

  func run(
    _ viewModel: PracticeSessionViewModel,
    mode: PracticeSoundMode,
    ambienceEnabled: Bool
  ) async {
    let plan = PracticeAudioPlan.make(mode: mode, ambienceEnabled: ambienceEnabled)
    switch viewModel.phase {
    case .running:
      guard await prepareIfNeeded(kind: viewModel.plan.kind, plan: plan) else {
        if !Task.isCancelled { viewModel.handleInterruption() }
        return
      }
      while !Task.isCancelled && viewModel.phase == .running {
        guard viewModel.remainingTime > 0 else {
          coordinator.pause()
          return
        }
        let moment = PracticeAudioTimeline.moment(for: viewModel.plan.kind, snapshot: viewModel.timelineSnapshot)
        if moment.id != lastMomentID || lastTimelineGeneration != viewModel.timelineGeneration {
          lastTimelineGeneration = viewModel.timelineGeneration
          lastMomentID = moment.id
          coordinator.play(moment)
        }
        try? await Task.sleep(for: .milliseconds(25))
      }
    case .paused:
      lastMomentID = nil
      coordinator.pause()
    case .ready, .comparison, .saved:
      stop()
    }
  }

  func stop() {
    generation += 1
    configurationRecoveryTask?.cancel()
    configurationRecoveryTask = nil
    coordinator.stop()
    configuredKind = nil
    configuredPlan = nil
    lastMomentID = nil
    lastTimelineGeneration = nil
    canContinueInBackground = false
  }

  func scheduleEngineConfigurationRecovery(_ viewModel: PracticeSessionViewModel) {
    canContinueInBackground = false
    configurationRecoveryTask?.cancel()
    configurationRecoveryTask = Task { @MainActor [weak self, weak viewModel] in
      do {
        try await Task.sleep(for: .milliseconds(120))
      } catch {
        return
      }
      guard let self, let viewModel, !Task.isCancelled else { return }
      configurationRecoveryTask = nil
      await handleEngineConfigurationChange(viewModel)
    }
  }

  func handleEngineConfigurationChange(_ viewModel: PracticeSessionViewModel) async {
    guard !isRecoveringConfiguration else { return }
    guard
      viewModel.phase == .running,
      let kind = configuredKind,
      let plan = configuredPlan
    else {
      stop()
      viewModel.handleInterruption()
      return
    }

    isRecoveringConfiguration = true
    defer { isRecoveringConfiguration = false }
    stop()
    if !(await prepareIfNeeded(kind: kind, plan: plan)), !Task.isCancelled {
      viewModel.handleInterruption()
    }
  }

  @discardableResult
  private func prepareIfNeeded(kind: PracticeKind, plan: PracticeAudioPlan) async -> Bool {
    let request = generation
    do {
      let isNewConfiguration = kind != configuredKind || plan != configuredPlan
      let continuous = try await coordinator.prepare(kind: kind, plan: plan)
      guard !Task.isCancelled, request == generation else { return false }
      canContinueInBackground = continuous
      if isNewConfiguration {
        configuredKind = kind
        configuredPlan = plan
        lastMomentID = nil
      }
      return true
    } catch {
      guard !Task.isCancelled, request == generation else { return false }
      stop()
      return false
    }
  }
}
