import InnerBalanceCore
import SwiftUI

struct PracticeChangePicker: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Binding var selection: PracticeChangeChoice?
  let beforeRating: Int
  @Binding var afterRating: Double

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
      Text("和刚才比")
        .font(.headline)
      Group {
        if dynamicTypeSize.isAccessibilitySize {
          VStack(spacing: FangcunLayout.spacing(2)) { choices }
        } else {
          HStack(spacing: FangcunLayout.spacing(2)) { choices }
        }
      }
    }
    .sensoryFeedback(.selection, trigger: selection)
  }

  @ViewBuilder private var choices: some View {
    ForEach(PracticeChangeChoice.allCases, id: \.self) { choice in
      Button(choice.title) {
        selection = choice
        afterRating = Double(choice.afterRating(before: beforeRating))
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(
        selection == choice ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink
      )
      .frame(maxWidth: .infinity, minHeight: 56)
      .background(
        selection == choice ? InnerBalanceTheme.strongFill : InnerBalanceTheme.subtleFill,
        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(
            selection == choice ? InnerBalanceTheme.strongFill : InnerBalanceTheme.hairline,
            lineWidth: 1
          )
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(selection == choice ? .isSelected : [])
    }
  }
}

struct PostPracticeCompassPicker: View {
  @Binding var valence: Double
  @Binding var arousal: Double
  @Binding var hasSelection: Bool

  private let choices: [(String, String, Double, Double)] = [
    ("低落", "cloud.rain", -0.7, -0.7),
    ("紧绷", "bolt", -0.7, 0.8),
    ("平平", "minus", 0, 0),
    ("平和", "water.waves", 0.7, -0.7),
    ("有劲", "sparkles", 0.7, 0.8),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
      Text("现在更接近")
        .font(.headline)
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 92), spacing: FangcunLayout.spacing(2))],
        spacing: FangcunLayout.spacing(2)
      ) {
        ForEach(choices, id: \.0) { title, image, valence, arousal in
          Button {
            self.valence = valence
            self.arousal = arousal
            hasSelection = true
          } label: {
            Label(title, systemImage: image)
              .font(.subheadline.weight(.semibold))
              .frame(maxWidth: .infinity, minHeight: 52)
          }
          .buttonStyle(PracticeStateButtonStyle(isSelected: isSelected(valence, arousal)))
          .accessibilityAddTraits(isSelected(valence, arousal) ? .isSelected : [])
        }
      }
    }
    .sensoryFeedback(.selection, trigger: selectionKey)
  }

  private func isSelected(_ valence: Double, _ arousal: Double) -> Bool {
    hasSelection && self.valence == valence && self.arousal == arousal
  }

  private var selectionKey: String {
    hasSelection ? "\(valence)-\(arousal)" : "none"
  }
}

private struct PracticeStateButtonStyle: ButtonStyle {
  let isSelected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(isSelected ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink)
      .background(
        isSelected ? InnerBalanceTheme.strongFill : InnerBalanceTheme.subtleFill,
        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(
            isSelected ? InnerBalanceTheme.strongFill : InnerBalanceTheme.hairline,
            lineWidth: 1
          )
      }
      .opacity(configuration.isPressed ? 0.68 : 1)
  }
}

struct PracticeSessionAtmosphere: View {
  let kind: PracticeKind

  var body: some View {
    InnerBalanceTheme.canvas
      .ignoresSafeArea()
      .accessibilityHidden(true)
  }
}
