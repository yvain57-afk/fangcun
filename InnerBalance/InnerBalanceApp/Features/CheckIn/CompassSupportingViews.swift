import InnerBalanceCore
import SwiftUI

struct CompassAtmosphere: View {
  var body: some View {
    InnerBalanceTheme.canvas
      .ignoresSafeArea()
      .accessibilityHidden(true)
  }
}

struct EmotionWordSuggestions: View {
  @Bindable var viewModel: CheckInViewModel
  private let columns = [
    GridItem(.flexible(), spacing: FangcunLayout.spacing(3)),
    GridItem(.flexible(), spacing: FangcunLayout.spacing(3)),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Does a word fit?").font(.title3.weight(.semibold))
      LazyVGrid(columns: columns, spacing: FangcunLayout.spacing(3)) {
        ForEach(viewModel.suggestedLabels, id: \.self) { label in
          Button {
            Task { await viewModel.select(label: label) }
          } label: {
            Text(label.displayName)
              .font(.headline)
              .frame(maxWidth: .infinity, minHeight: 52)
              .background(
                InnerBalanceTheme.surface,
                in: RoundedRectangle(
                  cornerRadius: FangcunLayout.spacing(5),
                  style: .continuous
                )
              )
              .overlay {
                RoundedRectangle(
                  cornerRadius: FangcunLayout.spacing(5),
                  style: .continuous
                )
                .strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1)
              }
          }
          .buttonStyle(.plain)
          .foregroundStyle(InnerBalanceTheme.ink)
          .disabled(viewModel.saveState == .saving)
          .accessibilityIdentifier("emotionWord.\(label.rawValue)")
          .accessibilityHint("Your choice saves right away")
        }
      }
      Button {
        Task { await viewModel.selectUnclassified() }
      } label: {
        Text("None of these / Not sure")
          .font(.subheadline.weight(.semibold))
          .frame(maxWidth: .infinity, minHeight: 48)
          .background(
            InnerBalanceTheme.subtleFill,
            in: RoundedRectangle(
              cornerRadius: FangcunLayout.spacing(5),
              style: .continuous
            )
          )
          .overlay {
            RoundedRectangle(
              cornerRadius: FangcunLayout.spacing(5),
              style: .continuous
            )
            .strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .foregroundStyle(InnerBalanceTheme.mutedInk)
      .disabled(viewModel.saveState == .saving)
      .accessibilityIdentifier("emotionWord.unclassified")

      if viewModel.saveState == .failed {
        Label(
          "Couldn't save. Your position is still here. Choose a word again to retry.",
          systemImage: "exclamationmark.circle"
        )
        .font(.caption)
        .foregroundStyle(InnerBalanceTheme.emphasis)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct CheckInHeader: View {
  let step: String
  let onClose: () -> Void

  var body: some View {
    HStack {
      Text(step)
        .font(.caption.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.emphasis)
      Spacer()
      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(.subheadline.weight(.semibold))
          .frame(width: 44, height: 44)
          .background(InnerBalanceTheme.subtleFill, in: Circle())
          .overlay { Circle().strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1) }
      }
      .buttonStyle(.plain)
      .foregroundStyle(InnerBalanceTheme.ink)
      .accessibilityLabel("Close")
    }
  }
}
