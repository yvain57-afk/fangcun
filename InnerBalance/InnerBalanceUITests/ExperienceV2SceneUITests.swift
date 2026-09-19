import XCTest

final class ExperienceV2SceneUITests: XCTestCase {
  @MainActor private func launch(_ scenario: String, dark: Bool = false, large: Bool = false, motion: String = "standard") -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--readiness-fixture=" + scenario, "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN",
      "-fangcun.dark", dark ? "YES" : "NO", "-fangcun.largeType", large ? "YES" : "NO", "-fangcun.reduceMotion", "NO", "-fangcun.motionMode", motion]
    if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
    app.launch()
    XCTAssertTrue(app.staticTexts["today.conclusion"].waitForExistence(timeout: 12))
    return app
  }
  @MainActor func testDistinctCurrentConclusionsAndSceneEntry() {
    for (scenario, title) in [("assessable", "恢复接近平常"), ("reduced", "今天建议放缓一点"), ("low", "今天优先安排恢复"), ("insufficient", "今天的判断还没形成")] {
      let app = launch(scenario)
      expectation(for: NSPredicate(format: "label == %@", title), evaluatedWith: app.staticTexts["today.conclusion"])
      waitForExpectations(timeout: 10)
      Thread.sleep(forTimeInterval: 2)
      capture("scene-" + scenario, app)
      XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "看看它")).firstMatch.exists)
      app.terminate()
    }
  }
  @MainActor func testWaterCoffeeAlcoholAndUndoShowCommittedFeedback() {
    let app = launch("assessable")
    reveal(app.buttons["today.drinks"], app); app.buttons["today.drinks"].tap()
    XCTAssertTrue(app.buttons["drinks.add.water"].waitForExistence(timeout: 5))
    for (button, scene) in [("drinks.add.water", "water"), ("drinks.add.coffee", "coffee"), ("drinks.add.beer", "alcohol")] {
      reveal(app.buttons[button], app); app.buttons[button].tap()
      XCTAssertEqual(app.staticTexts["drinks.feedback"].label, "这杯已经记好。")
      Thread.sleep(forTimeInterval: 1.5)
      capture("scene-drink-" + scene, app)
    }
    app.buttons["撤销"].tap()
    XCTAssertEqual(app.staticTexts["drinks.feedback"].label, "已撤销上一笔。")
    Thread.sleep(forTimeInterval: 1)
    capture("scene-drink-undo", app)
    XCTAssertTrue(app.descendants(matching: .any)["drinks.totals"].firstMatch.label.contains("550"))
  }
  @MainActor func testActualMinuteCompletesBeforePawTouchSaveScreen() {
    let app = launch("assessable")
    app.tabBars.buttons["练习"].tap()
    app.buttons["practice.physiologicalSigh.60"].tap()
    XCTAssertTrue(app.buttons["practice.prepare.start"].waitForExistence(timeout: 5))
    app.buttons["practice.prepare.start"].tap()
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 5))
    let finish = app.buttons["先完成"]
    XCTAssertTrue(finish.waitForExistence(timeout: 70))
    reveal(finish, app); finish.tap()
    XCTAssertTrue(app.buttons["practice.saved.done"].waitForExistence(timeout: 6))
    Thread.sleep(forTimeInterval: 2)
    capture("scene-completed", app)
  }
  @MainActor func testOneDayDarkMaximumTypeHasScopedFactsAndNoPersonalRange() {
    let app = launch("oneDay", dark: true, large: true, motion: "static")
    expectation(for: NSPredicate(format: "label == %@", "基于睡眠的今日建议"), evaluatedWith: app.staticTexts["today.conclusion"])
    waitForExpectations(timeout: 12)
    capture("scene-dark-large-home", app)
    reveal(app.buttons["today.evidence"], app); app.buttons["today.evidence"].tap()
    XCTAssertTrue(app.staticTexts["readiness.detail.conclusion"].waitForExistence(timeout: 5))
    capture("scene-dark-large-detail", app)
    reveal(app.buttons["readiness.method"], app); app.buttons["readiness.method"].tap()
    XCTAssertFalse(app.staticTexts["readiness.baseline.reference"].exists)
    XCTAssertFalse(app.staticTexts["readiness.identity"].exists)
    app.navigationBars.buttons.firstMatch.tap()
    reveal(app.buttons["today.drinks"], app); app.buttons["today.drinks"].tap()
    XCTAssertTrue(app.buttons["drinks.add.water"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["drinks.add.water"].isHittable)
    capture("scene-dark-large-drinks", app)
    app.buttons["drinks.add.water"].tap()
    let undo = app.buttons["撤销"]
    reveal(undo, app)
    XCTAssertTrue(app.descendants(matching: .any)["drinks.totals"].firstMatch.label.contains("250"))
    capture("scene-dark-large-drink-summary", app)
    undo.tap()
    XCTAssertTrue(app.descendants(matching: .any)["drinks.totals"].firstMatch.label.contains("0"))
  }
  @MainActor private func reveal(_ item: XCUIElement, _ app: XCUIApplication) {
    for _ in 0..<8 where !item.isHittable { app.swipeUp() }
    XCTAssertTrue(item.isHittable)
  }
  @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
    let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
  }
}
