import AVFAudio
import Foundation
import InnerBalanceCore
import Testing

@testable import InnerBalance

@Suite("Practice presentation", .serialized)
struct PracticePresentationTests {
  @Test("五种练习使用与动作本身匹配的视觉舞台")
  func practiceKindsChoosePurposeBuiltStages() {
    #expect(PracticeStageKind.for(.physiologicalSigh) == .breathing)
    #expect(PracticeStageKind.for(.pacedBreathing) == .breathing)
    #expect(PracticeStageKind.for(.meditation) == .settling)
    #expect(PracticeStageKind.for(.nsdr) == .bodyScan)
    #expect(PracticeStageKind.for(.kegel) == .pelvicFloor)
  }

  @Test("练习后只需选择相对变化即可得到可比较的强度")
  func quickComparisonMapsFromTheStartingLevel() {
    #expect(PracticeChangeChoice.lighter.afterRating(before: 7) == 4)
    #expect(PracticeChangeChoice.same.afterRating(before: 7) == 7)
    #expect(PracticeChangeChoice.heavier.afterRating(before: 7) == 9)
    #expect(PracticeChangeChoice.heavier.afterRating(before: 10) == 10)
  }

  @Test("未填写练前状态时，只需选择练后感受即可保留")
  func feedbackWithoutStartingRatingNeedsOnlyPostPosition() {
    #expect(
      PracticeFeedbackPolicy.canSave(
        beforeRating: nil, changeChoice: nil, hasPostPosition: true))
    #expect(
      !PracticeFeedbackPolicy.canSave(
        beforeRating: nil, changeChoice: nil, hasPostPosition: false))
  }

  @Test("填写过练前状态时，保留变化仍需相对变化和练后感受")
  func comparisonRequiresBothResponses() {
    #expect(
      !PracticeFeedbackPolicy.canSave(
        beforeRating: 5, changeChoice: nil, hasPostPosition: true))
    #expect(
      !PracticeFeedbackPolicy.canSave(
        beforeRating: 5, changeChoice: .lighter, hasPostPosition: false))
    #expect(
      PracticeFeedbackPolicy.canSave(
        beforeRating: 5, changeChoice: .lighter, hasPostPosition: true))
  }

  @Test("没有练前参照的完成文案只确认保存现在的感受")
  func savedPostStateDoesNotClaimAComparison() {
    let detail = PracticeSavedCopy.detail(
      kind: .pacedBreathing,
      healthNeedsAttention: false,
      hasSubjectiveComparison: false
    )
    #expect(detail.contains("此刻的感受"))
    #expect(!detail.contains("变化"))
  }

  @Test("练习库先说明适用场景")
  func practiceLibraryUsesSituationLanguage() {
    #expect(PracticeKind.physiologicalSigh.outcomeTitle == "压力突然升高")
    #expect(PracticeKind.pacedBreathing.outcomeTitle == "压力中等，节奏偏快")
    #expect(PracticeKind.meditation.outcomeTitle == "压力较低，思绪占满")
    #expect(PracticeKind.nsdr.outcomeTitle == "睡眠或训练透支")
    #expect(PracticeKind.kegel.outcomeTitle == "专项训练，不用于即时减压")
  }

  @Test("五种练习都有完整且可读的功能说明")
  func everyPracticeExplainsPurposeTimingStepsAndSafety() {
    for kind in PracticeKind.allCases {
      #expect(!kind.purpose.isEmpty)
      #expect(!kind.bestFor.isEmpty)
      #expect(!kind.steps.isEmpty)
      #expect(!kind.preparation.isEmpty)
    }

    #expect(PracticeKind.physiologicalSigh.steps.contains("再补一小口"))
    #expect(PracticeKind.pacedBreathing.steps.contains("4 秒"))
    #expect(PracticeKind.nsdr.preparation.contains("不能代替正常睡眠"))
  }

  @Test("准备页用三个可理解的起点代替数字滑杆")
  func startingChoicesHaveStableEvidenceValues() {
    #expect(PracticeStartingChoice.allCases.map(\.rating) == [2, 5, 8])
    #expect(PracticeStartingChoice.allCases.map(\.title) == ["还好", "有点需要", "很需要"])
  }

  @Test("静心、身体扫描和凯格尔都有独立的可视节奏")
  func nonBreathingStageStatesFollowTheirOwnCadence() {
    #expect(PracticeStageState.make(kind: .meditation, elapsed: 31).focusIndex == 1)
    #expect(PracticeStageState.make(kind: .nsdr, elapsed: 46).focusIndex == 1)
    #expect(PracticeStageState.make(kind: .kegel, elapsed: 2).intensity == 0.5)
    #expect(PracticeStageState.make(kind: .kegel, elapsed: 8).intensity == 0.5)
  }

  @Test("暂停和继续共享同一个播放器页面身份")
  func pauseDoesNotRebuildTheWholePlayer() {
    #expect(PracticeScreenIdentity.for(.running) == .active)
    #expect(PracticeScreenIdentity.for(.paused) == .active)
    #expect(PracticeScreenIdentity.for(.ready) == .ready)
    #expect(PracticeScreenIdentity.for(.comparison) == .comparison)
  }

  @Test("只有需要连续动画的舞台才高频刷新")
  func timelineCadenceMatchesTheStage() {
    #expect(
      PracticeTimelineCadence.interval(
        kind: .pacedBreathing, phase: .running, reduceMotion: false) == 1.0 / 30
    )
    #expect(
      PracticeTimelineCadence.interval(
        kind: .nsdr, phase: .running, reduceMotion: false) == 1
    )
    #expect(
      PracticeTimelineCadence.interval(
        kind: .nsdr, phase: .paused, reduceMotion: false) == 1
    )
  }

  @Test("呼吸场域用弧面开合表达相位，而不是倒计时")
  func breathingFieldTargets() {
    #expect(
      BreathingFieldPresentation.targetExpansion(for: .inhale, kind: .physiologicalSigh) == 0.82
    )
    #expect(
      BreathingFieldPresentation.targetExpansion(for: .topUp, kind: .physiologicalSigh) == 1
    )
    #expect(
      BreathingFieldPresentation.targetExpansion(for: .exhale, kind: .physiologicalSigh) == 0.28
    )
    #expect(BreathingFieldPresentation.targetExpansion(for: .inhale, kind: .pacedBreathing) == 1)
  }

  @Test("节律呼吸在吸气转呼气时弧面位置连续")
  func pacedBreathingHasNoPhaseJump() {
    let inhaleEnd = PracticeBreathGuide.state(for: .pacedBreathing, elapsed: 3.999_999)
    let exhaleStart = PracticeBreathGuide.state(for: .pacedBreathing, elapsed: 4)
    let before = BreathingFieldPresentation.currentExpansion(
      for: inhaleEnd,
      kind: .pacedBreathing
    )
    let after = BreathingFieldPresentation.currentExpansion(
      for: exhaleStart,
      kind: .pacedBreathing
    )
    #expect(abs(before - after) < 0.001)
  }

  @Test("减少动态效果时弧面不发生物理位移")
  func reduceMotionRemovesArcTranslation() {
    #expect(BreathingFieldPresentation.usesPhysicalTranslation(reduceMotion: false))
    #expect(!BreathingFieldPresentation.usesPhysicalTranslation(reduceMotion: true))
  }

  @Test("暂停后恢复只播放当前相位的剩余部分")
  func resumedBreathUsesRemainingPhaseDuration() {
    let state = PracticeBreathGuide.state(for: .pacedBreathing, elapsed: 6)
    #expect(BreathingFieldPresentation.remainingAnimationDuration(for: state) == 4)
    #expect(
      BreathingFieldPresentation.currentExpansion(for: state, kind: .pacedBreathing) < 0.76
    )
    #expect(
      BreathingFieldPresentation.currentExpansion(for: state, kind: .pacedBreathing) > 0.28
    )
  }

  @Test("保存失败对话框的重试动作必须再次发起保存")
  func saveFailureRetryPolicy() {
    #expect(PracticeSessionDialogPolicy.shouldRetry(for: .retry))
    #expect(!PracticeSessionDialogPolicy.shouldRetry(for: .dismiss))
  }

  @Test("提前结束文案不承诺尚未发生的保存，也不要求凯格尔评价感受")
  func finishDialogCopyMatchesTheNextStep() {
    #expect(PracticeSessionDialogCopy.finishActionTitle == "结束练习")
    #expect(PracticeSessionDialogCopy.finishActionID == "practice.finish.confirm")
    #expect(PracticeSessionDialogCopy.finishMessage != PracticeSessionDialogCopy.finishMessageKey)
    #expect(!PracticeSessionDialogCopy.finishMessage.isEmpty)
    #expect(!PracticeSessionDialogCopy.finishMessage.contains("已保存"))
    #expect(!PracticeSessionDialogCopy.finishMessage.contains("主观变化"))
  }

  @Test("凯格尔只说明练习本身，不解释它和压力的关系")
  func kegelUsesAPlainBodyPracticeDescription() {
    #expect(
      PracticeKind.kegel.summary
        == "轻收 4 秒、完全放松 8 秒，同时保持自然呼吸。"
    )
  }

  @Test("凯格尔使用完成记录而不是主观调节证据")
  func kegelUsesCompletionOnlyFlow() {
    #expect(PracticeCompletionMode.for(.kegel) == .completionOnly)
    #expect(PracticeCompletionMode.for(.physiologicalSigh) == .subjectiveComparison)
  }

  @Test("凯格尔准备页包含完整的安全提醒")
  func kegelSafetyCopyCoversThePlannedConditions() {
    let copy = PracticeKind.kegel.preparation
    #expect(copy.contains("盆底持续紧张"))
    #expect(copy.contains("排尿排便异常"))
    #expect(copy.contains("产后"))
    #expect(copy.contains("术后"))
    #expect(copy.contains("专业人员"))
  }

  @Test("声音模式明确控制语音、节奏与环境声层")
  func soundModeChoosesAudioLayers() {
    let guided = PracticeAudioPlan.make(mode: .guided, ambienceEnabled: true)
    let silent = PracticeAudioPlan.make(mode: .silent, ambienceEnabled: true)

    #expect(guided.layers == [.voice, .cue, .ambience])
    #expect(silent.layers.isEmpty)
  }

  @Test("五种练习使用各自的声音提示时间线")
  func practiceKindsUsePurposeBuiltAudioCues() {
    #expect(
      PracticeAudioTimeline.cue(for: .physiologicalSigh, elapsed: 3) == .sighTopUp
    )
    #expect(
      PracticeAudioTimeline.cue(for: .pacedBreathing, elapsed: 4) == .pacedExhale
    )
    #expect(
      PracticeAudioTimeline.cue(for: .meditation, elapsed: 31) == .meditationBreath
    )
    #expect(
      PracticeAudioTimeline.cue(for: .nsdr, elapsed: 46) == .nsdrShoulders
    )
    #expect(
      PracticeAudioTimeline.cue(for: .kegel, elapsed: 4) == .kegelRelease
    )
  }

  @Test("声音提示在相位内只触发一次并在下一周期重新触发")
  func audioCueIdentityTracksPhaseBoundaries() {
    let first = PracticeAudioTimeline.moment(for: .pacedBreathing, elapsed: 0.2)
    let samePhase = PracticeAudioTimeline.moment(for: .pacedBreathing, elapsed: 3.8)
    let nextCycle = PracticeAudioTimeline.moment(for: .pacedBreathing, elapsed: 10.2)

    #expect(first.id == samePhase.id)
    #expect(first.id != nextCycle.id)
    #expect(first.cue == nextCycle.cue)
  }

  @Test("重复动作只在开头完整播报，长练习保持稀疏引导")
  func voiceGuidanceDoesNotTalkThroughEveryCycle() {
    #expect(
      PracticeAudioTimeline.moment(for: .physiologicalSigh, elapsed: 1).shouldSpeak
    )
    #expect(
      !PracticeAudioTimeline.moment(for: .physiologicalSigh, elapsed: 25).shouldSpeak
    )
    #expect(
      !PracticeAudioTimeline.moment(for: .pacedBreathing, elapsed: 21).shouldSpeak
    )
    #expect(PracticeAudioTimeline.moment(for: .meditation, elapsed: 181).shouldSpeak)
    #expect(PracticeAudioTimeline.moment(for: .nsdr, elapsed: 181).shouldSpeak)
  }

  @Test("NSDR 引导不会留下超过半分钟的空白")
  func nsdrGuidanceAdvancesWithinThirtySeconds() {
    let opening = PracticeAudioTimeline.moment(for: .nsdr, elapsed: 1)
    let nextGuidance = PracticeAudioTimeline.moment(for: .nsdr, elapsed: 29)

    #expect(opening.id != nextGuidance.id)
  }

  @Test("NSDR 身体扫描之间穿插轻柔呼吸提示")
  func nsdrGuidanceIncludesBreathing() {
    let nsdrCues = PracticeAudioCue.allCases.filter { $0.rawValue.hasPrefix("nsdr") }

    #expect(nsdrCues.contains { $0.spokenText.contains("呼气") })
    #expect(PracticeAudioTimeline.cue(for: .nsdr, elapsed: 51) == .nsdrBreath)
  }

  @Test("NSDR 在结束前把用户温和带回而不是突然停下")
  func nsdrGuidanceClosesBeforeTheSessionEnds() {
    let closing = PracticeAudioTimeline.moment(for: .nsdr, elapsed: 575, duration: 600)

    #expect(closing.cue.spokenText.contains("睁开眼睛"))
  }

  @Test(
    "NSDR 文字、视觉和触觉在语音相位边界同步",
    arguments: [0.0, 24.999, 25, 49.999, 50, 75, 100, 125, 150, 569.999, 570, 575, 599]
  )
  func nsdrPresentationFollowsTheAudioPhase(elapsed: TimeInterval) {
    let state = PracticeBodyScanState.make(elapsed: elapsed, duration: 600)
    let audio = PracticeAudioTimeline.moment(for: .nsdr, elapsed: elapsed, duration: 600)
    let visual = PracticeStageState.make(kind: .nsdr, elapsed: elapsed, duration: 600)

    #expect(state.cue == audio.cue)
    #expect(state.id == audio.id)
    #expect(
      PracticeKind.nsdr.cue(elapsed: elapsed, duration: 600) == audio.cue.spokenText)
    #expect(visual.focusIndex == (state.focusIndex ?? -1))
    #expect(
      PracticeHapticTimeline.cueID(for: .nsdr, elapsed: elapsed, duration: 600) == audio.id)
  }

  @Test("NSDR 在第 25 秒聚焦肩膀，并在最后 30 秒统一进入返回阶段")
  func nsdrVisualFocusAndReturnAreActionable() {
    let shoulders = PracticeBodyScanState.make(elapsed: 30, duration: 600)
    #expect(shoulders.cue == .nsdrShoulders)
    #expect(shoulders.focusIndex == 1)
    #expect(!shoulders.isReturning)

    let beforeReturn = PracticeBodyScanState.make(elapsed: 569.999, duration: 600)
    let returning = PracticeBodyScanState.make(elapsed: 570, duration: 600)
    let laterReturn = PracticeBodyScanState.make(elapsed: 599, duration: 600)
    #expect(!beforeReturn.isReturning)
    #expect(returning.isReturning)
    #expect(returning.focusIndex == nil)
    #expect(returning.id != beforeReturn.id)
    #expect(returning.id == laterReturn.id)
  }

  @Test("提示音的升降与时长能表达动作方向")
  func cueToneProfilesMatchTheMovement() {
    let inhale = PracticeCueToneSpec.for(.sighInhale)
    let topUp = PracticeCueToneSpec.for(.sighTopUp)
    let exhale = PracticeCueToneSpec.for(.sighExhale)
    let contract = PracticeCueToneSpec.for(.kegelContract)
    let release = PracticeCueToneSpec.for(.kegelRelease)

    #expect(topUp.endFrequency > inhale.endFrequency)
    #expect(exhale.duration > inhale.duration)
    #expect(exhale.endFrequency < exhale.startFrequency)
    #expect(release.endFrequency < contract.endFrequency)
  }

  @Test("提示音渲染为有包络的本地 PCM")
  func cueToneRendererCreatesAnAudibleFadedBuffer() throws {
    let sampleRate = 8_000.0
    let spec = PracticeCueToneSpec.for(.sighInhale)
    let buffer = try #require(PracticeToneRenderer.buffer(for: spec, sampleRate: sampleRate))
    let samples = try #require(buffer.floatChannelData?[0])

    #expect(buffer.frameLength == AVAudioFrameCount(sampleRate * spec.duration))
    #expect(abs(samples[0]) < 0.001)
    #expect(abs(samples[Int(buffer.frameLength) - 1]) < 0.01)
    #expect((0..<Int(buffer.frameLength)).contains { abs(samples[$0]) > 0.02 })
  }

  @Test("不同练习拥有可循环且彼此不同的环境声底色")
  func ambienceProfilesArePurposeBuiltAndRenderable() throws {
    let meditation = PracticeAmbienceSpec.for(.meditation)
    let nsdr = PracticeAmbienceSpec.for(.nsdr)
    let sampleRate = 8_000.0
    let buffer = try #require(
      PracticeToneRenderer.ambienceBuffer(for: meditation, sampleRate: sampleRate)
    )

    #expect(meditation.frequencies != nsdr.frequencies)
    #expect(buffer.frameLength == AVAudioFrameCount(sampleRate * meditation.duration))
    #expect(buffer.format.channelCount == 2)
  }

  @Test("声音选项直接说明用户会听到什么")
  func soundModesHavePlainLanguageCopy() {
    #expect(PracticeSoundMode.guided.title == "语音引导")
    #expect(PracticeSoundMode.rhythmOnly.title == "仅节奏")
    #expect(PracticeSoundMode.silent.title == "静音")
    #expect(PracticeSoundMode.guided.supportsAmbience)
    #expect(!PracticeSoundMode.silent.supportsAmbience)
  }

  @Test("播放类别依赖系统的 A2DP 与 AirPlay 路由，不传入非法选项")
  func playbackSessionUsesOnlyValidCategoryOptions() {
    #expect(PracticeAudioSessionPolicy.category == .playback)
    #expect(PracticeAudioSessionPolicy.mode == .default)
    #expect(PracticeAudioSessionPolicy.options.isEmpty)
  }

  @Test("没有真人语音资源时不向用户开放语音选项")
  func unavailableVoiceModeFallsBackHonestly() {
    #expect(
      PracticeSoundMode.availableCases(hasVoiceAssets: false) == [.rhythmOnly, .silent]
    )
    #expect(
      PracticeSoundMode.resolved(.guided, hasVoiceAssets: false) == .rhythmOnly
    )
    #expect(
      PracticeSoundMode.availableCases(hasVoiceAssets: true) == [.guided, .rhythmOnly, .silent]
    )
  }

  @Test("语音资源齐全时默认引导，缺失时安全退回节奏")
  @MainActor
  func guidedVoiceIsThePreferredDefault() throws {
    let suiteName = "PracticePresentationTests.guidedVoiceIsThePreferredDefault"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let preferences = PracticeSoundPreferences(defaults: defaults)

    #expect(preferences.preferredMode == .guided)
    #expect(preferences.mode(hasVoiceAssets: true) == .guided)
    #expect(preferences.mode(hasVoiceAssets: false) == .rhythmOnly)
  }

  @Test("知性女声首次启用时打开语音，之后尊重用户选择")
  @MainActor
  func selectedVoicePackActivatesGuidanceOnlyOnce() throws {
    let suiteName = "PracticePresentationTests.selectedVoicePackActivatesGuidanceOnlyOnce"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(PracticeSoundMode.rhythmOnly.rawValue, forKey: "practice.sound.mode")

    let activated = PracticeSoundPreferences(defaults: defaults)
    #expect(activated.preferredMode == .guided)

    activated.preferredMode = .silent
    let reopened = PracticeSoundPreferences(defaults: defaults)
    #expect(reopened.preferredMode == .silent)
  }

  @Test("五种练习所需的知性女声资源都随 App 打包")
  func selectedVoicePackIsComplete() throws {
    #expect(PracticeKind.allCases.allSatisfy { PracticeVoiceAssets.isAvailable(for: $0) })
    for cue in PracticeAudioCue.allCases {
      let url = try #require(PracticeVoiceAssets.url(for: cue))
      let file = try AVAudioFile(forReading: url)
      #expect(file.length > 0)
    }
  }

  @Test("真实音频图可以启动持续环境声")
  @MainActor
  func realAudioGraphStartsContinuousAmbience() async throws {
    let coordinator = PracticeAudioCoordinator()
    defer { coordinator.stop() }

    let continuousAudioStarted = try await coordinator.prepare(
      kind: .physiologicalSigh,
      plan: PracticeAudioPlan.make(mode: .guided, ambienceEnabled: true)
    )

    #expect(continuousAudioStarted)
  }

  @Test("开始练习会让声音控制器进入持续播放状态")
  @MainActor
  func runningSessionStartsTheAudioController() async throws {
    let viewModel = PracticeSessionViewModel(
      plan: PracticeCatalog.protocol(for: .physiologicalSigh)!,
      duration: 60
    )
    let controller = PracticeAudioController()
    viewModel.start(beforeRating: 5)

    let runTask = Task {
      await controller.run(viewModel, mode: .guided, ambienceEnabled: true)
    }
    defer {
      runTask.cancel()
      controller.stop()
    }
    try await Task.sleep(for: .milliseconds(400))

    #expect(controller.canContinueInBackground)
  }

  @Test("运行中音频配置变化会自动重建而不是变成静音暂停")
  @MainActor
  func engineConfigurationChangeRebuildsActiveAudio() async throws {
    let viewModel = PracticeSessionViewModel(
      plan: PracticeCatalog.protocol(for: .physiologicalSigh)!,
      duration: 60
    )
    let controller = PracticeAudioController()
    viewModel.start(beforeRating: 5)
    let runTask = Task {
      await controller.run(viewModel, mode: .guided, ambienceEnabled: true)
    }
    defer {
      runTask.cancel()
      controller.stop()
    }
    try await Task.sleep(for: .milliseconds(400))
    #expect(controller.canContinueInBackground)

    await controller.handleEngineConfigurationChange(viewModel)

    #expect(viewModel.phase == .running)
    #expect(controller.canContinueInBackground)
  }

  @Test("连续音频配置通知只重建一次")
  @MainActor
  func repeatedEngineConfigurationChangesAreCoalesced() async throws {
    let coordinator = CountingPracticeAudioCoordinator()
    let viewModel = PracticeSessionViewModel(
      plan: PracticeCatalog.protocol(for: .physiologicalSigh)!,
      duration: 60
    )
    let controller = PracticeAudioController(coordinator: coordinator)
    viewModel.start(beforeRating: 5)
    let runTask = Task {
      await controller.run(viewModel, mode: .guided, ambienceEnabled: true)
    }
    defer {
      runTask.cancel()
      controller.stop()
    }
    let initialDeadline = ContinuousClock.now + .seconds(1)
    while coordinator.prepareCount < 1, ContinuousClock.now < initialDeadline {
      await Task.yield()
    }
    #expect(coordinator.prepareCount == 1)

    controller.scheduleEngineConfigurationRecovery(viewModel)
    controller.scheduleEngineConfigurationRecovery(viewModel)
    #expect(!controller.canContinueInBackground)
    let recoveryDeadline = ContinuousClock.now + .seconds(1)
    while coordinator.prepareCount < 2, ContinuousClock.now < recoveryDeadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    try await Task.sleep(for: .milliseconds(450))

    #expect(coordinator.prepareCount == 2)
    #expect(viewModel.phase == .running)
    #expect(controller.canContinueInBackground)
  }

  @Test("退出后迟到的音频准备结果不会重新激活练习")
  @MainActor
  func cancelledAudioPreparationDoesNotReactivateSession() async {
    let coordinator = SuspendedPracticeAudioCoordinator()
    let controller = PracticeAudioController(coordinator: coordinator)
    let viewModel = PracticeSessionViewModel(
      plan: PracticeCatalog.protocol(for: .physiologicalSigh)!, duration: 300)
    viewModel.start(beforeRating: nil)
    let task = Task { await controller.run(viewModel, mode: .guided, ambienceEnabled: true) }
    while coordinator.pending == nil { await Task.yield() }
    viewModel.finish()
    task.cancel()
    controller.stop()
    coordinator.pending?.resume(returning: true)
    coordinator.pending = nil
    await task.value
    #expect(!controller.canContinueInBackground)
    #expect(coordinator.playCount == 0)
  }

  @Test("未开始的准备页不创建会话或启动音频，关闭后保持停止")
  @MainActor func closingReadyPreparationHasNoSessionOrAudio() async {
    let coordinator = CountingPracticeAudioCoordinator()
    let audio = PracticeAudioController(coordinator: coordinator)
    let model = PracticeSessionViewModel(plan: PracticeCatalog.protocol(for: .physiologicalSigh)!, duration: 60)
    await audio.run(model, mode: .guided, ambienceEnabled: true)
    audio.stop()
    #expect(model.phase == .ready && model.startedAt == nil)
    #expect(model.makeCompletion(sessionID: "synthetic-ready") == nil)
    #expect(coordinator.prepareCount == 0 && !audio.canContinueInBackground)
    model.finish()
    #expect(model.phase == .ready)
  }

  @Test("每条语音提示都有稳定的本地资源名")
  func voiceCuesHaveStableResourceNames() {
    #expect(PracticeAudioCue.sighTopUp.voiceResourceName == "practice_sigh_top_up")
    #expect(PracticeAudioCue.nsdrShoulders.voiceResourceName == "practice_nsdr_shoulders")
    #expect(
      Set(PracticeAudioCue.allCases.map(\.voiceResourceName)).count
        == PracticeAudioCue.allCases.count
    )
  }

  @Test("语音文案短而可以离屏理解")
  func voiceScriptsAreBriefAndActionable() {
    #expect(PracticeAudioCue.sighTopUp.spokenText == "再补一小口。")
    #expect(PracticeAudioCue.meditationReturn.spokenText.contains("回来就好"))
    #expect(PracticeAudioCue.allCases.allSatisfy { $0.spokenText.count <= 20 })
  }

  @Test("只有持续环境声开启时才允许锁屏继续")
  func backgroundPolicyRequiresContinuousAudio() {
    #expect(
      !PracticeAudioBackgroundPolicy.shouldPauseWhenInactive(
        mode: .guided,
        ambienceEnabled: true,
        continuousAudioAvailable: true
      ))
    #expect(
      PracticeAudioBackgroundPolicy.shouldPauseWhenInactive(
        mode: .guided,
        ambienceEnabled: false,
        continuousAudioAvailable: true
      ))
    #expect(
      PracticeAudioBackgroundPolicy.shouldPauseWhenInactive(
        mode: .silent,
        ambienceEnabled: true,
        continuousAudioAvailable: true
      ))
    #expect(
      PracticeAudioBackgroundPolicy.shouldPauseWhenInactive(
        mode: .rhythmOnly,
        ambienceEnabled: true,
        continuousAudioAvailable: false
      ))
    #expect(
      PracticeAudioBackgroundPolicy.shouldPauseForRouteChange(
        reason: .oldDeviceUnavailable
      ))
  }

  @Test("没有可恢复配置时，音频硬件变化才暂停练习")
  @MainActor
  func engineConfigurationChangeRequiresARebuild() async {
    let viewModel = PracticeSessionViewModel(
      plan: PracticeCatalog.protocol(for: .pacedBreathing)!,
      duration: 180
    )
    let audio = PracticeAudioController()
    viewModel.start(beforeRating: 5)

    await audio.handleEngineConfigurationChange(viewModel)

    #expect(viewModel.phase == .paused)
    #expect(!audio.canContinueInBackground)
  }
}

@MainActor
private final class CountingPracticeAudioCoordinator: PracticeAudioCoordinating {
  private(set) var prepareCount = 0
  let configurationChangeSource: AnyObject = NSObject()

  func prepare(kind: PracticeKind, plan: PracticeAudioPlan) async throws -> Bool {
    prepareCount += 1
    return true
  }

  func play(_ moment: PracticeAudioMoment) {}
  func pause() {}
  func stop() {}
}

@MainActor
private final class SuspendedPracticeAudioCoordinator: PracticeAudioCoordinating {
  let configurationChangeSource: AnyObject = NSObject()
  var pending: CheckedContinuation<Bool, Never>?
  var playCount = 0
  func prepare(kind: PracticeKind, plan: PracticeAudioPlan) async throws -> Bool {
    await withCheckedContinuation { pending = $0 }
  }
  func play(_ moment: PracticeAudioMoment) { playCount += 1 }
  func pause() {}
  func stop() {}
}
