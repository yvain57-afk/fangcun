import XCTest

final class CheckInFlowUITests: XCTestCase {
  @MainActor
  private func launchApp() -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep480",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryLarge",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()
    return app
  }

  @MainActor
  func testHomeLeadsWithOneScoreAndAction() {
    let app = launchApp()
    XCTAssertTrue(app.descendants(matching: .any).matching(identifier:"daily.title").firstMatch.waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["100"].waitForExistence(timeout:10))
    XCTAssertEqual(app.staticTexts["status.band"].label,"良好")
    XCTAssertTrue(app.buttons["today.start"].isHittable)
    XCTAssertEqual(app.buttons.matching(identifier:"today.start").count,1)
    XCTAssertFalse(app.buttons["home.echo.state.calm"].exists)
    XCTAssertFalse(app.staticTexts["Reported pressure"].exists)
    XCTAssertFalse(app.staticTexts["Limited context"].exists)
  }

  @MainActor
  func testStatusNeedsNoWritingAndDoesNotCreateAChoreList() {
    let app = launchApp()
    XCTAssertTrue(app.staticTexts["100"].waitForExistence(timeout:10))
    XCTAssertEqual(app.textFields.count,0)
    XCTAssertFalse(app.buttons["home.echo.state.calm"].exists)
    XCTAssertFalse(app.buttons["补一句"].exists)
    XCTAssertFalse(app.staticTexts["今日足迹"].exists)
    XCTAssertTrue(app.buttons["today.start"].isHittable)
  }

  @MainActor
  func testExplicitNoBreathingChoiceChangesActionOnly() {
    let app = launchApp()
    XCTAssertTrue(app.staticTexts["100"].waitForExistence(timeout:10))
    openDailyActions(app)
    let toggle = app.switches["Skip breathing suggestions this time"]
    XCTAssertTrue(toggle.waitForExistence(timeout:5))
    if toggle.value as? String != "1" { toggle.coordinate(withNormalizedOffset:CGVector(dx:0.93,dy:0.5)).tap() }
    XCTAssertEqual(toggle.value as? String,"1")
    app.buttons["Done"].tap()
    expectation(for:NSPredicate(format:"label CONTAINS %@","Quiet rest"),evaluatedWith:app.buttons["today.start"])
    waitForExpectations(timeout:5)
    XCTAssertTrue(app.staticTexts["100"].exists)
    // Reset only the explicit preference this test changed.
    openDailyActions(app)
    let reset = app.switches["Skip breathing suggestions this time"]
    reset.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
    XCTAssertEqual(reset.value as? String, "0")
    app.buttons["Done"].tap()
  }

  @MainActor
  func testPacedBreathingLeadsWithTheCurrentBreathPhase() {
    let app = launchApp()

    openV4Method("pacedBreathing", app: app)
    app.buttons["practice.pacedBreathing.300"].tap()

    let guide = app.descendants(matching: .any)["practice.breathGuide"]
    XCTAssertTrue(guide.waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["Breathe in"].exists)
  }

  @MainActor
  func testBreathPhaseRemainsThePrimaryGuideAtAccessibilityTextSizes() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep480",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()

    openV4Method("pacedBreathing", app: app)
    let start = app.buttons["practice.pacedBreathing.300"]
    XCTAssertTrue(start.isHittable)
    start.tap()

    let phase = app.staticTexts["practice.breathPhase"]
    XCTAssertTrue(phase.waitForExistence(timeout: 3))
    XCTAssertTrue(phase.isHittable)
  }

  @MainActor
  func testHomeResponseRemainsReachableAtAccessibilityTextSizes() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction","--readiness-fixture=scoreSleep480","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()
    XCTAssertTrue(app.staticTexts["100"].waitForExistence(timeout:10))
    let action = app.buttons["today.start"]
    for _ in 0..<8 where !action.isHittable { app.swipeUp() }
    XCTAssertTrue(action.isHittable)
    XCTAssertGreaterThanOrEqual(action.frame.height,44)
  }

  @MainActor
  func testBottomChromeDoesNotInterceptHomeScroll() {
    let app = launchApp()
    XCTAssertTrue(app.staticTexts["100"].waitForExistence(timeout:10))
    let tabBar = app.tabBars.firstMatch
    XCTAssertLessThan(tabBar.frame.height,120)
    let response = app.buttons["today.drinks"]
    XCTAssertTrue(response.exists)
    let initialY = response.frame.minY
    app.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.80)).press(forDuration:0.05,thenDragTo:app.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.35)))
    XCTAssertLessThan(response.frame.minY,initialY-12)
    let checkIn = app.buttons["home.checkIn"]
    for _ in 0..<6 where !checkIn.isHittable { app.swipeUp() }
    XCTAssertTrue(checkIn.isHittable)
  }

  @MainActor
  func testFangcunNavigationUsesProductLanguage() {
    let app = launchApp()

    XCTAssertTrue(app.tabBars.buttons["Daily"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.tabBars.buttons["Breathe"].exists)
    XCTAssertFalse(app.tabBars.buttons["Settings"].exists)
    XCTAssertTrue(app.buttons["daily.settings"].exists)
    XCTAssertEqual(app.tabBars.buttons.count, 2)
  }

  @MainActor
  func testSelectingSuggestedWordImmediatelySavesPrimaryRecord() {
    let app = launchApp()
    revealAndTapCheckIn(in: app)
    XCTAssertTrue(app.staticTexts["How is it right now?"].waitForExistence(timeout: 2))

    chooseHighNegativePosition(in: app)
    XCTAssertTrue(app.staticTexts["Does a word fit?"].waitForExistence(timeout: 2))
    XCTAssertFalse(app.buttons["checkIn.continue"].exists)
    XCTAssertEqual(app.sliders.count, 0)

    app.buttons["emotionWord.anxious"].tap()

    XCTAssertTrue(app.staticTexts["Check-in saved"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Anxious"].exists)
  }

  @MainActor
  func testUnclassifiedStillSavesSelectedValence() {
    let app = launchApp()
    revealAndTapCheckIn(in: app)
    chooseLowPositivePosition(in: app)

    app.buttons["emotionWord.unclassified"].tap()

    XCTAssertTrue(app.staticTexts["Check-in saved"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["No label needed. Your position is saved."].exists)
  }

  @MainActor
  func testEmotionCompassDragCommitsItsEndpoint() {
    let app = launchApp()
    revealAndTapCheckIn(in: app)

    let field = app.otherElements["checkIn.emotionField"]
    XCTAssertTrue(field.waitForExistence(timeout: 2))
    XCTAssertTrue(field.isHittable)

    let start = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let end = field.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.25))
    start.press(forDuration: 0.1, thenDragTo: end)

    XCTAssertEqual(field.value as? String, "较不愉快，较有劲")
    XCTAssertTrue(app.buttons["emotionWord.anxious"].waitForExistence(timeout: 2))
  }

  @MainActor
  func testEmotionFieldRemainsUsableAtAccessibilityTextSizes() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep480",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()

    revealAndTapCheckIn(in: app)
    chooseHighNegativePosition(in: app)

    let unclassified = app.buttons["emotionWord.unclassified"]
    XCTAssertTrue(unclassified.waitForExistence(timeout: 2))
    for _ in 0..<4 where !unclassified.isHittable {
      app.scrollViews["checkIn.scroll"].swipeUp()
    }
    XCTAssertTrue(unclassified.isHittable)
  }

  @MainActor
  func testPracticeLibraryOpensARealSession() {
    let app = launchApp()

    app.tabBars.buttons["Breathe"].tap()
    XCTAssertTrue(app.staticTexts["A little room to breathe"].waitForExistence(timeout: 2))

    app.buttons["practice.physiologicalSigh.60"].tap()

    XCTAssertTrue(app.staticTexts["A little sigh"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["What this offers"].exists)
    XCTAssertTrue(app.staticTexts["A good moment for it"].exists)
    XCTAssertTrue(app.staticTexts["How it works"].exists)
    XCTAssertTrue(app.staticTexts["Before you begin"].exists)
    XCTAssertTrue(app.buttons["开始 1 分钟练习"].exists)
  }

  @MainActor
  func testPracticeLibraryStartsFromTheOutcomeInsteadOfAPlainCatalog() {
    let app = launchApp()

    app.tabBars.buttons["Breathe"].tap()

    XCTAssertTrue(app.staticTexts["A little room to breathe"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["hub.quickStart"].exists)
    XCTAssertTrue(app.buttons["practice.physiologicalSigh.60"].exists)
    XCTAssertTrue(app.staticTexts["Wind down"].exists)
    XCTAssertTrue(app.staticTexts["Make room for your thoughts"].exists)
    XCTAssertTrue(app.staticTexts["A place to rest"].exists)
    reveal(app.staticTexts["Build gentle control"],in:app)
    XCTAssertTrue(app.staticTexts["Build gentle control"].exists)
  }

  @MainActor
  func testPracticeOffersHandsFreeSoundAndHapticGuidance() {
    let app = launchApp()

    app.tabBars.buttons["Breathe"].tap()
    app.buttons["practice.physiologicalSigh.60"].tap()

    XCTAssertTrue(app.buttons["开始 1 分钟练习"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.descendants(matching: .any)["practice.sound.controls"].exists)
    XCTAssertTrue(app.buttons["Guided"].exists)
    XCTAssertTrue(app.buttons["Guided"].isSelected)
    XCTAssertTrue(app.buttons["Cues only"].exists)
    XCTAssertTrue(app.buttons["Silent"].exists)
    XCTAssertTrue(app.switches["practice.haptics"].exists)
  }

  @MainActor
  func testPracticePreparationIsScrollableForLargeContent() {
    let app = launchApp()

    app.tabBars.buttons["Breathe"].tap()
    app.buttons["practice.physiologicalSigh.60"].tap()

    XCTAssertTrue(app.scrollViews["practice.preparation"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["开始 1 分钟练习"].exists)
  }

  @MainActor
  func testPracticeCompletionRemainsReachableAtAccessibilityTextSizes() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep480",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()

    app.tabBars.buttons["Breathe"].tap()
    app.buttons["practice.physiologicalSigh.60"].tap()
    let start = app.buttons["开始 1 分钟练习"]
    XCTAssertTrue(start.waitForExistence(timeout: 3))
    start.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["practice.breathGuide"].waitForExistence(timeout: 5)
    )
    let end = app.buttons["End"]
    XCTAssertTrue(end.waitForExistence(timeout: 3))
    end.tap()
    let confirmEnd = app.buttons["practice.finish.confirm"].firstMatch
    XCTAssertTrue(confirmEnd.waitForExistence(timeout: 3))
    confirmEnd.tap()

    XCTAssertFalse(app.staticTexts["Compared with before"].exists)
    tapPracticeChoice("A little easier", in: app)
    tapPracticeChoice("Save this feeling", in: app)

    let done = app.buttons["practice.saved.done"]
    XCTAssertTrue(done.waitForExistence(timeout: 3))
    if !done.isHittable {
      app.scrollViews["practice.saved.scroll"].swipeUp()
    }
    XCTAssertTrue(done.isHittable)
  }

  @MainActor
  func testKegelCompletionRemainsReachableAtAccessibilityTextSizes() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--ui-testing-skip-introduction", "--readiness-fixture=scoreSleep480",
      "--ui-testing-practice-save-failure",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["Daily"].tap()

    openV4Method("kegel", app: app)
    let start = app.buttons["practice.kegel.180"]
    XCTAssertTrue(start.waitForExistence(timeout: 3)); XCTAssertTrue(start.isHittable); start.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["practice.pelvicFloorStage"].waitForExistence(timeout: 5)
    )
    let end = app.buttons["End"]
    XCTAssertTrue(end.waitForExistence(timeout: 3))
    end.tap()
    let confirmEnd = app.buttons["practice.finish.confirm"].firstMatch
    XCTAssertTrue(confirmEnd.waitForExistence(timeout: 3))
    confirmEnd.tap()

    let saveAlert = app.alerts["Couldn't save this practice"]
    XCTAssertTrue(saveAlert.waitForExistence(timeout: 5))
    saveAlert.buttons["Not now"].tap()

    let completionScroll = app.scrollViews["practice.comparison.scroll"]
    XCTAssertTrue(completionScroll.waitForExistence(timeout: 3))
    let save = app.buttons["practice.feedback.skip"]
    XCTAssertTrue(save.waitForExistence(timeout: 3))
    if !save.isHittable {
      completionScroll.swipeUp()
    }
    XCTAssertTrue(save.isHittable)
  }

  @MainActor
  private func revealAndTapCheckIn(in app: XCUIApplication) {
    let button = app.buttons["home.checkIn"]
    let scroll = app.scrollViews.firstMatch
    XCTAssertTrue(scroll.waitForExistence(timeout: 3))
    for _ in 0..<8 where !button.isHittable {
      scroll.swipeUp()
    }
    XCTAssertTrue(button.waitForExistence(timeout: 3))
    XCTAssertTrue(button.isHittable)
    button.tap()
  }

  @MainActor
  private func tapPracticeChoice(_ label: String, in app: XCUIApplication) {
    let button = app.buttons[label]
    let scroll = app.scrollViews["practice.comparison.scroll"]
    for _ in 0..<4 {
      if !button.exists || button.frame.maxY > scroll.frame.maxY {
        scroll.swipeUp()
      } else if button.frame.minY < scroll.frame.minY {
        scroll.swipeDown()
      } else if button.isHittable {
        break
      }
    }
    XCTAssertTrue(button.waitForExistence(timeout: 3))
    XCTAssertTrue(button.isHittable)
    button.tap()
    if label != "保留这次变化" && label != "Save this feeling" {
      expectation(
        for: NSPredicate(format: "selected == true"),
        evaluatedWith: button
      )
      waitForExpectations(timeout: 2)
    }
  }

  @MainActor
  private func chooseHighNegativePosition(in app: XCUIApplication) {
    let field = app.otherElements["checkIn.emotionField"]
    XCTAssertTrue(field.waitForExistence(timeout: 2))
    field.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.25)).tap()
  }

  @MainActor
  private func chooseLowPositivePosition(in app: XCUIApplication) {
    let field = app.otherElements["checkIn.emotionField"]
    XCTAssertTrue(field.waitForExistence(timeout: 2))
    field.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.75)).tap()
  }

  @MainActor
  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<8 where !element.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(element.isHittable)
  }

}
