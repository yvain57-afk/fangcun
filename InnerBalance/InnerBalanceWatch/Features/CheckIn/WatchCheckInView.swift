import InnerBalanceCore
import SwiftUI
import WatchKit

struct WatchCheckInView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var selectedPoint: WatchCompassRegion?
  @State private var isSaving = false
  @State private var saveFailed = false
  @State private var showsSupportGuidance = false
  let coordinator: WatchHealthWriteCoordinator

  var body: some View {
    Group {
      if showsSupportGuidance {
        supportGuidance
      } else if let selectedPoint {
        wordStep(selectedPoint)
      } else {
        compassStep
      }
    }
    .navigationTitle(navigationTitle)
    .navigationBarTitleDisplayMode(.inline)
    .alert("未能保存", isPresented: $saveFailed) {
      Button("知道了", role: .cancel) {}
    } message: {
      Text("未能写入 Apple 健康，也未能留在本地队列。请检查健康权限和可用空间。")
    }
  }

  private var navigationTitle: String {
    if showsSupportGuidance { return "先照顾好自己" }
    return selectedPoint == nil ? "此刻在哪里？" : "最接近哪个？"
  }

  private var supportGuidance: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        Label("记录已保存", systemImage: "checkmark.circle.fill")
          .font(.headline)
          .foregroundStyle(.mint)
        Text("你不必独自处理。现在可以联系一位你信任的人。")
          .font(.footnote)
        Text("如果你有立即伤害自己的危险，请联系当地急救或紧急支持。")
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("我知道了") { dismiss() }
          .buttonStyle(.borderedProminent)
          .tint(.mint)
      }
    }
  }

  private var compassStep: some View {
    ScrollView {
      VStack(spacing: 7) {
        Text("上方更激活·右侧更愉快")
          .font(.caption2)
          .foregroundStyle(.secondary)
        LazyVGrid(columns: compassColumns, spacing: 5) {
          ForEach(WatchCompassRegion.all) { point in
            Button {
              selectedPoint = point
            } label: {
              VStack(spacing: 2) {
                Image(systemName: point.systemImage)
                  .font(.body)
                Text(point.shortName)
                  .font(.caption2.weight(.medium))
                  .fixedSize(horizontal: false, vertical: true)
              }
              .frame(maxWidth: .infinity, minHeight: 43)
            }
            .buttonStyle(.plain)
            .background(point.color.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
            .accessibilityLabel(point.accessibilityLabel)
          }
        }
      }
    }
  }

  private var compassColumns: [GridItem] {
    let count = dynamicTypeSize.isAccessibilitySize ? 2 : 3
    return Array(repeating: GridItem(.flexible(), spacing: 5), count: count)
  }

  private func wordStep(_ point: WatchCompassRegion) -> some View {
    ScrollView {
      VStack(spacing: 7) {
        ForEach(point.suggestions, id: \.rawValue) { label in
          Button(label.watchDisplayName) {
            Task { await save(point: point, label: label) }
          }
          .buttonStyle(.bordered)
          .tint(.mint)
          .disabled(isSaving)
        }
        Button("不知道") {
          Task { await save(point: point, label: nil) }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .disabled(isSaving)
      }
    }
    .overlay {
      if isSaving { ProgressView() }
    }
  }

  private func save(point: WatchCompassRegion, label: EmotionLabel?) async {
    guard !isSaving else { return }
    isSaving = true
    let identifier = "com.yvainair.innerbalance.state.watch.\(UUID().uuidString)"
    let saved = await coordinator.save(
      .stateOfMind(
        WatchStateOfMindPayload(
          syncIdentifier: identifier,
          date: .now,
          valence: point.valence,
          arousal: point.arousal,
          label: label,
          unclassified: label == nil
        )
      )
    )
    isSaving = false
    if saved {
      WKInterfaceDevice.current().play(.success)
      if label == .hopeless {
        showsSupportGuidance = true
      } else {
        dismiss()
      }
    } else {
      saveFailed = true
    }
  }
}

extension WatchCompassRegion {
  var shortName: String {
    switch (valence, arousal) {
    case (...(-0.1), 0.1...): "紧绷"
    case (0.1..., 0.1...): "振奋"
    case (...(-0.1), ...(-0.1)): "低落"
    case (0.1..., ...(-0.1)): "松弛"
    default: "中间"
    }
  }

  var systemImage: String {
    if arousal > 0.1 { return "arrow.up" }
    if arousal < -0.1 { return "arrow.down" }
    return "minus"
  }

  var color: Color {
    if valence < -0.1 { return .orange }
    if valence > 0.1 { return .mint }
    return .gray
  }

  var accessibilityLabel: String {
    let pleasure = valence < -0.1 ? "不愉快" : valence > 0.1 ? "愉快" : "中性"
    let activation = arousal < -0.1 ? "低激活" : arousal > 0.1 ? "高激活" : "中等激活"
    return "\(pleasure)，\(activation)"
  }

  var suggestions: [EmotionLabel] {
    let quadrant = EmotionCatalog.quadrant(valence: valence, arousal: arousal)
    let labels = EmotionCatalog.labels(for: quadrant)
    let fallback: [EmotionLabel] = [.indifferent, .calm, .content, .satisfied]
    return Array((labels.count >= 4 ? labels : labels + fallback).uniqued().prefix(5))
  }
}

extension Array where Element: Hashable {
  fileprivate func uniqued() -> [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}

extension EmotionLabel {
  fileprivate var watchDisplayName: String {
    switch self {
    case .amazed: "惊叹"
    case .amused: "愉快"
    case .angry: "生气"
    case .anxious: "焦虑"
    case .ashamed: "羞愧"
    case .brave: "勇敢"
    case .calm: "平静"
    case .content: "知足"
    case .disappointed: "失望"
    case .discouraged: "泄气"
    case .disgusted: "厌恶"
    case .embarrassed: "尴尬"
    case .excited: "兴奋"
    case .frustrated: "挫败"
    case .grateful: "感激"
    case .guilty: "内疚"
    case .happy: "开心"
    case .hopeless: "绝望"
    case .irritated: "烦躁"
    case .jealous: "嫉妒"
    case .joyful: "喜悦"
    case .lonely: "孤独"
    case .passionate: "热情"
    case .peaceful: "安宁"
    case .proud: "自豪"
    case .relieved: "释然"
    case .sad: "难过"
    case .scared: "害怕"
    case .stressed: "紧张"
    case .surprised: "惊讶"
    case .worried: "担心"
    case .annoyed: "恼火"
    case .confident: "自信"
    case .drained: "疲惫"
    case .hopeful: "希望"
    case .indifferent: "无所谓"
    case .overwhelmed: "不堪重负"
    case .satisfied: "满意"
    }
  }
}
