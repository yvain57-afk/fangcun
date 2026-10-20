import XCTest

extension XCTestCase {
  @MainActor func openDailySettings(_ app: XCUIApplication) {
    if !app.tabBars.buttons["日常"].isSelected { app.tabBars.buttons["日常"].tap() }
    let settings = app.buttons["daily.settings"]
    for _ in 0..<4 where !settings.exists && app.navigationBars.buttons.firstMatch.exists {
      app.navigationBars.buttons.firstMatch.tap()
    }
    // iOS 27 can report this icon non-hittable after a cover dismisses, although native
    // Button.tap opens Settings correctly. Verify the real destination, as the original flow did.
    for _ in 0..<12 {
      let frame = settings.frame
      if settings.exists, frame.height > 0, frame.minY >= app.frame.minY,
        frame.maxY <= app.tabBars.firstMatch.frame.minY { break }
      app.swipeDown()
    }
    XCTAssertTrue(settings.exists)
    XCTAssertGreaterThan(settings.frame.height, 0)
    settings.tap()
    XCTAssertTrue(app.switches["深色模式"].waitForExistence(timeout: 5))
  }
  @MainActor func openDailyActions(_ app: XCUIApplication) {
    for _ in 0..<12 where !app.buttons["daily.lightActions"].isHittable { app.swipeUp() }
    XCTAssertTrue(app.buttons["daily.lightActions"].isHittable)
    app.buttons["daily.lightActions"].tap()
  }
  @MainActor func openV4Records(_ app: XCUIApplication) {
    app.tabBars.buttons["呼吸"].tap()
    let records = app.buttons["hub.records"]
    for _ in 0..<3 where !records.exists && app.navigationBars.buttons.firstMatch.exists {
      app.navigationBars.buttons.firstMatch.tap()
    }
    for _ in 0..<14 where !records.isHittable { app.swipeDown() }
    XCTAssertTrue(records.isHittable)
    records.tap()
    XCTAssertTrue(app.navigationBars["练习记录"].waitForExistence(timeout: 5))
  }
  @MainActor func openV4Method(_ id: String, app: XCUIApplication) {
    app.tabBars.buttons["呼吸"].tap()
    let card = app.buttons["hub.method." + id]
    for _ in 0..<20 {
      if card.isHittable { break }
      if card.exists && card.frame.height > 0 && card.frame.maxY < 80 { app.swipeDown() } else { app.swipeUp() }
    }
    XCTAssertTrue(card.isHittable)
    card.tap()
    XCTAssertTrue(app.buttons["practice.demo"].waitForExistence(timeout: 5), "Method detail must actually open")

  }
}

final class BreathingHubV4UITests: XCTestCase {
  @MainActor private func launch() -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.practice.v4.quickKind", "", "-fangcun.reduceMotion", "YES"]
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["呼吸"].waitForExistence(timeout: 8))
    return app
  }
  @MainActor func testDefaultHubHasTwoTabsAndNoHealthGate() {
    let app = launch()
    XCTAssertEqual(app.tabBars.buttons.count, 2)
    XCTAssertTrue(app.tabBars.buttons["呼吸"].isSelected)
    XCTAssertTrue(app.buttons["hub.quickStart"].isHittable)
    XCTAssertFalse(app.staticTexts["status.band"].exists)
    XCTAssertFalse(app.buttons["today.drinks"].exists)
    XCTAssertFalse(app.buttons["status.refresh"].exists)
    XCTAssertFalse(app.buttons["home.checkIn"].exists)
    XCTAssertFalse(app.tabBars.buttons["设置"].exists)
    let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "V4-breathing-home"; screenshot.lifetime = .keepAlways; add(screenshot)
    app.tabBars.buttons["日常"].tap()
    XCTAssertTrue(app.buttons["daily.records"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["daily.settings"].exists)
  }
  @MainActor func testAllNineMethodsStartPauseAndSaveWithoutHealth() {
    let app = launch()
    let methods: [(String, Int)] = [("physiologicalSigh",300),("pacedBreathing",300),("nsdr",600),("meditation",300),("balancedBreathing",300),("boxBreathing",180),("diaphragmaticBreathing",180),("alternateNostrilBreathing",180),("kegel",180)]
    for (kind, duration) in methods {
      for _ in 0..<12 where !app.buttons["hub.quickStart"].isHittable { app.swipeDown() }
      openV4Method(kind, app: app)
      let start = app.buttons["practice.\(kind).\(duration)"]
      XCTAssertTrue(start.waitForExistence(timeout: 5)); XCTAssertTrue(start.isHittable); start.tap()
      let pause = app.buttons["暂停练习"]
      XCTAssertTrue(pause.waitForExistence(timeout: 8))
      let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "V4-method-" + kind; shot.lifetime = .keepAlways; add(shot)
      pause.tap()
      XCTAssertTrue(app.staticTexts["已暂停"].waitForExistence(timeout: 3))
      app.buttons["继续练习"].tap()
      XCTAssertTrue(pause.waitForExistence(timeout: 8))
      app.buttons["结束"].tap(); app.buttons["practice.finish.confirm"].firstMatch.tap()
      XCTAssertTrue(app.staticTexts["practice.actualSummary"].waitForExistence(timeout: 6))
      let skip = app.buttons["practice.feedback.skip"]
      for _ in 0..<6 where !skip.isHittable { app.swipeUp() }
      XCTAssertTrue(skip.isHittable); skip.tap()
      let done = app.buttons["practice.saved.done"]
      XCTAssertTrue(done.waitForExistence(timeout: 6)); done.tap()
      XCTAssertTrue(app.tabBars.buttons["呼吸"].isSelected)
      if app.navigationBars.buttons.firstMatch.exists { app.navigationBars.buttons.firstMatch.tap() }
    }
    openV4Records(app)
    XCTAssertTrue(app.navigationBars["练习记录"].waitForExistence(timeout: 5))
    XCTAssertGreaterThanOrEqual(app.descendants(matching: .any).matching(identifier: "practice.history.record").count, 1)
  }
  @MainActor func testEntryIsSkippableAndDoesNotStartTheActiveSessionEarly() {
    let app = launch()
    openV4Method("nsdr", app: app)
    app.buttons["practice.nsdr.600"].tap()
    let entry = app.buttons["practice.entry.skip"]
    XCTAssertTrue(entry.waitForExistence(timeout: 3))
    XCTAssertFalse(app.buttons["暂停练习"].exists)
    XCTAssertTrue(app.staticTexts["先自然呼吸，准备时间不计入练习。"].exists)
    entry.tap()
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 3))
  }

  @MainActor func testSaveFailureRetriesWithoutFalseSuccessOrDuplicateRecord() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "--ui-testing-practice-save-failure-once", "-fangcun.practice.v4.quickKind", "physiologicalSigh"]
    app.launch()
    openV4Method("balancedBreathing", app: app)
    app.buttons["practice.balancedBreathing.300"].tap()
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 5))
    app.buttons["结束"].tap(); app.buttons["practice.finish.confirm"].firstMatch.tap()
    let error = app.alerts["未能保留本次练习"]
    XCTAssertTrue(error.waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["practice.saved.done"].exists)
    error.buttons["重试"].tap()
    let done = app.buttons["practice.saved.done"]
    XCTAssertTrue(done.waitForExistence(timeout: 6)); done.tap()
    openV4Records(app)
    XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "practice.history.record").count, 1)
  }

  @MainActor func testSpecialMethodsExplainHumanMovementAndCorrectNostrilOrder() {
    let app = launch()
    for (method, teaching) in [("diaphragmaticBreathing", "diaphragm"), ("alternateNostrilBreathing", "nostrils"), ("kegel", "pelvicFloor")] {
      for _ in 0..<12 where !app.buttons["hub.quickStart"].isHittable { app.swipeDown() }
      openV4Method(method, app: app)
      let disclosure = app.buttons["动作要领与注意事项"]
      for _ in 0..<8 where !disclosure.isHittable { app.swipeUp() }
      XCTAssertTrue(disclosure.isHittable)
      disclosure.tap()
      let instruction = app.descendants(matching: .any)["practice.teaching." + teaching].firstMatch
      for _ in 0..<10 where !instruction.isHittable { app.swipeUp() }
      XCTAssertTrue(instruction.exists)
      if method == "alternateNostrilBreathing" {
        let expected = ["你的左侧吸气", "你的右侧呼气", "你的右侧吸气", "你的左侧呼气"]
        for index in 0..<4 {
          let step = app.descendants(matching: .any)["practice.teaching.nostril.\(index + 1)"].firstMatch
          for _ in 0..<5 where !step.isHittable { app.swipeUp() }
          XCTAssertTrue(step.label.contains(expected[index]))
          XCTAssertTrue(step.label.contains(index == 0 || index == 3 ? "右鼻孔" : "左鼻孔"))
        }
      }
      let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "V4-human-teaching-" + method; screenshot.lifetime = .keepAlways; add(screenshot)
      app.navigationBars.buttons.firstMatch.tap()
    }
  }

  @MainActor func testPurposeFiltersDoNotRequireMoodInput() {
    let app = launch()
    let filter = app.buttons["hub.filter.身体训练"]
    if !filter.isHittable { app.scrollViews.element(boundBy: 1).swipeLeft() }
    XCTAssertTrue(filter.isHittable); filter.tap()
    let card = app.buttons["hub.method.kegel"]
    for _ in 0..<5 where !card.isHittable { app.swipeUp() }
    XCTAssertTrue(card.isHittable)
    XCTAssertFalse(app.buttons["hub.method.nsdr"].exists)
  }
}

/// Deliberately slow, real-time native capture. Run independently with
/// -only-testing:InnerBalanceUITests/PracticeV4CaptureUITests/testCaptureNinePracticeScenes
/// while simctl records the simulator. No injected clock or final presentation state.
final class PracticeV4CaptureUITests: XCTestCase {
  private struct CaptureCase {
    let method: String
    let duration: Int
    let variant: String?
    let observedSeconds: TimeInterval
    let snapshots: [TimeInterval]
    var name: String { method + (variant.map { "-" + $0 } ?? "") }
  }

  @MainActor func testCaptureNinePracticeScenes() {
    executionTimeAllowance = 1200
    continueAfterFailure = false
    let app = launchCaptureApp()
    let cases: [CaptureCase] = [
      .init(method: "physiologicalSigh", duration: 300, variant: nil, observedSeconds: 26, snapshots: [1, 4, 8, 20]),
      .init(method: "pacedBreathing", duration: 300, variant: nil, observedSeconds: 26, snapshots: [1, 6, 21]),
      .init(method: "balancedBreathing", duration: 300, variant: "equal_5_5", observedSeconds: 26, snapshots: [1, 7, 21]),
      .init(method: "balancedBreathing", duration: 300, variant: "easy_4_4", observedSeconds: 26, snapshots: [1, 5, 17]),
      .init(method: "boxBreathing", duration: 180, variant: nil, observedSeconds: 26, snapshots: [1, 4, 7, 10, 22]),
      .init(method: "alternateNostrilBreathing", duration: 180, variant: nil, observedSeconds: 26, snapshots: [1, 4, 7, 10, 22]),
      .init(method: "kegel", duration: 180, variant: nil, observedSeconds: 38, snapshots: [1, 6, 25, 34]),
      .init(method: "diaphragmaticBreathing", duration: 180, variant: nil, observedSeconds: 62, snapshots: [1, 28, 54]),
      .init(method: "meditation", duration: 300, variant: nil, observedSeconds: 105, snapshots: [1, 28, 58, 102]),
      .init(method: "nsdr", duration: 600, variant: nil, observedSeconds: 100, snapshots: [1, 33, 63, 94]),
    ]

    for item in cases {
      XCTContext.runActivity(named: "Real-time scene · " + item.name) { _ in
        goToHubTop(app)
        openV4Method(item.method, app: app)
        if let variant = item.variant {
          let choice = app.segmentedControls["practice.variant"].buttons[variant == "easy_4_4" ? "吸 4 秒 / 呼 4 秒" : "吸 5 秒 / 呼 5 秒"]
          revealCaptureElement(choice, app: app, direction: .up, limit: 10)
          choice.tap()
          XCTAssertTrue(choice.isSelected, "The captured variant must match the visible selected option")
        }
        let start = app.buttons["practice.\(item.method).\(item.duration)"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(start.isHittable)
        marker("ENTRY_START", name: item.name)
        start.tap()
        // Let the original entry run at native speed. It does not count as active training.
        XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 10))
        let beginning = Date()
        marker("START", name: item.name, at: beginning)
        for offset in item.snapshots {
          waitInRealTime(until: beginning.addingTimeInterval(offset), label: item.name + " at " + String(offset))
          XCTAssertTrue(app.buttons["暂停练习"].exists, "Session must remain running during capture")
          let phase = app.staticTexts["practice.breathPhase"]
          let stage = app.staticTexts["practice.stageTitle"]
          let visiblePhase = phase.exists ? phase.label : stage.exists ? stage.label : ""
          marker("FRAME", name: item.name + " requested=" + String(offset) + " visible=" + visiblePhase)
          captureNativeFrame("V4-" + item.name + "-t" + String(Int(offset)), app: app)
        }
        waitInRealTime(until: beginning.addingTimeInterval(item.observedSeconds), label: item.name + " full capture")
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(beginning), item.observedSeconds)
        marker("END", name: item.name)
        finishAndSaveCapture(app, name: item.name)
        marker("EXIT_END", name: item.name)
      }
    }

    goToHubTop(app)
    openV4Records(app)
    XCTAssertTrue(app.navigationBars["练习记录"].waitForExistence(timeout: 5))
    captureNativeFrame("V4-real-session-records", app: app)
    marker("RUN_COMPLETE", name: "nine-methods-plus-balanced-4-4")
  }

  @MainActor func testCaptureGuidedScenesAndPauseResume() {
    continueAfterFailure = false
    let app = launchCaptureApp()
    captureNativeFrame("V4-final-home", app: app)
    app.tabBars.buttons["日常"].tap()
    XCTAssertTrue(app.buttons["daily.settings"].waitForExistence(timeout: 5))
    captureNativeFrame("V4-final-daily", app: app)
    for (method, duration, seconds) in [("meditation", 300, 105.0), ("nsdr", 600, 100.0)] {
      goToHubTop(app)
      openV4Method(method, app: app)
      marker("ENTRY_START", name: method)
      app.buttons["practice.\(method).\(duration)"].tap()
      XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 10))
      let beginning = Date()
      marker("START", name: method, at: beginning)
      for offset in [1.0, 34.0, 65.0, 95.0] {
        waitInRealTime(until: beginning.addingTimeInterval(offset), label: method)
        XCTAssertTrue(app.buttons["暂停练习"].exists)
        captureNativeFrame("V4-" + method + "-t" + String(Int(offset)), app: app)
      }
      waitInRealTime(until: beginning.addingTimeInterval(seconds), label: method)
      marker("END", name: method)
      app.buttons["暂停练习"].tap()
      XCTAssertTrue(app.staticTexts["已暂停"].waitForExistence(timeout: 5))
      captureNativeFrame("V4-" + method + "-paused", app: app)
      waitInRealTime(until: Date().addingTimeInterval(2), label: "paused")
      app.buttons["继续练习"].tap()
      XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 8))
      waitInRealTime(until: Date().addingTimeInterval(4), label: "resumed")
      captureNativeFrame("V4-" + method + "-resumed", app: app)
      finishAndSaveCapture(app, name: method)
      marker("EXIT_END", name: method)
    }
    goToHubTop(app)
    openV4Records(app)
    captureNativeFrame("V4-final-real-records", app: app)
  }

  @MainActor func testCaptureLowFrequencyExpressions() {
    continueAfterFailure = false
    let app = launchCaptureApp()
    for method in ["physiologicalSigh", "kegel"] {
      goToHubTop(app)
      openV4Method(method, app: app)
      let duration = method == "kegel" ? 180 : 300
      marker("ENTRY_START", name: method + "-expressions")
      app.buttons["practice.\(method).\(duration)"].tap()
      XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 10))
      let beginning = Date()
      marker("START", name: method + "-expressions", at: beginning)
      // Real fourth-cycle frames verify that a slow blink cannot be repeated at
      // the top-up/contract/release boundaries. No injected animation state.
      for offset in [35.5, 37.5, 39.5, 41.5] {
        waitInRealTime(until: beginning.addingTimeInterval(offset), label: method + " expression boundary")
        XCTAssertTrue(app.buttons["暂停练习"].exists)
        captureNativeFrame("V4-" + method + "-expression-t" + String(offset), app: app)
      }
      marker("END", name: method + "-expressions")
      finishAndSaveCapture(app, name: method + "-expressions")
      marker("EXIT_END", name: method + "-expressions")
    }
  }

  @MainActor func testCaptureDarkLargeTypeAndStaticModes() {
    continueAfterFailure = false
    let modes: [(String, Bool, String, Bool)] = [
      ("dark", true, "standard", false),
      ("maximum-type", false, "standard", true),
      ("static", false, "static", false),
      ("reduced-motion", true, "standard", false),
    ]
    for (name, dark, motion, large) in modes {
      let app = launchCaptureApp(dark: dark, motion: motion, large: large, reduced: name == "reduced-motion")
      marker("APPEARANCE_START", name: name)
      XCTAssertTrue(app.buttons["hub.quickStart"].waitForExistence(timeout: 5))
      captureNativeFrame("V4-appearance-" + name + "-hub", app: app)
      app.tabBars.buttons["日常"].tap()
      XCTAssertTrue(app.buttons["daily.settings"].waitForExistence(timeout: 5))
      captureNativeFrame("V4-appearance-" + name + "-daily-no-health", app: app)
      openV4Method("alternateNostrilBreathing", app: app)
      let start = app.buttons["practice.alternateNostrilBreathing.180"]
      XCTAssertTrue(start.waitForExistence(timeout: 5)); XCTAssertTrue(start.isHittable)
      start.tap()
      let entry = app.buttons["practice.entry.skip"]
      if entry.waitForExistence(timeout: 1), entry.isHittable { entry.tap() }
      XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 10))
      captureNativeFrame("V4-appearance-" + name + "-active-a", app: app)
      waitInRealTime(until: Date().addingTimeInterval(4), label: name + " next phase")
      captureNativeFrame("V4-appearance-" + name + "-active-b", app: app)
      app.buttons["暂停练习"].tap()
      XCTAssertTrue(app.staticTexts["已暂停"].waitForExistence(timeout: 5))
      captureNativeFrame("V4-appearance-" + name + "-paused", app: app)
      finishAndSaveCapture(app, name: name)
      marker("APPEARANCE_END", name: name)
      app.terminate()
    }
  }

  private enum RevealDirection { case up, down }

  @MainActor private func launchCaptureApp(dark: Bool = false, motion: String = "standard", large: Bool = false, reduced: Bool = false) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN",
      "-fangcun.dark", dark ? "YES" : "NO", "-fangcun.largeType", large ? "YES" : "NO",
      "-fangcun.motionMode", motion, "-fangcun.reduceMotion", reduced ? "YES" : "NO",
      "-fangcun.practice.v4.quickKind", "physiologicalSigh", "-practice.sound.mode", "guided", "-practice.sound.ambience", "YES",
      "-UIPreferredContentSizeCategoryName", large ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryLarge"]
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["呼吸"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.tabBars.buttons["呼吸"].isSelected)
    return app
  }

  @MainActor private func goToHubTop(_ app: XCUIApplication) {
    app.tabBars.buttons["呼吸"].tap()
    let quickStart = app.buttons["hub.quickStart"]
    // A completed session resets the hub navigation. The bounded fallback also handles a detail still open.
    for _ in 0..<3 where !quickStart.exists && app.navigationBars.buttons.firstMatch.exists {
      app.navigationBars.buttons.firstMatch.tap()
    }
    revealCaptureElement(quickStart, app: app, direction: .down, limit: 14)
  }

  @MainActor private func revealCaptureElement(_ element: XCUIElement, app: XCUIApplication, direction: RevealDirection, limit: Int) {
    for _ in 0..<limit where !element.isHittable {
      switch direction { case .up: app.swipeUp(); case .down: app.swipeDown() }
    }
    XCTAssertTrue(element.exists, "Required capture element is missing: " + element.identifier)
    XCTAssertTrue(element.isHittable, "Required capture element is unreachable: " + element.identifier)
  }

  @MainActor private func finishAndSaveCapture(_ app: XCUIApplication, name: String) {
    let end = app.buttons["结束"]
    XCTAssertTrue(end.isHittable); end.tap()
    let confirm = app.buttons["practice.finish.confirm"].firstMatch
    XCTAssertTrue(confirm.waitForExistence(timeout: 5)); confirm.tap()
    XCTAssertTrue(app.staticTexts["practice.actualSummary"].waitForExistence(timeout: 8))
    captureNativeFrame("V4-" + name + "-actual-time", app: app)
    let skip = app.buttons["practice.feedback.skip"]
    revealCaptureElement(skip, app: app, direction: .up, limit: 12)
    skip.tap()
    let done = app.buttons["practice.saved.done"]
    XCTAssertTrue(done.waitForExistence(timeout: 8))
    captureNativeFrame("V4-" + name + "-saved", app: app)
    XCTAssertTrue(done.isHittable); done.tap()
    XCTAssertTrue(app.tabBars.buttons["呼吸"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.tabBars.buttons["呼吸"].isSelected)
  }

  @MainActor private func waitInRealTime(until deadline: Date, label: String) {
    let remaining = deadline.timeIntervalSinceNow
    guard remaining > 0 else { return }
    let clockReached = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in Date() >= deadline }, object: nil)
    let result = XCTWaiter.wait(for: [clockReached], timeout: remaining + 8)
    XCTAssertEqual(result, .completed, "Real-time capture wait failed: " + label)
  }

  @MainActor private func captureNativeFrame(_ name: String, app: XCUIApplication) {
    let frame = XCTAttachment(screenshot: app.screenshot())
    frame.name = name; frame.lifetime = .keepAlways; add(frame)
  }

  private func marker(_ stage: String, name: String, at date: Date = Date()) {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    print("V4_CAPTURE_" + stage + " " + name + " " + formatter.string(from: date))
  }
}
