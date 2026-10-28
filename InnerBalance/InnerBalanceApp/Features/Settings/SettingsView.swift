import SwiftUI
import InnerBalanceCore

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.careOwner) private var care
  @Environment(\.phoneSync) private var sync
  @Environment(\.recoveryOwner) private var recovery
  @Environment(\.readinessOwner) private var readiness
  @State private var practiceSound = PracticeSoundPreferences()
  @AppStorage("fangcun.dark") private var dark = false
  @AppStorage("fangcun.largeType") private var large = false
  @AppStorage("fangcun.reduceMotion") private var reduced = false
  @AppStorage("fangcun.motionMode") private var motionMode = "standard"
  @AppStorage("fangcun.coffeeMg") private var coffeeMg = 140
  let authorizationCoordinator: HealthAuthorizationCoordinator
  let homeViewModel: HomeViewModel
  let healthRepository: HealthKitRepository?
  let isUITesting: Bool
  let diagnosticsAvailable: Bool

  var body: some View {
    NavigationStack {
      List {
        if let care { NavigationLink(FangcunCopy.text("care.settings")) { BeverageCareSettings(owner: care) } }
        if let sync { NavigationLink(FangcunCopy.text("sync.title")) { PhoneSyncStatusView(owner: sync) } }
        if let recovery { NavigationLink(FangcunCopy.text("recovery.history")) { RecoveryHistoryView(owner: recovery) } }
        if let readiness {
          NavigationLink(FangcunCopy.text("readiness.settings")) { ReadinessSettingsView(owner: readiness) }
        }
        Section {
          Toggle(isOn: $dark) { Label("Dark appearance", systemImage: "moon") }
          Toggle(isOn: $large) { Label("Larger text", systemImage: "textformat.size") }
          Picker(FangcunCopy.text("motion.mode"), selection: $motionMode) {
            ForEach(["standard", "gentle", "static"], id: \.self) { Text(FangcunCopy.text("motion." + $0)).tag($0) }
          }
          Toggle(isOn: $reduced) { Label("Reduce motion", systemImage: "leaf") }
        } header: { Text("Make yourself comfortable") }
        .listRowBackground(InnerBalanceTheme.surface)
        Section("Voice guidance") {
          PracticeSoundControls(mode: Binding(get: { practiceSound.mode(hasVoiceAssets: PracticeVoiceAssets.isAvailable(for: .physiologicalSigh)) }, set: { practiceSound.preferredMode = $0 }),
            ambienceEnabled: Binding(get: { practiceSound.ambienceEnabled }, set: { practiceSound.ambienceEnabled = $0 }),
            voiceAvailable: PracticeVoiceAssets.isAvailable(for: .physiologicalSigh))
        }.listRowBackground(InnerBalanceTheme.surface)
        Section {
          NavigationLink { if let readiness, readiness.enabled { DailyStatusHistoryView(owner: readiness) } else { FangcunTrendsView() } } label: { Label("History and patterns", systemImage: "chart.bar") }
          Stepper(value: $coffeeMg, in: 0...500, step: 10) {
            VStack(alignment: .leading, spacing: 4) {
              Text("About \(coffeeMg) mg caffeine per cup")
              Text("Applies only to coffee logged from now on").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
            }
          }
        } header: { Text("Logging preferences") }
        .listRowBackground(InnerBalanceTheme.surface)
        Section {
          NavigationLink {
            PrivacyView()
          } label: {
            Label("Privacy and data", systemImage: "hand.raised.fill")
          }
          if !isUITesting {
            Button {
              Task { _ = await authorizationCoordinator.request(.initialBodyStatus); await readiness?.refresh() }
            } label: {
              Label("Manage Apple Health access", systemImage: "heart.text.clipboard")
            }
          }
        } header: {
          Text("Your data, your choice")
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)

        if diagnosticsAvailable {
          Section("Support") {
            NavigationLink {
              DiagnosticsView(
                homeViewModel: homeViewModel,
                healthRepository: healthRepository
              )
            } label: {
              Label("Diagnostics and export", systemImage: "stethoscope")
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
                Text("Little Exhale").font(.headline)
                Text("A little room to breathe.")
                  .font(.caption)
                  .foregroundStyle(InnerBalanceTheme.mutedInk)
              }
              .padding(.vertical, 8)
            }
          }
          LabeledContent("Version", value: appVersion)
        } header: {
          Text("About")
        }
        .listRowBackground(InnerBalanceTheme.surface)
        .listRowSeparatorTint(InnerBalanceTheme.hairline)
      }
      .foregroundStyle(InnerBalanceTheme.ink)
      .tint(InnerBalanceTheme.strongFill)
      .scrollContentBackground(.hidden)
      .background(InnerBalanceTheme.canvas)
      .fangcunCleanList().navigationTitle("Settings")
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("settings.done") } }
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
        "At home on your device",
        "No account, app server, ads, third-party analytics, or telemetry.",
        "iphone"
      )
      privacyRow(
        "Apple Health",
        "With your permission, reads recovery, sleep, and workout data. Writes only when you log feelings or eligible practices.",
        "heart.fill"
      )
      privacyRow(
        "What deletion includes",
        "Deleting local data doesn't delete Apple Health records. Manage those in the Health app.",
        "trash"
      )
      if let policyURL = URL(string: "https://yvain57-afk.github.io/fangcun/privacy.html") {
        Link(destination: policyURL) {
          Label("Read the privacy policy", systemImage: "doc.text")
        }.accessibilityIdentifier("settings.privacyPolicy")
      }
      if let supportURL = URL(string: "https://yvain57-afk.github.io/fangcun/support.html") {
        Link(destination: supportURL) {
          Label("Help and contact", systemImage: "questionmark.circle")
        }.accessibilityIdentifier("settings.support")
      }
    }
    .foregroundStyle(InnerBalanceTheme.ink)
    .tint(InnerBalanceTheme.strongFill)
    .listRowBackground(InnerBalanceTheme.surface)
    .listRowSeparatorTint(InnerBalanceTheme.hairline)
    .scrollContentBackground(.hidden)
    .background(InnerBalanceTheme.canvas)
    .fangcunCleanList().navigationTitle("Privacy and data")
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
