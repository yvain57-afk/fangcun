import XCTest

final class FangcunAppearanceUITests: XCTestCase {
  @MainActor
  func testCriticalScreensInCurrentAppearance() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryLarge",
    ]
    app.launch()

    XCTAssertTrue(app.otherElements["home.brandPoint"].waitForExistence(timeout: 3))
    capture("home-initial", from: app)

    let calm = app.buttons["home.echo.state.calm"]
    XCTAssertTrue(calm.waitForExistence(timeout: 3))
    XCTAssertGreaterThanOrEqual(calm.frame.width, 44)
    XCTAssertGreaterThanOrEqual(calm.frame.height, 44)
    calm.tap()
    XCTAssertTrue(calm.isSelected)
    capture("home-selected", from: app)

    app.tabBars.buttons["练习"].tap()
    let practice = app.buttons["practice.physiologicalSigh.60"]
    XCTAssertTrue(practice.waitForExistence(timeout: 3))
    capture("practice-library", from: app)

    practice.tap()
    let preparation = app.scrollViews["practice.preparation"]
    XCTAssertTrue(preparation.waitForExistence(timeout: 3))
    capture("practice-overview", from: app)
    let ambience = app.switches["环境声·锁屏继续"]
    XCTAssertTrue(ambience.waitForExistence(timeout: 3))
    for _ in 0..<5 where !ambience.isHittable {
      preparation.swipeUp()
    }
    XCTAssertTrue(ambience.isHittable)
    let ambienceValue = String(describing: ambience.value)
    ambience.tap()
    XCTAssertNotEqual(String(describing: ambience.value), ambienceValue)
    let haptics = app.switches["practice.haptics"]
    XCTAssertTrue(haptics.exists)
    for _ in 0..<3 where !haptics.isHittable {
      preparation.swipeUp()
    }
    XCTAssertTrue(haptics.isHittable)
    capture("practice-preparation", from: app)

    app.buttons["开始 1 分钟练习"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["practice.breathGuide"].waitForExistence(timeout: 3)
    )
    capture("practice-active", from: app)

    app.buttons["结束"].tap()
    let finish = app.buttons["practice.finish.confirm"].firstMatch
    XCTAssertTrue(finish.waitForExistence(timeout: 3))
    finish.tap()
    XCTAssertTrue(
      app.scrollViews["practice.comparison.scroll"].waitForExistence(timeout: 3)
    )
    capture("practice-comparison", from: app)

    app.buttons["先完成"].tap()
    XCTAssertTrue(app.scrollViews["practice.saved.scroll"].waitForExistence(timeout: 3))
    capture("practice-complete", from: app)
    app.buttons["practice.saved.done"].tap()

    app.tabBars.buttons["此刻"].tap()
    revealAndTapCheckIn(in: app)
    XCTAssertTrue(app.otherElements["checkIn.emotionField"].waitForExistence(timeout: 3))
    capture("check-in-compass", from: app)

    app.otherElements["checkIn.emotionField"]
      .coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.25))
      .tap()
    XCTAssertTrue(app.buttons["emotionWord.anxious"].waitForExistence(timeout: 3))
    capture("check-in-words", from: app)

    app.buttons["emotionWord.unclassified"].tap()
    let done = app.buttons["先这样"]
    XCTAssertTrue(done.waitForExistence(timeout: 3))
    done.tap()

    app.tabBars.buttons["设置"].tap()
    XCTAssertTrue(app.staticTexts["设置"].waitForExistence(timeout: 3))
    capture("settings", from: app)

    app.buttons["隐私与数据"].tap()
    XCTAssertTrue(app.staticTexts["本地优先"].waitForExistence(timeout: 3))
    capture("privacy", from: app)
  }

  @MainActor
  private func revealAndTapCheckIn(in app: XCUIApplication) {
    let button = app.buttons["home.checkIn"]
    XCTAssertTrue(button.waitForExistence(timeout: 3))
    for _ in 0..<6 where !button.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(button.isHittable)
    button.tap()
  }

  @MainActor
  private func capture(_ name: String, from app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
