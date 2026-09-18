import InnerBalanceCore
import SwiftUI

struct PracticePreparationHero: View {
  let kind: PracticeKind
  let duration: TimeInterval

  var body: some View {
    HStack(alignment: .center, spacing: FangcunLayout.spacing(5)) {
      PracticeFieldGlyph(kind: kind, size: 96)
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
        Text(kind.outcomeTitle)
          .font(.caption.weight(.bold))
          .foregroundStyle(InnerBalanceTheme.emphasis)
        Text(kind.title)
          .font(.title.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.ink)
        Text(PracticeDurationFormatter.text(duration))
          .font(.subheadline.monospacedDigit())
          .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(FangcunLayout.spacing(5))
    .fangcunLevelOneSurface(cornerRadius: FangcunLayout.spacing(5))
  }
}

struct PracticeIntroductionCard: View {
  let kind: PracticeKind

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(5)) {
      Text(kind.summary)
        .font(.title3.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.ink)
        .fixedSize(horizontal: false, vertical: true)

      explanation("这个练什么", kind.purpose, systemImage: "scope")
      explanation("适合什么时候", kind.bestFor, systemImage: "clock")
      explanation("怎么做", kind.steps, systemImage: "list.number")
      explanation("开始前", kind.preparation, systemImage: "checkmark.shield")
    }
    .padding(FangcunLayout.spacing(5))
    .fangcunLevelOneSurface(cornerRadius: FangcunLayout.spacing(5))
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("practice.introduction")
  }

  private func explanation(_ title: String, _ detail: String, systemImage: String) -> some View {
    HStack(alignment: .top, spacing: FangcunLayout.spacing(3)) {
      Image(systemName: systemImage)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.emphasis)
        .frame(width: 24, height: 24)
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
        Text(title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.ink)
        Text(detail)
          .font(.subheadline)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

struct PracticeStartingPicker: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Binding var value: Double

  var body: some View {
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        VStack(spacing: FangcunLayout.spacing(2)) { choices }
      } else {
        HStack(spacing: FangcunLayout.spacing(2)) { choices }
      }
    }
    .sensoryFeedback(.selection, trigger: Int(value))
  }

  @ViewBuilder private var choices: some View {
    ForEach(PracticeStartingChoice.allCases, id: \.self) { choice in
      Button(choice.title) { value = Double(choice.rating) }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(
          isSelected(choice) ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink
        )
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(
          isSelected(choice) ? InnerBalanceTheme.strongFill : InnerBalanceTheme.subtleFill,
          in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
              isSelected(choice) ? InnerBalanceTheme.strongFill : InnerBalanceTheme.hairline,
              lineWidth: 1
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected(choice) ? .isSelected : [])
        .accessibilityHint("选择后作为练习前的主观参照")
    }
  }

  private func isSelected(_ choice: PracticeStartingChoice) -> Bool {
    Int(value.rounded()) == choice.rating
  }
}

struct PracticeHapticToggle: View {
  @Binding var isOn: Bool

  var body: some View {
    Toggle(isOn: $isOn) {
      Label {
        VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
          Text("触觉提示").font(.headline)
          Text("每次换动作时轻触一下")
            .font(.caption)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
      } icon: {
        Image(systemName: "waveform.path")
          .foregroundStyle(InnerBalanceTheme.emphasis)
      }
    }
    .tint(InnerBalanceTheme.strongFill)
    .padding(FangcunLayout.spacing(5))
    .fangcunLevelOneSurface(cornerRadius: 20)
    .accessibilityHint("在节奏切换处提供轻触感，可独立关闭")
    .accessibilityIdentifier("practice.haptics")
  }
}
