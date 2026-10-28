import InnerBalanceCore
import SwiftUI

enum CompassGesturePhase {
  case changing
  case committed
}

enum EmotionCompassPresentation {
  static func orbOpacity(hasSelectedPosition: Bool) -> Double {
    hasSelectedPosition ? 1 : 0
  }

  static func shouldPlayHaptic(for phase: CompassGesturePhase) -> Bool {
    phase == .committed
  }

  static func wordTransitionDuration(reduceMotion: Bool) -> TimeInterval {
    reduceMotion ? 0 : 0.32
  }

}

struct EmotionCompassView: View {
  @Environment(\.fangcunReduceMotion) private var reduceMotion
  @Bindable var viewModel: CheckInViewModel
  @State private var commitHapticTrigger = 0
  let onClose: () -> Void

  var body: some View {
    ZStack {
      CompassAtmosphere()
      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: FangcunLayout.spacing(6)) {
            CheckInHeader(step: "A small check-in", onClose: onClose)
            HStack(spacing: 12) {
              introduction
              PracticeCompanionV4(kind: .meditation, elapsed: 0, duration: 300, isActive: false)
                .frame(width: 84, height: 84).accessibilityHidden(true)
            }
            SpatialEmotionField(
              valence: viewModel.valence,
              arousal: viewModel.arousal,
              hasSelectedPosition: viewModel.hasSelectedPosition,
              onPositionChanged: updatePosition,
              onPositionCommitted: commitPosition,
              onAdjust: adjust
            )

            if viewModel.step == .words {
              EmotionWordSuggestions(viewModel: viewModel)
                .id("checkIn.words")
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            } else {
              Label("Tap or drag to the place that feels closest", systemImage: "hand.draw")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(InnerBalanceTheme.mutedInk)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .padding(.horizontal, FangcunLayout.pageHorizontalPadding)
          .padding(.vertical, FangcunLayout.spacing(5))
        }
        .accessibilityIdentifier("checkIn.scroll")
        .onChange(of: viewModel.step) { _, step in
          guard step == .words else { return }
          withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) {
            proxy.scrollTo("checkIn.words", anchor: .top)
          }
        }
      }

      if viewModel.saveState == .saving {
        ProgressView("Saving…")
          .padding(20)
          .background(
            InnerBalanceTheme.elevatedSurface,
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
          .tint(InnerBalanceTheme.emphasis)
      }
    }
    .foregroundStyle(InnerBalanceTheme.ink)
    .sensoryFeedback(.impact(flexibility: .rigid), trigger: commitHapticTrigger)
  }

  private var introduction: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
      Text("How is it right now?").font(.title.weight(.semibold))
      Text("Right feels more pleasant; up feels more energized. Find a place that feels like you.")
        .font(.subheadline)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func updatePosition(_ location: CGPoint, size: CGFloat) {
    let coordinates = CompassGeometry.coordinates(for: location, size: size)
    viewModel.select(valence: coordinates.valence, arousal: coordinates.arousal)
  }

  private func commitPosition(_ location: CGPoint, size: CGFloat) {
    updatePosition(location, size: size)
    if EmotionCompassPresentation.shouldPlayHaptic(for: .committed) {
      commitHapticTrigger += 1
    }
    withAnimation(wordTransitionAnimation) { viewModel.continueToWords() }
  }

  private func adjust(valence: Double, arousal: Double) {
    viewModel.select(valence: viewModel.valence + valence, arousal: viewModel.arousal + arousal)
    commitHapticTrigger += 1
    withAnimation(wordTransitionAnimation) { viewModel.continueToWords() }
  }

  private var wordTransitionAnimation: Animation? {
    let duration = EmotionCompassPresentation.wordTransitionDuration(reduceMotion: reduceMotion)
    return duration > 0 ? .easeOut(duration: duration) : nil
  }
}
