import XCTest

/// Native visual evidence, using only the isolated synthetic test store.
final class MotionReviewUITests: XCTestCase {
  @MainActor func testTenNativeMotionClips() {
    continueAfterFailure = false
    executionTimeAllowance = 1200
    let methods = ["physiologicalSigh", "pacedBreathing", "balancedBreathing", "boxBreathing", "diaphragmaticBreathing", "alternateNostrilBreathing", "meditation", "nsdr", "kegel", "progressiveMuscleRelaxation"]
    for kind in methods {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "--ui-testing-skip-introduction", "--readiness-disabled", "-AppleLanguages", "(zh-Hans)", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO", "-fangcun.motionMode", "standard", "-fangcun.practice.v4.quickKind", kind]
      app.launch()
      XCTAssertTrue(app.buttons["hub.quickStart"].waitForExistence(timeout: 10))
      app.buttons["hub.quickStart"].tap()
      let prepare = app.buttons["practice.prepare.start"]
      if prepare.waitForExistence(timeout: 2) { prepare.tap() }
      XCTAssertTrue(app.buttons["Pause practice"].waitForExistence(timeout: 10))
      if kind == "progressiveMuscleRelaxation" {
        // Wait on the real clock for the first hand tension/release, never inject elapsed time.
        RunLoop.current.run(until: Date().addingTimeInterval(90))
      }
      print("FANGCUN_MOTION_START:\(kind)")
      RunLoop.current.run(until: Date().addingTimeInterval(24))
      app.buttons["Pause practice"].tap()
      XCTAssertTrue(app.buttons["Continue practice"].waitForExistence(timeout: 3))
      RunLoop.current.run(until: Date().addingTimeInterval(3))
      app.buttons["Continue practice"].tap()
      RunLoop.current.run(until: Date().addingTimeInterval(4))
      print("FANGCUN_MOTION_STOP:\(kind)")
      app.terminate()
    }
  }
}
