import XCTest

/// Native visual evidence, using only the isolated synthetic test store.
final class MotionReviewUITests: XCTestCase {
  @MainActor func testNineNativeMotionClips() {
    continueAfterFailure = false
    executionTimeAllowance = 1200
    let methods: [(String, Int)] = [("physiologicalSigh",300),("pacedBreathing",300),("balancedBreathing",300),("boxBreathing",180),("diaphragmaticBreathing",180),("alternateNostrilBreathing",180),("meditation",300),("nsdr",600),("kegel",180)]
    for (kind, duration) in methods {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "--readiness-disabled", "-AppleLanguages", "(zh-Hans)", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO", "-fangcun.motionMode", "standard"]
      app.launch()
      XCTAssertTrue(app.tabBars.buttons["呼吸"].waitForExistence(timeout: 10))
      openV4Method(kind, app: app)
      app.buttons["practice.\(kind).\(duration)"].tap()
      if app.buttons["practice.entry.skip"].waitForExistence(timeout: 1) { app.buttons["practice.entry.skip"].tap() }
      XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 10))
      print("FANGCUN_MOTION_START:\(kind)")
      RunLoop.current.run(until: Date().addingTimeInterval(24))
      app.buttons["暂停练习"].tap()
      XCTAssertTrue(app.buttons["继续练习"].waitForExistence(timeout: 3))
      RunLoop.current.run(until: Date().addingTimeInterval(3))
      app.buttons["继续练习"].tap()
      RunLoop.current.run(until: Date().addingTimeInterval(4))
      print("FANGCUN_MOTION_STOP:\(kind)")
      app.terminate()
    }
  }
}
