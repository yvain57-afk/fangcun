import SwiftUI

struct SettingsView: View {
  @Environment(\.phoneSync) private var sync
  @Environment(\.recoveryOwner) private var recovery
  @Environment(\.readinessOwner) private var readiness
  @AppStorage("fangcun.dark") private var dark = false
  @AppStorage("fangcun.largeType") private var large = false
  @AppStorage("fangcun.reduceMotion") private var reduced = false
  @AppStorage("fangcun.coffeeMg") private var coffeeMg = 140
  let authorizationCoordinator: HealthAuthorizationCoordinator
  let homeViewModel: HomeViewModel
  let healthRepository: HealthKitRepository?
  let isUITesting: Bool
  let diagnosticsAvailable: Bool

  var body: some View {
    NavigationStack {
      List {
        if let sync { NavigationLink(FangcunCopy.text("sync.title")) { PhoneSyncStatusView(owner: sync) } }
        if let recovery { NavigationLink(FangcunCopy.text("recovery.history")) { RecoveryHistoryView(owner: recovery) } }
        if let readiness {
          NavigationLink(FangcunCopy.text("readiness.settings")) { ReadinessSettingsView(owner: readiness) }
        }
        Section {
          Toggle(isOn: $dark) { Label("深色模式", systemImage: "moon") }
          Toggle(isOn: $large) { Label("较大字号", systemImage: "textformat.size") }
          Toggle(isOn: $reduced) { Label("减少动态效果", systemImage: "leaf") }
        } header: { Text("舒服的方式，由你决定") }
        .listRowBackground(InnerBalanceTheme.surface)
        Section {
          NavigationLink { if let readiness, readiness.enabled { ReadinessHistoryView(owner: readiness) } else { FangcunTrendsView() } } label: { Label("历史与趋势", systemImage: "chart.bar") }
          Stepper(value: $coffeeMg, in: 0...500, step: 10) {
            VStack(alignment: .leading, spacing: 4) {
              Text("每杯咖啡因约 \(coffeeMg) mg")
              Text("只影响之后新增的咖啡记录").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
            }
          }
        } header: { Text("记录与预设") }
        .listRowBackground(InnerBalanceTheme.surface)
        Section {
          NavigationLink {
            PrivacyView()
          } label: {
            Label("隐私与数据", systemImage: "hand.raised.fill")
          }
          if !isUITesting {
            Button {
              Task { _ = await authorizationCoordinator.request(.initialBodyStatus); await readiness?.refresh() }
            } label: {
              Label("管理 Apple 健康权限", systemImage: "heart.text.clipboard")
            }
          }
        } header: {
          Text("数据掌握在你手中")
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)

        if diagnosticsAvailable {
          Section("支持") {
            NavigationLink {
              DiagnosticsView(
                homeViewModel: homeViewModel,
                healthRepository: healthRepository
              )
            } label: {
              Label("诊断与导出", systemImage: "stethoscope")
            }
          }
          .listRowBackground(InnerBalanceTheme.surface)
          .listRowSeparatorTint(InnerBalanceTheme.hairline)
        }

        Section {
          NavigationLink {
            FangcunBrandAboutView()
          } label: {
            HStack(spacing: 14) {
              FangcunBrandMark(size: 36)
              VStack(alignment: .leading, spacing: 5) {
                Text("方寸 Fangcun").font(.headline)
                Text("给自己，留一点空间。")
                  .font(.caption)
                  .foregroundStyle(InnerBalanceTheme.mutedInk)
              }
              .padding(.vertical, 8)
            }
          }
          LabeledContent("版本", value: appVersion)
        } header: {
          Text("关于")
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
      }
      .foregroundStyle(InnerBalanceTheme.ink)
      .tint(InnerBalanceTheme.strongFill)
      .scrollContentBackground(.hidden)
      .background(InnerBalanceTheme.canvas)
      .navigationTitle("设置")
      .toolbarBackground(InnerBalanceTheme.canvas, for: .navigationBar)
    }
  }

  private var appVersion: String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    return "\(version) (\(build))"
  }
}

private struct PrivacyView: View {
  var body: some View {
    List {
      privacyRow(
        "本地优先",
        "方寸不创建账号，不使用服务器、广告、第三方分析或遥测。",
        "iphone"
      )
      privacyRow(
        "Apple 健康",
        "仅在你授权后读取身体恢复、睡眠和训练数据；记录感受和适用练习时才写入。",
        "heart.fill"
      )
      privacyRow(
        "删除的边界",
        "删除本地数据不会自动删除 Apple 健康中的记录；后者需在「健康」App 中管理。",
        "trash"
      )
    }
    .foregroundStyle(InnerBalanceTheme.ink)
    .tint(InnerBalanceTheme.strongFill)
    .listRowBackground(InnerBalanceTheme.surface)
    .listRowSeparatorTint(InnerBalanceTheme.hairline)
    .scrollContentBackground(.hidden)
    .background(InnerBalanceTheme.canvas)
    .navigationTitle("隐私与数据")
    .toolbarBackground(InnerBalanceTheme.canvas, for: .navigationBar)
  }

  private func privacyRow(_ title: String, _ detail: String, _ image: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: image)
        .font(.headline)
        .foregroundStyle(InnerBalanceTheme.ink)
      Text(detail)
        .font(.subheadline)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 8)
  }
}
