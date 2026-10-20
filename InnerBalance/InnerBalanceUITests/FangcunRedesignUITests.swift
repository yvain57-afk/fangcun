import XCTest

final class FangcunRedesignUITests: XCTestCase {
  @MainActor
  func testDisplayPreferencesSurviveRelaunch() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep480"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()
    openDailySettings(app)
    let labels = ["深色模式", "较大字号", "减少动态效果"]
    for label in labels {
      let toggle = app.switches[label]
      for _ in 0..<5 where !toggle.isHittable { app.scrollViews.firstMatch.swipeUp() }
      XCTAssertTrue(toggle.exists)
      if toggle.value as? String != "1" {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
      }
      XCTAssertEqual(toggle.value as? String, "1", "Immediate value: \(label)")
    }
    app.terminate()
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()
    openDailySettings(app)
    for label in labels { XCTAssertEqual(app.switches[label].value as? String, "1", "Relaunch value: \(label)") }
    capture("preferences-relaunch", app)
    // Keep the shared simulator preferences neutral for subsequent visual tests.
    for label in labels {
      let toggle = app.switches[label]
      for _ in 0..<5 where !toggle.isHittable { app.scrollViews.firstMatch.swipeUp() }
      toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
    }
  }

  @MainActor
  func testNativeTodayDrinksTrendsPracticeAndSettings() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep480", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "YES"]
    app.launchArguments += ["-status-v3.avoidBreathing", "NO", "-status-v3.favorite", "breath"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()
    XCTAssertTrue(app.staticTexts["status.band"].waitForExistence(timeout: 15))
    XCTAssertFalse(app.buttons["home.echo.state.calm"].exists)
    XCTAssertTrue(app.buttons["today.start"].isHittable)
    capture("redesign-home", app)
    reveal(app.buttons["today.drinks"], app)
    app.buttons["today.drinks"].tap()
    let addWater = app.buttons["drinks.add.water"]
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
    XCTAssertTrue(app.buttons["status.history.score"].waitForExistence(timeout: 5))
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
    app.buttons["practice.finish.confirm"].firstMatch.tap()
    let finish = app.buttons["practice.feedback.skip"]
    XCTAssertTrue(finish.waitForExistence(timeout: 6))
    reveal(finish, app)
    finish.tap()
    let done = app.buttons["practice.saved.done"]
    XCTAssertTrue(done.waitForExistence(timeout: 8))
    capture("redesign-completion", app)
    done.tap()
    openDailySettings(app)
    XCTAssertTrue(app.switches["深色模式"].waitForExistence(timeout: 5))
    capture("redesign-settings", app)
  }

  @MainActor
  func testBreathingWithMotionEnabledCanPauseAndExit() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep480", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO"]
    app.launchArguments += ["-status-v3.avoidBreathing", "NO", "-status-v3.favorite", "breath"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()
    XCTAssertTrue(app.staticTexts["100"].waitForExistence(timeout: 12))
    XCTAssertTrue(app.buttons["today.start"].waitForExistence(timeout: 10))
    app.buttons["today.start"].tap()
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["舒缓紧张"].exists)
    let exhale = NSPredicate(format: "label == %@", "呼气")
    expectation(for: exhale, evaluatedWith: app.staticTexts["practice.breathPhase"])
    waitForExpectations(timeout: 12)
    capture("redesign-breathing-live", app)
    app.buttons["暂停练习"].tap()
    XCTAssertTrue(app.staticTexts["已暂停"].waitForExistence(timeout: 5))
    capture("redesign-breathing-paused", app)
    app.buttons["结束"].tap()
    app.buttons["practice.finish.confirm"].firstMatch.tap()
    XCTAssertTrue(app.buttons["practice.feedback.skip"].waitForExistence(timeout: 5))
  }

  @MainActor
  func testAcceptedSoloAndDuoScenesInDarkAndLargeType() {
    continueAfterFailure = false
    let app = XCUIApplication()
    for state in ["480", "240", "45"] {
      app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep\(state)", "-fangcun.dark", state == "240" ? "YES" : "NO", "-fangcun.largeType", state == "45" ? "YES" : "NO", "-fangcun.reduceMotion", "YES"]
      app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()
      XCTAssertTrue(app.staticTexts["status.band"].waitForExistence(timeout: 10))
      XCTAssertEqual(app.staticTexts["status.band"].label, state == "480" ? "良好" : state == "240" ? "偏低" : "优先休息")
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
