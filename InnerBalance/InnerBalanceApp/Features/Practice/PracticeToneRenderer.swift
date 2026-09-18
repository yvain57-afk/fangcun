import AVFAudio
import Foundation

enum PracticeToneRenderer {
  static func buffer(
    for spec: PracticeCueToneSpec,
    sampleRate: Double = 44_100
  ) -> AVAudioPCMBuffer? {
    guard spec.duration > 0, sampleRate > 0 else { return nil }
    let frameCount = AVAudioFrameCount((sampleRate * spec.duration).rounded())
    guard
      frameCount > 0,
      let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
      let samples = buffer.floatChannelData?[0]
    else { return nil }

    buffer.frameLength = frameCount
    var phase = 0.0
    for frame in 0..<Int(frameCount) {
      let progress = Double(frame) / Double(max(1, Int(frameCount) - 1))
      let eased = progress * progress * (3 - 2 * progress)
      let frequency =
        spec.startFrequency + (spec.endFrequency - spec.startFrequency) * eased
      let attack = min(1, progress / 0.12)
      let release = min(1, (1 - progress) / 0.22)
      let envelope = max(0, min(attack, release))
      samples[frame] = Float(sin(phase) * envelope * 0.13)
      phase += 2 * Double.pi * frequency / sampleRate
    }
    return buffer
  }

  static func ambienceBuffer(
    for spec: PracticeAmbienceSpec,
    sampleRate: Double = 44_100
  ) -> AVAudioPCMBuffer? {
    guard spec.duration > 0, sampleRate > 0, !spec.frequencies.isEmpty else { return nil }
    let frameCount = AVAudioFrameCount((sampleRate * spec.duration).rounded())
    guard
      frameCount > 0,
      let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
      let channels = buffer.floatChannelData
    else { return nil }

    buffer.frameLength = frameCount
    for frame in 0..<Int(frameCount) {
      let time = Double(frame) / sampleRate
      let drift = sin(2 * Double.pi * time / spec.duration)
      var left = 0.0
      var right = 0.0
      for (index, frequency) in spec.frequencies.enumerated() {
        let phase = Double(index) * Double.pi / 3
        left += sin(2 * Double.pi * frequency * time + phase)
        right += sin(2 * Double.pi * frequency * time - phase)
      }
      let normalization = spec.volume / Double(spec.frequencies.count)
      channels[0][frame] = Float(left * normalization * (1 + drift * 0.08))
      channels[1][frame] = Float(right * normalization * (1 - drift * 0.08))
    }
    return buffer
  }
}
