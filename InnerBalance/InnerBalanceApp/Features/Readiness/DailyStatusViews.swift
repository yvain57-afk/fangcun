import SwiftUI
import InnerBalanceCore

struct DailyStatusPresentation {
  let score: DailyStatusSnapshot
  let now: Date
  var title: String { now < score.currentUntil ? "今日状态" : "上次状态" }
  var reason: String {
    let factor = score.components.max { (100-$0.score)*$0.normalizedWeight < (100-$1.score)*$1.normalizedWeight }
    if factor?.name == "sleep", let minutes = score.features.input.sleepMinutes {
      let value = Int(minutes.rounded())
      return "睡了 \(value/60) 小时\(value%60 == 0 ? "" : " \(value%60) 分")，" + (minutes < score.configuration.sleepGoalMinutes ? "今天给自己留点余地。" : "达到了你的睡眠目标。")
    }
    return factor?.name == "hrv" ? "心率变异性与近期个人水平的变化计入了分数。" : "静息心率与近期个人水平的变化计入了分数。"
  }
  var scene: FangcunCompanionScene { score.band == .good || score.band == .fair ? .calm : .rest }
  var cycle: String {
    let date = score.asOf.formatted(.dateTime.month().day())
    let hour = Calendar.current.component(.hour, from: score.asOf)
    return date + (score.features.sleepEnd == nil ? "日间评估" : hour < 12 ? "晨间评估" : "睡后评估")
  }
  static func componentName(_ key: String) -> String { key == "sleep" ? "睡眠" : key == "hrv" ? "心率变异性" : "静息心率" }
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
          }.accessibilityElement(children: .combine).accessibilityLabel("方寸状态分，\(score.displayScore)分")
          Text(score.band.title).font(.title3.weight(.semibold)).accessibilityIdentifier("status.band")
        }
        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
        if !typeSize.isAccessibilitySize {
          PracticeCompanionV4(kind: p.scene == .calm ? .balancedBreathing : .nsdr, elapsed: 0, duration: 300, isActive: false)
            .frame(width: 135, height: 110)
        }
      }
      Text(p.reason).font(.subheadline).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("status.reason")
      if night { Text("今晚早点收尾。").font(.subheadline).accessibilityIdentifier("status.arrangement") }
      Text(p.cycle).font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        .accessibilityIdentifier("status.cycle").accessibilityValue(score.asOf.ISO8601Format())
    }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
  }
}

struct DailyStatusDetailView: View {
  let score: DailyStatusSnapshot
  var onStart: (() -> Void)?
  var actionTitle = "开始 2 分钟安静休息"
  var lastQueryAt: Date?
  @State private var method = false
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("\(score.displayScore) /100 · \(score.band.title)").font(.largeTitle.weight(.semibold)).accessibilityIdentifier("status.detail.score")
        Text(DailyStatusPresentation(score: score, now: score.asOf).reason).font(.subheadline)
        ForEach(score.components, id: \.name) { part in
          VStack(alignment: .leading, spacing: 6) {
            Text("\(DailyStatusPresentation.componentName(part.name)) · \(Int(part.score.rounded())) 分").font(.headline)
            Text("占本次评分 \(Int((part.normalizedWeight*100).rounded()))%").font(.subheadline)
            DisclosureGroup("查看这项数据") {
              if let value = score.features.displayValues[part.name] {
                Text(part.name == "sleep" ? "实际睡眠 \(Int(value.rounded())) 分钟" : part.name == "hrv" ? "SDNN \(value.formatted(.number.precision(.fractionLength(1)))) ms" : "系统静息心率 \(value.formatted(.number.precision(.fractionLength(1)))) 次/分")
              }
              if let measured = score.features.measuredAt[part.name] {
                Text("测量："+measured.formatted(.dateTime.month().day().hour().minute()))
              }
              if part.name == "sleep" {
                Text("个人目标 \(Int(score.configuration.sleepGoalMinutes)) 分钟")
                if score.features.manual { Text("你补记的睡眠") }
                ForEach(score.sleepSubscores.keys.sorted(),id:\.self) { key in
                  Text("\(key == "duration" ? "时长" : key == "continuity" ? "连续性" : "规律")：\(Int(score.sleepSubscores[key]!.rounded())) 分")
                }
              } else {
                Text("个人比较历史：\(part.name == "hrv" ? score.features.input.hrvDays : score.features.input.rhrDays) 天")
                if part.name == "hrv" { Text("本次 \(score.features.input.hrvSamples) 个样本，覆盖 \(score.features.input.hrvHours) 个小时桶") }
                Text(part.name == "hrv" ? "所选主睡眠内，同源 SDNN 的对数中位数。" : score.features.windowPolicy.contains("dailyRHR") ? "当日系统静息心率；同源过去 28 天每日代表值作个人比较。" : "晨间窗口内系统静息心率；同源过去 28 天每日代表值作个人比较。")
              }
            }.font(.caption)

          }.frame(maxWidth: .infinity, alignment: .leading).fangcunPaperCard()
        }
        if score.compositionUpdated { Text("计入项目已更新").font(.caption).accessibilityIdentifier("status.compositionChanged") }
        if let onStart { Button(actionTitle, action: onStart).buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("status.detail.action") }
        Button("评分说明") { method.toggle() }.frame(minHeight: 44).accessibilityIdentifier("status.method")
        if method {
          Text("本次计入：" + score.components.map { DailyStatusPresentation.componentName($0.name) }.joined(separator: "、"))
          Text("方寸状态分是睡眠及可用心率变化的日常指数，高分表示这些输入在本规则中表现较好。它不是测得的心理压力百分比或运动安全许可。缺失项目不参与加权。")
          Text("计算版本：\(score.modelVersion)").font(.caption)
          Text(score.features.manual ? "睡眠由你补记。" : "数据来自所选健康来源。").font(.caption)
          Text("评估基准："+score.asOf.formatted(.dateTime.month().day().hour().minute())).font(.caption)
            .accessibilityIdentifier("status.time.asOf").accessibilityValue(score.asOf.ISO8601Format())
          Text("本次计算："+score.createdAt.formatted(.dateTime.month().day().hour().minute())).font(.caption)
            .accessibilityIdentifier("status.time.computed").accessibilityValue(score.createdAt.ISO8601Format())
          if let lastQueryAt {
            Text("最近查询："+lastQueryAt.formatted(.dateTime.month().day().hour().minute())).font(.caption)
              .accessibilityIdentifier("status.time.query").accessibilityValue(lastQueryAt.ISO8601Format())
          }
        }
      }.padding(20)
    }.background(InnerBalanceTheme.canvas).foregroundStyle(InnerBalanceTheme.ink)
      .navigationTitle("看看分数构成").navigationBarTitleDisplayMode(.inline)
  }
}
