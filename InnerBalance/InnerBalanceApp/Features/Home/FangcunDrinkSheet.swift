import SwiftUI
import InnerBalanceCore

struct FangcunDrinkSheet: View {
  @Environment(FangcunDiary.self) private var diary
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.careOwner) private var care
  @Environment(\.dismiss) private var dismiss
  @AppStorage("fangcun.coffeeMg") private var coffeeMg = 140
  @State private var sweetCoffee = false
  @State private var feedback = "轻轻记一下，就好。"
  @State private var reaction = 0
  @State private var motionEvent = CompanionMotionEvent.entered
  @State private var committedEvent: CompanionEvent?
  @State private var editing = false
  private var kinds: [FangcunDrink] { [.water, sweetCoffee ? .sweetCoffee : .coffee, .beer, .soda] }
  private var totals: BeverageTotals { BeverageTotals(diary.entries().map(\.beverage)) }
  private var cupML: Int { care?.preferences.cupML ?? 250 }

  var body: some View {
    Group {
      if typeSize.isAccessibilitySize {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) { header; rows; summary }
        }
      } else {
        VStack(spacing: 8) { header; ScrollView { rows }; summary }
      }
    }
    .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 8)
    .foregroundStyle(InnerBalanceTheme.ink).tint(InnerBalanceTheme.strongFill)
    .background(InnerBalanceTheme.canvas)
    .sheet(isPresented: $editing) { FangcunDrinkEditor() }
    .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.fraction(0.55), .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(28)
  }
  private var header: some View {
    let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout())
    return layout {
      VStack(alignment: .leading, spacing: 4) {
        Text("今天喝了什么？").font(.title3.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
        Text(feedback).font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
          .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("drinks.feedback")
      }
      HStack {
        Spacer(minLength: 0)
        FangcunCompanion(scene: .drink, paused: editing, reaction: reaction, event: motionEvent, committedEvent: committedEvent).frame(width: 68, height: 68)
        Button("完成") { dismiss() }.font(.subheadline).frame(minWidth: 44, minHeight: 44)
      }
    }
  }
  private var rows: some View {
    VStack(spacing: typeSize.isAccessibilitySize ? 28 : 3) {
      ForEach(kinds) { kind in drinkRow(kind) }
      Toggle("咖啡是甜拿铁（同时记糖饮）", isOn: $sweetCoffee).font(.caption).padding(.vertical, 6)
      Button(FangcunCopy.text("diary.manage")) { editing = true }.accessibilityIdentifier("drinks.manage")
      Text("按杯预估，实际含量会因品牌与杯量变化。酒精不折算为补水建议。")
        .font(.caption2).foregroundStyle(InnerBalanceTheme.mutedInk).frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
  private func drinkRow(_ kind: FangcunDrink) -> some View {
    let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 10))
    return layout {
      HStack(alignment: .top, spacing: 10) {
        Image(systemName: kind.symbol).foregroundStyle(InnerBalanceTheme.strongFill).accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 3) {
          Text(kind.title).font(.subheadline.weight(.medium))
          Text("\(kind == .water ? cupML : kind.fluid) ml" + (kind.isCoffee ? " · 每杯约 \(coffeeMg) mg 咖啡因" : kind == .beer ? " · 5% · 约 13 g 酒精" : ""))
            .font(.caption2).foregroundStyle(InnerBalanceTheme.mutedInk)
        }.fixedSize(horizontal: false, vertical: true)
      }
      HStack(spacing: 10) {
        Spacer(minLength: 0)
        Button { change(kind, adding: false) } label: { Image(systemName: "minus").frame(minWidth: 44, minHeight: 44) }
          .accessibilityLabel("减少\(kind.title)").disabled(count(kind) == 0)
        Text("\(count(kind))").font(.subheadline.monospacedDigit()).frame(minWidth: 12)
          .accessibilityIdentifier("drinks.count.\(kind.rawValue)")
        Button { change(kind, adding: true) } label: {
          if kind == .water {
            Text(FangcunCopy.text("drink.logCup", cupML)).font(.caption2).multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true).padding(.horizontal, 12).padding(.vertical, 6)
              .frame(minWidth: 72, minHeight: 44).background(InnerBalanceTheme.subtleFill, in: RoundedRectangle(cornerRadius: 18))
          } else { Image(systemName: "plus").frame(minWidth: 44, minHeight: 44).background(InnerBalanceTheme.subtleFill, in: Circle()) }
        }
        .accessibilityLabel(kind == .water ? FangcunCopy.text("drink.logCup", cupML) : "增加\(kind.title)")
        .accessibilityIdentifier("drinks.add." + kind.rawValue)
      }
    }
    .opacity(diary.storageMessage == nil ? 1 : 0.5).disabled(diary.storageMessage != nil)
  }
  private var summary: some View {
    VStack(spacing: 8) {
      if let care, care.preferences.volumePromptsAllowed {
        if care.preferences.referenceAccepted {
          Text(FangcunCopy.text("care.progress", totals.nonAlcoholBeverageML, care.preferences.referenceML)).font(.caption)
          ProgressView(value: Double(min(totals.nonAlcoholBeverageML, care.preferences.referenceML)), total: Double(care.preferences.referenceML))
        } else {
          Button(FangcunCopy.text("care.acceptDraft", care.preferences.referenceML)) {
            var p = care.preferences; p.referenceAccepted = true; care.update(p)
          }.font(.caption).frame(minHeight: 44)
        }
      }
      Divider()
      (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout())) {
        VStack(alignment: .leading, spacing: 3) {
          Text(FangcunCopy.text("drink.recordedFluid", totals.allBeverageML, totals.nonAlcoholBeverageML))
          Text(FangcunCopy.text("drink.recordedDose", totals.knownCaffeineMG, totals.knownAlcoholGrams))
        }.font(.caption).fixedSize(horizontal: false, vertical: true).accessibilityElement(children: .combine).accessibilityIdentifier("drinks.totals")
        if !typeSize.isAccessibilitySize { Spacer() }
        Button { report(diary.undo(), key: "drink.undone", event: .drinkUndone) } label: { Label("撤销", systemImage: "arrow.uturn.backward") }
          .font(.caption).frame(minHeight: 44).disabled(!diary.canUndo)
      }
      if totals.hasUnknownCaffeine { Text(FangcunCopy.text("drink.unknownCaffeine")).font(.caption) }
      if totals.hasUnknownAlcohol { Text(FangcunCopy.text("diary.unknownAlcohol")).font(.caption) }
      if let message = diary.storageMessage {
        Text(message).font(.caption).foregroundStyle(InnerBalanceTheme.emphasis)
        Button(FangcunCopy.text("diary.retry")) { diary.retry() }
      }
    }
  }
  private func count(_ kind: FangcunDrink) -> Int { diary.entries().filter { kind.isCoffee ? $0.kind.isCoffee : $0.kind == kind }.count }
  private func change(_ kind: FangcunDrink, adding: Bool) {
    let result: DrinkCommandResult
    if adding { result = diary.add(kind, caffeine: coffeeMg, volumeML: kind == .water ? cupML : nil) }
    else if kind.isCoffee, let last = diary.entries().last(where: { $0.kind.isCoffee }) { result = diary.remove(last.kind) }
    else { result = diary.remove(kind) }
    report(result, key: adding ? "drink.saved" : "drink.removed", event: !adding ? .drinkUndone : kind == .water ? .waterCommitted : .drinkCommitted)
  }
  private func report(_ result: DrinkCommandResult, key: String, event: CompanionMotionEvent) {
    switch result {
    case let .committed(receipt):
      feedback = FangcunCopy.text(key); motionEvent = event
      committedEvent = .init(id: receipt.eventID, kind: event, entityID: receipt.entityID.uuidString,
        revision: receipt.revision, committedAt: receipt.committedAt)
      reaction += 1
    case .rejected: feedback = FangcunCopy.text("drink.rejected")
    case .failed: feedback = diary.storageMessage ?? FangcunCopy.text("drink.failed")
    }
  }
}
