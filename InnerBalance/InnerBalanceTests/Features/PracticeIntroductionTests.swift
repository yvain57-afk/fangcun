import AVFAudio
import Foundation
import InnerBalanceCore
import Testing
@testable import InnerBalance

@MainActor struct PracticeIntroductionTests {
  @Test("Every phone method ships a decodable introduction, including both balanced variants")
  func introductionAssetsAreBundled() throws {
    for kind in PracticeKind.allCases {
      let variants: [String?] = kind == .balancedBreathing ? ["equal_5_5", "easy_4_4"] : [nil]
      for variant in variants {
        let resource = PracticeGuidanceContent.introductionResource(for: kind, variantID: variant)
        let url = try #require(PracticeVoiceAssets.url(named: resource), "Missing introduction: \(resource)")
        let player = try AVAudioPlayer(contentsOf: url)
        #expect(player.duration > 10 && player.duration < 120)
      }
    }
  }

  @Test("Skipping an intro starts exactly once, never consumes preparation time")
  func skipIsOnceAndOutsideTraining() throws {
    var clock = Date(timeIntervalSince1970: 1000)
    let vm = PracticeSessionViewModel(plan: try #require(PracticeCatalog.protocol(for: .physiologicalSigh)), duration: 300, now: { clock })
    let gate = PracticeIntroductionGate()
    gate.begin(shouldIntroduce: true)
    clock = clock.addingTimeInterval(90)
    #expect(vm.phase == .ready && vm.elapsedActive == 0 && vm.remainingTime == 300)
    #expect(vm.startedAt == nil)
    if gate.finish(.introduction) { vm.start(beforeRating: nil) }
    #expect(vm.phase == .running && vm.remainingTime == 300)
    #expect(!gate.finish(.introduction)) // Late audio completion after a skip.
    #expect(!gate.finish(.settling))
    clock = clock.addingTimeInterval(1)
    #expect(vm.elapsedActive == 1)
  }

  @Test("Cancelled introductions do not auto-start on late completion")
  func backgroundCancellation() {
    let gate = PracticeIntroductionGate()
    gate.begin(shouldIntroduce: true)
    gate.cancel()
    #expect(gate.stage == .ready)
    #expect(!gate.finish(.introduction))
    gate.begin(shouldIntroduce: false)
    #expect(gate.stage == .settling)
    #expect(gate.finish(.settling))
    #expect(!gate.finish(.settling))
  }

  @Test("Skip preference is opt-in per method and does not overwrite audio/display preferences")
  func skipPreferenceScope() throws {
    let suite = "practice.intro.synthetic." + UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set("rhythmOnly", forKey: "practice.sound.mode")
    defaults.set(true, forKey: "fangcun.dark")
    #expect(!PracticeIntroductionPreferences.skips(.meditation, defaults: defaults))
    PracticeIntroductionPreferences.setSkips(true, for: .meditation, defaults: defaults)
    #expect(PracticeIntroductionPreferences.skips(.meditation, defaults: defaults))
    #expect(!PracticeIntroductionPreferences.skips(.physiologicalSigh, defaults: defaults))
    #expect(defaults.string(forKey: "practice.sound.mode") == "rhythmOnly")
    #expect(defaults.bool(forKey: "fangcun.dark"))
    PracticeIntroductionPreferences.setSkips(false, for: .meditation, defaults: defaults)
    #expect(!PracticeIntroductionPreferences.skips(.meditation, defaults: defaults))
  }

  @Test("PMR resume rests through interrupted tension without adding time or replaying clipped audio")
  func pmrResumeReleases() throws {
    var clock = Date(timeIntervalSince1970: 1000)
    let vm = PracticeSessionViewModel(plan: try #require(PracticeCatalog.protocol(for: .progressiveMuscleRelaxation)), duration: 600, now: { clock })
    vm.start(beforeRating: nil)
    clock = clock.addingTimeInterval(102); vm.pause()
    clock = clock.addingTimeInterval(60); vm.resume()
    #expect(vm.elapsedActive == 102 && vm.remainingTime == 498)
    #expect(PracticeMuscleRelaxationState(snapshot: vm.timelineSnapshot).action == .release)
    #expect(!PracticeAudioTimeline.moment(for: .progressiveMuscleRelaxation, snapshot: vm.timelineSnapshot).shouldSpeak)
    clock = clock.addingTimeInterval(3)
    #expect(vm.timelineSnapshot.segment?.id == "pmr_m01_c")
    #expect(PracticeAudioTimeline.moment(for: .progressiveMuscleRelaxation, snapshot: vm.timelineSnapshot).shouldSpeak)
  }
}
