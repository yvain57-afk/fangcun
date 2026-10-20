import AVFAudio
import Foundation
import InnerBalanceCore
import Observation

/// The gate lives before the training clock. A late audio completion cannot start twice.
@MainActor @Observable
final class PracticeIntroductionGate {
  enum Stage: Equatable { case ready, introduction, settling, started }
  private(set) var stage: Stage = .ready

  func begin(shouldIntroduce: Bool) {
    guard stage == .ready else { return }
    stage = shouldIntroduce ? .introduction : .settling
  }
  @discardableResult func finish(_ expected: Stage) -> Bool {
    guard stage == expected, stage == .introduction || stage == .settling else { return false }
    stage = .started
    return true
  }
  func cancel() {
    if stage != .started { stage = .ready }
  }
}

enum PracticeIntroductionPreferences {
  static func key(for kind: PracticeKind) -> String { "fangcun.practice.introduction.skip." + kind.rawValue }
  static func skips(_ kind: PracticeKind, defaults: UserDefaults = .standard) -> Bool {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
      ProcessInfo.processInfo.arguments.contains("--ui-testing-skip-introduction") { return true }
    #endif
    return defaults.bool(forKey: key(for: kind))
  }
  static func setSkips(_ value: Bool, for kind: PracticeKind, defaults: UserDefaults = .standard) {
    defaults.set(value, forKey: key(for: kind))
  }
}

@MainActor @Observable
final class PracticeIntroductionAudio {
  private var player: AVAudioPlayer?
  private var generation = 0
  private let session = PracticeAudioSessionWorker.shared
  private(set) var isPlaying = false
  private(set) var isPaused = false
  private(set) var unavailable = false
  private(set) var elapsed: TimeInterval = 0
  private(set) var duration: TimeInterval = 0

  /// Completion is true only for naturally completed playback, never for skip/cancel/failure.
  func play(resource: String) async -> Bool {
    stop(deactivateSession: false)
    unavailable = false
    guard let url = PracticeVoiceAssets.url(named: resource) else { unavailable = true; return false }
    let token = generation
    do {
      try await session.activate()
      try Task.checkCancellation()
      guard token == generation else { return false }
      let sound = try AVAudioPlayer(contentsOf: url)
      player = sound
      duration = sound.duration
      elapsed = 0
      sound.volume = PracticeAudioLevels.read("voice")
      guard sound.play() else { unavailable = true; return false }
      isPlaying = true
      while token == generation, !Task.isCancelled {
        guard let player else { return false }
        elapsed = player.currentTime
        if !player.isPlaying && !isPaused {
          isPlaying = false
          self.player = nil
          return true
        }
        try await Task.sleep(for: .milliseconds(100))
      }
    } catch {
      if token == generation && !Task.isCancelled { unavailable = true }
    }
    return false
  }
  func togglePause() {
    guard let player else { return }
    if isPaused {
      guard player.play() else { unavailable = true; return }
      isPaused = false; isPlaying = true
    } else {
      player.pause(); isPaused = true; isPlaying = false
    }
  }
  func stop(deactivateSession: Bool = true) {
    generation += 1
    player?.stop(); player = nil
    isPlaying = false; isPaused = false
    if deactivateSession { session.deactivate() }
  }
}
