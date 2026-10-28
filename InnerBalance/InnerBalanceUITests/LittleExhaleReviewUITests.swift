import XCTest

/// Runs the actual screens and clocks with synthetic, in-memory records only.
final class LittleExhaleReviewUITests: XCTestCase {
  @MainActor private func launch(_ kind: String = "physiologicalSigh", dark: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled",
      "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN", "-fangcun.dark", dark ? "YES" : "NO",
      "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO", "-fangcun.motionMode", "standard",
      "-fangcun.practice.v4.quickKind", kind, "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryLarge"]
    app.launch()
    XCTAssertTrue(app.buttons["hub.quickStart"].waitForExistence(timeout: 10))
    return app
  }
  @MainActor private func capture(_ name: String, app: XCUIApplication) {
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "LE2-" + name; shot.lifetime = .keepAlways; add(shot)
  }
  @MainActor func testAllTenRealPracticeStages() {
    for kind in ["physiologicalSigh", "pacedBreathing", "balancedBreathing", "boxBreathing", "diaphragmaticBreathing", "alternateNostrilBreathing", "meditation", "nsdr", "kegel", "progressiveMuscleRelaxation"] {
      let app = launch(kind)
      if kind == "physiologicalSigh" { capture("home-light", app: app) }
      app.buttons["hub.quickStart"].tap()
      let prepare = app.buttons["practice.prepare.start"]
      if prepare.waitForExistence(timeout: 2) { prepare.tap() }
      let pause = app.buttons["Pause practice"]
      XCTAssertTrue(pause.waitForExistence(timeout: 10))
      let character = app.descendants(matching: .any)["practice.companion"].firstMatch
      XCTAssertTrue(character.exists, kind)
      XCTAssertGreaterThan(character.frame.height, 100, kind)
      capture(kind + "-start", app: app)
      RunLoop.current.run(until: Date().addingTimeInterval(4))
      capture(kind + "-next-phase", app: app)
      pause.tap()
      XCTAssertTrue(app.buttons["Continue practice"].exists)
      capture(kind + "-paused", app: app)
      app.terminate()
    }
  }
  @MainActor func testStorePhoneScreenshots() {
    for kind in ["physiologicalSigh", "balancedBreathing", "nsdr"] {
      let app = launch(kind)
      if kind == "physiologicalSigh" { capture("store-home-light", app: app) }
      app.buttons["hub.quickStart"].tap()
      let prepare = app.buttons["practice.prepare.start"]
      if prepare.waitForExistence(timeout: 2) { prepare.tap() }
      XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 10))
      XCTAssertTrue(app.descendants(matching: .any)["practice.companion"].firstMatch.exists)
      capture("store-" + kind, app: app)
      app.terminate()
    }
    let app = launch(dark: true)
    app.buttons["Daily"].tap()
    XCTAssertTrue(app.buttons["today.drinks"].waitForExistence(timeout: 5))
    capture("store-daily-dark", app: app)
    app.buttons["today.drinks"].tap()
    XCTAssertTrue(app.buttons["drinks.add.water"].waitForExistence(timeout: 5))
    capture("store-drinks-dark", app: app)
  }
  @MainActor func testEnglishDailyAndDarkPracticeOnChineseSystem() {
    let app = launch(dark: true)
    capture("home-dark", app: app)
    app.buttons["Daily"].tap()
    XCTAssertTrue(app.buttons["home.checkIn"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["today.drinks"].isHittable)
    XCTAssertFalse(app.buttons["today.start"].isHittable)
    for text in app.staticTexts.allElementsBoundByIndex where text.isHittable {
      XCTAssertNil(text.label.range(of: "[\\u4e00-\\u9fff]", options: .regularExpression), text.label)
    }
    capture("daily-dark", app: app)
    app.buttons["today.drinks"].tap()
    XCTAssertTrue(app.buttons["drinks.add.water"].waitForExistence(timeout: 5))
    capture("drinks-dark", app: app)
  }
}
