import SwiftUI

struct WatchSyncStatusView: View {
  @State private var summary = WatchPendingSummary(
    totalCount: 0,
    terminalCount: 0,
    authorizationRequiredCount: 0
  )
  @State private var isRetrying = false
  let coordinator: WatchHealthWriteCoordinator

  var body: some View {
    VStack(spacing: 10) {
      Image(
        systemName: summary.totalCount == 0
          ? "checkmark.icloud.fill" : "arrow.triangle.2.circlepath.icloud"
      )
      .font(.largeTitle)
      .foregroundStyle(summary.totalCount == 0 ? .mint : .yellow)
      Text(summary.totalCount == 0 ? "No pending writes" : "\(summary.totalCount) pending writes")
        .font(.headline)
        .multilineTextAlignment(.center)
      Text("Apple Health is the shared record across devices. No data is sent to an app server.")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      if summary.authorizationRequiredCount > 0 {
        Text("On your Watch, open Settings > Health > Apps > Little Exhale to allow mood or mindful-session writes.")
          .font(.caption2)
          .foregroundStyle(.yellow)
          .multilineTextAlignment(.center)
      }
      if summary.terminalCount > 0 {
        Text("\(summary.terminalCount) local entries are damaged and can't be retried.")
          .font(.caption2)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
        Button("Remove damaged entries", role: .destructive) {
          coordinator.discardTerminalWrites()
          summary = coordinator.pendingSummary
        }
        .font(.caption)
      }
      if summary.totalCount > summary.terminalCount {
        Button(isRetrying ? "Trying again…" : "Try now") {
          Task {
            isRetrying = true
            await coordinator.retryPending(force: true)
            summary = coordinator.pendingSummary
            isRetrying = false
          }
        }
        .buttonStyle(.borderedProminent)
        .tint(.mint)
        .disabled(isRetrying)
      }
    }
    .padding(.horizontal, 6)
    .navigationTitle("Sync status")
    .task { summary = coordinator.pendingSummary }
  }
}
