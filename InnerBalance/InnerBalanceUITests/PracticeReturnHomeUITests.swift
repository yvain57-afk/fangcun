import XCTest

final class PracticeReturnHomeUITests: XCTestCase {
  @MainActor
  func testCompletedLibraryPracticeReturnsToNowTab() {
    let app = launchPracticeFromLibrary()
    app.buttons["开始 1 分钟练习"].tap()
    let end = app.buttons["结束"]
    XCTAssertTrue(end.waitForExistence(timeout: 5))
    end.tap()
    let confirmEnd = app.buttons["结束练习"]
    XCTAssertTrue(confirmEnd.waitForExistence(timeout: 3))
    confirmEnd.tap()

    let skip = app.buttons["先完成"]
    XCTAssertTrue(skip.waitForExistence(timeout: 5))
    for _ in 0..<4 where !skip.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(skip.isHittable)
    skip.tap()
    let done = app.buttons["practice.saved.done"]
    XCTAssertTrue(done.waitForExistence(timeout: 5))
    done.tap()

    let now = app.tabBars.buttons["此刻"]
    XCTAssertTrue(now.waitForExistence(timeout: 5))
    XCTAssertTrue(now.isSelected)
    XCTAssertTrue(app.descendants(matching: .any)["home.latestPractice"].exists)
  }

  @MainActor
  func testClosingBeforeStartingKeepsThePracticeTabSelected() {
    let app = launchPracticeFromLibrary()
    app.buttons["关闭练习"].tap()

    let practice = app.tabBars.buttons["练习"]
    XCTAssertTrue(practice.waitForExistence(timeout: 5))
    XCTAssertTrue(practice.isSelected)
    XCTAssertTrue(app.staticTexts["按压力状态选择"].exists)
  }

  @MainActor
  private func launchPracticeFromLibrary() -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()
    let practice = app.tabBars.buttons["练习"]
    XCTAssertTrue(practice.waitForExistence(timeout: 5))
    practice.tap()
    let launch = app.buttons["开始生理性叹息，1 分钟"]
    XCTAssertTrue(launch.waitForExistence(timeout: 5))
    launch.tap()
    XCTAssertTrue(app.buttons["开始 1 分钟练习"].waitForExistence(timeout: 5))
    return app
  }
}
