import XCTest
final class RecoveryActionUITests: XCTestCase {
  @MainActor func testLocalActionPauseEarlyEndSkipThenEditFeedback() throws {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep375", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "YES"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()
    let suggestion = app.buttons["today.start"]
    XCTAssertTrue(suggestion.waitForExistence(timeout: 10))
    for _ in 0..<4 where !suggestion.isHittable { app.swipeUp() }
    suggestion.tap()
    let start = app.buttons["recovery.start"]
    XCTAssertTrue(start.waitForExistence(timeout: 5)); start.tap()
    let pause = app.buttons["recovery.pauseResume"]
    XCTAssertTrue(pause.waitForExistence(timeout: 5)); pause.tap()
    XCTAssertEqual(pause.label, "Continue")
    pause.tap()
    app.buttons["recovery.finish"].tap()
    XCTAssertTrue(app.buttons["recovery.skip"].waitForExistence(timeout: 5))
    app.buttons["recovery.skip"].tap()
    XCTAssertTrue(app.buttons["recovery.done"].waitForExistence(timeout: 5)); app.buttons["recovery.done"].tap()
    openDailySettings(app)
    app.buttons["Small actions and reflections"].tap()
    let record = app.buttons.matching(identifier: "recovery.history.record")
    XCTAssertEqual(record.count, 1); record.firstMatch.tap()
    XCTAssertTrue(app.staticTexts["recovery.feedback.current"].label.contains("Not answered"))
    app.buttons["Uncomfortable"].tap()
    XCTAssertTrue(app.staticTexts["recovery.feedback.current"].label.contains("Uncomfortable"))
    app.navigationBars.buttons.firstMatch.tap()
    app.navigationBars.buttons.firstMatch.tap()
    app.buttons["settings.done"].tap()
    app.tabBars.buttons["Daily"].tap()
    for _ in 0..<5 where !suggestion.isHittable { app.swipeDown() }
    XCTAssertTrue(suggestion.label.contains("座位舒展"))
    // The separate close affordance must also return to a fully interactive Daily screen.
    suggestion.tap()
    XCTAssertTrue(app.buttons["recovery.start"].waitForExistence(timeout: 5))
    let close = app.navigationBars.buttons["Close"]
    XCTAssertTrue(close.waitForExistence(timeout: 5)); XCTAssertTrue(close.isHittable); close.tap()
    XCTAssertFalse(app.buttons["recovery.start"].exists)
    openDailySettings(app)
    app.buttons["settings.done"].tap()
    let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "m303-feedback"; shot.lifetime = .keepAlways; add(shot)
  }
}
