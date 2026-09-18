import InnerBalanceCore
import SwiftUI

enum FangcunEchoSelectionEvent {
  case loaded
  case tapped
}

enum FangcunEchoGridLayout {
  static func columnCount(isAccessibilitySize: Bool) -> Int {
    isAccessibilitySize ? 2 : 3
  }

  static func isSelected(candidate: DailyEchoState, selection: DailyEchoState?) -> Bool {
    candidate == selection
  }

  static func shouldPlayHaptic(for event: FangcunEchoSelectionEvent) -> Bool {
    event == .tapped
  }
}

struct EchoArcSelector: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.fangcunReduceMotion) private var reduceMotion
  @State private var hapticTrigger = 0

  let selection: DailyEchoState?
  let historyAvailable: Bool
  let saveMessage: String?
  let onSelect: (DailyEchoState) -> Void
  let onShowHistory: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
        heading
        echoGrid

        Text(saveMessage ?? " ")
          .font(.caption2)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
          .frame(maxWidth: .infinity, minHeight: 16, alignment: .trailing)
          .opacity(saveMessage == nil ? 0 : 1)
          .animation(
            FangcunMotion.stateAnimation(reduceMotion: reduceMotion),
            value: saveMessage
          )
          .accessibilityHidden(saveMessage == nil)
          .accessibilityAddTraits(.updatesFrequently)
      }
      .padding(.vertical, FangcunLayout.spacing(4))

      FangcunEditorialRule()
        .frame(height: 1)
    }
    .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
  }

  private var heading: some View {
    ViewThatFits(in: .horizontal) {
      HStack(alignment: .firstTextBaseline, spacing: FangcunLayout.spacing(3)) {
        headingTitle
        Spacer(minLength: FangcunLayout.spacing(2))
        instruction
        historyButton
      }
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
        HStack {
          headingTitle
          Spacer()
          historyButton
        }
        instruction
      }
    }
  }

  private var headingTitle: some View {
    Text("现在怎样")
      .font(.title3.weight(.semibold))
      .foregroundStyle(InnerBalanceTheme.ink)
  }

  private var instruction: some View {
    Text("不用解释，选最接近的")
      .font(.subheadline)
      .foregroundStyle(InnerBalanceTheme.mutedInk)
  }

  private var historyButton: some View {
    Button("过去", action: onShowHistory)
      .font(.caption.weight(.semibold))
      .foregroundStyle(InnerBalanceTheme.strongFill)
      .frame(minWidth: 44, minHeight: 44)
      .contentShape(Rectangle())
      .buttonStyle(FangcunPressButtonStyle())
      // Reserve the same space before the first save so the choices do not move.
      .opacity(historyAvailable ? 1 : 0)
      .disabled(!historyAvailable)
      .accessibilityHidden(!historyAvailable)
      .accessibilityIdentifier("home.echo.history")
  }

  private var echoGrid: some View {
    let columnCount = FangcunEchoGridLayout.columnCount(
      isAccessibilitySize: dynamicTypeSize.isAccessibilitySize
    )
    return LazyVGrid(
      columns: Array(
        repeating: GridItem(.flexible(), spacing: FangcunLayout.spacing(2)),
        count: columnCount
      ),
      spacing: FangcunLayout.spacing(2)
    ) {
      ForEach(DailyEchoState.allCases, id: \.rawValue) { state in
        touchpoint(for: state)
      }
    }
  }

  private func touchpoint(for state: DailyEchoState) -> some View {
    let isSelected = FangcunEchoGridLayout.isSelected(candidate: state, selection: selection)
    return Button {
      onSelect(state)
      if FangcunEchoGridLayout.shouldPlayHaptic(for: .tapped) { hapticTrigger += 1 }
    } label: {
      Group {
        if dynamicTypeSize.isAccessibilitySize {
          VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
            HStack(spacing: FangcunLayout.spacing(2)) {
              stateIcon(state)
              Spacer(minLength: 0)
              selectionMark(isSelected)
            }
            stateTitle(state, isSelected: isSelected)
          }
        } else {
          HStack(spacing: FangcunLayout.spacing(2)) {
            stateIcon(state, isSelected: isSelected)
            stateTitle(state, isSelected: isSelected)
            Spacer(minLength: 0)
          }
        }
      }
      .foregroundStyle(isSelected ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink)
      .padding(.horizontal, FangcunLayout.spacing(3))
      .padding(.vertical, FangcunLayout.spacing(2))
      .frame(
        maxWidth: .infinity,
        minHeight: dynamicTypeSize.isAccessibilitySize ? 64 : 52,
        alignment: .leading
      )
      .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
      .background(
        isSelected ? InnerBalanceTheme.strongFill : Color.clear,
        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .strokeBorder(
            isSelected ? InnerBalanceTheme.inverseInk.opacity(0.28) : Color.clear,
            lineWidth: 1
          )
      }
      .overlay(alignment: .bottom) {
        Rectangle()
          .fill(isSelected ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.hairline)
          .frame(height: isSelected ? 2 : 1)
      }
      .animation(
        FangcunMotion.stateAnimation(reduceMotion: reduceMotion),
        value: isSelected
      )
    }
    .buttonStyle(FangcunPressButtonStyle())
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityHint("点一下即保存当下状态")
    .accessibilityIdentifier("home.echo.state.\(state.rawValue)")
  }

  private func stateIcon(_ state: DailyEchoState, isSelected: Bool = false) -> some View {
    Image(systemName: isSelected ? "checkmark.circle.fill" : state.systemImage)
      .font(.system(size: 17, weight: .medium))
      .accessibilityHidden(true)
  }

  private func stateTitle(_ state: DailyEchoState, isSelected: Bool) -> some View {
    Text(state.title)
      .font(.caption.weight(isSelected ? .bold : .semibold))
      .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
      .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.84)
  }

  private func selectionMark(_ isSelected: Bool) -> some View {
    Image(systemName: "checkmark.circle.fill")
      .font(.caption.weight(.bold))
      .opacity(isSelected ? 1 : 0)
      .accessibilityHidden(true)
  }
}
