import AVFAudio
import SwiftUI

struct PracticeAudioLifecycle: ViewModifier {
  @Environment(\.scenePhase) private var scenePhase
  @Bindable var viewModel: PracticeSessionViewModel
  let audio: PracticeAudioController
  let mode: PracticeSoundMode
  let ambienceEnabled: Bool

  func body(content: Content) -> some View {
    content
      .onChange(of: scenePhase) { _, phase in
        guard phase != .active else { return }
        if PracticeAudioBackgroundPolicy.shouldPauseWhenInactive(
          mode: mode,
          ambienceEnabled: ambienceEnabled,
          continuousAudioAvailable: audio.canContinueInBackground
        ) {
          viewModel.handleInterruption()
        }
      }
      .onReceive(
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
      ) { notification in
        guard
          let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          AVAudioSession.InterruptionType(rawValue: rawValue) == .began
        else { return }
        viewModel.handleInterruption()
      }
      .onReceive(
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
      ) { notification in
        guard
          let rawValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: rawValue),
          PracticeAudioBackgroundPolicy.shouldPauseForRouteChange(reason: reason)
        else { return }
        audio.stop()
        viewModel.handleInterruption()
      }
      .onReceive(
        NotificationCenter.default.publisher(
          for: .AVAudioEngineConfigurationChange,
          object: audio.configurationChangeSource
        )
      ) { _ in
        audio.scheduleEngineConfigurationRecovery(viewModel)
      }
      .task(id: viewModel.phase) {
        await audio.run(viewModel, mode: mode, ambienceEnabled: ambienceEnabled)
      }
      .onDisappear { audio.stop() }
  }
}
