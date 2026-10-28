import XCTest

final class StatusScoreV3UITests: XCTestCase {
  @MainActor func testFirstNightRawSleepPublishes78AndRealAction() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep375", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()
    XCTAssertTrue(app.staticTexts["尚可"].waitForExistence(timeout: 12))
    XCTAssertTrue(app.staticTexts["78"].exists)
    XCTAssertTrue(app.buttons["today.start"].isHittable)
    XCTAssertTrue(app.buttons["today.start"].label.contains("2 minutes of quiet rest"))
    assertClean(app); capture("s1-score-78", app)
    app.buttons["today.evidence"].tap()
    XCTAssertTrue(app.staticTexts["status.detail.score"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["睡眠 · 78 分"].exists)
    XCTAssertFalse(app.staticTexts["静息心率 · 0 分"].exists)
    assertClean(app); capture("s1-score-composition", app)
    app.buttons["status.method"].tap()
    XCTAssertTrue(app.staticTexts["本次计入：睡眠"].exists)
    app.navigationBars.buttons.firstMatch.tap()
    app.buttons["today.start"].tap()
    XCTAssertTrue(app.buttons["recovery.start"].waitForExistence(timeout: 5))
    app.buttons["recovery.start"].tap()
    XCTAssertTrue(app.buttons["recovery.pauseResume"].waitForExistence(timeout: 5))
    capture("s1-real-rest-action", app)
    app.buttons["recovery.finish"].tap()
    XCTAssertTrue(app.buttons["recovery.skip"].waitForExistence(timeout: 5)); app.buttons["recovery.skip"].tap()
    app.buttons["recovery.done"].tap()
    XCTAssertTrue(app.staticTexts["78"].waitForExistence(timeout: 5))
  }
  @MainActor func testNightKeeps78AndStartsShortBreathingThenForegroundStillClean() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction","--readiness-fixture=scoreSleep375","--score-night","-fangcun.dark","YES","-fangcun.largeType","NO","-fangcun.reduceMotion","YES"]
    app.launchArguments += ["-status-v3.avoidBreathing", "NO"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()
    XCTAssertTrue(app.staticTexts["78"].waitForExistence(timeout:12))
    XCTAssertTrue(app.staticTexts["Consider an earlier wind-down tonight."].exists)
    XCTAssertTrue(app.buttons["today.start"].label.contains("2 分钟放松"))
    assertClean(app); capture("v3-night-2322",app)
    XCUIDevice.shared.press(.home); app.activate()
    XCTAssertTrue(app.staticTexts["78"].waitForExistence(timeout:5)); assertClean(app)
    app.buttons["today.start"].tap()
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout:8))
    capture("v3-night-real-breathing",app)
    app.buttons["Pause practice"].tap()
    XCTAssertTrue(app.buttons["Continue practice"].exists)
  }
  @MainActor func testEmptyCanSaveActualSleepWithoutConnectingHealth() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction","--readiness-fixture=insufficient","-fangcun.dark","NO","-fangcun.largeType","NO"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()
    XCTAssertTrue(app.staticTexts["status.empty"].waitForExistence(timeout:12))
    XCTAssertFalse(app.staticTexts["status.score"].exists); assertClean(app)
    app.buttons["status.manual"].tap()
    XCTAssertTrue(app.buttons["status.manual.save"].waitForExistence(timeout:5)); app.buttons["status.manual.save"].tap()
    XCTAssertTrue(app.staticTexts["78"].waitForExistence(timeout:8))
    app.buttons["today.evidence"].tap()
    app.buttons["status.method"].tap()
    XCTAssertTrue(app.staticTexts["Sleep was added by you."].exists)
    capture("v3-manual-sleep",app)
  }
  @MainActor func testMaximumTypeDarkModeScoreAndActionRemainReachable() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction","--readiness-fixture=scoreSleep375","-fangcun.dark","YES","-fangcun.largeType","YES","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL","-fangcun.reduceMotion","YES"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()
    XCTAssertTrue(app.staticTexts["78"].waitForExistence(timeout:12))
    let settingsControl = app.buttons["daily.settings"]
    let brand = app.descendants(matching: .any).matching(identifier: "daily.title").firstMatch
    XCTAssertLessThanOrEqual(brand.frame.maxX, settingsControl.frame.minX)
    XCTAssertGreaterThanOrEqual(settingsControl.frame.width, 44)
    XCTAssertGreaterThanOrEqual(settingsControl.frame.height, 44)
    assertClean(app); capture("v3-dark-maximum-home",app)
    let action = app.buttons["today.start"]
    for _ in 0..<6 where !action.isHittable { app.swipeUp() }
    XCTAssertTrue(action.isHittable); action.tap()
    let start = app.buttons["recovery.start"]
    XCTAssertTrue(start.waitForExistence(timeout:5))
    for _ in 0..<6 where !start.isHittable { app.swipeUp() }
    XCTAssertTrue(start.isHittable)
  }
  @MainActor private func assertClean(_ app: XCUIApplication) {
    for phrase in ["Limited context","有限资料","An early reference","A suggestion based on sleep","不是整体恢复结论","不代表整体状态","这条建议只基于已有线索","不是完整恢复结论","仍需更多线索","资料不足以判断"] {
      XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", phrase)).firstMatch.exists)
    }
  }
  @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
    let item = XCTAttachment(screenshot: app.screenshot()); item.name = name; item.lifetime = .keepAlways; add(item)
  }
}
