import XCTest

final class DrinkEditorUITests: XCTestCase {
  @MainActor func testCapacityEditingUndoAndQuickLogShareTheSameRecords() {
    continueAfterFailure = false
    let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--readiness-disabled", "-fangcun.dark", "NO"]
    app.launch()
    let drinks = app.buttons["today.drinks"]
    XCTAssertTrue(app.buttons["today.start"].waitForExistence(timeout: 10))
    reveal(drinks, app); drinks.tap()
    XCTAssertTrue(app.buttons["drinks.add.water"].waitForExistence(timeout: 5)); app.buttons["drinks.add.water"].tap()
    let manage = app.buttons["drinks.manage"]; reveal(manage, app); manage.tap()
    let volume = app.textFields["drinks.edit.volume"]
    XCTAssertTrue(volume.waitForExistence(timeout: 5))
    volume.tap(); volume.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10)+"500")
    let save = app.buttons["drinks.edit.save"]; reveal(save, app); save.tap()
    let entries = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "drinks.edit.entry."))
    XCTAssertEqual(entries.count, 2)
    let newest = entries.firstMatch; reveal(newest, app); newest.tap()
    reveal(volume, app); volume.tap()
    volume.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10)+"750")
    reveal(save, app); save.tap()
    let undo = app.buttons["撤销上一笔"]; reveal(undo, app); undo.tap()
    app.navigationBars.buttons["完成"].tap()
    let totals = app.descendants(matching: .any)["drinks.totals"].firstMatch
    XCTAssertTrue(totals.waitForExistence(timeout: 5))
    XCTAssertTrue(totals.label.contains("750")) // 250 quick log + 500 edited entry after undo.
  }
  @MainActor private func reveal(_ item: XCUIElement, _ app: XCUIApplication) {
    for _ in 0..<6 where !item.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(item.isHittable)
  }
}
