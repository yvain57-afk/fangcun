import XCTest

final class PracticeGuidanceIntroUITests: XCTestCase {
  @MainActor private func launch() -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--readiness-disabled", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN",
      "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-practice.sound.mode", "guided", "-practice.sound.volume.voice", "1",
      "-fangcun.practice.v4.quickKind", "physiologicalSigh",
      "-fangcun.practice.introduction.skip.physiologicalSigh", "NO", "-fangcun.practice.introduction.skip.progressiveMuscleRelaxation", "NO"]
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["Breathe"].waitForExistence(timeout: 8))
    return app
  }
  @MainActor private func capture(_ name: String, app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
  }
  @MainActor private func start(_ kind: String, seconds: Int, app: XCUIApplication) {
    openV4Method(kind, app: app)
    app.buttons["practice.\(kind).\(seconds)"].tap()
    XCTAssertTrue(app.scrollViews["practice.introduction.reading"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["practice.entry.skip"].isHittable)
    XCTAssertFalse(app.staticTexts["practice.remaining"].exists)
  }
  @MainActor func testSkipIntroductionStartsOnceWithFullTrainingTime() {
    let app = launch()
    start("physiologicalSigh", seconds: 300, app: app)
    XCTAssertTrue(app.staticTexts["This introduction is outside your practice time"].exists)
    let introPause = app.buttons["practice.intro.pause"]
    XCTAssertTrue(introPause.waitForExistence(timeout: 5))
    introPause.tap()
    XCTAssertTrue(app.buttons["Resume introduction"].exists || introPause.label.contains("Resume introduction"))
    XCTAssertFalse(app.buttons["Pause practice"].exists)
    capture("新版开场-可暂停与跳过", app: app)
    app.buttons["practice.entry.skip"].tap()
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.scrollViews["practice.introduction.reading"].exists)
    let timer = app.staticTexts["practice.remaining"].label
    XCTAssertTrue(timer.contains("5:00") || timer.contains("4:5"), timer)
    capture("跳过后-原五分钟训练", app: app)
    app.buttons["Pause practice"].tap()
    XCTAssertTrue(app.buttons["Continue practice"].exists)
  }
  @MainActor func testNaturalIntroductionCompletionStartsTraining() {
    let app = launch()
    start("physiologicalSigh", seconds: 300, app: app)
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 150))
    let timer = app.staticTexts["practice.remaining"].label
    XCTAssertTrue(timer.contains("5:00") || timer.contains("4:5"), timer)
    XCTAssertFalse(app.buttons["practice.entry.skip"].exists)
    capture("开场听完-自动进入训练", app: app)
  }
  @MainActor func testPMRSleepEndingSavesWithoutForcingFeedback() {
    let app = launch()
    openV4Method("progressiveMuscleRelaxation", app: app)
    let sleep = app.segmentedControls["practice.pmr.ending"].buttons["Bedtime · Stay resting"]
    for _ in 0..<8 where !sleep.isHittable { app.swipeUp() }
    XCTAssertTrue(sleep.isHittable); sleep.tap()
    capture("肌肉放松-独立方法与睡前结尾", app: app)
    app.buttons["practice.progressiveMuscleRelaxation.600"].tap()
    XCTAssertTrue(app.buttons["practice.entry.skip"].waitForExistence(timeout: 5))
    app.buttons["practice.entry.skip"].tap()
    XCTAssertTrue(app.scrollViews["practice.muscleRelaxationStage"].waitForExistence(timeout: 5))
    capture("肌肉放松-自然呼吸与动作引导", app: app)
    app.buttons["Pause practice"].tap()
    XCTAssertTrue(app.staticTexts["Paused. Let go for now."].exists)
    app.buttons["End"].tap(); app.buttons["practice.finish.confirm"].firstMatch.tap()
    XCTAssertTrue(app.buttons["practice.saved.done"].waitForExistence(timeout: 8))
    XCTAssertFalse(app.buttons["practice.feedback.save"].exists)
    XCTAssertTrue(app.staticTexts["Saved on this device. You can keep resting, with nothing to fill in."].exists)
    capture("肌肉放松-睡前静默保留", app: app)
    app.buttons["practice.saved.done"].tap()
    openV4Records(app)
    let record = app.descendants(matching: .any).matching(identifier: "practice.history.record").firstMatch
    XCTAssertTrue(record.waitForExistence(timeout: 5))
    XCTAssertTrue(record.label.contains("Muscle relaxation"), record.label)
    XCTAssertFalse((record.value as? String ?? "").isEmpty)
    capture("肌肉放松-已保存记录", app: app)
  }
  @MainActor func testPMRRealTensionAndReleaseBoundaries() {
    let app = launch()
    start("progressiveMuscleRelaxation", seconds: 600, app: app)
    app.buttons["practice.entry.skip"].tap()
    let stage = app.staticTexts["practice.stageTitle"]
    let tense = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Gently tense"), object: stage)
    XCTAssertEqual(XCTWaiter.wait(for: [tense], timeout: 110), .completed)
    XCTAssertTrue(app.staticTexts["practice.pmr.muscle"].label.contains("Hands"))
    capture("肌肉放松-真实100秒-轻收阶段", app: app)
    let release = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Let go now"), object: stage)
    XCTAssertEqual(XCTWaiter.wait(for: [release], timeout: 7), .completed)
    capture("肌肉放松-真实105秒-松开阶段", app: app)
    app.buttons["Pause practice"].tap()
    XCTAssertTrue(app.staticTexts["Paused. Let go for now."].exists)
  }
}
