import InnerBalanceCore
import SwiftData
import SwiftUI

struct DiagnosticsView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var snapshot: DiagnosticsSnapshot?
  let homeViewModel: HomeViewModel
  let healthRepository: HealthKitRepository?

  var body: some View {
    List {
      if let snapshot {
        Section("Health data status") {
          LabeledContent("Baseline progress", value: "\(snapshot.baselineDays) / 5 days")
          LabeledContent("Available measures", value: "\(snapshot.availableEvidenceCount) measures")
          LabeledContent("Current assessment", value: bodyLoadText)
          LabeledContent(
            "Unavailable types",
            value: snapshot.unavailableDataKinds.isEmpty
              ? "None" : snapshot.unavailableDataKinds.joined(separator: "、")
          )
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
        Section("Local write status") {
          LabeledContent("Waiting for HealthKit", value: "\(snapshot.pendingHealthWriteCount) entries")
          LabeledContent("Check-ins", value: "\(snapshot.checkInCount) times")
          LabeledContent("Unlabeled check-ins", value: "\(snapshot.unclassifiedCheckInCount) times")
          LabeledContent("Completed practices", value: "\(snapshot.practiceCompletionCount) times")
          LabeledContent("Median check-in time", value: durationText(snapshot.medianCheckInDuration))
          LabeledContent("P90 check-in time", value: durationText(snapshot.p90CheckInDuration))
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
        Section("On-device flow counts") {
          LabeledContent("Opened check-in", value: "\(snapshot.checkInOpenedCount) times")
          LabeledContent("Completed compass", value: "\(snapshot.compassCompletedCount) times")
          LabeledContent("Selected a feeling word", value: "\(snapshot.emotionWordSelectedCount) times")
          LabeledContent(
            "Completed optional details",
            value: "\(snapshot.optionalSupplementCompletedCount) times"
          )
          LabeledContent("Accepted suggestion", value: "\(snapshot.recommendationAcceptedCount) times")
          LabeledContent("Started practice", value: "\(snapshot.practiceStartedCount) times")
          LabeledContent(
            "Subjective comparison available",
            value: "\(snapshot.subjectiveComparisonAvailableCount) times"
          )
          LabeledContent(
            "Watch heart-rate windows",
            value:
              "\(snapshot.watchHeartRateAvailableCount) / \(snapshot.watchHeartRateEligibleCount)"
          )
          LabeledContent(
            "Reminder responses",
            value:
              "\(snapshot.notificationRespondedCount) / \(snapshot.notificationScheduledCount)"
          )
          LabeledContent(
            "Sync errors",
            value: snapshot.syncErrorCounts.isEmpty
              ? "None"
              : snapshot.syncErrorCounts.map { "\($0.key): \($0.value)" }.sorted()
                .joined(separator: "、")
          )
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
        Section {
          if let exportText = exportText(snapshot) {
            ShareLink(item: exportText) {
              Label("Export diagnostics", systemImage: "square.and.arrow.up")
            }
          }
          Text("The export contains permission status, data availability, counts, and timings only. No heart rate, HRV, sleep periods, feeling words, or compass coordinates.")
            .font(.caption)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
      } else {
        ProgressView("Preparing local status…")
          .tint(InnerBalanceTheme.emphasis)
          .listRowBackground(InnerBalanceTheme.surface)
      }
    }
    .foregroundStyle(InnerBalanceTheme.ink)
    .tint(InnerBalanceTheme.strongFill)
    .scrollContentBackground(.hidden)
    .background(InnerBalanceTheme.canvas)
    .navigationTitle("Diagnostics")
    .toolbarBackground(InnerBalanceTheme.canvas, for: .navigationBar)
    .toolbar {
      Button("Refresh") { Task { await refresh() } }
    }
    .task { await refresh() }
  }

  private func refresh() async {
    let watchCounts =
      await healthRepository?.watchHeartRateDiagnosticCounts() ?? .zero
    snapshot = DiagnosticsSnapshotBuilder.build(
      homeViewModel: homeViewModel,
      modelContext: modelContext,
      watchHeartRateCounts: watchCounts
    )
  }

  private func exportText(_ snapshot: DiagnosticsSnapshot) -> String? {
    guard let data = try? DiagnosticsExporter.encode(snapshot) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private func durationText(_ duration: TimeInterval?) -> String {
    guard let duration else { return "Not available" }
    return "\(duration.formatted(.number.precision(.fractionLength(1)))) seconds"
  }

  private var bodyLoadText: String {
    switch homeViewModel.assessment.level {
    case .steady: "Steady"
    case .watch: "Worth noticing"
    case .elevated: "Elevated"
    case .buildingBaseline: "Building baseline"
    }
  }
}
