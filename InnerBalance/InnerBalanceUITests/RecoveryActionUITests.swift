import XCTest
final class RecoveryActionUITests: XCTestCase {
  @MainActor func testLocalActionPauseEarlyEndSkipThenEditFeedback() throws {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--readiness-fixture=insufficient", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "YES"]
    app.launch()
    let suggestion = app.buttons["recovery.suggestion"]
    XCTAssertTrue(suggestion.waitForExistence(timeout: 10))
    for _ in 0..<4 where !suggestion.isHittable { app.swipeUp() }
    suggestion.tap()
    let start = app.buttons["recovery.start"]
    XCTAssertTrue(start.waitForExistence(timeout: 5)); start.tap()
    let pause = app.buttons["recovery.pauseResume"]
    XCTAssertTrue(pause.waitForExistence(timeout: 5)); pause.tap()
    XCTAssertEqual(pause.label, "继续")
    pause.tap()
    app.buttons["recovery.finish"].tap()
    XCTAssertTrue(app.buttons["recovery.skip"].waitForExistence(timeout: 5))
    app.buttons["recovery.skip"].tap()
    XCTAssertTrue(app.buttons["recovery.done"].waitForExistence(timeout: 5)); app.buttons["recovery.done"].tap()
    app.tabBars.buttons["设置"].tap()
    app.buttons["行动与反馈记录"].tap()
    let record = app.buttons.matching(identifier: "recovery.history.record")
    XCTAssertEqual(record.count, 1); record.firstMatch.tap()
    XCTAssertTrue(app.staticTexts["recovery.feedback.current"].label.contains("未回答"))
    app.buttons["不舒服"].tap()
    XCTAssertTrue(app.staticTexts["recovery.feedback.current"].label.contains("不舒服"))
    let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "m303-feedback"; shot.lifetime = .keepAlways; add(shot)
  }
}
