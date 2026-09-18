import HealthKit
import Testing

@testable import InnerBalance

@Suite("HealthKit repository")
struct HealthKitRepositoryTests {
  @Test("Only the iPhone and Watch app bundle identifiers are treated as owned sources")
  func ownedSourcesIncludeCompanionWatch() {
    #expect(HealthKitRepository.isOwnedBundleIdentifier("com.yvainair.InnerBalance"))
    #expect(
      HealthKitRepository.isOwnedBundleIdentifier("com.yvainair.InnerBalance.watchkitapp")
    )
    #expect(HealthKitRepository.isOwnedBundleIdentifier("com.apple.Health") == false)
  }

  @Test("Owned State of Mind queries are restricted by app metadata before reading")
  func ownedQueryUsesMetadataBoundary() {
    let predicate = HealthKitRepository.ownedStateOfMindMetadataPredicate()
    let description = predicate.predicateFormat

    #expect(description.contains(HealthMetadataKeys.origin))
    #expect(HealthKitRepository.isOwnedSyncIdentifier("com.yvainair.innerbalance.checkin.123"))
    #expect(HealthKitRepository.isOwnedSyncIdentifier("other-app-checkin") == false)
  }

  @Test("Anchored State of Mind changes keep the highest sync version")
  func anchoredChangesAreDeduplicated() {
    let date = Date(timeIntervalSince1970: 1_786_296_600)
    let old = HKStateOfMind(
      date: date,
      kind: .momentaryEmotion,
      valence: -0.2,
      labels: [],
      associations: [],
      metadata: [
        HKMetadataKeySyncIdentifier: "check-in-123",
        HKMetadataKeySyncVersion: 1,
      ]
    )
    let current = HKStateOfMind(
      date: date,
      kind: .momentaryEmotion,
      valence: 0.4,
      labels: [.calm],
      associations: [],
      metadata: [
        HKMetadataKeySyncIdentifier: "check-in-123",
        HKMetadataKeySyncVersion: 2,
      ]
    )
    let unrelated = HKStateOfMind(
      date: date,
      kind: .momentaryEmotion,
      valence: 0,
      labels: [],
      associations: [],
      metadata: nil
    )

    let samples = HealthKitRepository.deduplicateStateOfMindSamples([
      old, unrelated, current,
    ])

    #expect(samples.count == 1)
    #expect(samples.first?.valence == 0.4)
    #expect(samples.first?.metadata?[HKMetadataKeySyncVersion] as? Int == 2)
  }

  @Test("常见训练类型在身体来信中有具体名称")
  func commonWorkoutTypesHaveReadableNames() {
    #expect(HealthKitRepository.activityName(for: .rowing) == "划船")
    #expect(HealthKitRepository.activityName(for: .elliptical) == "椭圆机")
    #expect(HealthKitRepository.activityName(for: .pilates) == "普拉提")
    #expect(HealthKitRepository.activityName(for: .cardioDance) == "舞蹈")
    #expect(HealthKitRepository.activityName(for: .tennis) == "网球")
    #expect(HealthKitRepository.activityName(for: .basketball) == "篮球")
  }
}
