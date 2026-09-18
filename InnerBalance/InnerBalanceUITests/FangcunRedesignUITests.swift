import XCTest

final class FangcunRedesignUITests: XCTestCase {
  @MainActor
  func testNativeTodayDrinksTrendsPracticeAndSettings() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "YES"]
    app.launch()
    XCTAssertTrue(app.staticTexts["today.conclusion"].waitForExistence(timeout: 15))
    XCTAssertFalse(app.buttons["home.echo.state.calm"].exists)
    XCTAssertTrue(app.buttons["today.start"].isHittable)
    capture("redesign-home", app)
    reveal(app.buttons["today.drinks"], app)
    app.buttons["today.drinks"].tap()
    let addWater = app.buttons["增加白水"]
    XCTAssertTrue(addWater.waitForExistence(timeout: 5))
    addWater.tap()
    app.buttons["增加美式"].tap()
    XCTAssertTrue(app.descendants(matching: .any)["drinks.totals"].firstMatch.label.contains("550"))
    app.buttons["撤销"].tap()
    XCTAssertTrue(app.descendants(matching: .any)["drinks.totals"].firstMatch.label.contains("250"))
    capture("redesign-drinks", app)
    app.buttons["完成"].tap()
    reveal(app.buttons["today.trends"], app)
    app.buttons["today.trends"].tap()
    XCTAssertTrue(app.staticTexts["trends.snapshot"].waitForExistence(timeout: 5))
    capture("redesign-trends", app)
    app.navigationBars.buttons.firstMatch.tap()
    for _ in 0..<4 where !app.buttons["today.start"].isHittable { app.scrollViews.firstMatch.swipeDown() }
    app.buttons["today.start"].tap()
    let pause = app.buttons["暂停练习"]
    XCTAssertTrue(pause.waitForExistence(timeout: 10))
    capture("redesign-breathing", app)
    pause.tap()
    XCTAssertTrue(app.staticTexts["已暂停"].waitForExistence(timeout: 4))
    app.buttons["继续练习"].tap()
    XCTAssertTrue(pause.waitForExistence(timeout: 4))
    app.buttons["结束"].tap()
    app.buttons["结束练习"].tap()
    let finish = app.buttons["先完成"]
    XCTAssertTrue(finish.waitForExistence(timeout: 6))
    reveal(finish, app)
    finish.tap()
    let done = app.buttons["practice.saved.done"]
    XCTAssertTrue(done.waitForExistence(timeout: 8))
    capture("redesign-completion", app)
    done.tap()
    app.tabBars.buttons["设置"].tap()
    XCTAssertTrue(app.switches["深色模式"].waitForExistence(timeout: 5))
    capture("redesign-settings", app)
  }

  @MainActor
  func testBreathingWithMotionEnabledCanPauseAndExit() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO"]
    app.launch()
    XCTAssertTrue(app.buttons["today.start"].waitForExistence(timeout: 10))
    app.buttons["today.start"].tap()
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["双吸一呼"].exists)
    let exhale = NSPredicate(format: "label == %@", "呼气")
    expectation(for: exhale, evaluatedWith: app.staticTexts["practice.breathPhase"])
    waitForExpectations(timeout: 12)
    capture("redesign-breathing-live", app)
    app.buttons["暂停练习"].tap()
    XCTAssertTrue(app.staticTexts["已暂停"].waitForExistence(timeout: 5))
    capture("redesign-breathing-paused", app)
    app.buttons["结束"].tap()
    app.buttons["结束练习"].tap()
    XCTAssertTrue(app.buttons["先完成"].waitForExistence(timeout: 5))
  }

  @MainActor
  func testAcceptedSoloAndDuoScenesInDarkAndLargeType() {
    continueAfterFailure = false
    let app = XCUIApplication()
    for (state, title) in [("steady", "今日压力负荷平稳"), ("elevated", "今日身体负荷偏高"), ("insufficient", "还需要一点身体线索")] {
      app.launchArguments = ["--ui-testing", "--preview-state=\(state)", "-fangcun.dark", state == "elevated" ? "YES" : "NO", "-fangcun.largeType", state == "insufficient" ? "YES" : "NO", "-fangcun.reduceMotion", "YES"]
      app.launch()
      XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10))
      capture("redesign-\(state)", app)
      reveal(app.buttons["today.start"], app)
      XCTAssertTrue(app.buttons["today.start"].isHittable)
      app.terminate()
    }
  }
  @MainActor private func reveal(_ element: XCUIElement, _ app: XCUIApplication) {
    for _ in 0..<6 where !element.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(element.isHittable)
  }
  @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = name; shot.lifetime = .keepAlways; add(shot)
  }
}
