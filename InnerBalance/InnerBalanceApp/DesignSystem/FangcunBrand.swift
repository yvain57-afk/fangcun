import SwiftUI

/// The approved open-curve mark. Assets retain the original SVG geometry.
struct FangcunBrandMark: View {
  var size: CGFloat = 32

  var body: some View {
    Image("FangcunMark")
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }
}

struct FangcunBrandAboutView: View {
  @ScaledMetric(relativeTo: .title) private var markSize = 80

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        VStack(spacing: 16) {
          FangcunBrandMark(size: markSize)
          Text("Little Exhale")
            .font(.title.weight(.semibold))
            .tracking(3)
          Text("A little room to breathe.")
            .font(.subheadline)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)

        Text("A little room to breathe.")
          .font(.title2.weight(.semibold))
          .accessibilityAddTraits(.isHeader)
        Text("Small, gentle practices for the moments between everything else. Breathe, rest, and find a rhythm that feels like yours.")
        Text("An open curve, with room in the middle. A reminder that you can be supported without being held in place.")
          .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
      .font(.body)
      .fixedSize(horizontal: false, vertical: true)
      .padding(24)
    }
    .foregroundStyle(InnerBalanceTheme.ink)
    .background(InnerBalanceTheme.canvas)
    .navigationTitle("About Little Exhale")
    .navigationBarTitleDisplayMode(.inline)
  }
}
