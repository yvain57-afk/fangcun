import XCTest

final class FangcunResponseLoopUITests: XCTestCase {
  @MainActor
  func testStateChoicesStayInPlaceAfterResponding() {
    let app = launchApp()
    let calm = app.buttons["home.echo.state.calm"]
    XCTAssertTrue(calm.waitForExistence(timeout: 5))
    let originalFrame = calm.frame
    capture("home-before-selection", from: app)

    calm.tap()
    XCTAssertTrue(calm.isSelected)
    capture("home-after-selection", from: app)
    XCTAssertEqual(calm.frame.minY, originalFrame.minY, accuracy: 2)
    XCTAssertTrue(calm.isHittable)

    let tense = app.buttons["home.echo.state.tense"]
    XCTAssertTrue(tense.isHittable)
    tense.tap()
    XCTAssertTrue(tense.isSelected)
    XCTAssertEqual(calm.frame.minY, originalFrame.minY, accuracy: 2)
    XCTAssertEqual(app.staticTexts["home.currentState"].label, "绷着")
    let action = app.buttons["home.startRecommendation"]
    XCTAssertTrue(action.isHittable)
    XCTAssertLessThanOrEqual(action.frame.maxY, app.tabBars.firstMatch.frame.minY)
    capture("home-tense-response", from: app)
  }

  @MainActor
  func testSavedPostPracticeFeelingImmediatelyUpdatesHome() {
    let app = launchApp()
    let tense = app.buttons["home.echo.state.tense"]
    XCTAssertTrue(tense.waitForExistence(timeout: 5))
    tense.tap()
    XCTAssertEqual(app.staticTexts["home.stressConclusion"].label, "压力较高")

    let recommendation = app.buttons["home.startRecommendation"]
    for _ in 0..<6 where !recommendation.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(recommendation.isHittable)
    recommendation.tap()
    let start = app.buttons["开始 1 分钟练习"]
    XCTAssertTrue(start.waitForExistence(timeout: 5))
    start.tap()
    XCTAssertTrue(app.buttons["结束"].waitForExistence(timeout: 5))
    app.buttons["结束"].tap()
    app.buttons["结束练习"].tap()

    let peaceful = app.buttons["平和"]
    XCTAssertTrue(peaceful.waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["和刚才比"].exists)
    peaceful.tap()
    let keep = app.buttons["保留现在的感受"]
    XCTAssertTrue(keep.isEnabled)
    keep.tap()
    let done = app.buttons["practice.saved.done"]
    XCTAssertTrue(done.waitForExistence(timeout: 5))
    capture("practice-feedback-saved", from: app)
    done.tap()

    let conclusion = app.staticTexts["home.stressConclusion"]
    XCTAssertTrue(conclusion.waitForExistence(timeout: 5))
    XCTAssertEqual(conclusion.label, "压力较低")
    XCTAssertFalse(app.buttons["home.startRecommendation"].exists)
    XCTAssertFalse(app.buttons["home.echo.state.tense"].isSelected)
    let completion = app.descendants(matching: .any)["home.latestPractice"]
    XCTAssertTrue(completion.exists)
    XCTAssertFalse(completion.label.contains("持平"))
    capture("home-after-peaceful-feedback", from: app)
  }

  @MainActor
  func testQuickThenDetailedImmediatelyShowsOnlyTheDetailedState() {
    let app = launchApp()

    revealEchoChoices(in: app)
    app.buttons["home.echo.state.calm"].tap()
    revealAndTapCheckIn(in: app)
    chooseHighNegativePosition(in: app)
    app.buttons["emotionWord.anxious"].tap()
    finishCheckIn(in: app)

    let currentState = app.staticTexts["home.currentState"]
    XCTAssertTrue(currentState.waitForExistence(timeout: 3))
    expectation(
      for: NSPredicate(format: "label == %@", "焦虑"),
      evaluatedWith: currentState
    )
    waitForExpectations(timeout: 3)
    XCTAssertEqual(currentState.label, "焦虑")
    XCTAssertTrue(app.buttons["开始 · 生理性叹息"].exists)
    revealEchoChoices(in: app)
    XCTAssertFalse(app.buttons["home.echo.state.calm"].isSelected)
  }

  @MainActor
  func testDetailedThenQuickImmediatelyShowsOnlyTheQuickState() {
    let app = launchApp()

    revealAndTapCheckIn(in: app)
    chooseHighNegativePosition(in: app)
    app.buttons["emotionWord.anxious"].tap()
    finishCheckIn(in: app)
    revealEchoChoices(in: app)
    app.buttons["home.echo.state.calm"].tap()

    let currentState = app.staticTexts["home.currentState"]
    XCTAssertTrue(currentState.waitForExistence(timeout: 3))
    XCTAssertEqual(currentState.label, "平静")
    XCTAssertTrue(app.buttons["home.echo.state.calm"].isSelected)
    XCTAssertFalse(app.buttons["home.startRecommendation"].exists)
    XCTAssertTrue(app.staticTexts["照常进行，不需要额外练习。"].exists)
  }

  @MainActor
  func testFinishThenSkipFeedbackReturnsHomeWithCompletedOnly() {
    let app = launchApp()

    revealEchoChoices(in: app)
    let tense = app.buttons["home.echo.state.tense"]
    for _ in 0..<4 where !tense.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(tense.isHittable)
    tense.tap()
    let recommendation = app.buttons["home.startRecommendation"]
    for _ in 0..<4 where !recommendation.isHittable {
      app.scrollViews.firstMatch.swipeDown()
    }
    XCTAssertTrue(recommendation.isHittable)
    recommendation.tap()
    XCTAssertTrue(app.buttons["开始 1 分钟练习"].waitForExistence(timeout: 5))
    app.buttons["开始 1 分钟练习"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["practice.breathGuide"].waitForExistence(timeout: 5)
    )
    let end = app.buttons["结束"]
    XCTAssertTrue(end.waitForExistence(timeout: 3))
    end.tap()
    let confirmEnd = app.buttons["结束练习"]
    XCTAssertTrue(confirmEnd.waitForExistence(timeout: 3))
    confirmEnd.tap()

    let skip = app.buttons["先完成"]
    XCTAssertTrue(skip.waitForExistence(timeout: 5))
    skip.tap()
    let done = app.buttons["practice.saved.done"]
    XCTAssertTrue(done.waitForExistence(timeout: 5))
    done.tap()

    let latestPractice = app.descendants(matching: .any)["home.latestPractice"]
    XCTAssertTrue(latestPractice.waitForExistence(timeout: 5))
    XCTAssertTrue(latestPractice.label.contains("已完成"))
    XCTAssertFalse(latestPractice.label.contains("持平"))
  }

  @MainActor
  func testSelectedPressureSourceImmediatelyUpdatesTheWholeHomeResponse() {
    let app = launchApp()

    revealAndTapCheckIn(in: app)
    chooseHighNegativePosition(in: app)
    app.buttons["emotionWord.anxious"].tap()
    XCTAssertTrue(app.staticTexts["已记录此刻"].waitForExistence(timeout: 3))

    let work = app.buttons["工作"]
    for _ in 0..<6 where !work.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(work.isHittable)
    work.tap()

    let save = app.buttons["保存补充"]
    for _ in 0..<4 where !save.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(save.isHittable)
    save.tap()

    let conclusion = app.staticTexts["home.stressConclusion"]
    XCTAssertTrue(conclusion.waitForExistence(timeout: 5))
    XCTAssertEqual(conclusion.label, "压力较高")
    let source = app.descendants(matching: .any)["home.stressSource"]
    XCTAssertTrue(source.label.contains("工作"))
    XCTAssertTrue(app.buttons["开始 · 生理性叹息"].exists)
    XCTAssertTrue(app.staticTexts["给「工作」的一句"].exists)
  }

  @MainActor
  private func launchApp() -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryLarge",
    ]
    app.launch()
    return app
  }

  @MainActor
  private func revealAndTapCheckIn(in app: XCUIApplication) {
    let button = app.buttons["home.checkIn"]
    XCTAssertTrue(button.waitForExistence(timeout: 3))
    for _ in 0..<4 where !button.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(button.isHittable)
    button.tap()
  }

  @MainActor
  private func chooseHighNegativePosition(in app: XCUIApplication) {
    let field = app.otherElements["checkIn.emotionField"]
    XCTAssertTrue(field.waitForExistence(timeout: 2))
    field.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.25)).tap()
  }

  @MainActor
  private func finishCheckIn(in app: XCUIApplication) {
    XCTAssertTrue(app.staticTexts["已记录此刻"].waitForExistence(timeout: 3))
    let done = app.buttons["先这样"]
    for _ in 0..<4 where !done.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(done.isHittable)
    done.tap()
  }

  @MainActor
  private func revealEchoChoices(in app: XCUIApplication) {
    let calm = app.buttons["home.echo.state.calm"]
    let scroll = app.scrollViews.firstMatch
    for _ in 0..<6 where !calm.isHittable {
      if calm.exists && calm.frame.minY < scroll.frame.minY {
        scroll.swipeDown()
      } else {
        scroll.swipeUp()
      }
    }
    XCTAssertTrue(calm.waitForExistence(timeout: 3))
    XCTAssertTrue(calm.isHittable)
  }

  @MainActor
  private func capture(_ name: String, from app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
