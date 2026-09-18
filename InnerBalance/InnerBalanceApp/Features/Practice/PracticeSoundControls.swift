import SwiftUI

struct PracticeSoundControls: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Binding var mode: PracticeSoundMode
  @Binding var ambienceEnabled: Bool
  let voiceAvailable: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(4)) {
      Label {
        VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
          Text("不用盯着屏幕").font(.headline)
          Text("语音只提示下一步")
            .font(.caption)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
      } icon: {
        Image(systemName: "ear")
          .foregroundStyle(InnerBalanceTheme.emphasis)
      }

      Group {
        if dynamicTypeSize.isAccessibilitySize {
          VStack(spacing: FangcunLayout.spacing(2)) { modeButtons }
        } else {
          HStack(spacing: FangcunLayout.spacing(2)) { modeButtons }
        }
      }

      if mode.supportsAmbience {
        Toggle("环境声·锁屏继续", isOn: $ambienceEnabled)
          .font(.subheadline.weight(.semibold))
          .tint(InnerBalanceTheme.strongFill)
          .padding(.vertical, FangcunLayout.spacing(2))
          .accessibilityHint("开启后练习在锁屏时仍会继续播放")
      } else {
        Label("声音已关闭", systemImage: "speaker.slash.fill")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }
    .padding(FangcunLayout.spacing(5))
    .fangcunLevelOneSurface(cornerRadius: FangcunLayout.spacing(5))
    .sensoryFeedback(.selection, trigger: mode.rawValue)
    .accessibilityIdentifier("practice.sound.controls")
  }

  @ViewBuilder private var modeButtons: some View {
    ForEach(PracticeSoundMode.availableCases(hasVoiceAssets: voiceAvailable), id: \.rawValue) {
      option in
      Button {
        mode = option
      } label: {
        VStack(spacing: FangcunLayout.spacing(1)) {
          Text(option.title).font(.subheadline.weight(.semibold))
          Text(option.detail)
            .font(.caption2)
            .foregroundStyle(
              mode == option ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.mutedInk
            )
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(.horizontal, FangcunLayout.spacing(2))
        .background(
          mode == option ? InnerBalanceTheme.strongFill : InnerBalanceTheme.subtleFill,
          in: RoundedRectangle(cornerRadius: FangcunLayout.spacing(4), style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: FangcunLayout.spacing(4), style: .continuous)
            .strokeBorder(
              mode == option ? InnerBalanceTheme.strongFill : InnerBalanceTheme.hairline,
              lineWidth: 1
            )
        }
        .foregroundStyle(
          mode == option ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink
        )
      }
      .buttonStyle(.plain)
      .accessibilityLabel(option.title)
      .accessibilityAddTraits(mode == option ? .isSelected : [])
      .accessibilityHint(option.detail)
    }
  }
}
