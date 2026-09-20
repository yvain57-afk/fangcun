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
        Picker("时间范围", selection: $span) { Text("7 天").tag(7); Text("28 天").tag(28) }
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
            }.buttonStyle(.plain).accessibilityLabel(day.formatted(.dateTime.month().day()) + (value.map { "，\($0.displayScore)分，\($0.band.title)" } ?? "，没有状态分"))
              .accessibilityIdentifier("status.history.day.\(Calendar.current.component(.day,from:day))")
          }
        }
        let day = selected ?? owner.now
        Text(day,format:.dateTime.month().day()).font(.headline)
        if let score = scores(day).first {
          NavigationLink { DailyStatusDetailView(score:score) } label: {
            VStack(alignment:.leading,spacing:8) {
              Text("\(score.displayScore) /100 · \(score.band.title)").font(.title2.weight(.semibold))
              Text("本次计入："+score.components.map { DailyStatusPresentation.componentName($0.name) }.joined(separator:"、")).font(.subheadline)
              Text("查看分数构成").font(.caption)
            }.frame(maxWidth:.infinity,alignment:.leading).fangcunPaperCard()
          }.buttonStyle(.plain).accessibilityIdentifier("status.history.score")
          let preceding = (owner.snapshot.statusScores ?? []).filter { $0.asOf < score.asOf }.max { $0.asOf < $1.asOf }
          if score.compositionUpdated || preceding.map({ $0.scoreBasisProfile != score.scoreBasisProfile }) == true {
            Text("计入项目已更新").font(.caption).accessibilityIdentifier("status.history.composition")
          }
          let revisions = scores(day).filter { $0.cycleID == score.cycleID && $0.scoreID != score.scoreID }
          if !revisions.isEmpty {
            DisclosureGroup("此周期的修订记录") {
              ForEach(revisions,id:\.scoreID) { prior in
                NavigationLink("修订 \(prior.revision) · \(prior.displayScore)分") { DailyStatusDetailView(score:prior) }
              }
            }
          }
        } else { Text("这一天还没有状态分。") }
        Text("状态分从 v3 开始记录，旧版记录保持原样。").font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        NavigationLink("查看旧版记录（无状态分）") { ReadinessHistoryView(owner:owner) }
          .accessibilityIdentifier("status.history.legacy")
      }.padding(20)
    }.background(InnerBalanceTheme.canvas).foregroundStyle(InnerBalanceTheme.ink)
      .navigationTitle("这一周的节奏").navigationBarTitleDisplayMode(.inline)
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
        Text("补记这次主睡眠的实际时长和结束时间。记录保存在方寸，标注为你补记的睡眠。")
        Stepper("实际睡眠 \(Int(minutes)/60) 小时 \(Int(minutes)%60) 分",value:$minutes,in:0...1440,step:15).accessibilityIdentifier("status.manual.minutes")
        DatePicker("结束时间",selection:$end,in:owner.now.addingTimeInterval(-23*3600)...owner.now)
        Button(saving ? "正在保存" : "保存并查看状态") {
          Task { saving = true; await owner.saveManualSleep(minutes:minutes,end:end); saving = false
            if owner.statusScore?.features.manual == true { dismiss() } else { failed = true }
          }
        }.disabled(saving).accessibilityIdentifier("status.manual.save")
        if failed { Text("暂时未能保存，请重试。") }
      }.navigationTitle("补记一次睡眠").toolbar { Button("取消") { dismiss() } }
    }
  }
}
