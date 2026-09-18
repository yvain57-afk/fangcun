import HealthKit
import Testing

@testable import InnerBalance

@Suite("Health authorization layers")
struct HealthAuthorizationCoordinatorTests {
  @Test("Initial access does not request workout evidence permissions")
  func initialAuthorizationIsMinimal() {
    let plan = HealthAuthorizationPlan.initialBodyStatus
    let readIdentifiers = Set(plan.typesToRead.map(\.identifier))
    let shareIdentifiers = Set(plan.typesToShare.map(\.identifier))

    #expect(readIdentifiers.contains(HKQuantityTypeIdentifier.heartRate.rawValue) == false)
    #expect(shareIdentifiers.contains(HKWorkoutType.workoutType().identifier) == false)
    #expect(readIdentifiers.contains(HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue))
    #expect(readIdentifiers.contains(HKQuantityTypeIdentifier.restingHeartRate.rawValue))
    #expect(readIdentifiers.contains(HKCategoryTypeIdentifier.sleepAnalysis.rawValue))
    #expect(readIdentifiers.contains(HKWorkoutType.workoutType().identifier))
    #expect(shareIdentifiers.contains(HKCategoryTypeIdentifier.mindfulSession.rawValue))
    #expect(shareIdentifiers.contains(HKObjectType.stateOfMindType().identifier))
  }

  @Test("A status query error remains retryable instead of hiding authorization")
  @MainActor
  func statusQueryErrorIsRetryable() async {
    let coordinator = HealthAuthorizationCoordinator(
      healthStore: ThrowingAuthorizationStore(),
      healthDataAvailable: { true }
    )

    let snapshot = await coordinator.status(for: .initialBodyStatus)

    #expect(snapshot.state == .partial)
  }
}

@MainActor
private final class ThrowingAuthorizationStore: HealthAuthorizationStoring {
  struct QueryError: Error {}

  func statusForAuthorizationRequest(
    toShare typesToShare: Set<HKSampleType>,
    read typesToRead: Set<HKObjectType>
  ) async throws -> HKAuthorizationRequestStatus {
    throw QueryError()
  }

  func requestAuthorization(
    toShare typesToShare: Set<HKSampleType>,
    read typesToRead: Set<HKObjectType>
  ) async throws {}

  func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
    .notDetermined
  }
}
