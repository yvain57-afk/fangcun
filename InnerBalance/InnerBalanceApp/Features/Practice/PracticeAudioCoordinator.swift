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
  private var voiceGeneration = 0
  private var duckTask: Task<Void, Never>?

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
      return continuousAmbienceStarted && PracticeAudioLevels.read("ambience") > 0
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
    cueNode.volume = 0.7 * PracticeAudioLevels.read("cue")
    voiceNode.volume = PracticeAudioLevels.read("voice")
    ambienceNode.volume = PracticeAudioLevels.read("ambience")

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
    return continuousAmbienceStarted && PracticeAudioLevels.read("ambience") > 0
  }

  func play(_ moment: PracticeAudioMoment) {
    guard let plan = activePlan else { return }
    // A new timeline event replaces stale output; never queue late phase cues.
    cueNode.stop()
    voiceNode.stop()
    voiceGeneration += 1
    fadeAmbience(to: PracticeAudioLevels.read("ambience"), duration: 0.12)
    if plan.layers.contains(.cue), (!moment.isSegment || !plan.layers.contains(.voice)), moment.offset < 0.2,
      let buffer = PracticeToneRenderer.buffer(
        for: PracticeCueToneSpec.for(moment.cue),
        sampleRate: sampleRate
      )
    {
      cueNode.scheduleBuffer(buffer, at: nil)
      if !cueNode.isPlaying { cueNode.play() }
    }
    if plan.layers.contains(.voice), moment.shouldSpeak {
      playVoiceResource(moment)
    }
  }

  func pause() {
    voiceGeneration += 1
    duckTask?.cancel()
    voiceNode.stop()
    cueNode.stop()
    ambienceNode.volume = PracticeAudioLevels.read("ambience")
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
    voiceGeneration += 1
    duckTask?.cancel()
    duckTask = nil
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

  private func playVoiceResource(_ moment: PracticeAudioMoment) {
    guard let url = PracticeVoiceAssets.url(named: moment.voiceResourceName ?? moment.cue.voiceResourceName),
      let file = try? AVAudioFile(forReading: url) else { return }
    guard let slice = PracticeVoicePlaybackSlice.make(frameLength: file.length,
      sampleRate: file.processingFormat.sampleRate, offset: moment.offset, remainingWindow: moment.remainingWindow)
    else { return } // Quiet remainder of a segment is intentional.
    let token = voiceGeneration
    fadeAmbience(to: PracticeAudioLevels.read("ambience") * 0.35, duration: 0.12)
    voiceNode.scheduleSegment(file, startingFrame: slice.startFrame,
      frameCount: slice.frameCount, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
        Task { @MainActor [weak self] in
          guard let self, self.voiceGeneration == token else { return }
          self.fadeAmbience(to: PracticeAudioLevels.read("ambience"), duration: 0.45)
        }
      }
    voiceNode.play()
  }

  private func fadeAmbience(to target: Float, duration: Double) {
    duckTask?.cancel()
    let start = ambienceNode.volume
    duckTask = Task { @MainActor [weak self] in
      for step in 1...12 {
        guard let self, !Task.isCancelled else { return }
        self.ambienceNode.volume = start + (target - start) * Float(step) / 12
        try? await Task.sleep(for: .seconds(duration / 12))
      }
    }
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
