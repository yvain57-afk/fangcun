import Foundation
import HealthKit
import InnerBalanceCore
import Testing
@testable import InnerBalance

@Suite("M2 HealthKit adapter") @MainActor
struct ReadinessHealthKitProviderTests {
  @Test func actualHKObjectsNormalizeWithoutWritingHealthStore() throws {
    let date = Date(timeIntervalSince1970: 1_789_704_000)
    let sample = HKQuantitySample(type: HKQuantityType(.heartRateVariabilitySDNN),
      quantity: HKQuantity(unit: .second(), doubleValue: 0.05), start: date, end: date,
      metadata: [HKMetadataKeyWasUserEntered: true, HKMetadataKeySyncIdentifier: "synthetic", HKMetadataKeySyncVersion: 2])
    let normalized = try #require(ReadinessHealthKitProvider.normalize(sample, metric: .hrvSDNN, queriedAt: date.addingTimeInterval(60)))
    #expect(normalized.id == sample.uuid && normalized.value == 50 && normalized.unit == "ms")
    #expect(normalized.manuallyEntered && normalized.syncIdentifier == "synthetic" && normalized.syncVersion == 2)
    #expect(normalized.end == date && normalized.queriedAt != normalized.end)
    #expect(normalized.source.bundleID == sample.sourceRevision.source.bundleIdentifier)
    #expect(normalized.source.identityIncomplete)
    #expect(StableSourceSelector.select(metric: .hrvSDNN, samples: [normalized], existing: nil, calendar: .current, now: date) == nil)
    #expect(ReadinessHealthKitProvider.normalize(sample, metric: .restingHeartRate, queriedAt: date) == nil)
    let sleep = HKCategorySample(type: HKCategoryType(.sleepAnalysis), value: HKCategoryValueSleepAnalysis.inBed.rawValue,
      start: date.addingTimeInterval(-3600), end: date)
    #expect(ReadinessHealthKitProvider.normalize(sleep, metric: .sleep, queriedAt: date)?.stage == .inBed)
    #expect(ReadinessHealthKitProvider.permittedMetrics == [.hrvSDNN, .restingHeartRate, .sleep, .workout])
  }
}
