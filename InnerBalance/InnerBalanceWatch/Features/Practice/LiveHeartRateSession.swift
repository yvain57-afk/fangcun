import HealthKit
import InnerBalanceCore
import Observation

enum LiveHeartRateSessionState: Equatable, Sendable {
  case idle
  case starting
  case running
  case paused
  case unavailable
  case stopped
}

@MainActor
@Observable
final class LiveHeartRateSession: NSObject {
  private let healthStore = HKHealthStore()
  private var workoutSession: HKWorkoutSession?
  private var workoutBuilder: HKLiveWorkoutBuilder?
  private var samples: [HeartRateSample] = []
  private var cleanupCompleted = false
  private var isCleaningUp = false
  private var finalEvidence: HeartRateEvidence?

  private(set) var state: LiveHeartRateSessionState = .idle
  private(set) var latestBeatsPerMinute: Double?
  private(set) var startDate: Date?
  private(set) var endDate: Date?

  func start() async -> Bool {
    guard state == .idle else { return state == .running }
    state = .starting
    let heartRateType = HKQuantityType(.heartRate)
    do {
      try await healthStore.requestAuthorization(
        toShare: [HKWorkoutType.workoutType()],
        read: [heartRateType]
      )
      let configuration = HKWorkoutConfiguration()
      configuration.activityType = .mindAndBody
      configuration.locationType = .unknown

      let session = try HKWorkoutSession(
        healthStore: healthStore,
        configuration: configuration
      )
      let builder = session.associatedWorkoutBuilder()
      builder.dataSource = HKLiveWorkoutDataSource(
        healthStore: healthStore,
        workoutConfiguration: configuration
      )
      session.delegate = self
      builder.delegate = self
      workoutSession = session
      workoutBuilder = builder

      let start = Date.now
      startDate = start
      session.startActivity(with: start)
      try await builder.beginCollection(at: start)
      state = .running
      return true
    } catch {
      _ = await shutdownAndDiscard(finalState: .unavailable)
      return false
    }
  }

  func pause() {
    guard state == .running else { return }
    workoutSession?.pause()
    state = .paused
  }

  func resume() {
    guard state == .paused else { return }
    workoutSession?.resume()
    state = .running
  }

  func stopAndDiscard() async -> HeartRateEvidence? {
    await shutdownAndDiscard(finalState: .stopped)
  }

  private func shutdownAndDiscard(
    finalState: LiveHeartRateSessionState
  ) async -> HeartRateEvidence? {
    if cleanupCompleted { return finalEvidence }
    if isCleaningUp {
      while isCleaningUp {
        await Task.yield()
      }
      return finalEvidence
    }
    isCleaningUp = true
    defer {
      isCleaningUp = false
      cleanupCompleted = true
    }
    let end = Date.now
    endDate = end
    workoutSession?.stopActivity(with: end)
    if let workoutBuilder {
      _ = try? await workoutBuilder.endCollection(at: end)
      workoutBuilder.discardWorkout()
    }
    workoutSession?.end()
    self.workoutBuilder = nil
    workoutSession = nil
    if let startDate {
      finalEvidence = HeartRateEvidenceAnalyzer.analyze(
        samples: samples,
        startDate: startDate,
        endDate: end
      )
    }
    state = finalState
    return finalEvidence
  }

  private func collect(from builder: HKLiveWorkoutBuilder) {
    let heartRateType = HKQuantityType(.heartRate)
    guard let statistics = builder.statistics(for: heartRateType),
      let quantity = statistics.mostRecentQuantity(),
      let dateInterval = statistics.mostRecentQuantityDateInterval()
    else { return }
    let value = quantity.doubleValue(for: .count().unitDivided(by: .minute()))
    guard value.isFinite, (30...220).contains(value) else { return }
    if samples.last?.date != dateInterval.end {
      samples.append(HeartRateSample(date: dateInterval.end, beatsPerMinute: value))
    }
    latestBeatsPerMinute = value
  }
}

extension LiveHeartRateSession: HKWorkoutSessionDelegate {
  nonisolated func workoutSession(
    _ workoutSession: HKWorkoutSession,
    didChangeTo toState: HKWorkoutSessionState,
    from fromState: HKWorkoutSessionState,
    date: Date
  ) {
    Task { @MainActor in
      guard !cleanupCompleted else { return }
      switch toState {
      case .running: state = .running
      case .paused: state = .paused
      case .ended, .stopped: state = .stopped
      default: break
      }
    }
  }

  nonisolated func workoutSession(
    _ workoutSession: HKWorkoutSession,
    didFailWithError error: any Error
  ) {
    Task { @MainActor in
      _ = await shutdownAndDiscard(finalState: .unavailable)
    }
  }
}

extension LiveHeartRateSession: HKLiveWorkoutBuilderDelegate {
  nonisolated func workoutBuilder(
    _ workoutBuilder: HKLiveWorkoutBuilder,
    didCollectDataOf collectedTypes: Set<HKSampleType>
  ) {
    Task { @MainActor in
      guard collectedTypes.contains(HKQuantityType(.heartRate)) else { return }
      collect(from: workoutBuilder)
    }
  }

  nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
