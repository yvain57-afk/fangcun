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
        Section("身体数据状态") {
          LabeledContent("基线进度", value: "\(snapshot.baselineDays) / 5 天")
          LabeledContent("可用证据", value: "\(snapshot.availableEvidenceCount) 项")
          LabeledContent("当前判断", value: bodyLoadText)
          LabeledContent(
            "不可用类型",
            value: snapshot.unavailableDataKinds.isEmpty
              ? "无" : snapshot.unavailableDataKinds.joined(separator: "、")
          )
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
        Section("本地写入状态") {
          LabeledContent("等待 HealthKit", value: "\(snapshot.pendingHealthWriteCount) 条")
          LabeledContent("情绪登记", value: "\(snapshot.checkInCount) 次")
          LabeledContent("未分类登记", value: "\(snapshot.unclassifiedCheckInCount) 次")
          LabeledContent("已完成练习", value: "\(snapshot.practiceCompletionCount) 次")
          LabeledContent("登记中位用时", value: durationText(snapshot.medianCheckInDuration))
          LabeledContent("登记 P90 用时", value: durationText(snapshot.p90CheckInDuration))
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
        Section("本地漏斗") {
          LabeledContent("打开登记", value: "\(snapshot.checkInOpenedCount) 次")
          LabeledContent("完成罗盘", value: "\(snapshot.compassCompletedCount) 次")
          LabeledContent("选择情绪词", value: "\(snapshot.emotionWordSelectedCount) 次")
          LabeledContent(
            "完成可选补充",
            value: "\(snapshot.optionalSupplementCompletedCount) 次"
          )
          LabeledContent("接受推荐", value: "\(snapshot.recommendationAcceptedCount) 次")
          LabeledContent("开始练习", value: "\(snapshot.practiceStartedCount) 次")
          LabeledContent(
            "主观对比可用",
            value: "\(snapshot.subjectiveComparisonAvailableCount) 次"
          )
          LabeledContent(
            "Watch 心率窗口",
            value:
              "\(snapshot.watchHeartRateAvailableCount) / \(snapshot.watchHeartRateEligibleCount)"
          )
          LabeledContent(
            "提醒响应",
            value:
              "\(snapshot.notificationRespondedCount) / \(snapshot.notificationScheduledCount)"
          )
          LabeledContent(
            "同步错误",
            value: snapshot.syncErrorCounts.isEmpty
              ? "无"
              : snapshot.syncErrorCounts.map { "\($0.key): \($0.value)" }.sorted()
                .joined(separator: "、")
          )
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
        Section {
          if let exportText = exportText(snapshot) {
            ShareLink(item: exportText) {
              Label("导出诊断信息", systemImage: "square.and.arrow.up")
            }
          }
          Text("导出只含权限状态、数据可用性、计数和用时；不含心率、HRV、睡眠时段、情绪词或罗盘坐标。")
            .font(.caption)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
      } else {
        ProgressView("正在整理本地状态…")
          .tint(InnerBalanceTheme.emphasis)
          .listRowBackground(InnerBalanceTheme.surface)
      }
    }
    .foregroundStyle(InnerBalanceTheme.ink)
    .tint(InnerBalanceTheme.strongFill)
    .scrollContentBackground(.hidden)
    .background(InnerBalanceTheme.canvas)
    .navigationTitle("诊断")
    .toolbarBackground(InnerBalanceTheme.canvas, for: .navigationBar)
    .toolbar {
      Button("刷新") { Task { await refresh() } }
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
    guard let duration else { return "暂无" }
    return "\(duration.formatted(.number.precision(.fractionLength(1)))) 秒"
  }

  private var bodyLoadText: String {
    switch homeViewModel.assessment.level {
    case .steady: "平稳"
    case .watch: "留意"
    case .elevated: "偏高"
    case .buildingBaseline: "建立基线中"
    }
  }
}
