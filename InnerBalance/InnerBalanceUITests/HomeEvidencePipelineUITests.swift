import XCTest

final class HomeEvidencePipelineUITests: XCTestCase {
  @MainActor func testHistoryFailureAndLimitedEvidence() {
    verify([("noCurrentHistory", "insufficient"), ("failed", "insufficient"),
      ("sleepOnly", "limited"), ("oneCardio", "limited")])
  }

  @MainActor func testQualifiedEvidenceAndWorkoutProtection() {
    verify([("steady", "steady"), ("watch", "watch"), ("elevated", "elevated"),
      ("workoutProtected", "limited")])
  }

  @MainActor func testPreviousSleepAndIncompleteBaselines() {
    verify([("previousSleep", "insufficient"), ("baselineBuilding", "limited"),
      ("unreliablePair", "limited")])
  }

  @MainActor func testMeasurementTimeDoesNotBecomeQueryTime() {
    continueAfterFailure = false
    let app = launch("stale")
    expectState("insufficient", app)
    let measured = Date(timeIntervalSince1970: 1_789_704_000 - 37 * 3_600).ISO8601Format()
    let fetched = Date(timeIntervalSince1970: 1_789_704_000 - 60).ISO8601Format()
    XCTAssertEqual(app.staticTexts["today.measuredAt"].value as? String, measured)
    capture("m1-stale-measurement", app)
    let detail = app.buttons["today.evidence"]
    for _ in 0..<5 where !detail.isHittable { app.scrollViews.firstMatch.swipeUp() }
    detail.tap()
    XCTAssertTrue(app.staticTexts["evidence.fetchedAt"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["evidence.fetchedAt"].value as? String, fetched)
    XCTAssertEqual(app.staticTexts["evidence.computedAt"].value as? String,
      Date(timeIntervalSince1970: 1_789_704_000).ISO8601Format())
    capture("m1-time-detail", app)
  }

  @MainActor private func verify(_ cases: [(String, String)]) {
    continueAfterFailure = false
    for (fixture, state) in cases {
      let app = launch(fixture)
      expectState(state, app)
      if fixture == "failed" {
        XCTAssertEqual(app.staticTexts["today.measuredAt"].value as? String, "none")
      }
      capture("m1-" + fixture, app)
      app.terminate()
    }
  }

  @MainActor private func launch(_ fixture: String) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--health-fixture=\(fixture)",
      "-fangcun.dark", fixture == "watch" ? "YES" : "NO",
      "-fangcun.largeType", fixture == "oneCardio" ? "YES" : "NO",
      "-fangcun.reduceMotion", "YES"]
    // No --preview-state: the UI must derive its conclusion from the raw provider data.
    app.launch()
    return app
  }

  @MainActor private func expectState(_ state: String, _ app: XCUIApplication) {
    let conclusion = app.staticTexts["today.conclusion"]
    XCTAssertTrue(conclusion.waitForExistence(timeout: 10))
    let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", state), object: conclusion)], timeout: 8)
    XCTAssertEqual(result, .completed)
  }

  @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
  }
}
