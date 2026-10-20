import XCTest

/// V3 replaces the legacy homepage availability enum. Legacy algorithm assertions remain in App/Core tests.
final class ReadinessHomeUITests: XCTestCase {
  @MainActor func testAssessable() throws { try verify("assessable", band:"良好") }
  @MainActor func testProvisional() throws { try verify("provisional", band:"良好") }
  @MainActor func testLimited() throws { try verify("limited", band:"良好") }
  @MainActor func testInsufficient() throws { try verify("insufficient", band:nil) }
  @MainActor func testAwaiting() throws { try verify("awaitingData", band:"良好") }
  @MainActor func testFailed() throws { try verify("failed", band:nil) }
  @MainActor func testHistoryIdentityAndAccessibleLargeDarkLayout() throws {
    let app = launch("scoreSleep375",large:true)
    XCTAssertTrue(app.staticTexts["尚可"].waitForExistence(timeout:12))
    reveal(app.buttons["today.evidence"],app); app.buttons["today.evidence"].tap()
    let title = app.staticTexts["status.detail.score"].label
    XCTAssertTrue(title.contains("78"))
    capture("v3-dark-large-detail",app)
    app.navigationBars.buttons.firstMatch.tap()
    reveal(app.buttons["today.trends"],app); app.buttons["today.trends"].tap()
    XCTAssertTrue(app.segmentedControls["readiness.history.range"].waitForExistence(timeout:5))
    app.buttons["28 天"].tap()
    let row = app.buttons["status.history.score"]
    reveal(row,app); row.tap()
    XCTAssertEqual(app.staticTexts["status.detail.score"].label,title)
    XCTAssertFalse(app.staticTexts["readiness.identity"].exists)
  }
  @MainActor func testBreathingRoundTripKeepsCurrentAssessmentWithoutReward() throws {
    let app = launch("scoreSleep480")
    XCTAssertTrue(app.staticTexts["100"].waitForExistence(timeout:12))
    let cycle = app.staticTexts["status.cycle"].value as? String
    app.buttons["today.start"].tap()
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout:10))
    app.buttons["结束"].tap(); app.buttons["practice.finish.confirm"].firstMatch.tap()
    let skip = app.buttons["practice.feedback.skip"]
    XCTAssertTrue(skip.waitForExistence(timeout:6)); reveal(skip,app); skip.tap()
    XCTAssertTrue(app.buttons["practice.saved.done"].waitForExistence(timeout:8)); app.buttons["practice.saved.done"].tap()
    XCTAssertTrue(app.tabBars.buttons["呼吸"].isSelected)
    app.tabBars.buttons["日常"].tap()
    reveal(app.staticTexts["today.latestPractice"],app)
    XCTAssertFalse((app.staticTexts["today.latestPractice"].value as? String ?? "").isEmpty)
    for _ in 0..<6 where !app.staticTexts["100"].isHittable { app.swipeDown() }
    XCTAssertTrue(app.staticTexts["100"].exists)
    XCTAssertEqual(app.staticTexts["status.cycle"].value as? String,cycle)
  }
  @MainActor private func verify(_ scenario:String,band:String?) throws {
    let app = launch(scenario)
    if let band {
      XCTAssertTrue(app.staticTexts[band].waitForExistence(timeout:12))
      reveal(app.buttons["today.evidence"],app); app.buttons["today.evidence"].tap()
      XCTAssertTrue(app.staticTexts["status.detail.score"].waitForExistence(timeout:5))
      XCTAssertFalse(app.staticTexts["readiness.identity"].exists)
      XCTAssertFalse(app.staticTexts["有限线索"].exists)
    } else {
      XCTAssertTrue(app.staticTexts["status.empty"].waitForExistence(timeout:12))
      XCTAssertFalse(app.staticTexts["status.score"].exists)
      XCTAssertTrue(app.buttons["today.start"].exists)
      XCTAssertTrue(app.buttons["status.manual"].exists)
    }
    capture("v3-home-"+scenario,app)
    // Diagnostic data and time labels remain reachable separately from the consumer score screen.
    openDailySettings(app); app.buttons["恢复参考与来源"].tap()
    app.buttons["readiness.diagnostics"].tap()
    XCTAssertTrue(app.staticTexts["readiness.identity"].waitForExistence(timeout:5))
    reveal(app.staticTexts["readiness.time.attempt"],app)
    XCTAssertTrue(app.staticTexts["readiness.time.attempt"].exists)
  }
  @MainActor private func launch(_ scenario:String,large:Bool=false)->XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction","--readiness-fixture="+scenario,"-AppleLanguages","(zh-Hans)","-AppleLocale","zh_CN","-fangcun.dark",large ? "YES":"NO","-fangcun.largeType",large ? "YES":"NO","-fangcun.reduceMotion","YES"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap(); return app
  }
  @MainActor private func reveal(_ item:XCUIElement,_ app:XCUIApplication) {
    for _ in 0..<8 where !item.isHittable { app.swipeUp() }; XCTAssertTrue(item.isHittable)
  }
  @MainActor private func capture(_ name:String,_ app:XCUIApplication) {
    let a = XCTAttachment(screenshot:app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
  }
}
