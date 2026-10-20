import InnerBalanceCore
import SwiftUI

struct PracticeIntroductionScreen: View {
  let kind: PracticeKind
  let variantID: String?
  @Bindable var audio: PracticeIntroductionAudio
  @Binding var skipsNextTime: Bool
  let onSkip: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 8) {
            Text("先听听怎么做").font(.title2.weight(.semibold))
            Text("这段说明不计入练习时间")
              .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
          }
          Spacer()
          PracticeCompanionV4(kind: kind, elapsed: 0, duration: kind.v4DefaultDuration, isActive: false)
            .frame(width: 96, height: 100).accessibilityHidden(true)
        }
        if audio.unavailable {
          Text("可以先阅读下面的说明，准备好后直接开始。")
            .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
            .accessibilityIdentifier("practice.intro.readInstead")
        } else {
          HStack(spacing: 14) {
            Button(action: audio.togglePause) {
              Label(audio.isPaused ? "继续说明" : "暂停说明", systemImage: audio.isPaused ? "play.fill" : "pause.fill")
                .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            }.disabled(audio.duration == 0).accessibilityIdentifier("practice.intro.pause")
            ProgressView(value: audio.elapsed, total: max(1, audio.duration))
              .tint(Color("FangcunExhale")).accessibilityLabel("开场说明进度")
          }
        }
        ForEach(Array(PracticeGuidanceContent.introduction(for: kind, variantID: variantID)
          .components(separatedBy: "\n").filter { !$0.isEmpty }.enumerated()), id: \.offset) { _, paragraph in
          Text(paragraph).font(.body).lineSpacing(6).fixedSize(horizontal: false, vertical: true)
        }
        Toggle("下次跳过这项说明", isOn: $skipsNextTime)
          .font(.subheadline).tint(InnerBalanceTheme.strongFill)
          .accessibilityIdentifier("practice.intro.skipNextTime")
        Text("只跳过开场，训练中的阶段提示仍按你的引导设置播放。")
          .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
      }.padding(.vertical, 16).padding(.bottom, 20)
    }
    .accessibilityIdentifier("practice.introduction.reading")
    .safeAreaInset(edge: .bottom) {
      Button("跳过，直接开始", action: onSkip)
        .buttonStyle(InnerBalancePrimaryButtonStyle())
        .accessibilityIdentifier("practice.entry.skip")
        .padding(.vertical, 12).background(InnerBalanceTheme.canvas)
    }
  }
}
