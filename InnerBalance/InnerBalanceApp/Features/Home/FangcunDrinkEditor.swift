import SwiftUI

struct FangcunDrinkEditor: View {
  @Environment(FangcunDiary.self) private var diary
  @Environment(\.dismiss) private var dismiss
  @AppStorage("fangcun.coffeeMg") private var coffeeMg = 140
  @State private var selectedID: UUID?
  @State private var kind = FangcunDrink.water
  @State private var consumedAt = Date.now
  @State private var volume = 250
  private var earliest: Date { Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now))! }
  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker(FangcunCopy.text("diary.kind"), selection: $kind) {
            ForEach(FangcunDrink.allCases) { Text($0.title).tag($0) }
          }.disabled(selectedID != nil)
          DatePicker(FangcunCopy.text("diary.time"), selection: $consumedAt, in: earliest...Date.now)
            .accessibilityIdentifier("drinks.edit.time")
          TextField(FangcunCopy.text("diary.volume"), value: $volume, format: .number)
            .keyboardType(.numberPad).accessibilityIdentifier("drinks.edit.volume")
          Text(FangcunCopy.text("diary.estimate")).font(.caption)
          Button(FangcunCopy.text(selectedID == nil ? "diary.add" : "diary.save")) {
            if let selectedID { diary.edit(selectedID, consumedAt: consumedAt, volumeML: volume) }
            else { diary.add(kind, caffeine: coffeeMg, at: consumedAt, volumeML: volume) }
            if diary.storageMessage == nil { selectedID = nil }
          }.accessibilityIdentifier("drinks.edit.save")
            .disabled(!(10...3000).contains(volume) || diary.storageMessage != nil)
          Button(FangcunCopy.text("diary.undo")) { diary.undo() }.disabled(!diary.canUndo)
        } footer: { Text(FangcunCopy.text("diary.range")) }
        if let message = diary.storageMessage {
          Section { Text(message); Button(FangcunCopy.text("diary.retry")) { diary.retry() } }
        }
        Section(FangcunCopy.text("diary.records")) {
          ForEach(diary.allEntries.filter { $0.date >= earliest }.sorted { $0.date > $1.date }) { entry in
            Button {
              selectedID = entry.id; kind = entry.kind; consumedAt = entry.date; volume = entry.volumeML
            } label: {
              VStack(alignment: .leading) {
                Text(FangcunCopy.text("diary.entry", entry.kind.title, entry.volumeML))
                Text(FangcunCopy.timestamp(entry.date)).font(.caption)
              }
            }.accessibilityIdentifier("drinks.edit.entry.\(entry.id)")
          }
        }
      }.scrollContentBackground(.hidden).background(InnerBalanceTheme.canvas)
        .foregroundStyle(InnerBalanceTheme.ink).tint(InnerBalanceTheme.strongFill)
        .navigationTitle(FangcunCopy.text("diary.manage"))
        .toolbar { Button(FangcunCopy.text("diary.done")) { dismiss() } }
        .onChange(of: kind) { _, value in if selectedID == nil { volume = value.fluid } }
    }
  }
}
