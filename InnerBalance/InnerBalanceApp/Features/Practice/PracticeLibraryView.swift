import InnerBalanceCore
import SwiftUI

struct PracticeLaunch: Identifiable, Equatable {
  let kind: PracticeKind
  let duration: TimeInterval
  var startsImmediately = false

  var id: String { "\(kind.rawValue)-\(Int(duration))" }
}

struct PracticeLibraryView: View {
  let onStart: (PracticeLaunch) -> Void

  private let featuredPlan = PracticeCatalog.buildOne[0]
  private let otherPlans = Array(PracticeCatalog.buildOne.dropFirst())

  var body: some View {
    NavigationStack {
      ZStack {
        InnerBalanceTheme.canvas.ignoresSafeArea()
        ScrollView {
          VStack(alignment: .leading, spacing: FangcunLayout.spacing(8)) {
            PracticeLibraryHeader()
            VStack(alignment: .leading, spacing: 18) {
              FangcunCompanion(scene: .breathe).frame(height: 160).frame(maxWidth: .infinity)
              Text("先从一口呼吸开始").font(.title2.weight(.semibold))
              Text("大口吸气，再补一小口，慢慢呼出。").font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
              Button("开始 5 分钟 · 双吸一呼") {
                onStart(PracticeLaunch(kind: .physiologicalSigh, duration: 300, startsImmediately: true))
              }.buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("practice.sigh.300")
              Button("先试 1 分钟，看看练习说明") {
                onStart(PracticeLaunch(kind: .physiologicalSigh, duration: 60))
              }.font(.caption).frame(minHeight: 44).accessibilityIdentifier("practice.physiologicalSigh.60")
            }.fangcunPaperCard()
            VStack(alignment: .leading, spacing: FangcunLayout.spacing(5)) {
              Text("其他练习")
                .font(.title2.weight(.semibold))
                .foregroundStyle(InnerBalanceTheme.ink)
              ForEach(otherPlans, id: \.kind.rawValue) { plan in
                PracticeLibraryRow(plan: plan, onStart: onStart)
              }
            }
          }
          .padding(.horizontal, FangcunLayout.pageHorizontalPadding)
          .padding(.top, FangcunLayout.spacing(6))
          .padding(.bottom, FangcunLayout.spacing(6))
        }
      }
      .toolbar(.hidden, for: .navigationBar)
    }
  }
}

private struct PracticeLibraryHeader: View {
  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
      HStack(spacing: FangcunLayout.spacing(2)) {
        Circle()
          .fill(InnerBalanceTheme.strongFill)
          .frame(width: 8, height: 8)
        Text("练习")
          .font(.caption.weight(.semibold))
          .tracking(1.2)
          .foregroundStyle(InnerBalanceTheme.strongFill)
      }
      Text("给自己留一点时间")
        .font(.largeTitle.weight(.bold))
        .foregroundStyle(InnerBalanceTheme.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text("呼吸、休息，或慢慢感受身体。")
        .font(.subheadline)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
    }
  }
}
