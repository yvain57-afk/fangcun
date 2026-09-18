import Foundation
import InnerBalanceCore
import SwiftData
import Testing

@testable import InnerBalance

@Suite("Privacy-safe diagnostics export")
struct DiagnosticsExporterTests {
  @Test("Export contains only status and aggregate counters")
  func exportExcludesRawHealthAndMoodValues() throws {
    let snapshot = DiagnosticsSnapshot(
      generatedAt: Date(timeIntervalSince1970: 1_786_320_000),
      baselineDays: 4,
      availableEvidenceCount: 3,
      unavailableDataKinds: ["sleep"],
      pendingHealthWriteCount: 2,
      checkInCount: 5,
      checkInOpenedCount: 7,
      compassCompletedCount: 6,
      emotionWordSelectedCount: 4,
      optionalSupplementCompletedCount: 2,
      medianCheckInDuration: 8.4,
      p90CheckInDuration: 13.2,
      unclassifiedCheckInCount: 1,
      recommendationAcceptedCount: 2,
      practiceStartedCount: 3,
      practiceCompletionCount: 2,
      subjectiveComparisonAvailableCount: 2,
      watchHeartRateEligibleCount: 1,
      watchHeartRateAvailableCount: 1,
      notificationScheduledCount: 0,
      notificationRespondedCount: 0,
      syncErrorCounts: ["write_failed": 2]
    )

    let data = try DiagnosticsExporter.encode(snapshot)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let exportedText = try #require(String(data: data, encoding: .utf8))

    #expect(object["baselineDays"] as? Int == 4)
    #expect(object["pendingHealthWriteCount"] as? Int == 2)
    #expect(object["medianCheckInDuration"] as? Double == 8.4)
    #expect(object["p90CheckInDuration"] as? Double == 13.2)
    #expect(
      Set(object.keys) == [
        "availableEvidenceCount",
        "baselineDays",
        "checkInCount",
        "checkInOpenedCount",
        "compassCompletedCount",
        "emotionWordSelectedCount",
        "generatedAt",
        "medianCheckInDuration",
        "notificationRespondedCount",
        "notificationScheduledCount",
        "optionalSupplementCompletedCount",
        "pendingHealthWriteCount",
        "p90CheckInDuration",
        "practiceCompletionCount",
        "practiceStartedCount",
        "recommendationAcceptedCount",
        "subjectiveComparisonAvailableCount",
        "syncErrorCounts",
        "unavailableDataKinds",
        "unclassifiedCheckInCount",
        "watchHeartRateAvailableCount",
        "watchHeartRateEligibleCount",
      ]
    )
    #expect(exportedText.contains("heartRate") == false)
    #expect(exportedText.contains("valence") == false)
    #expect(exportedText.contains("arousal") == false)
    #expect(exportedText.contains("emotionLabel") == false)
    #expect(exportedText.contains("beforeRating") == false)
    #expect(exportedText.contains("afterRating") == false)
    #expect(exportedText.contains("bodyLoadState") == false)
  }

  @Test("Diagnostics appear only in Debug or TestFlight")
  func diagnosticsChannelBoundary() {
    #expect(DiagnosticsAvailability.isAvailable(isDebug: true, receiptName: nil))
    #expect(
      DiagnosticsAvailability.isAvailable(
        isDebug: false,
        receiptName: "sandboxReceipt"
      )
    )
    #expect(
      DiagnosticsAvailability.isAvailable(
        isDebug: false,
        receiptName: "receipt"
      ) == false
    )
    #expect(DiagnosticsAvailability.isAvailable(isDebug: false, receiptName: nil) == false)
  }

  @Test("Builder aggregates local funnel, duration and sync diagnostics")
  @MainActor
  func builderAggregatesPrivacySafeDiagnostics() throws {
    let container = try ModelContainer(
      for: CheckInDiagnosticEvent.self, PendingHealthWrite.self,
      StoredPracticeCompletion.self, LocalDiagnosticEvent.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let baseDate = Date(timeIntervalSince1970: 1_786_320_000)

    for duration in 1...10 {
      context.insert(
        CheckInDiagnosticEvent(
          startedAt: baseDate,
          completedAt: baseDate.addingTimeInterval(TimeInterval(duration)),
          unclassified: duration.isMultiple(of: 5)
        )
      )
    }
    for kind in [
      LocalDiagnosticKind.checkInOpened,
      .checkInOpened,
      .compassCompleted,
      .emotionWordSelected,
      .optionalSupplementCompleted,
      .recommendationAccepted,
      .practiceStarted,
      .subjectiveComparisonAvailable,
    ] {
      context.insert(LocalDiagnosticEvent(kind: kind, occurredAt: baseDate))
    }
    context.insert(
      LocalDiagnosticEvent(
        kind: .syncError,
        occurredAt: baseDate,
        categoryCode: "write_failed"
      )
    )
    context.insert(
      PendingHealthWrite(
        kind: .mindfulSession,
        payload: Data(),
        syncIdentifier: "diagnostics.pending",
        syncVersion: 1,
        createdAt: baseDate
      )
    )
    context.insert(
      StoredPracticeCompletion(
        record: PracticeCompletionRecord(
          sessionID: "diagnostics.practice",
          practiceKind: .pacedBreathing,
          plannedDuration: 180,
          actualDuration: 175,
          startedAt: baseDate,
          endedAt: baseDate.addingTimeInterval(175),
          beforeRating: 7,
          afterRating: 4
        ),
        mindfulWriteResult: .queued,
        postWriteResult: .saved
      )
    )
    try context.save()

    let snapshot = DiagnosticsSnapshotBuilder.build(
      homeViewModel: HomeViewModel(provider: EmptyDiagnosticsHealthProvider()),
      modelContext: context,
      watchHeartRateCounts: WatchHeartRateDiagnosticCounts(eligible: 2, available: 1),
      now: baseDate
    )

    #expect(snapshot.checkInCount == 10)
    #expect(snapshot.checkInOpenedCount == 2)
    #expect(snapshot.compassCompletedCount == 1)
    #expect(snapshot.emotionWordSelectedCount == 1)
    #expect(snapshot.optionalSupplementCompletedCount == 1)
    #expect(snapshot.medianCheckInDuration == 5.5)
    #expect(snapshot.p90CheckInDuration == 9)
    #expect(snapshot.unclassifiedCheckInCount == 2)
    #expect(snapshot.recommendationAcceptedCount == 1)
    #expect(snapshot.practiceStartedCount == 1)
    #expect(snapshot.practiceCompletionCount == 1)
    #expect(snapshot.subjectiveComparisonAvailableCount == 1)
    #expect(snapshot.watchHeartRateEligibleCount == 2)
    #expect(snapshot.watchHeartRateAvailableCount == 1)
    #expect(snapshot.pendingHealthWriteCount == 1)
    #expect(snapshot.syncErrorCounts == ["write_failed": 1])
  }
}

@MainActor
private struct EmptyDiagnosticsHealthProvider: BodyHealthDataProviding {
  func fetchBodyHealthData(now: Date) async -> BodyHealthDataSnapshot {
    .empty(at: now)
  }
}
