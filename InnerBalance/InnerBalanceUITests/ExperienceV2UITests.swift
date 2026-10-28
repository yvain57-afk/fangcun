import XCTest

final class ExperienceV2UITests: XCTestCase {
  @MainActor func testFirstExperienceDelivery() throws {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep480", "-AppleLanguages", "(zh-Hans)",
      "-AppleLocale", "zh_CN", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()
    let conclusion = app.staticTexts["status.band"]
    XCTAssertTrue(conclusion.waitForExistence(timeout: 12))
    expectation(for: NSPredicate(format: "label == %@", "良好"), evaluatedWith: conclusion)
    waitForExpectations(timeout: 12)
    XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "看看它")).firstMatch.exists)
    capture("v2-home", app)
    print("V2_CLIP_HOME")
    Thread.sleep(forTimeInterval: 3)
    for _ in 0..<5 where !app.buttons["today.evidence"].isHittable { app.swipeUp() }
    app.buttons["today.evidence"].tap()
    XCTAssertTrue(app.staticTexts["status.detail.score"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["readiness.identity"].exists)
    XCTAssertFalse(app.staticTexts["readiness.baseline.reference"].exists)
    capture("v2-detail", app)
    app.navigationBars.buttons.firstMatch.tap()
    for _ in 0..<5 where !app.buttons["today.drinks"].isHittable { app.swipeUp() }
    app.buttons["today.drinks"].tap()
    XCTAssertTrue(app.buttons["drinks.add.water"].waitForExistence(timeout: 5))
    print("V2_CLIP_WATER")
    app.buttons["drinks.add.water"].tap()
    Thread.sleep(forTimeInterval: 2)
    capture("v2-drinks", app)
    app.buttons["Done"].tap()
    for _ in 0..<5 where !app.buttons["today.start"].isHittable { app.swipeDown() }
    app.buttons["today.start"].tap()
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 8))
    print("V2_CLIP_BREATH")
    Thread.sleep(forTimeInterval: 12)
    capture("v2-breathing", app)
    app.buttons["Pause practice"].tap()
    XCTAssertTrue(app.buttons["Continue practice"].exists)
  }
  @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
    let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
  }
}
