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
    .alert("Couldn't save", isPresented: $saveFailed) {
      Button("Got it", role: .cancel) {}
    } message: {
      Text("Couldn't save to Apple Health or the local queue. Check Health access and available storage.")
    }
  }

  private var navigationTitle: String {
    if showsSupportGuidance { return "Take care of yourself first" }
    return selectedPoint == nil ? "Where are you right now?" : "What feels closest?"
  }

  private var supportGuidance: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        Label("Entry saved", systemImage: "checkmark.circle.fill")
          .font(.headline)
          .foregroundStyle(.mint)
        Text("You don't have to manage this alone. Reach out to someone you trust now.")
          .font(.footnote)
        Text("If you're in immediate danger of harming yourself, contact local emergency or crisis support.")
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("Got it") { dismiss() }
          .buttonStyle(.borderedProminent)
          .tint(.mint)
      }
    }
  }

  private var compassStep: some View {
    ScrollView {
      VStack(spacing: 7) {
        Text("Up: more energy · Right: more pleasant")
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
        Button("Not sure") {
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
    case (...(-0.1), 0.1...): "Tense"
    case (0.1..., 0.1...): "Uplifted"
    case (...(-0.1), ...(-0.1)): "Low"
    case (0.1..., ...(-0.1)): "Relaxed"
    default: "In between"
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
    let pleasure = valence < -0.1 ? "Unpleasant" : valence > 0.1 ? "Pleasant" : "Neutral"
    let activation = arousal < -0.1 ? "Lower energy" : arousal > 0.1 ? "Higher energy" : "Moderate energy"
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
    case .amazed: "Amazed"
    case .amused: "Pleasant"
    case .angry: "Angry"
    case .anxious: "Anxious"
    case .ashamed: "Ashamed"
    case .brave: "Brave"
    case .calm: "Calm"
    case .content: "Content"
    case .disappointed: "Disappointed"
    case .discouraged: "Discouraged"
    case .disgusted: "Disgusted"
    case .embarrassed: "Embarrassed"
    case .excited: "Excited"
    case .frustrated: "Frustrated"
    case .grateful: "Grateful"
    case .guilty: "Guilty"
    case .happy: "Happy"
    case .hopeless: "Hopeless"
    case .irritated: "Irritated"
    case .jealous: "Jealous"
    case .joyful: "Joyful"
    case .lonely: "Lonely"
    case .passionate: "Passionate"
    case .peaceful: "Peaceful"
    case .proud: "Proud"
    case .relieved: "Relieved"
    case .sad: "Sad"
    case .scared: "Scared"
    case .stressed: "Stressed"
    case .surprised: "Surprised"
    case .worried: "Worried"
    case .annoyed: "Annoyed"
    case .confident: "Confident"
    case .drained: "Worn out"
    case .hopeful: "Hopeful"
    case .indifferent: "Indifferent"
    case .overwhelmed: "Overwhelmed"
    case .satisfied: "Satisfied"
    }
  }
}
