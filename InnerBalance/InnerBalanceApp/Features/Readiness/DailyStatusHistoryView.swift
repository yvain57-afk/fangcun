import SwiftUI
import InnerBalanceCore

struct DailyStatusHistoryView: View {
  let owner: ReadinessCoordinator
  @State private var span = 7
  @State private var selected: Date?
  private var dates: [Date] { (0..<span).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Calendar.current.startOfDay(for: owner.now)) } }
  private func scores(_ day: Date) -> [DailyStatusSnapshot] {
    (owner.snapshot.statusScores ?? []).filter { $0.isValid && Calendar.current.isDate($0.asOf, inSameDayAs:day) }
      .sorted { $0.asOf == $1.asOf ? $0.revision > $1.revision : $0.asOf > $1.asOf }
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Every day has its own rhythm").font(.title2.weight(.semibold))
        Text("Look back without expecting every day to be the same.").font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
        Picker("Time range", selection: $span) { Text("7 days").tag(7); Text("28 days").tag(28) }
          .pickerStyle(.segmented).accessibilityIdentifier("readiness.history.range")
        LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:7)) {
          ForEach(dates,id:\.self) { day in
            let value = scores(day).first
            Button { selected = day } label: {
              VStack(spacing:8) {
                Text(day,format:.dateTime.day()).font(.caption)
                ZStack(alignment:.bottom) {
                  Capsule().fill(InnerBalanceTheme.subtleFill).frame(height:48)
                  if let value { Capsule().fill(InnerBalanceTheme.strongFill).frame(height:max(2,48*Double(value.displayScore)/100)) }
                }.frame(width:10,height:48)
                Text(value.map { String($0.displayScore) } ?? "—").font(.caption.monospacedDigit())
              }.frame(maxWidth:.infinity).padding(.vertical,8)
                .background(Calendar.current.isDate(day,inSameDayAs:selected ?? owner.now) ? InnerBalanceTheme.subtleFill : .clear,in:RoundedRectangle(cornerRadius:12))
            }.buttonStyle(.plain).accessibilityLabel(day.formatted(.dateTime.month().day().locale(Locale(identifier: "en"))) + (value.map { ", \($0.displayScore) points, \($0.band.englishTitle)" } ?? ", no index available"))
              .accessibilityIdentifier("status.history.day.\(Calendar.current.component(.day,from:day))")
          }
        }
        let day = selected ?? owner.now
        Text(day,format:.dateTime.month().day()).font(.headline)
        if let score = scores(day).first {
          NavigationLink { DailyStatusDetailView(score:score) } label: {
            VStack(alignment:.leading,spacing:8) {
              Text("\(score.displayScore) /100 · \(score.band.englishTitle)").font(.title2.weight(.semibold))
              Text("Included this time: "+score.components.map { DailyStatusPresentation.componentName($0.name) }.joined(separator:"、")).font(.subheadline)
              Text("See what's included").font(.caption)
            }.frame(maxWidth:.infinity,alignment:.leading).fangcunPaperCard()
          }.buttonStyle(.plain).accessibilityIdentifier("status.history.score")
          let preceding = (owner.snapshot.statusScores ?? []).filter { $0.asOf < score.asOf }.max { $0.asOf < $1.asOf }
          if score.compositionUpdated || preceding.map({ $0.scoreBasisProfile != score.scoreBasisProfile }) == true {
            Text("Included measures have changed").font(.caption).accessibilityIdentifier("status.history.composition")
          }
          let revisions = scores(day).filter { $0.cycleID == score.cycleID && $0.scoreID != score.scoreID }
          if !revisions.isEmpty {
            DisclosureGroup("Revisions for this period") {
              ForEach(revisions,id:\.scoreID) { prior in
                NavigationLink("Revision \(prior.revision) · \(prior.displayScore) points") { DailyStatusDetailView(score:prior) }
              }
            }
          }
        } else {
          VStack(alignment: .leading, spacing: 10) {
            Label("No index for this day yet.", systemImage: "leaf")
            Text("An empty day isn't a bad day.").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
          }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
        }
        Text("Index history starts with version 3. Earlier records are preserved.").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        NavigationLink("View earlier records (without an index)") { ReadinessHistoryView(owner:owner) }
          .accessibilityIdentifier("status.history.legacy")
      }.padding(20)
    }.background(InnerBalanceTheme.canvas).foregroundStyle(InnerBalanceTheme.ink)
      .fangcunCleanList().navigationTitle(span == 7 ? "This week's rhythm" : "The past four weeks").navigationBarTitleDisplayMode(.inline)
  }
}

struct ManualStatusSleepView: View {
  let owner: ReadinessCoordinator
  @Environment(\.dismiss) private var dismiss
  @State private var minutes = 375.0
  @State private var end: Date
  @State private var saving = false
  @State private var failed = false
  init(owner:ReadinessCoordinator) { self.owner = owner; _end = State(initialValue:owner.now.addingTimeInterval(-3600)) }
  var body: some View {
    NavigationStack {
      Form {
        Text("Add the time you actually slept and when you woke. This stays in Little Exhale and is marked as manually added.")
        Stepper("Time asleep: \(Int(minutes)/60) hr \(Int(minutes)%60) min",value:$minutes,in:0...1440,step:15).accessibilityIdentifier("status.manual.minutes")
        DatePicker("End time",selection:$end,in:owner.now.addingTimeInterval(-23*3600)...owner.now)
        Button(saving ? "Saving" : "Save and view body context") {
          Task { saving = true; await owner.saveManualSleep(minutes:minutes,end:end); saving = false
            if owner.statusScore?.features.manual == true { dismiss() } else { failed = true }
          }
        }.disabled(saving).accessibilityIdentifier("status.manual.save")
        if failed { Text("Couldn't save right now. Please try again.") }
      }.fangcunCleanList().navigationTitle("Add sleep manually").toolbar { Button("Cancel") { dismiss() } }
    }
  }
}
