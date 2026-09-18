import SwiftUI

struct BaselineProgressView: View {
  let completedDays: Int
  private let requiredDays = 5

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
      HStack {
        Text("个人基线")
          .font(.subheadline.weight(.medium))
        Spacer()
        Text("\(min(completedDays, requiredDays))/\(requiredDays) 天")
          .font(.subheadline.monospacedDigit().weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.strongFill)
      }

      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule().fill(InnerBalanceTheme.subtleFill)
          Capsule()
            .fill(InnerBalanceTheme.strongFill)
            .frame(
              width: proxy.size.width
                * CGFloat(min(completedDays, requiredDays)) / CGFloat(requiredDays)
            )
        }
      }
      .frame(height: FangcunLayout.spacing(2))
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("个人基线进度")
    .accessibilityValue("已获得 \(min(completedDays, requiredDays)) 天，共需 \(requiredDays) 天")
  }
}
