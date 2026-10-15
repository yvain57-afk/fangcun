import XCTest

/// Raw-provider UI contract migrated to score-v3. Legacy workout/measurement gates stay in HomeEvidencePipelineTests.
final class HomeEvidencePipelineUITests: XCTestCase {
  @MainActor func testHistoryFailureAndLimitedEvidence() {
    verify("scoreNoCurrentHistory",score:nil)
    verify("failed",score:nil)
    verify("scoreSleep375",score:"78")
    verify("scoreHRVOnly",score:nil)
  }
  @MainActor func testQualifiedEvidenceAndWorkoutProtection() {
    verify("scoreSleep480",score:"100")
    verify("scoreSleep240",score:"50")
    verify("scoreRHR",score:"85")
    verify("scoreFull240",score:"64")
  }
  @MainActor func testPreviousSleepAndIncompleteBaselines() {
    let old = launch("scoreExpired")
    XCTAssertTrue(old.staticTexts["status.empty"].waitForExistence(timeout:10))
    XCTAssertFalse(old.staticTexts["status.score"].exists)
    XCTAssertFalse(old.staticTexts["昨晚"].exists)
    old.terminate()
    verify("oneDay",score:"100")
    verify("scoreHRVOnly",score:nil)
  }
  @MainActor func testMeasurementTimeDoesNotBecomeQueryTime() {
    let app = launch("scoreSleep375")
    XCTAssertTrue(app.staticTexts["78"].waitForExistence(timeout:10))
    let asOf = app.staticTexts["status.cycle"].value as? String
    XCTAssertNotNil(asOf)
    app.buttons["today.evidence"].tap(); app.buttons["status.method"].tap()
    let time = app.staticTexts["status.time.asOf"]
    for _ in 0..<6 where !time.isHittable { app.swipeUp() }
    XCTAssertEqual(time.value as? String,asOf)
    XCTAssertEqual(app.staticTexts["status.time.query"].value as? String,"2026-09-20T04:00:00Z")
    XCTAssertEqual(app.staticTexts["status.time.computed"].value as? String,"2026-09-20T04:00:00Z")
    XCTAssertNotEqual(asOf,app.staticTexts["status.time.query"].value as? String)
  }
  @MainActor private func verify(_ fixture:String,score:String?) {
    let app = launch(fixture)
    if let score { XCTAssertTrue(app.staticTexts[score].waitForExistence(timeout:12)) }
    else { XCTAssertTrue(app.staticTexts["status.empty"].waitForExistence(timeout:12)); XCTAssertFalse(app.staticTexts["status.score"].exists) }
    XCTAssertFalse(app.staticTexts["有限线索"].exists)
    XCTAssertTrue(app.buttons["today.start"].exists)
    let a = XCTAttachment(screenshot:app.screenshot()); a.name = "v3-raw-"+fixture; a.lifetime = .keepAlways; add(a)
    app.terminate()
  }
  @MainActor private func launch(_ fixture:String)->XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing","--readiness-fixture="+fixture,"-fangcun.dark","NO","-fangcun.largeType","NO","-fangcun.reduceMotion","YES"]
    app.launchArguments += ["-fangcun.practice.v4.quickKind", "physiologicalSigh"]; app.launch(); app.tabBars.buttons["日常"].tap(); return app
  }
}
