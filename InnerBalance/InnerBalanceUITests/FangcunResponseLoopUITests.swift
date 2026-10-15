import XCTest

/// V3: subjective records are preserved separately; they never manufacture a status-score change.
final class FangcunResponseLoopUITests: XCTestCase {
  @MainActor func testActionChooserKeepsScorePositionStable() {
    let app = launchApp(), score = app.staticTexts["100"]
    XCTAssertFalse(app.buttons["home.echo.state.tense"].exists)
    let actions = app.buttons["daily.lightActions"]
    reveal(actions, app)
    // Compare at the same scroll offset: reaching the relocated Daily entry is intentional scrolling.
    let frame = score.frame
    actions.tap()
    XCTAssertTrue(app.buttons["完成"].waitForExistence(timeout:5)); app.buttons["完成"].tap()
    XCTAssertEqual(score.frame.minY,frame.minY,accuracy:2)
    for _ in 0..<12 where !app.buttons["today.start"].isHittable { app.swipeDown() }
    XCTAssertTrue(app.buttons["today.start"].isHittable)
    XCTAssertLessThanOrEqual(app.buttons["today.start"].frame.maxY,app.tabBars.firstMatch.frame.minY)
  }
  @MainActor func testSavedPostPracticeFeelingImmediatelyUpdatesHistoryWithoutInventingMood() {
    let app = launchApp(); finishPractice(app)
    let comfortable = app.buttons["practice.feedback.更舒服"]
    reveal(comfortable, app); comfortable.tap()
    XCTAssertFalse(app.staticTexts["和刚才比"].exists)
    let keep = app.buttons["practice.feedback.save"]; reveal(keep, app); XCTAssertTrue(keep.isEnabled); keep.tap()
    XCTAssertTrue(app.buttons["practice.saved.done"].waitForExistence(timeout:6)); app.buttons["practice.saved.done"].tap()
    openV4Records(app)
    let record = app.descendants(matching: .any).matching(identifier: "practice.history.record").firstMatch
    XCTAssertTrue(record.waitForExistence(timeout: 5))
    XCTAssertTrue(record.label.contains("这次感受：更舒服"))
    app.buttons["practice.history.done"].tap()
    app.tabBars.buttons["日常"].tap()
    XCTAssertFalse(app.staticTexts["today.feeling"].exists)
    assertScore(app)
  }
  @MainActor func testDetailedFeelingRemainsSeparateFromScore() {
    let app = launchApp(); checkIn(app,label:"emotionWord.anxious")
    reveal(app.staticTexts["today.feeling"],app)
    XCTAssertTrue(app.staticTexts["today.feeling"].label.contains("焦虑"))
    XCTAssertFalse(app.buttons["home.echo.state.calm"].exists)
    assertScore(app)
  }
  @MainActor func testDisplayPreferencesDoNotOverwriteFeeling() {
    let app = launchApp(); checkIn(app,label:"emotionWord.anxious")
    reveal(app.staticTexts["today.feeling"],app)
    let identity = app.staticTexts["today.feeling"].value as? String
    // A display preference or opening practice selection must not overwrite the saved feeling.
    openDailySettings(app)
    let appearance = app.switches["深色模式"]
    appearance.tap(); appearance.tap()
    app.buttons["settings.done"].tap()
    reveal(app.staticTexts["today.feeling"],app)
    XCTAssertEqual(app.staticTexts["today.feeling"].value as? String,identity)
    XCTAssertTrue(app.staticTexts["today.feeling"].label.contains("焦虑")); assertScore(app)
  }
  @MainActor func testFinishThenSkipFeedbackReturnsHomeWithCompletedOnly() {
    let app = launchApp(); finishPractice(app)
    reveal(app.buttons["practice.feedback.skip"], app); app.buttons["practice.feedback.skip"].tap()
    XCTAssertTrue(app.buttons["practice.saved.done"].waitForExistence(timeout:6)); app.buttons["practice.saved.done"].tap()
    app.tabBars.buttons["日常"].tap()
    reveal(app.staticTexts["today.latestPractice"],app)
    XCTAssertFalse((app.staticTexts["today.latestPractice"].value as? String ?? "").isEmpty)
    XCTAssertFalse(app.staticTexts["today.feeling"].exists)
    XCTAssertFalse(app.staticTexts["today.latestPractice"].label.contains("持平")); assertScore(app)
  }
  @MainActor func testSelectedPressureSourceImmediatelyUpdatesTheWholeHomeResponse() {
    let app = launchApp(); openCheckIn(app)
    app.buttons["emotionWord.anxious"].tap()
    XCTAssertTrue(app.staticTexts["已记录此刻"].waitForExistence(timeout:5))
    reveal(app.buttons["工作"],app); app.buttons["工作"].tap()
    reveal(app.buttons["保存补充"],app); app.buttons["保存补充"].tap()
    reveal(app.staticTexts["today.feeling"],app)
    XCTAssertTrue(app.staticTexts["today.feeling"].label.contains("工作"))
    XCTAssertTrue(app.staticTexts["today.feeling"].label.contains("焦虑")); assertScore(app)
  }
  @MainActor private func launchApp()->XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing","--readiness-fixture=scoreSleep480","-fangcun.dark","NO","-fangcun.largeType","NO","-status-v3.avoidBreathing","NO","-status-v3.favorite","breath","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryLarge"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap(); XCTAssertTrue(app.staticTexts["100"].waitForExistence(timeout:12)); return app
  }
  @MainActor private func openCheckIn(_ app:XCUIApplication) {
    reveal(app.buttons["home.checkIn"],app); app.buttons["home.checkIn"].tap()
    let field = app.otherElements["checkIn.emotionField"]
    XCTAssertTrue(field.waitForExistence(timeout:5)); field.coordinate(withNormalizedOffset:CGVector(dx:0.25,dy:0.25)).tap()
  }
  @MainActor private func checkIn(_ app:XCUIApplication,label:String) {
    openCheckIn(app); app.buttons[label].tap()
    XCTAssertTrue(app.staticTexts["已记录此刻"].waitForExistence(timeout:5))
    reveal(app.buttons["先这样"],app); app.buttons["先这样"].tap()
  }
  @MainActor private func finishPractice(_ app:XCUIApplication) {
    app.buttons["today.start"].tap()
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout:8))
    app.buttons["结束"].tap(); app.buttons["practice.finish.confirm"].firstMatch.tap()
    XCTAssertTrue(app.buttons["practice.feedback.skip"].waitForExistence(timeout:6))
  }
  @MainActor private func assertScore(_ app:XCUIApplication) {
    for _ in 0..<7 where !app.staticTexts["100"].isHittable { app.swipeDown() }
    XCTAssertTrue(app.staticTexts["100"].exists); XCTAssertEqual(app.staticTexts["status.band"].label,"良好")
  }
  @MainActor private func reveal(_ item:XCUIElement,_ app:XCUIApplication) {
    for _ in 0..<8 where !item.isHittable { app.swipeUp() }; XCTAssertTrue(item.isHittable)
  }
}
