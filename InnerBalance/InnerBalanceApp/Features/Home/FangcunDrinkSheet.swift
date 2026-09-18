import SwiftUI

struct FangcunDrinkSheet: View {
  @Environment(FangcunDiary.self) private var diary
  @Environment(\.dismiss) private var dismiss
  @AppStorage("fangcun.coffeeMg") private var coffeeMg = 140
  @State private var sweetCoffee = false
  @State private var feedback = "轻轻记一下，就好。"
  @State private var reaction = 0
  private var kinds: [FangcunDrink] { [.water, sweetCoffee ? .sweetCoffee : .coffee, .beer, .soda] }
  private var totals: FangcunDrinkTotals { FangcunDrinkTotals(diary.entries()) }

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("今天喝了什么？").font(.title3.weight(.semibold))
          Text(feedback).font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
            .accessibilityIdentifier("drinks.feedback")
        }
        Spacer()
        FangcunCompanion(scene: .drink, reaction: reaction).frame(width: 68, height: 68)
        Button("完成") { dismiss() }.font(.subheadline).frame(minWidth: 44, minHeight: 44)
      }
      ScrollView {
        VStack(spacing: 3) {
          ForEach(kinds) { kind in
            HStack(spacing: 10) {
              Image(systemName: kind.symbol).frame(width: 22).foregroundStyle(InnerBalanceTheme.strongFill)
              VStack(alignment: .leading, spacing: 3) {
                Text(kind.title).font(.subheadline.weight(.medium))
                Text("\(kind.fluid) ml" + (kind.isCoffee ? " · 约 \(coffeeMg) mg 咖啡因" : kind == .beer ? " · 约 10 g 酒精" : ""))
                  .font(.caption2).foregroundStyle(InnerBalanceTheme.mutedInk)
              }
              Spacer(minLength: 0)
              Button { change(kind, adding: false) } label: { Image(systemName: "minus").frame(width: 44, height: 44) }
                .accessibilityLabel("减少\(kind.title)")
                .disabled(count(kind) == 0)
              Text("\(count(kind))").font(.subheadline.monospacedDigit()).frame(minWidth: 12)
                .accessibilityIdentifier("drinks.count.\(kind.rawValue)")
              Button { change(kind, adding: true) } label: { Image(systemName: "plus").frame(width: 44, height: 44).background(InnerBalanceTheme.subtleFill, in: Circle()) }
                .accessibilityLabel("增加\(kind.title)")
            }
            .opacity(diary.storageMessage == nil ? 1 : 0.5)
            .disabled(diary.storageMessage != nil)
          }
          Toggle("咖啡是甜拿铁（同时记糖饮）", isOn: $sweetCoffee).font(.caption).padding(.vertical, 6)
          Text("按杯预估，实际含量会因品牌与杯量变化。酒精不折算为补水建议。")
            .font(.caption2).foregroundStyle(InnerBalanceTheme.mutedInk).frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      Divider()
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("总液体 \(totals.fluid) ml · 咖啡因 \(totals.caffeine) mg")
          Text("酒精 \(totals.alcohol) g · 糖饮 \(totals.sugar) 份")
        }.font(.caption).accessibilityElement(children: .combine).accessibilityIdentifier("drinks.totals")
        Spacer()
        Button { diary.undo(); feedback = "已撤销上一笔"; reaction += 1 } label: { Label("撤销", systemImage: "arrow.uturn.backward") }
          .font(.caption).frame(minHeight: 44).disabled(!diary.canUndo)
      }
      if let message = diary.storageMessage { Text(message).font(.caption).foregroundStyle(InnerBalanceTheme.emphasis) }
    }
    .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 8)
    .foregroundStyle(InnerBalanceTheme.ink).tint(InnerBalanceTheme.strongFill)
    .background(InnerBalanceTheme.canvas)
    .presentationDetents([.fraction(0.55), .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(28)
  }
  private func count(_ kind: FangcunDrink) -> Int { diary.entries().filter { kind.isCoffee ? $0.kind.isCoffee : $0.kind == kind }.count }
  private func change(_ kind: FangcunDrink, adding: Bool) {
    if adding { diary.add(kind, caffeine: coffeeMg) }
    else if kind.isCoffee, let last = diary.entries().last(where: { $0.kind.isCoffee }) { diary.remove(last.kind) }
    else { diary.remove(kind) }
    feedback = diary.storageMessage ?? "已\(adding ? "记录" : "减少")一杯\(kind.title)"
    reaction += 1
  }
}
