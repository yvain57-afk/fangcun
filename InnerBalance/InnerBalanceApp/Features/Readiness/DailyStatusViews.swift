import SwiftUI
import InnerBalanceCore

struct DailyStatusPresentation {
  let score: DailyStatusSnapshot
  let now: Date
  var title: String { now < score.currentUntil ? "Today's body context" : "Previous body context" }
  var reason: String {
    let factor = score.components.max { (100-$0.score)*$0.normalizedWeight < (100-$1.score)*$1.normalizedWeight }
    if factor?.name == "sleep", let minutes = score.features.input.sleepMinutes {
      let value = Int(minutes.rounded())
      return "You slept \(value/60) hr \(value%60) min. " + (minutes < score.configuration.sleepGoalMinutes ? "Leave a little room in your day." : "You met your sleep goal.")
    }
    return factor?.name == "hrv" ? "The index includes how your HRV compares with your recent level." : "The index includes how your resting heart rate compares with your recent level."
  }
  var scene: FangcunCompanionScene { score.band == .good || score.band == .fair ? .calm : .rest }
  var cycle: String {
    let date = score.asOf.formatted(.dateTime.month().day().locale(Locale(identifier: "en")))
    let hour = Calendar.current.component(.hour, from: score.asOf)
    return date + (score.features.sleepEnd == nil ? " · Daytime assessment" : hour < 12 ? " · Morning assessment" : " · After-sleep assessment")
  }
  static func componentName(_ key: String) -> String { key == "sleep" ? "Sleep" : key == "hrv" ? "Heart rate variability" : "Resting heart rate" }
}

struct DailyStatusHero: View {
  let score: DailyStatusSnapshot
  let now: Date
  let night: Bool
  var covered = false
  @Environment(\.dynamicTypeSize) private var typeSize
  @ScaledMetric(relativeTo: .largeTitle) private var numberSize = 56.0
  private var p: DailyStatusPresentation { .init(score: score, now: now) }
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(p.title).font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
      let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
      layout {
        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(String(score.displayScore)).font(.system(size: numberSize, weight: .semibold).monospacedDigit())
              .accessibilityIdentifier("status.score")
            Text("/100").font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
          }.accessibilityElement(children: .combine).accessibilityLabel("Daily index, \(score.displayScore) out of 100")
          Text(score.band.englishTitle).font(.title3.weight(.semibold)).accessibilityIdentifier("status.band")
        }
        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
        if !typeSize.isAccessibilitySize {
          PracticeCompanionV4(kind: p.scene == .calm ? .balancedBreathing : .nsdr, elapsed: 0, duration: 300, isActive: false)
            .frame(width: 135, height: 110)
        }
      }
      Text(p.reason).font(.subheadline).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("status.reason")
      if night { Text("Consider an earlier wind-down tonight.").font(.subheadline).accessibilityIdentifier("status.arrangement") }
      Text(p.cycle).font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        .accessibilityIdentifier("status.cycle").accessibilityValue(score.asOf.ISO8601Format())
    }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
  }
}

struct DailyStatusDetailView: View {
  let score: DailyStatusSnapshot
  var onStart: (() -> Void)?
  var actionTitle = "Take 2 minutes of quiet rest"
  var lastQueryAt: Date?
  @State private var method = false
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("\(score.displayScore) /100 · \(score.band.englishTitle)").font(.largeTitle.weight(.semibold)).accessibilityIdentifier("status.detail.score")
        Text(DailyStatusPresentation(score: score, now: score.asOf).reason).font(.subheadline)
        ForEach(score.components, id: \.name) { part in
          VStack(alignment: .leading, spacing: 6) {
            Text("\(DailyStatusPresentation.componentName(part.name)) · \(Int(part.score.rounded())) points").font(.headline)
            Text("\(Int((part.normalizedWeight*100).rounded()))% of this assessment").font(.subheadline)
            DisclosureGroup("View this measure") {
              if let value = score.features.displayValues[part.name] {
                Text(part.name == "sleep" ? "Time asleep: \(Int(value.rounded())) min" : part.name == "hrv" ? "SDNN \(value.formatted(.number.precision(.fractionLength(1)))) ms" : "System resting heart rate: \(value.formatted(.number.precision(.fractionLength(1)))) bpm")
              }
              if let measured = score.features.measuredAt[part.name] {
                Text("Measured: "+measured.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "en"))))
              }
              if part.name == "sleep" {
                Text("Your goal: \(Int(score.configuration.sleepGoalMinutes)) min")
                if score.features.manual { Text("Sleep you added") }
                ForEach(score.sleepSubscores.keys.sorted(),id:\.self) { key in
                  Text("\(key == "duration" ? "Duration" : key == "continuity" ? "Continuity" : "Regularity"): \(Int(score.sleepSubscores[key]!.rounded())) points")
                }
              } else {
                Text("Personal history: \(part.name == "hrv" ? score.features.input.hrvDays : score.features.input.rhrDays) days")
                if part.name == "hrv" { Text("\(score.features.input.hrvSamples) samples across \(score.features.input.hrvHours) hourly windows") }
                Text(part.name == "hrv" ? "Log median of SDNN from the same source during the selected main sleep." : score.features.windowPolicy.contains("dailyRHR") ? "Today's system resting heart rate, compared with daily values from the same source over the past 28 days." : "System resting heart rate in the morning window, compared with daily values from the same source over the past 28 days.")
              }
            }.font(.caption)

          }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
        }
        if score.compositionUpdated { Text("Included measures have changed").font(.caption).accessibilityIdentifier("status.compositionChanged") }
        if let onStart { Button(actionTitle, action: onStart).buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("status.detail.action") }
        Button("About this index") { method.toggle() }.frame(minHeight: 44).accessibilityIdentifier("status.method")
        if method {
          Text("Included this time: " + score.components.map { DailyStatusPresentation.componentName($0.name) }.joined(separator: "、"))
          Text("This everyday index combines sleep with available heart-rate measures. A higher number means those inputs scored more favorably under these rules. It isn't a measured stress percentage or clearance to exercise. Missing measures are excluded from weighting.")
          Text("Model version: \(score.modelVersion)").font(.caption)
          Text(score.features.manual ? "Sleep was added by you." : "Data comes from the selected health sources.").font(.caption)
          Text("Assessment as of: "+score.asOf.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "en")))).font(.caption)
            .accessibilityIdentifier("status.time.asOf").accessibilityValue(score.asOf.ISO8601Format())
          Text("Calculated: "+score.createdAt.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "en")))).font(.caption)
            .accessibilityIdentifier("status.time.computed").accessibilityValue(score.createdAt.ISO8601Format())
          if let lastQueryAt {
            Text("Last checked: "+lastQueryAt.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "en")))).font(.caption)
              .accessibilityIdentifier("status.time.query").accessibilityValue(lastQueryAt.ISO8601Format())
          }
        }
      }.padding(20)
    }.background(InnerBalanceTheme.canvas).foregroundStyle(InnerBalanceTheme.ink)
      .navigationTitle("What goes into this number?").navigationBarTitleDisplayMode(.inline)
  }
}
