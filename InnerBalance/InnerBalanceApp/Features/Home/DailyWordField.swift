import InnerBalanceCore
import SwiftUI

struct DailyWordField: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.fangcunReduceMotion) private var reduceMotion

  let reflection: DailyReflection
  let contextTitle: String

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: FangcunLayout.spacing(3)) {
        if !dynamicTypeSize.isAccessibilitySize {
          Text("“")
            .font(.system(size: 52, weight: .light, design: .default))
            .foregroundStyle(InnerBalanceTheme.ink)
            .frame(width: 36, alignment: .leading)
            .accessibilityHidden(true)
        }

        VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
          HStack(spacing: FangcunLayout.spacing(2)) {
            Text(contextTitle)
          }
          .font(.caption2.weight(.bold))
          .tracking(1.2)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
          .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

          VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
            Text(reflection.text)
              .fangcunQuoteStyle()
              .foregroundStyle(InnerBalanceTheme.ink)
              .fixedSize(horizontal: false, vertical: true)
              .accessibilityAddTraits(.isHeader)
              .accessibilityIdentifier("home.dailyReflection")

            if let attribution = reflection.attribution {
              Text(
                reflection.work.map { "\(attribution) · \($0)" }
                  ?? attribution
              )
              .font(.footnote.weight(.medium))
              .foregroundStyle(InnerBalanceTheme.mutedInk)
              .fixedSize(horizontal: false, vertical: true)
              .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
          }
          .id(reflection.id)
          .transition(.opacity)
          .animation(
            .easeOut(duration: reduceMotion ? 0.12 : 0.28),
            value: reflection.id
          )
        }
      }
      .padding(.vertical, FangcunLayout.spacing(6))

      FangcunEditorialRule()
        .frame(height: 1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .contain)
  }
}
