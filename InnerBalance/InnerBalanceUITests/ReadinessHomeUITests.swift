import XCTest

final class ReadinessHomeUITests: XCTestCase {
  @MainActor func testAssessable() throws { try verify("assessable") }
  @MainActor func testProvisional() throws { try verify("provisional") }
  @MainActor func testLimited() throws { try verify("limited") }
  @MainActor func testInsufficient() throws { try verify("insufficient") }
  @MainActor func testAwaiting() throws { try verify("awaitingData") }
  @MainActor func testFailed() throws { try verify("failed") }
  @MainActor func testHistoryIdentityAndAccessibleLargeDarkLayout() throws {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--readiness-fixture=assessable", "-fangcun.dark", "YES", "-fangcun.largeType", "YES", "-fangcun.reduceMotion", "YES"]
    app.launch()
    XCTAssertTrue(app.staticTexts["today.conclusion"].waitForExistence(timeout: 10))
    let home = XCTAttachment(screenshot: app.screenshot()); home.name = "m302-dark-large-home"; home.lifetime = .keepAlways; add(home)
    for _ in 0..<5 where !app.buttons["today.evidence"].isHittable { app.swipeUp() }
    app.buttons["today.evidence"].tap()
    let identity = app.staticTexts["readiness.identity"]
    XCTAssertTrue(identity.waitForExistence(timeout: 5))
    let id = try XCTUnwrap(identity.value as? String)
    let detail = XCTAttachment(screenshot: app.screenshot()); detail.name = "m302-dark-large-detail"; detail.lifetime = .keepAlways; add(detail)
    app.navigationBars.buttons.firstMatch.tap()
    for _ in 0..<6 where !app.buttons["today.trends"].isHittable { app.swipeUp() }
    app.buttons["today.trends"].tap()
    XCTAssertTrue(app.segmentedControls["readiness.history.range"].waitForExistence(timeout: 5))
    app.buttons["28 天"].tap()
    let day = app.buttons["readiness.history.day.recorded"].firstMatch
    XCTAssertTrue(day.waitForExistence(timeout: 5)); day.tap()
    let row = app.buttons["readiness.history.assessment"].firstMatch
    for _ in 0..<5 where !row.isHittable { app.swipeUp() }
    XCTAssertTrue(row.exists); row.tap()
    XCTAssertEqual(app.staticTexts["readiness.identity"].value as? String, id)
  }
  @MainActor private func verify(_ scenario: String) throws {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "--readiness-fixture=" + scenario, "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
      app.launch()
      let conclusion = app.staticTexts["today.conclusion"]
      XCTAssertTrue(conclusion.waitForExistence(timeout: 10))
      let predicate = NSPredicate(format: "value == %@", scenario)
      expectation(for: predicate, evaluatedWith: conclusion)
      waitForExpectations(timeout: 15)
      XCTAssertTrue(app.buttons["today.start"].exists)
      app.swipeUp()
      let detail = app.buttons["today.evidence"]
      XCTAssertTrue(detail.waitForExistence(timeout: 5)); detail.tap()
      XCTAssertTrue(app.staticTexts["readiness.identity"].waitForExistence(timeout: 5))
      for _ in 0..<4 where !app.staticTexts["readiness.time.attempt"].exists { app.swipeUp() }
      XCTAssertTrue(app.staticTexts["readiness.time.attempt"].exists)
      let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "m302-" + scenario; shot.lifetime = .keepAlways; add(shot)
      app.terminate()
  }
}
