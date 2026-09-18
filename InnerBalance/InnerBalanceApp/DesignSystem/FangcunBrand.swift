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
          Text("方寸")
            .font(.title.weight(.semibold))
            .tracking(3)
          Text("给自己，留一点空间。")
            .font(.subheadline)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)

        Text("留一方余地。")
          .font(.title2.weight(.semibold))
          .accessibilityAddTraits(.isHeader)
        Text("在纷乱的日常里，留一小处照顾自己的空间。先听懂身体的信号，再慢慢找回自己的节奏。")
        Text("中心的留白，是属于自己的那一小处空间。柔软的弧形像被轻轻托住，向外的开口留有余地，也容得下呼吸。")
          .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
      .font(.body)
      .fixedSize(horizontal: false, vertical: true)
      .padding(24)
    }
    .foregroundStyle(InnerBalanceTheme.ink)
    .background(InnerBalanceTheme.canvas)
    .navigationTitle("关于方寸")
    .navigationBarTitleDisplayMode(.inline)
  }
}
