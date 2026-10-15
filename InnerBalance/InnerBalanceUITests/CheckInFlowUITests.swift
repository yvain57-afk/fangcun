import XCTest

final class CheckInFlowUITests: XCTestCase {
  @MainActor
  private func launchApp() -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--readiness-fixture=scoreSleep480",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryLarge",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()
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
    XCTAssertFalse(app.staticTexts["当前压力"].exists)
    XCTAssertFalse(app.staticTexts["有限线索"].exists)
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
    let toggle = app.switches["这次不做呼吸练习"]
    XCTAssertTrue(toggle.waitForExistence(timeout:5))
    if toggle.value as? String != "1" { toggle.coordinate(withNormalizedOffset:CGVector(dx:0.93,dy:0.5)).tap() }
    XCTAssertEqual(toggle.value as? String,"1")
    app.buttons["完成"].tap()
    expectation(for:NSPredicate(format:"label CONTAINS %@","安静休息"),evaluatedWith:app.buttons["today.start"])
    waitForExpectations(timeout:5)
    XCTAssertTrue(app.staticTexts["100"].exists)
    // Reset only the explicit preference this test changed.
    openDailyActions(app)
    let reset = app.switches["这次不做呼吸练习"]
    reset.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
    XCTAssertEqual(reset.value as? String, "0")
    app.buttons["完成"].tap()
  }

  @MainActor
  func testPacedBreathingLeadsWithTheCurrentBreathPhase() {
    let app = launchApp()

    openV4Method("pacedBreathing", app: app)
    app.buttons["practice.pacedBreathing.300"].tap()

    let guide = app.descendants(matching: .any)["practice.breathGuide"]
    XCTAssertTrue(guide.waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["吸气"].exists)
  }

  @MainActor
  func testBreathPhaseRemainsThePrimaryGuideAtAccessibilityTextSizes() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--readiness-fixture=scoreSleep480",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()

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
    app.launchArguments = ["--ui-testing","--readiness-fixture=scoreSleep480","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()
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

    XCTAssertTrue(app.tabBars.buttons["日常"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.tabBars.buttons["呼吸"].exists)
    XCTAssertFalse(app.tabBars.buttons["设置"].exists)
    XCTAssertTrue(app.buttons["daily.settings"].exists)
    XCTAssertEqual(app.tabBars.buttons.count, 2)
  }

  @MainActor
  func testSelectingSuggestedWordImmediatelySavesPrimaryRecord() {
    let app = launchApp()
    revealAndTapCheckIn(in: app)
    XCTAssertTrue(app.staticTexts["现在怎样？"].waitForExistence(timeout: 2))

    chooseHighNegativePosition(in: app)
    XCTAssertTrue(app.staticTexts["哪个词最接近？"].waitForExistence(timeout: 2))
    XCTAssertFalse(app.buttons["checkIn.continue"].exists)
    XCTAssertEqual(app.sliders.count, 0)

    app.buttons["emotionWord.anxious"].tap()

    XCTAssertTrue(app.staticTexts["已记录此刻"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["焦虑"].exists)
  }

  @MainActor
  func testUnclassifiedStillSavesSelectedValence() {
    let app = launchApp()
    revealAndTapCheckIn(in: app)
    chooseLowPositivePosition(in: app)

    app.buttons["emotionWord.unclassified"].tap()

    XCTAssertTrue(app.staticTexts["已记录此刻"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["都不像，也已保留罗盘位置"].exists)
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
      "--ui-testing", "--readiness-fixture=scoreSleep480",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()

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

    app.tabBars.buttons["呼吸"].tap()
    XCTAssertTrue(app.staticTexts["呼吸与身心练习"].waitForExistence(timeout: 2))

    app.buttons["practice.physiologicalSigh.60"].tap()

    XCTAssertTrue(app.staticTexts["生理性叹息"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["这个练什么"].exists)
    XCTAssertTrue(app.staticTexts["适合什么时候"].exists)
    XCTAssertTrue(app.staticTexts["怎么做"].exists)
    XCTAssertTrue(app.staticTexts["开始前"].exists)
    XCTAssertTrue(app.buttons["开始 1 分钟练习"].exists)
  }

  @MainActor
  func testPracticeLibraryStartsFromTheOutcomeInsteadOfAPlainCatalog() {
    let app = launchApp()

    app.tabBars.buttons["呼吸"].tap()

    XCTAssertTrue(app.staticTexts["呼吸与身心练习"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["hub.quickStart"].exists)
    XCTAssertTrue(app.buttons["practice.physiologicalSigh.60"].exists)
    XCTAssertTrue(app.staticTexts["睡前放松"].exists)
    XCTAssertTrue(app.staticTexts["减少分心"].exists)
    XCTAssertTrue(app.staticTexts["恢复精力"].exists)
    reveal(app.staticTexts["盆底控制"],in:app)
    XCTAssertTrue(app.staticTexts["盆底控制"].exists)
  }

  @MainActor
  func testPracticeOffersHandsFreeSoundAndHapticGuidance() {
    let app = launchApp()

    app.tabBars.buttons["呼吸"].tap()
    app.buttons["practice.physiologicalSigh.60"].tap()

    XCTAssertTrue(app.buttons["开始 1 分钟练习"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.descendants(matching: .any)["practice.sound.controls"].exists)
    XCTAssertTrue(app.buttons["语音引导"].exists)
    XCTAssertTrue(app.buttons["语音引导"].isSelected)
    XCTAssertTrue(app.buttons["仅节奏"].exists)
    XCTAssertTrue(app.buttons["静音"].exists)
    XCTAssertTrue(app.switches["practice.haptics"].exists)
  }

  @MainActor
  func testPracticePreparationIsScrollableForLargeContent() {
    let app = launchApp()

    app.tabBars.buttons["呼吸"].tap()
    app.buttons["practice.physiologicalSigh.60"].tap()

    XCTAssertTrue(app.scrollViews["practice.preparation"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["开始 1 分钟练习"].exists)
  }

  @MainActor
  func testPracticeCompletionRemainsReachableAtAccessibilityTextSizes() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--readiness-fixture=scoreSleep480",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()

    app.tabBars.buttons["呼吸"].tap()
    app.buttons["practice.physiologicalSigh.60"].tap()
    let start = app.buttons["开始 1 分钟练习"]
    XCTAssertTrue(start.waitForExistence(timeout: 3))
    start.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["practice.breathGuide"].waitForExistence(timeout: 5)
    )
    let end = app.buttons["结束"]
    XCTAssertTrue(end.waitForExistence(timeout: 3))
    end.tap()
    let confirmEnd = app.buttons["practice.finish.confirm"].firstMatch
    XCTAssertTrue(confirmEnd.waitForExistence(timeout: 3))
    confirmEnd.tap()

    XCTAssertFalse(app.staticTexts["和刚才比"].exists)
    tapPracticeChoice("更舒服", in: app)
    tapPracticeChoice("保留这次感受", in: app)

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
      "--ui-testing", "--readiness-fixture=scoreSleep480",
      "--ui-testing-practice-save-failure",
      "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap()

    openV4Method("kegel", app: app)
    let start = app.buttons["practice.kegel.180"]
    XCTAssertTrue(start.waitForExistence(timeout: 3)); XCTAssertTrue(start.isHittable); start.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["practice.pelvicFloorStage"].waitForExistence(timeout: 5)
    )
    let end = app.buttons["结束"]
    XCTAssertTrue(end.waitForExistence(timeout: 3))
    end.tap()
    let confirmEnd = app.buttons["practice.finish.confirm"].firstMatch
    XCTAssertTrue(confirmEnd.waitForExistence(timeout: 3))
    confirmEnd.tap()

    let saveAlert = app.alerts["未能保留本次练习"]
    XCTAssertTrue(saveAlert.waitForExistence(timeout: 5))
    saveAlert.buttons["稍后处理"].tap()

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
    if label != "保留这次变化" && label != "保留这次感受" {
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
