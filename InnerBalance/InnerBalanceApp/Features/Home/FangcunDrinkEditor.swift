import SwiftUI
import InnerBalanceCore

struct FangcunDrinkEditor: View {
  @Environment(FangcunDiary.self) private var diary
  @Environment(\.dismiss) private var dismiss
  @AppStorage("fangcun.coffeeMg") private var coffeeMg = 140
  @State private var selectedID: UUID?
  @State private var kind = FangcunDrink.water
  @State private var consumedAt = Date.now
  @State private var volume = 250
  @State private var name = ""
  @State private var caffeinePresence = BeveragePresence.no
  @State private var doseMethod = BeverageDoseMethod.perServing
  @State private var dose = 140.0
  @State private var alcoholPresence = BeveragePresence.no
  @State private var abv = 5.0
  @State private var abvKnown = true
  @State private var feedback: String?
  @State private var editingLegacy = false
  private var details: BeverageDetails { .init(displayName: name.isEmpty ? kind.title : name,
    caffeinePresence: caffeinePresence, caffeineMethod: doseMethod, caffeineDose: doseMethod == .unknown ? nil : dose,
    alcoholPresence: alcoholPresence, abvPercent: abvKnown ? abv : nil) }
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
          TextField(FangcunCopy.text("drink.name"), text: $name)
          if editingLegacy { Text(FangcunCopy.text("drink.legacy")) }
          else {
            Picker(FangcunCopy.text("drink.caffeinePresence"), selection: $caffeinePresence) {
              ForEach([BeveragePresence.no, .yes, .unknown], id: \.self) { Text(FangcunCopy.text("drink.presence." + $0.rawValue)).tag($0) }
            }
            if caffeinePresence == .yes {
              Picker(FangcunCopy.text("drink.doseMethod"), selection: $doseMethod) {
                ForEach([BeverageDoseMethod.perServing, .per100ML, .unknown], id: \.self) { Text(FangcunCopy.text("drink.dose." + $0.rawValue)).tag($0) }
              }
              if doseMethod != .unknown { TextField(FangcunCopy.text("drink.doseMG"), value: $dose, format: .number).keyboardType(.decimalPad) }
            }
            Picker(FangcunCopy.text("drink.alcoholPresence"), selection: $alcoholPresence) {
              ForEach([BeveragePresence.no, .yes, .unknown], id: \.self) { Text(FangcunCopy.text("drink.presence." + $0.rawValue)).tag($0) }
            }
            if alcoholPresence == .yes {
              Toggle(FangcunCopy.text("drink.abvKnown"), isOn: $abvKnown)
              if abvKnown { TextField(FangcunCopy.text("drink.abv"), value: $abv, format: .number).keyboardType(.decimalPad) }
            }
          }
          Button(FangcunCopy.text(selectedID == nil ? "diary.add" : "diary.save")) {
            let result: DrinkCommandResult
            if let selectedID { result = diary.edit(selectedID, consumedAt: consumedAt, volumeML: volume, details: editingLegacy ? nil : details) }
            else { result = diary.add(kind, at: consumedAt, volumeML: volume, details: details) }
            feedback = FangcunCopy.text(result.receipt == nil ? "drink.failed" : "drink.saved")
            if result.receipt != nil { selectedID = nil; editingLegacy = false; resetDefaults() }
          }.accessibilityIdentifier("drinks.edit.save")
            .disabled(!(10...3000).contains(volume) || diary.storageMessage != nil)
          if let feedback { Text(feedback).accessibilityIdentifier("drinks.edit.feedback") }
          Button(FangcunCopy.text("diary.undo")) { _ = diary.undo() }.disabled(!diary.canUndo)
          if let selectedID {
            Button(FangcunCopy.text("drink.delete"), role: .destructive) {
              let result = diary.remove(id: selectedID)
              if result.receipt != nil { self.selectedID = nil; editingLegacy = false; resetDefaults() }
            }
          }
        } footer: { Text(FangcunCopy.text("diary.range")) }
        if let message = diary.storageMessage {
          Section { Text(message); Button(FangcunCopy.text("diary.retry")) { diary.retry() } }
        }
        Section(FangcunCopy.text("diary.records")) {
          ForEach(diary.allEntries.filter { $0.date >= earliest }.sorted { $0.date > $1.date }) { entry in
            Button {
              selectedID = entry.id; kind = entry.kind; consumedAt = entry.date; volume = entry.volumeML
              name = entry.displayName; editingLegacy = entry.details == nil
              if let d = entry.details {
                caffeinePresence = d.caffeinePresence; doseMethod = d.caffeineMethod; dose = d.caffeineDose ?? 0
                alcoholPresence = d.alcoholPresence; abvKnown = d.abvPercent != nil; abv = d.abvPercent ?? 5
              }
            } label: {
              VStack(alignment: .leading) {
                Text(FangcunCopy.text("diary.entry", entry.displayName, entry.volumeML))
                Text(FangcunCopy.timestamp(entry.date)).font(.caption)
              }
            }.accessibilityIdentifier("drinks.edit.entry.\(entry.id)")
          }
        }
      }.scrollContentBackground(.hidden).background(InnerBalanceTheme.canvas)
        .foregroundStyle(InnerBalanceTheme.ink).tint(InnerBalanceTheme.strongFill)
        .navigationTitle(FangcunCopy.text("diary.manage"))
        .toolbar { Button(FangcunCopy.text("diary.done")) { dismiss() } }
        .onChange(of: kind) { _, value in if selectedID == nil { volume = value.fluid; resetDefaults() } }
    }
  }
  private func resetDefaults() {
    let d = FangcunDiary.defaultDetails(kind, caffeine: coffeeMg)
    name = d.displayName; caffeinePresence = d.caffeinePresence; doseMethod = d.caffeineMethod; dose = d.caffeineDose ?? 140
    alcoholPresence = d.alcoholPresence; abvKnown = d.abvPercent != nil; abv = d.abvPercent ?? 5
  }
}
