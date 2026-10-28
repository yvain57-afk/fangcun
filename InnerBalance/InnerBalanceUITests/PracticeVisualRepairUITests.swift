import XCTest

final class PracticeVisualRepairUITests: XCTestCase {
  @MainActor func testNaturalBreathingArtworkStaysVisibleWithItsExplanation() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "-AppleLanguages", "(zh-Hans)",
      "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO", "-fangcun.motionMode", "standard"]
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["Breathe"].waitForExistence(timeout: 10))
    openV4Method("diaphragmaticBreathing", app: app)
    app.buttons["practice.diaphragmaticBreathing.180"].tap()
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 10))
    let character = app.descendants(matching: .any)["practice.companion"].firstMatch
    XCTAssertTrue(character.exists)
    XCTAssertGreaterThan(character.frame.height, 200)
    XCTAssertLessThan(character.frame.maxY, app.buttons["Pause practice"].frame.minY)
    XCTAssertTrue(app.staticTexts["A movement guide · Follow your own breath"].isHittable)
    for second in [0, 5, 10, 28] {
      if second > 0 { RunLoop.current.run(until: Date().addingTimeInterval(second == 28 ? 18 : 5)) }
      let shot = XCTAttachment(screenshot: app.screenshot())
      shot.name = "final-diaphragmaticBreathing-\(second)"; shot.lifetime = .keepAlways; add(shot)
    }
  }
  @MainActor func testFinalCoachAndRestingDogOverRealCycles() {
    continueAfterFailure = false
    for (kind, duration, seconds) in [("kegel", 180, 38.0), ("pacedBreathing", 300, 26.0)] {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "-AppleLanguages", "(zh-Hans)",
        "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO", "-fangcun.motionMode", "standard"]
      app.launch()
      XCTAssertTrue(app.tabBars.buttons["Breathe"].waitForExistence(timeout: 10))
      openV4Method(kind, app: app)
      app.buttons["practice.\(kind).\(duration)"].tap()
      XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 10))
      let start = Date()
      for offset in [1.0, 3, 6, 14, seconds] {
        RunLoop.current.run(until: start.addingTimeInterval(offset))
        XCTAssertTrue(app.buttons["Pause practice"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "final-\(kind)-\(Int(offset))"; shot.lifetime = .keepAlways; add(shot)
      }
      app.terminate()
    }
  }
  @MainActor func testActualSessionShowsLargeBreathMovementAndStopsOnPause() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "-AppleLanguages", "(zh-Hans)",
      "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO",
      "-fangcun.motionMode", "standard", "-fangcun.practice.v4.quickKind", "physiologicalSigh"]
    app.launch()
    XCTAssertTrue(app.buttons["hub.quickStart"].waitForExistence(timeout: 10))
    app.buttons["hub.quickStart"].tap()
    let prepare = app.buttons["practice.prepare.start"]
    if prepare.waitForExistence(timeout: 2) { prepare.tap() }
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 10))
    let envelope = app.descendants(matching: .any)["practice.breathEnvelope"].firstMatch
    XCTAssertTrue(envelope.waitForExistence(timeout: 5))
    var widths: [CGFloat] = []
    var phases = Set<String>()
    let start = Date()
    while Date().timeIntervalSince(start) < 25 {
      widths.append(envelope.frame.width)
      phases.insert(app.staticTexts["practice.breathPhase"].label)
      if widths.count % 4 == 0 {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "visual-repair-live-\(widths.count)"; shot.lifetime = .keepAlways; add(shot)
      }
      RunLoop.current.run(until: Date().addingTimeInterval(0.35))
    }
    XCTAssertTrue(phases.isSuperset(of: ["Breathe in", "A little more", "Breathe out"]))
    XCTAssertGreaterThan((widths.max() ?? 0) - (widths.min() ?? 0), 75,
      "The real rendered guide must visibly expand, not merely change its label.")
    app.buttons["Pause practice"].tap()
    XCTAssertTrue(app.staticTexts["Paused"].waitForExistence(timeout: 3))
    let pausedWidth = envelope.frame.width
    RunLoop.current.run(until: Date().addingTimeInterval(1.2))
    XCTAssertEqual(envelope.frame.width, pausedWidth, accuracy: 0.5)
    app.buttons["Continue practice"].tap()
    XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 8))
    XCTAssertTrue(app.staticTexts["practice.phaseSeconds"].exists)
  }
}
