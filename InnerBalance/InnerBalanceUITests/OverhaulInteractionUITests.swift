import XCTest

final class OverhaulInteractionUITests: XCTestCase {
  @MainActor func testExitOffersContinueAndRestoresRunningSession() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "-fangcun.dark", "NO", "-fangcun.largeType", "NO"]
    app.launch()
    openV4Method("physiologicalSigh", app: app)
    app.buttons["practice.physiologicalSigh.300"].tap()
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 10))
    app.buttons["practice.close"].tap()
    XCTAssertTrue(app.buttons["practice.finish.cancel"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.buttons["practice.finish.confirm"].isHittable)
    app.buttons["practice.finish.cancel"].tap()
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 5))
    app.buttons["Pause practice"].tap()
    XCTAssertTrue(app.staticTexts["Paused"].waitForExistence(timeout: 3))
    app.buttons["End"].tap()
    app.buttons["practice.finish.cancel"].tap()
    XCTAssertTrue(app.buttons["Continue practice"].waitForExistence(timeout: 3))
    XCTAssertFalse(app.buttons["Pause practice"].exists)
  }
  @MainActor func testDrinkCompositeAndManageAreReachableOnInitialSheet() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep375", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryLarge"]
    app.launch()
    app.tabBars.buttons["Daily"].tap()
    let drinks = app.buttons["today.drinks"]
    for _ in 0..<8 where !drinks.isHittable { app.swipeUp() }
    drinks.tap()
    XCTAssertTrue(app.buttons["drinks.add.water"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.switches["Sweetened latte (also log as a sweet drink)"].isHittable)
    XCTAssertTrue(app.buttons["drinks.manage"].isHittable)
    app.buttons["drinks.add.water"].tap()
    XCTAssertEqual(app.staticTexts["drinks.count.water"].label, "1")
    app.buttons["Undo"].tap()
    XCTAssertEqual(app.staticTexts["drinks.count.water"].label, "0")
  }
  @MainActor func testMaximumTypeKeepsPrimaryControlsReachable() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "-fangcun.dark", "NO",
      "-fangcun.largeType", "YES", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
      "-fangcun.practice.v4.quickKind", "physiologicalSigh"]
    app.launch()
    let start = app.buttons["hub.quickStart"]
    XCTAssertTrue(start.waitForExistence(timeout: 10)); XCTAssertTrue(start.isHittable)
    XCTAssertLessThan(start.frame.maxY, app.frame.maxY)
    start.tap()
    let prepare = app.buttons["practice.prepare.start"]
    if prepare.waitForExistence(timeout: 2) {
      XCTAssertTrue(prepare.isHittable); prepare.tap()
    }
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["Pause practice"].isHittable)
    app.buttons["practice.close"].tap()
    XCTAssertTrue(app.buttons["practice.finish.cancel"].waitForExistence(timeout: 5))
    for _ in 0..<6 where !app.buttons["practice.finish.confirm"].isHittable { app.swipeUp() }
    XCTAssertTrue(app.buttons["practice.finish.confirm"].isHittable)
    let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "maximum-type-exit"; shot.lifetime = .keepAlways; add(shot)
    app.buttons["practice.finish.confirm"].tap()
    XCTAssertTrue(app.buttons["practice.feedback.skip"].waitForExistence(timeout: 8))
  }

  @MainActor func testReducedMotionKeepsInstructionsWithoutContinuousResizing() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "-AppleLanguages", "(zh-Hans)",
      "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "YES",
      "-fangcun.motionMode", "standard", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryLarge"]
    app.launch(); openV4Method("balancedBreathing", app: app)
    app.buttons["practice.balancedBreathing.300"].tap()
    if app.buttons["practice.entry.skip"].waitForExistence(timeout: 1) { app.buttons["practice.entry.skip"].tap() }
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 10))
    let title = app.staticTexts["practice.breathPhase"]
    let exhale = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Breathe out"), object: title)
    XCTAssertEqual(XCTWaiter.wait(for: [exhale], timeout: 12), .completed)
    let inhale = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Breathe in"), object: title)
    XCTAssertEqual(XCTWaiter.wait(for: [inhale], timeout: 12), .completed)
    let aura = app.descendants(matching: .any)["practice.breathEnvelope"].firstMatch
    let width = aura.frame.width
    Thread.sleep(forTimeInterval: 1)
    XCTAssertEqual(title.label, "Breathe in")
    XCTAssertEqual(aura.frame.width, width, accuracy: 0.5)
    XCTAssertTrue(app.staticTexts["practice.phaseSeconds"].exists)
    XCTAssertTrue(app.descendants(matching: .any)["practice.phaseTrack"].firstMatch.exists)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "23-减少动态-保留阶段提示"; shot.lifetime = .keepAlways; add(shot)
  }

}
