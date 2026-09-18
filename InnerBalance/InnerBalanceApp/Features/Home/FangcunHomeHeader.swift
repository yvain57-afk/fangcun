import Foundation
import SwiftUI

struct FangcunHomeHeader: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ScaledMetric(relativeTo: .largeTitle) private var displayPointSize =
    FangcunTypography.display.basePointSize

  let date: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Group {
        if dynamicTypeSize.isAccessibilitySize {
          VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
            titleBlock
            dateLabel
          }
        } else {
          HStack(alignment: .bottom, spacing: FangcunLayout.spacing(5)) {
            titleBlock
            Spacer(minLength: FangcunLayout.spacing(3))
            dateLabel
          }
        }
      }
      .padding(.top, FangcunLayout.spacing(2))
      .padding(.bottom, FangcunLayout.spacing(5))

      FangcunEditorialRule(emphasized: true)
        .frame(height: 2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var titleBlock: some View {
    VStack(alignment: .leading, spacing: 0) {
      brandPoint
      Text("此刻")
        .font(
          dynamicTypeSize.isAccessibilitySize
            ? .largeTitle.bold()
            : .system(size: displayPointSize, weight: .bold, design: .default)
        )
        .tracking(FangcunTypography.display.tracking)
        .foregroundStyle(InnerBalanceTheme.ink)
        .accessibilityAddTraits(.isHeader)
    }
  }

  private var dateLabel: some View {
    Text(editorialDate)
      .font(.caption.weight(.medium))
      .foregroundStyle(InnerBalanceTheme.mutedInk)
      .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
      .fixedSize(horizontal: false, vertical: true)
      .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
      .accessibilityIdentifier("home.date")
  }

  private var brandPoint: some View {
    HStack(spacing: FangcunLayout.spacing(2)) {
      FangcunBrandMark(size: 28)
      Text("方寸")
        .font(.subheadline.weight(.semibold))
        .tracking(1.4)
        .foregroundStyle(InnerBalanceTheme.ink)
    }
    .frame(minHeight: 24)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("方寸")
    .accessibilityIdentifier("home.brandPoint")
  }

  private var editorialDate: String {
    let calendar = Calendar.autoupdatingCurrent
    let month = calendar.component(.month, from: date)
    let day = calendar.component(.day, from: date)
    let weekday = date.formatted(.dateTime.weekday(.wide))
    return String(format: "%02d / %02d\n%@", month, day, weekday)
  }
}
