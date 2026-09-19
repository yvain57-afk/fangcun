import SwiftUI
import InnerBalanceCore

struct BeverageCareCard: View {
  let owner: BeverageCareCoordinator
  var body: some View {
    if let candidate = owner.selection?.candidate {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top) {
          Text(FangcunCopy.text(candidate.titleKey)).font(.subheadline.weight(.semibold))
          Spacer()
          if candidate.category != .danger {
            Button { owner.action("care.dismiss") } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
              .accessibilityLabel(FangcunCopy.text("care.dismiss"))
          }
        }
        Text(FangcunCopy.text(candidate.bodyKey)).font(.subheadline)
        if let note = candidate.noteKey { Text(FangcunCopy.text(note)).font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk) }
        if candidate.category == .danger {
          Text(FangcunCopy.text("care.emergency")).font(.headline)
          Button(FangcunCopy.text("care.safetyResolved")) { owner.action("care.safetyResolved") }.frame(minHeight: 44)
        } else {
          ViewThatFits(in: .horizontal) {
            HStack { actions(candidate) }
            VStack(alignment: .leading) { actions(candidate) }
          }
        }
      }.accessibilityIdentifier("care.card").accessibilityValue(candidate.ruleID)
        .padding(.top, 6)
    }
  }
  @ViewBuilder private func actions(_ c: CareCandidate) -> some View {
    ForEach(c.actionKeys, id: \.self) { key in
      Button(FangcunCopy.text(key)) { owner.action(key) }.font(.caption).frame(minHeight: 44)
    }
  }
}

struct BeverageCareSettings: View {
  let owner: BeverageCareCoordinator
  @State private var clear = false
  @State private var severe = false
  private func binding<T>(_ key: WritableKeyPath<CarePreferences, T>) -> Binding<T> {
    Binding(get: { owner.preferences[keyPath: key] }, set: { value in var p = owner.preferences; p[keyPath: key] = value; owner.update(p) })
  }
  var body: some View {
    Form {
      Section(FangcunCopy.text("care.settings")) {
        Toggle(FangcunCopy.text("care.inApp"), isOn: binding(\.inAppEnabled))
        Toggle(FangcunCopy.text("care.fluidRestrictionSetting"), isOn: binding(\.fluidRestricted))
        Toggle(FangcunCopy.text("care.adult"), isOn: binding(\.adultReferenceApplies))
        Text(FangcunCopy.text("care.referenceBoundary")).font(.caption)
        Stepper(value: binding(\.referenceML), in: 500...3500, step: 250) {
          Text(FangcunCopy.text("care.reference", owner.preferences.referenceML))
        }.disabled(!owner.preferences.volumePromptsAllowed)
        Toggle(FangcunCopy.text("care.referenceAccept"), isOn: binding(\.referenceAccepted))
          .disabled(!owner.preferences.volumePromptsAllowed)
        Picker(FangcunCopy.text("care.cup"), selection: binding(\.cupML)) {
          ForEach([150,250,350,500], id: \.self) { Text("\($0) ml").tag($0) }
          if ![150,250,350,500].contains(owner.preferences.cupML) { Text("\(owner.preferences.cupML) ml").tag(owner.preferences.cupML) }
        }
        TextField(FangcunCopy.text("care.customCup"), value: binding(\.cupML), format: .number).keyboardType(.numberPad)
      }
      Section(FangcunCopy.text("care.sleepPlan")) {
        Toggle(FangcunCopy.text("care.confirmSleep"), isOn: binding(\.sleepPlanConfirmed))
        if owner.preferences.sleepPlanConfirmed {
          timePicker("care.sleep", minute: binding(\.sleepMinute))
          timePicker("care.wake", minute: binding(\.wakeMinute))
          Stepper(value: binding(\.lateWindowHours), in: 6...12, step: 1) { Text(FangcunCopy.text("care.window", owner.preferences.lateWindowHours)) }
          Toggle(FangcunCopy.text("care.shift"), isOn: Binding(get: { owner.preferences.sleepOverride != nil }, set: { value in
            var p = owner.preferences; p.sleepOverride = value ? .init(start: Date.now.addingTimeInterval(3600), end: Date.now.addingTimeInterval(9*3600)) : nil; owner.update(p)
          }))
          if let override = owner.preferences.sleepOverride {
            DatePicker(FangcunCopy.text("care.sleep"), selection: Binding(get: { owner.preferences.sleepOverride?.start ?? override.start }, set: { value in
              var p = owner.preferences; p.sleepOverride = .init(start: value, end: max(value.addingTimeInterval(60), p.sleepOverride!.end)); owner.update(p)
            }))
            DatePicker(FangcunCopy.text("care.wake"), selection: Binding(get: { owner.preferences.sleepOverride?.end ?? override.end }, set: { value in
              var p = owner.preferences; if value > p.sleepOverride!.start { p.sleepOverride?.end = value; owner.update(p) }
            }))
          }
        } else {
          Toggle(FangcunCopy.text("care.manualCutoff"), isOn: Binding(get: { owner.preferences.cutoffMinute != nil }, set: { value in
            var p = owner.preferences; p.cutoffMinute = value ? 15*60 : nil; owner.update(p)
          }))
          if owner.preferences.cutoffMinute != nil {
            timePicker("care.cutoff", minute: Binding(get: { owner.preferences.cutoffMinute ?? 900 }, set: { value in
              var p = owner.preferences; p.cutoffMinute = value; owner.update(p)
            }))
          }
        }
        Stepper(value: binding(\.caffeineReferenceMG), in: 50...400, step: 50) { Text(FangcunCopy.text("care.caffeineReference", owner.preferences.caffeineReferenceMG)) }
      }
      Section(FangcunCopy.text("care.notifications")) {
        ForEach([CareCategory.water, .caffeine, .alcohol], id: \.self) { category in
          Toggle(FangcunCopy.text("care.push." + category.rawValue), isOn: Binding(get: {
            switch category { case .water: owner.preferences.waterPush; case .caffeine: owner.preferences.caffeinePush; case .alcohol: owner.preferences.alcoholPush; case .danger: false }
          }, set: { value in Task { await owner.enablePush(category, enabled: value) } }))
        }
        Toggle(FangcunCopy.text("care.lockDetails"), isOn: binding(\.detailedLockScreen))
        Text(FangcunCopy.text("care.authorization." + owner.authorization)).font(.caption)
        if let through = owner.scheduledThrough { Text(FangcunCopy.text("care.plannedThrough", FangcunCopy.timestamp(through))).font(.caption) }
        Text(FangcunCopy.text("care.notificationBoundary")).font(.caption)
        Button(FangcunCopy.text("care.laterAlcohol")) { owner.action("care.laterAlcohol") }
          .disabled(!owner.preferences.alcoholPush)
        Button(FangcunCopy.text("care.mute")) { owner.action("care.mute") }
      }
      Section(FangcunCopy.text("care.alcoholHelp")) {
        Button(FangcunCopy.text("care.tooMuch")) { owner.action("care.tooMuch") }
        Button(FangcunCopy.text("care.severe")) { severe = true }
      }
      if let error = owner.errorKey { Text(FangcunCopy.text(error)) }
      Button(FangcunCopy.text("care.clear"), role: .destructive) { clear = true }
    }.navigationTitle(FangcunCopy.text("care.settings"))
      .scrollContentBackground(.hidden).background(InnerBalanceTheme.canvas)
      .confirmationDialog(FangcunCopy.text("care.clearExplanation"), isPresented: $clear, titleVisibility: .visible) {
        Button(FangcunCopy.text("care.clear"), role: .destructive) { Task { await owner.clearPrivateCare() } }
      }
      .sheet(isPresented: $severe) {
        VStack(alignment: .leading, spacing: 24) {
          Text(FangcunCopy.text("care.A05.title")).font(.title2)
          Text(FangcunCopy.text("care.A05.body"))
          Text(FangcunCopy.text("care.emergency")).font(.headline)
          Button(FangcunCopy.text("care.severeConfirm")) { owner.action("care.severe"); severe = false }
          Button(FangcunCopy.text("diary.done")) { severe = false }
        }.padding(24).presentationDetents([.medium,.large])
      }
  }
  private func timePicker(_ key: String, minute: Binding<Int>) -> some View {
    DatePicker(FangcunCopy.text(key), selection: Binding(get: {
      Calendar.current.date(bySettingHour: minute.wrappedValue/60, minute: minute.wrappedValue%60, second: 0, of: .now)!
    }, set: { minute.wrappedValue = Calendar.current.component(.hour, from: $0)*60 + Calendar.current.component(.minute, from: $0) }), displayedComponents: .hourAndMinute)
  }
}
