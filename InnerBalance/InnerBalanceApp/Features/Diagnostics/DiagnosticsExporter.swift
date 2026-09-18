import Foundation
import InnerBalanceCore
import SwiftData

struct DiagnosticsSnapshot: Codable, Equatable, Sendable {
  let generatedAt: Date
  let baselineDays: Int
  let availableEvidenceCount: Int
  let unavailableDataKinds: [String]
  let pendingHealthWriteCount: Int
  let checkInCount: Int
  let checkInOpenedCount: Int
  let compassCompletedCount: Int
  let emotionWordSelectedCount: Int
  let optionalSupplementCompletedCount: Int
  let medianCheckInDuration: TimeInterval?
  let p90CheckInDuration: TimeInterval?
  let unclassifiedCheckInCount: Int
  let recommendationAcceptedCount: Int
  let practiceStartedCount: Int
  let practiceCompletionCount: Int
  let subjectiveComparisonAvailableCount: Int
  let watchHeartRateEligibleCount: Int
  let watchHeartRateAvailableCount: Int
  let notificationScheduledCount: Int
  let notificationRespondedCount: Int
  let syncErrorCounts: [String: Int]
}

enum DiagnosticsExporter {
  static func encode(_ snapshot: DiagnosticsSnapshot) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(snapshot)
  }
}

@MainActor
enum DiagnosticsSnapshotBuilder {
  static func build(
    homeViewModel: HomeViewModel,
    modelContext: ModelContext,
    watchHeartRateCounts: WatchHeartRateDiagnosticCounts = .zero,
    now: Date = .now
  ) -> DiagnosticsSnapshot {
    let checkIns =
      (try? modelContext.fetch(
        FetchDescriptor<CheckInDiagnosticEvent>(sortBy: [SortDescriptor(\.completedAt)])
      )) ?? []
    let pendingWrites =
      (try? modelContext.fetch(FetchDescriptor<PendingHealthWrite>())) ?? []
    let practiceCount =
      (try? modelContext.fetchCount(FetchDescriptor<StoredPracticeCompletion>())) ?? 0
    let diagnosticEvents =
      (try? modelContext.fetch(FetchDescriptor<LocalDiagnosticEvent>())) ?? []
    let durations = checkIns.map(\.duration).sorted()

    func eventCount(_ kind: LocalDiagnosticKind) -> Int {
      diagnosticEvents.count { $0.kind == kind }
    }

    let errorCounts = Dictionary(
      grouping: diagnosticEvents.filter { $0.kind == .syncError }.compactMap(\.categoryCode),
      by: { $0 }
    ).mapValues(\.count)

    return DiagnosticsSnapshot(
      generatedAt: now,
      baselineDays: homeViewModel.baselineDays,
      availableEvidenceCount: homeViewModel.evidence.count,
      unavailableDataKinds: homeViewModel.unavailableKinds.map(\.rawValue).sorted(),
      pendingHealthWriteCount: pendingWrites.count,
      checkInCount: checkIns.count,
      checkInOpenedCount: eventCount(.checkInOpened),
      compassCompletedCount: eventCount(.compassCompleted),
      emotionWordSelectedCount: eventCount(.emotionWordSelected),
      optionalSupplementCompletedCount: eventCount(.optionalSupplementCompleted),
      medianCheckInDuration: median(durations),
      p90CheckInDuration: percentile90(durations),
      unclassifiedCheckInCount: checkIns.filter(\.unclassified).count,
      recommendationAcceptedCount: eventCount(.recommendationAccepted),
      practiceStartedCount: eventCount(.practiceStarted),
      practiceCompletionCount: practiceCount,
      subjectiveComparisonAvailableCount: eventCount(.subjectiveComparisonAvailable),
      watchHeartRateEligibleCount: watchHeartRateCounts.eligible,
      watchHeartRateAvailableCount: watchHeartRateCounts.available,
      notificationScheduledCount: eventCount(.notificationScheduled),
      notificationRespondedCount: eventCount(.notificationResponded),
      syncErrorCounts: errorCounts
    )
  }

  private static func median(_ values: [TimeInterval]) -> TimeInterval? {
    guard !values.isEmpty else { return nil }
    let middle = values.count / 2
    return values.count.isMultiple(of: 2)
      ? (values[middle - 1] + values[middle]) / 2
      : values[middle]
  }

  private static func percentile90(_ values: [TimeInterval]) -> TimeInterval? {
    guard !values.isEmpty else { return nil }
    let index = max(0, Int(ceil(Double(values.count) * 0.9)) - 1)
    return values[index]
  }
}

enum DiagnosticsAvailability {
  static func isAvailable(isDebug: Bool, receiptName: String?) -> Bool {
    isDebug || receiptName == "sandboxReceipt"
  }
}
