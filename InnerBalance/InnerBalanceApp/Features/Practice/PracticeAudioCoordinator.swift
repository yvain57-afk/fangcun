import AVFAudio
import Foundation
import InnerBalanceCore

@MainActor
protocol PracticeAudioCoordinating: AnyObject {
  var configurationChangeSource: AnyObject { get }
  func prepare(kind: PracticeKind, plan: PracticeAudioPlan) async throws -> Bool
  func play(_ moment: PracticeAudioMoment)
  func pause()
  func stop()
}

@MainActor
final class PracticeAudioCoordinator: PracticeAudioCoordinating {
  private let engine = AVAudioEngine()
  private let voiceNode = AVAudioPlayerNode()
  private let cueNode = AVAudioPlayerNode()
  private let ambienceNode = AVAudioPlayerNode()
  private let session = PracticeAudioSessionWorker()
  private var generation = 0

  private var activeKind: PracticeKind?
  private var activePlan: PracticeAudioPlan?
  private var continuousAmbienceStarted = false
  private var sampleRate = 44_100.0

  var configurationChangeSource: AnyObject { engine }

  init() {
    engine.attach(voiceNode)
    engine.attach(cueNode)
    engine.attach(ambienceNode)
  }

  func prepare(kind: PracticeKind, plan: PracticeAudioPlan) async throws -> Bool {
    guard !plan.layers.isEmpty else {
      stop()
      return false
    }
    guard kind != activeKind || plan != activePlan else {
      try resume()
      return continuousAmbienceStarted
    }

    stop(deactivateSession: false)
    let request = generation
    try await session.activate()
    try Task.checkCancellation()
    guard request == generation else { throw CancellationError() }

    let hardwareRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
    sampleRate = hardwareRate > 0 ? hardwareRate : 44_100
    let cueFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    let ambienceFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
    engine.connect(cueNode, to: engine.mainMixerNode, format: cueFormat)
    engine.connect(ambienceNode, to: engine.mainMixerNode, format: ambienceFormat)
    engine.connect(voiceNode, to: engine.mainMixerNode, format: nil)
    cueNode.volume = 0.7
    voiceNode.volume = 1
    ambienceNode.volume = 1

    engine.prepare()
    try engine.start()
    activeKind = kind
    activePlan = plan
    continuousAmbienceStarted = false

    if plan.layers.contains(.ambience),
      let buffer = PracticeToneRenderer.ambienceBuffer(
        for: PracticeAmbienceSpec.for(kind),
        sampleRate: sampleRate
      )
    {
      ambienceNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
      ambienceNode.play()
      continuousAmbienceStarted = ambienceNode.isPlaying
    }
    return continuousAmbienceStarted
  }

  func play(_ moment: PracticeAudioMoment) {
    guard let plan = activePlan else { return }
    if plan.layers.contains(.cue),
      let buffer = PracticeToneRenderer.buffer(
        for: PracticeCueToneSpec.for(moment.cue),
        sampleRate: sampleRate
      )
    {
      cueNode.scheduleBuffer(buffer, at: nil)
      if !cueNode.isPlaying { cueNode.play() }
    }
    if plan.layers.contains(.voice), moment.shouldSpeak {
      playVoiceResource(for: moment.cue)
    }
  }

  func pause() {
    guard engine.isRunning else { return }
    engine.pause()
  }

  func resume() throws {
    guard activePlan != nil, !engine.isRunning else { return }
    try engine.start()
  }

  func stop() {
    stop(deactivateSession: true)
  }

  private func stop(deactivateSession: Bool) {
    generation += 1
    voiceNode.stop()
    cueNode.stop()
    ambienceNode.stop()
    engine.stop()
    engine.disconnectNodeOutput(voiceNode)
    engine.disconnectNodeOutput(cueNode)
    engine.disconnectNodeOutput(ambienceNode)
    engine.reset()
    activeKind = nil
    activePlan = nil
    continuousAmbienceStarted = false
    if deactivateSession {
      session.deactivate()
    }
  }

  private func playVoiceResource(for cue: PracticeAudioCue) {
    guard
      let url = PracticeVoiceAssets.url(for: cue),
      let file = try? AVAudioFile(forReading: url)
    else { return }

    voiceNode.stop()
    voiceNode.scheduleFile(file, at: nil)
    voiceNode.play()
  }
}

// AVAudioSession activation can block while negotiating a route. Serialize those
// calls off the main thread so the breathing controls remain responsive.
nonisolated private final class PracticeAudioSessionWorker: @unchecked Sendable {
  private let queue = DispatchQueue(label: "com.yvainair.fangcun.audio-session")

  func activate() async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      queue.async {
        do {
          let session = AVAudioSession.sharedInstance()
          try session.setCategory(.playback, mode: .default, options: [])
          try session.setActive(true)
          continuation.resume()
        } catch { continuation.resume(throwing: error) }
      }
    }
  }

  func deactivate() {
    queue.async {
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
  }
}
