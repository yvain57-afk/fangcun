import SwiftUI

struct HealthAuthorizationInvitation: View {
  let isRequesting: Bool
  let onRequest: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Connect a little more context", systemImage: "heart.text.clipboard")
        .font(.headline)
        .foregroundStyle(InnerBalanceTheme.ink)
      Text("You choose what to share from Apple Health. Little Exhale doesn't send health data to its own or third-party servers. Apple Health's iCloud sync follows your system settings.")
        .font(.subheadline)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
        .fixedSize(horizontal: false, vertical: true)
      Button(isRequesting ? "Opening Apple Health…" : "Choose Health access", action: onRequest)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.strongFill)
        .frame(minHeight: 44, alignment: .leading)
        .disabled(isRequesting)
        .accessibilityHint("Opens system Health permissions. Allow or decline each item separately.")
    }
    .padding(FangcunLayout.spacing(5))
    .fangcunLevelOneSurface()
  }
}
