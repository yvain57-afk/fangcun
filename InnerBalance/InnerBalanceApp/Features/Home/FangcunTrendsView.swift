import SwiftData
import SwiftUI

struct FangcunTrendsView: View {
  @Environment(FangcunDiary.self) private var diary
  @Query(sort: \StoredPracticeCompletion.endedAt, order: .reverse) private var practices: [StoredPracticeCompletion]
  @State private var selected = Calendar.current.startOfDay(for: .now)
  @State private var drinks = false
  private var days: [Date] { (-6...0).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Calendar.current.startOfDay(for: .now)) } }
  private var snapshot: FangcunDaySnapshot? { diary.snapshot(on: selected) }
  private var totals: FangcunDrinkTotals { FangcunDrinkTotals(diary.entries(on: selected)) }
  private var minutes: Int {
    Int(practices.filter { Calendar.current.isDate($0.endedAt, inSameDayAs: selected) }.reduce(0) { $0 + $1.actualDuration } / 60)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text("Your week, gently").font(.title2.weight(.semibold))
        Text("Every day has its own rhythm.").font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
        HStack(alignment: .bottom, spacing: 8) {
          ForEach(days, id: \.self) { date in
            let daySnapshot = diary.snapshot(on: date)
            let dayState = daySnapshot?.state
            Button { selected = date } label: {
              VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                  .fill(color(dayState))
                  .frame(height: dayState == .elevated ? 88 : dayState == .watch ? 70 : dayState == .steady ? 52 : 12)
                  .frame(height: 92, alignment: .bottom)
                Text(date, format: .dateTime.weekday(.narrow)).font(.caption)
                Circle().fill(Calendar.current.isDate(date, inSameDayAs: selected) ? InnerBalanceTheme.strongFill : .clear).frame(width: 5, height: 5)
              }.frame(maxWidth: .infinity).frame(minHeight: 130).contentShape(Rectangle())
            }.buttonStyle(.plain)
              .accessibilityLabel("\(date.formatted(.dateTime.month().day().locale(Locale(identifier: "en")))), \(daySnapshot?.displayStateTitle ?? "No entry")")
              .accessibilityAddTraits(Calendar.current.isDate(date, inSameDayAs: selected) ? .isSelected : [])
          }
        }.fangcunPaperCard()
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 16) {
            Label(FangcunDayState.steady.shortTitle, systemImage: "circle.fill").foregroundStyle(color(.steady))
            Label(FangcunDayState.watch.shortTitle, systemImage: "circle.fill").foregroundStyle(color(.watch))
            Label(FangcunDayState.elevated.shortTitle, systemImage: "circle.fill").foregroundStyle(color(.elevated))
          }
          Text(FangcunCopy.text("body.history.unknownLegend")).foregroundStyle(InnerBalanceTheme.mutedInk)
        }.font(.caption2)
        VStack(alignment: .leading, spacing: 18) {
          HStack { Text(selected, format: .dateTime.month().day()).font(.headline); Spacer(); Text(snapshot?.displayStateTitle ?? "No entry").font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk) }
          if snapshot?.isLegacy == true {
            Text(FangcunCopy.text("body.history.legacy")).font(.caption).accessibilityIdentifier("trends.legacy")
          }
          Text(snapshot?.summary ?? "No body-status snapshot for this day. We won't guess what it was.")
            .font(.subheadline).accessibilityIdentifier("trends.snapshot")
          Divider()
          row("Sleep", snapshot?.sleep ?? "No entry", "moon")
          row("Activity", snapshot?.training ?? "No entry", "figure.walk")
          row("Practice", minutes > 0 ? "\(minutes) min" : "Nothing here yet", "wind")
          row("Drinks logged", "\(totals.fluid) ml", "drop")
          row("Caffeine / Alcohol", "\(totals.caffeine) mg / \(totals.alcohol) g", "cup.and.saucer")
          row("Sweet drinks", "\(totals.sugar) servings", "takeoutbag.and.cup.and.straw")
          if snapshot?.isLegacy == false {
            ForEach(diary.legacySnapshots(on: selected)) { legacy in
              VStack(alignment: .leading, spacing: 6) {
                Text(FangcunCopy.text("body.history.legacy")).font(.caption)
                Text(legacy.displayStateTitle + " · " + legacy.summary).font(.caption)
              }.foregroundStyle(InnerBalanceTheme.mutedInk)
            }
          }
        }.fangcunPaperCard()
        if Calendar.current.isDateInToday(selected) { Button("Add a drink for today") { drinks = true }.buttonStyle(InnerBalancePrimaryButtonStyle()) }
        Text("Daily snapshots begin when this feature was enabled. Earlier practice records are retained. Bar heights distinguish categories, not medical scores.")
          .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
      }.padding(20)
    }.background(InnerBalanceTheme.canvas).foregroundStyle(InnerBalanceTheme.ink)
      .navigationTitle("History and patterns").navigationBarTitleDisplayMode(.inline)
      .sheet(isPresented: $drinks) { FangcunDrinkSheet() }
  }
  private func color(_ state: FangcunDayState?) -> Color {
    switch state { case .steady: Color(red: 0.41, green: 0.60, blue: 0.57); case .watch: InnerBalanceTheme.strongFill; case .elevated: InnerBalanceTheme.emphasis; default: InnerBalanceTheme.mutedInk.opacity(0.22) }
  }
  private func row(_ title: String, _ value: String, _ symbol: String) -> some View {
    HStack(alignment: .top) { Label(title, systemImage: symbol).foregroundStyle(InnerBalanceTheme.mutedInk); Spacer(); Text(value).multilineTextAlignment(.trailing) }.font(.subheadline)
  }
}
