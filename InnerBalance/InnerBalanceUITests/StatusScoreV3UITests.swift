import XCTest

final class StatusScoreV3UITests: XCTestCase {
  @MainActor func testFirstNightRawSleepPublishes78AndRealAction() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--readiness-fixture=scoreSleep375", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO"]
    app.launch()
    XCTAssertTrue(app.staticTexts["尚可"].waitForExistence(timeout: 12))
    XCTAssertTrue(app.staticTexts["78"].exists)
    XCTAssertTrue(app.buttons["today.start"].isHittable)
    XCTAssertTrue(app.buttons["today.start"].label.contains("2 分钟安静休息"))
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
  @MainActor private func assertClean(_ app: XCUIApplication) {
    for phrase in ["有限线索","有限资料","初步参考","基于睡眠的今日建议","不是整体恢复结论","不代表整体状态"] {
      XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", phrase)).firstMatch.exists)
    }
  }
  @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
    let item = XCTAttachment(screenshot: app.screenshot()); item.name = name; item.lifetime = .keepAlways; add(item)
  }
}
