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
            Text("Before we begin").font(.title2.weight(.semibold))
            Text("This introduction is outside your practice time")
              .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
          }
          Spacer()
          PracticeCompanionV4(kind: kind, elapsed: 0, duration: kind.v4DefaultDuration, isActive: false)
            .frame(width: 96, height: 100).accessibilityHidden(true)
        }
        if audio.unavailable {
          Text("Read the guidance below, then start when you're ready.")
            .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
            .accessibilityIdentifier("practice.intro.readInstead")
        } else {
          HStack(spacing: 14) {
            Button(action: audio.togglePause) {
              Label(audio.isPaused ? "Resume introduction" : "Pause introduction", systemImage: audio.isPaused ? "play.fill" : "pause.fill")
                .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            }.disabled(audio.duration == 0).accessibilityIdentifier("practice.intro.pause")
            ProgressView(value: audio.elapsed, total: max(1, audio.duration))
              .tint(Color("FangcunExhale")).accessibilityLabel("Introduction progress")
          }
        }
        ForEach(Array(PracticeGuidanceContent.introduction(for: kind, variantID: variantID)
          .components(separatedBy: "\n").filter { !$0.isEmpty }.enumerated()), id: \.offset) { _, paragraph in
          Text(paragraph).font(.body).lineSpacing(6).fixedSize(horizontal: false, vertical: true)
        }
        Toggle("Skip this introduction next time", isOn: $skipsNextTime)
          .font(.subheadline).tint(InnerBalanceTheme.strongFill)
          .accessibilityIdentifier("practice.intro.skipNextTime")
        Text("This skips only the introduction. Your in-session guidance settings stay the same.")
          .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
      }.padding(.vertical, 16).padding(.bottom, 20)
    }
    .accessibilityIdentifier("practice.introduction.reading")
    .safeAreaInset(edge: .bottom) {
      Button("Skip intro and begin", action: onSkip)
        .buttonStyle(InnerBalancePrimaryButtonStyle())
        .accessibilityIdentifier("practice.entry.skip")
        .padding(.vertical, 12).background(InnerBalanceTheme.canvas)
    }
  }
}
