import HealthKit

@MainActor
protocol HealthAuthorizationStoring: AnyObject {
  func statusForAuthorizationRequest(
    toShare typesToShare: Set<HKSampleType>,
    read typesToRead: Set<HKObjectType>
  ) async throws -> HKAuthorizationRequestStatus

  func requestAuthorization(
    toShare typesToShare: Set<HKSampleType>,
    read typesToRead: Set<HKObjectType>
  ) async throws

  func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus
}

extension HKHealthStore: HealthAuthorizationStoring {}

struct HealthAuthorizationPlan {
  let typesToShare: Set<HKSampleType>
  let typesToRead: Set<HKObjectType>

  static let initialBodyStatus = HealthAuthorizationPlan(
    typesToShare: [
      HKObjectType.stateOfMindType(),
      HKCategoryType(.mindfulSession),
    ],
    typesToRead: [
      HKQuantityType(.heartRateVariabilitySDNN),
      HKQuantityType(.restingHeartRate),
      HKCategoryType(.sleepAnalysis),
      HKWorkoutType.workoutType(),
      HKObjectType.stateOfMindType(),
      HKCategoryType(.mindfulSession),
    ]
  )

  static let watchEvidence = HealthAuthorizationPlan(
    typesToShare: [HKWorkoutType.workoutType()],
    typesToRead: [HKQuantityType(.heartRate)]
  )
}

enum HealthAccessState: Equatable, Sendable {
  case unavailable
  case notRequested
  case requested
  case partial
  case authorizedForWriting
}

struct HealthAuthorizationSnapshot: Equatable, Sendable {
  let state: HealthAccessState
  let deniedWriteTypeIdentifiers: [String]

  static let unavailable = HealthAuthorizationSnapshot(
    state: .unavailable,
    deniedWriteTypeIdentifiers: []
  )
}

@MainActor
final class HealthAuthorizationCoordinator {
  private let healthStore: any HealthAuthorizationStoring
  private let healthDataAvailable: () -> Bool

  init(
    healthStore: any HealthAuthorizationStoring = HKHealthStore(),
    healthDataAvailable: @escaping () -> Bool = { HKHealthStore.isHealthDataAvailable() }
  ) {
    self.healthStore = healthStore
    self.healthDataAvailable = healthDataAvailable
  }

  var isHealthDataAvailable: Bool {
    healthDataAvailable()
  }

  func status(for plan: HealthAuthorizationPlan) async -> HealthAuthorizationSnapshot {
    guard isHealthDataAvailable else { return .unavailable }

    let requestStatus: HKAuthorizationRequestStatus
    do {
      requestStatus = try await healthStore.statusForAuthorizationRequest(
        toShare: plan.typesToShare,
        read: plan.typesToRead
      )
    } catch {
      return HealthAuthorizationSnapshot(state: .partial, deniedWriteTypeIdentifiers: [])
    }
    guard requestStatus != .shouldRequest else {
      return HealthAuthorizationSnapshot(state: .notRequested, deniedWriteTypeIdentifiers: [])
    }
    return writeSnapshot(for: plan)
  }

  func request(_ plan: HealthAuthorizationPlan) async -> HealthAuthorizationSnapshot {
    guard isHealthDataAvailable else { return .unavailable }

    do {
      try await healthStore.requestAuthorization(
        toShare: plan.typesToShare,
        read: plan.typesToRead
      )
    } catch {
      return HealthAuthorizationSnapshot(state: .partial, deniedWriteTypeIdentifiers: [])
    }
    return writeSnapshot(for: plan)
  }

  private func writeSnapshot(for plan: HealthAuthorizationPlan) -> HealthAuthorizationSnapshot {
    let denied = plan.typesToShare.filter {
      healthStore.authorizationStatus(for: $0) == .sharingDenied
    }
    .map(\.identifier)
    .sorted()
    let authorizedCount = plan.typesToShare.filter {
      healthStore.authorizationStatus(for: $0) == .sharingAuthorized
    }.count

    let state: HealthAccessState
    if denied.isEmpty, authorizedCount == plan.typesToShare.count {
      state = .authorizedForWriting
    } else if denied.isEmpty, authorizedCount == 0 {
      state = .requested
    } else {
      state = .partial
    }
    return HealthAuthorizationSnapshot(state: state, deniedWriteTypeIdentifiers: denied)
  }
}
