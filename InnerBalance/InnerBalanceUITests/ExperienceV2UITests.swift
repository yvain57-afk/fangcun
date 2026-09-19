import XCTest

final class ExperienceV2UITests: XCTestCase {
  @MainActor func testFirstExperienceDelivery() throws {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--readiness-fixture=assessable", "-AppleLanguages", "(zh-Hans)",
      "-AppleLocale", "zh_CN", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO"]
    app.launch()
    let conclusion = app.staticTexts["today.conclusion"]
    XCTAssertTrue(conclusion.waitForExistence(timeout: 12))
    expectation(for: NSPredicate(format: "value == %@", "assessable"), evaluatedWith: conclusion)
    waitForExpectations(timeout: 12)
    XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "看看它")).firstMatch.exists)
    capture("v2-home", app)
    print("V2_CLIP_HOME")
    Thread.sleep(forTimeInterval: 3)
    for _ in 0..<5 where !app.buttons["today.evidence"].isHittable { app.swipeUp() }
    app.buttons["today.evidence"].tap()
    XCTAssertTrue(app.staticTexts["readiness.detail.conclusion"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["readiness.identity"].exists)
    XCTAssertFalse(app.staticTexts["readiness.baseline.reference"].exists)
    capture("v2-detail", app)
    app.navigationBars.buttons.firstMatch.tap()
    for _ in 0..<5 where !app.buttons["today.drinks"].isHittable { app.swipeUp() }
    app.buttons["today.drinks"].tap()
    XCTAssertTrue(app.buttons["增加白水"].waitForExistence(timeout: 5))
    print("V2_CLIP_WATER")
    app.buttons["增加白水"].tap()
    Thread.sleep(forTimeInterval: 2)
    capture("v2-drinks", app)
    app.buttons["完成"].tap()
    for _ in 0..<5 where !app.buttons["today.start"].isHittable { app.swipeDown() }
    app.buttons["today.start"].tap()
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 8))
    print("V2_CLIP_BREATH")
    Thread.sleep(forTimeInterval: 12)
    capture("v2-breathing", app)
    app.buttons["暂停练习"].tap()
    XCTAssertTrue(app.buttons["继续练习"].exists)
  }
  @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
    let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
  }
}
