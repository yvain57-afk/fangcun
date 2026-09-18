import InnerBalanceCore
import SwiftData
import SwiftUI

struct WatchRootView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var pendingCount = 0
  private let repository = WatchHealthRepository()

  var body: some View {
    NavigationStack {
      List {
        Section {
          VStack(alignment: .leading, spacing: 7) {
            Text("今日一句")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(FangcunWatchColor.jade)
            Text(dailyReflection.text)
              .font(.headline)
              .fixedSize(horizontal: false, vertical: true)
            if let attribution = dailyReflection.attribution {
              Text("—— \(attribution)")
                .font(.caption2.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .padding(.vertical, 4)
          .accessibilityElement(children: .combine)
        }

        Section {
          NavigationLink {
            WatchCheckInView(coordinator: coordinator)
          } label: {
            WatchCompassHomeTile()
          }
          NavigationLink {
            WatchPracticeLibraryView(coordinator: coordinator)
          } label: {
            WatchHomeRow(
              title: "开始调节",
              detail: "选一个短练习",
              systemImage: "waveform.path"
            )
          }
          NavigationLink {
            WatchSyncStatusView(coordinator: coordinator)
          } label: {
            WatchHomeRow(
              title: "同步状态",
              detail: pendingCount == 0 ? "已写入 Apple 健康" : "\(pendingCount) 条等待重试",
              systemImage: pendingCount == 0 ? "checkmark.icloud" : "arrow.triangle.2.circlepath"
            )
          }
        } header: {
          VStack(alignment: .leading, spacing: 3) {
            Text("方寸")
              .font(.title3.weight(.semibold))
            Text("照料方寸之间的自己")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          .textCase(nil)
        }
      }
      .listStyle(.carousel)
      .navigationTitle("")
      .task {
        await coordinator.retryPending()
        pendingCount = coordinator.pendingCount
      }
    }
    .tint(FangcunWatchColor.jade)
  }

  private var dailyReflection: DailyReflection {
    DailyReflectionSelector.reflection(on: .now, echo: nil)
  }

  private var coordinator: WatchHealthWriteCoordinator {
    WatchHealthWriteCoordinator(repository: repository, modelContext: modelContext)
  }
}

private struct WatchCompassHomeTile: View {
  var body: some View {
    HStack(spacing: 12) {
      WatchCompassDial()
        .frame(width: 68, height: 68)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        Text("情绪罗盘")
          .font(.headline)
        Text("点两次，记下此刻")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("情绪罗盘，点两次记下此刻")
    .accessibilityIdentifier("watch.compass.home")
  }
}

private struct WatchCompassDial: View {
  var body: some View {
    GeometryReader { proxy in
      let size = min(proxy.size.width, proxy.size.height)
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [FangcunWatchColor.jade.opacity(0.24), Color.orange.opacity(0.14)],
              startPoint: .topTrailing,
              endPoint: .bottomLeading
            )
          )
        Circle()
          .stroke(FangcunWatchColor.jade.opacity(0.50), lineWidth: 1)
        Rectangle()
          .fill(.secondary.opacity(0.24))
          .frame(width: 1, height: size * 0.70)
        Rectangle()
          .fill(.secondary.opacity(0.24))
          .frame(width: size * 0.70, height: 1)
        ForEach(WatchCompassRegion.all) { region in
          Circle()
            .fill(region.valence < -0.1 ? Color.orange : FangcunWatchColor.jade)
            .frame(width: region.valence == 0 && region.arousal == 0 ? 7 : 5)
            .position(
              x: size * (0.5 + region.valence * 0.34),
              y: size * (0.5 - region.arousal * 0.34)
            )
        }
      }
    }
    .aspectRatio(1, contentMode: .fit)
  }
}

private struct WatchHomeRow: View {
  let title: String
  let detail: String
  let systemImage: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.title3)
        .foregroundStyle(FangcunWatchColor.jade)
        .frame(width: 27)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.headline)
        Text(detail)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
    .padding(.vertical, 3)
  }
}

private enum FangcunWatchColor {
  static let jade = Color(red: 0.45, green: 0.77, blue: 0.67)
}

#Preview {
  WatchRootView()
    .modelContainer(
      for: [WatchPendingHealthWrite.self, WatchPracticeCompletion.self],
      inMemory: true
    )
}
