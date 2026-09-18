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
      Text(summary.totalCount == 0 ? "无等待写入" : "\(summary.totalCount) 条等待写入")
        .font(.headline)
        .multilineTextAlignment(.center)
      Text("跨设备以 Apple 健康为事实源，不上传到任何服务器。")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      if summary.authorizationRequiredCount > 0 {
        Text("请在手表「设置 > 健康 > App > 方寸」中允许心境或正念写入。")
          .font(.caption2)
          .foregroundStyle(.yellow)
          .multilineTextAlignment(.center)
      }
      if summary.terminalCount > 0 {
        Text("\(summary.terminalCount) 条本地数据已损坏，无法重试。")
          .font(.caption2)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
        Button("移除损坏记录", role: .destructive) {
          coordinator.discardTerminalWrites()
          summary = coordinator.pendingSummary
        }
        .font(.caption)
      }
      if summary.totalCount > summary.terminalCount {
        Button(isRetrying ? "正在重试…" : "现在重试") {
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
    .navigationTitle("同步状态")
    .task { summary = coordinator.pendingSummary }
  }
}
