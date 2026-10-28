import XCTest

final class PracticeReturnHomeUITests: XCTestCase {
  @MainActor
  func testCompletedLibraryPracticeReturnsToNowTab() {
    let app = launchPracticeFromLibrary()
    app.buttons["practice.prepare.start"].tap()
    let end = app.buttons["End"]
    XCTAssertTrue(end.waitForExistence(timeout: 5))
    end.tap()
    let confirmEnd = app.buttons["practice.finish.confirm"].firstMatch
    XCTAssertTrue(confirmEnd.waitForExistence(timeout: 3))
    confirmEnd.tap()

    let skip = app.buttons["practice.feedback.skip"]
    XCTAssertTrue(skip.waitForExistence(timeout: 5))
    for _ in 0..<4 where !skip.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(skip.isHittable)
    skip.tap()
    let done = app.buttons["practice.saved.done"]
    XCTAssertTrue(done.waitForExistence(timeout: 5))
    done.tap()

    let now = app.tabBars.buttons["Breathe"]
    XCTAssertTrue(now.waitForExistence(timeout: 5))
    XCTAssertTrue(now.isSelected)
    app.tabBars.buttons["Daily"].tap()
    let saved = app.descendants(matching: .any)["today.latestPractice"].firstMatch
    reveal(saved, app)
    XCTAssertTrue(saved.exists)
    XCTAssertFalse((saved.value as? String ?? "").isEmpty)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "m3-pre-practice-return"; shot.lifetime = .keepAlways; add(shot)
  }

  @MainActor
  func testClosingBeforeStartingKeepsThePracticeTabSelected() {
    let app = launchPracticeFromLibrary()
    app.buttons["practice.close"].tap()

    let practice = app.tabBars.buttons["Breathe"]
    XCTAssertTrue(practice.waitForExistence(timeout: 5))
    XCTAssertTrue(practice.isSelected)
    XCTAssertTrue(app.buttons["hub.quickStart"].exists)
    XCTAssertFalse(app.buttons["Pause practice"].exists)
    app.tabBars.buttons["Daily"].tap()
    XCTAssertFalse(app.descendants(matching: .any)["today.latestPractice"].exists)
    app.tabBars.buttons["Breathe"].tap()
    let launch = app.buttons["practice.physiologicalSigh.60"]
    reveal(launch, app)
    launch.tap()
    XCTAssertTrue(app.buttons["practice.prepare.start"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["Pause practice"].exists)
  }

  @MainActor private func reveal(_ item: XCUIElement, _ app: XCUIApplication) {
    for _ in 0..<5 where !item.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(item.isHittable)
  }

  @MainActor
  private func launchPracticeFromLibrary() -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()
    let practice = app.tabBars.buttons["Breathe"]
    XCTAssertTrue(practice.waitForExistence(timeout: 5))
    practice.tap()
    let launch = app.buttons["practice.physiologicalSigh.60"]
    XCTAssertTrue(launch.waitForExistence(timeout: 5))
    reveal(launch, app)
    launch.tap()
    XCTAssertTrue(app.buttons["practice.prepare.start"].waitForExistence(timeout: 5))
    return app
  }
}
