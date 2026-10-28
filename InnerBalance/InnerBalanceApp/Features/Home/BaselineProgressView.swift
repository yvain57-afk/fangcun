import SwiftUI

struct BaselineProgressView: View {
  let completedDays: Int
  private let requiredDays = 5

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
      HStack {
        Text("Your baseline")
          .font(.subheadline.weight(.medium))
        Spacer()
        Text("\(min(completedDays, requiredDays))/\(requiredDays) days")
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
    .accessibilityLabel("Personal baseline progress")
    .accessibilityValue("\(min(completedDays, requiredDays)) of \(requiredDays) days collected")
  }
}
