import AVFAudio
import Foundation
import InnerBalanceCore
import Testing
@testable import InnerBalance

struct PracticeAudioV4Tests {
  @Test("交替鼻孔每一轮明确左吸右呼右吸左呼，不把左右隐藏到同一铃声")
  func alternateVoiceOrderDoesNotAlternateNaively() {
    let cues = [0.0, 3, 6, 9, 12].map {
      PracticeAudioTimeline.moment(for: .alternateNostrilBreathing, elapsed: $0, duration: 180)
    }
    #expect(cues.map(\.cue) == [.leftInhale, .rightExhale, .rightInhale, .leftExhale, .leftInhale])
    #expect(cues.allSatisfy { $0.shouldSpeak })
    #expect(PracticeAudioTimeline.moment(for: .alternateNostrilBreathing, elapsed: 120).shouldSpeak)
  }

  @Test("均衡4/4的音频相位读取用户选择的同一协议")
  func balancedVariantUsesSharedSnapshot() {
    let fast = PracticeAudioTimeline.moment(for: .balancedBreathing, elapsed: 4, duration: 180, variantID: "easy_4_4")
    let standard = PracticeAudioTimeline.moment(for: .balancedBreathing, elapsed: 4, duration: 180)
    #expect(fast.cue == .pacedExhale)
    #expect(standard.cue == .pacedInhale)
  }

  @Test("方块两次停留分别保留事件身份")
  func holdsAreDistinctTimelineEvents() {
    let first = PracticeAudioTimeline.moment(for: .boxBreathing, elapsed: 3, duration: 180)
    let second = PracticeAudioTimeline.moment(for: .boxBreathing, elapsed: 9, duration: 180)
    #expect(first.cue == .hold && second.cue == .hold)
    #expect(first.id != second.id)
    #expect(first.remainingWindow == 3 && second.remainingWindow == 3)
  }

  @Test("六条完整引导轨逐段映射唯一离线文件，不循环填充")
  func everyGuidedSegmentHasAnExactResourceAndWindow() {
    for (kind, durations) in [(PracticeKind.nsdr, [600.0, 1200]), (.meditation, [300.0, 600]), (.diaphragmaticBreathing, [180.0, 300])] {
      for duration in durations {
        let segments = PracticeTimeline.segments(for: kind, duration: duration)
        #expect(!segments.isEmpty)
        var resources: Set<String> = []
        for segment in segments {
          let start = PracticeAudioTimeline.moment(for: kind, elapsed: segment.start, duration: duration)
          let inside = PracticeAudioTimeline.moment(for: kind, elapsed: segment.start + 1, duration: duration)
          #expect(start.isSegment && start.shouldSpeak)
          #expect(start.id == inside.id)
          #expect(start.voiceResourceName == "practice_v4_" + segment.id)
          #expect(start.remainingWindow == segment.end - segment.start)
          #expect(inside.offset == 1)
          if let name = start.voiceResourceName { resources.insert(name) }
        }
        #expect(resources.count == segments.count)
      }
    }
  }

  @Test("暂停后从当前段落位置恢复，过期语音不补播、不越相位")
  func resumeSlicesDoNotReplayOrCrossPhase() {
    let resume = PracticeVoicePlaybackSlice.make(frameLength: 480_000, sampleRate: 48_000, offset: 4, remainingWindow: 30)
    #expect(resume?.startFrame == 192_000)
    #expect(resume?.frameCount == 288_000)
    let phase = PracticeVoicePlaybackSlice.make(frameLength: 480_000, sampleRate: 48_000, offset: 1, remainingWindow: 2)
    #expect(phase?.frameCount == 96_000)
    #expect(PracticeVoicePlaybackSlice.make(frameLength: 480_000, sampleRate: 48_000, offset: 11, remainingWindow: 20) == nil)
    #expect(PracticeVoicePlaybackSlice.make(frameLength: 480_000, sampleRate: 48_000, offset: .infinity, remainingWindow: 20) == nil)
  }

  @Test("独立音量的零是静音，不被默认音量覆盖")
  func independentLayersPreserveMutedPreference() throws {
    let name = "audio.v4." + UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    #expect(PracticeAudioLevels.read("voice", defaults: defaults) == 1)
    defaults.set(0, forKey: "practice.sound.volume.voice")
    defaults.set(0.25, forKey: "practice.sound.volume.ambience")
    #expect(PracticeAudioLevels.read("voice", defaults: defaults) == 0)
    #expect(PracticeAudioLevels.read("ambience", defaults: defaults) == 0.25)
    #expect(PracticeAudioLevels.read("cue", defaults: defaults) == 1)
  }
}
