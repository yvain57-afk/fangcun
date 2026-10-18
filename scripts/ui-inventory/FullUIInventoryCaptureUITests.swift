import XCTest

/// Review-only capture journeys. All records belong to the isolated UI-testing store.
final class FullUIInventoryCaptureUITests: XCTestCase {
  @MainActor private func launch(_ extra: [String] = []) -> XCUIApplication {
    continueAfterFailure = false
    executionTimeAllowance = 1200
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--readiness-fixture=scoreSleep375", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN", "-fangcun.dark", "NO", "-fangcun.largeType", "NO", "-fangcun.reduceMotion", "NO", "-fangcun.motionMode", "standard", "-fangcun.practice.v4.quickKind", "physiologicalSigh", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryLarge"] + extra
    if extra.contains(where: { $0.hasPrefix("--readiness-fixture=") }) {
      app.launchArguments.removeAll { $0 == "--readiness-fixture=scoreSleep375" }
    }
    // Launch defaults are explicit and unique, so appearance captures cannot inherit another run.
    for key in ["-fangcun.dark", "-fangcun.largeType", "-UIPreferredContentSizeCategoryName"] {
      if extra.contains(key), let first = app.launchArguments.firstIndex(of: key) {
        app.launchArguments.removeSubrange(first...(first + 1))
      }
    }
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["呼吸"].waitForExistence(timeout: 15))
    return app
  }
  @MainActor private func openAuditSettings(_ app: XCUIApplication) {
    if !app.tabBars.buttons["日常"].isSelected { app.tabBars.buttons["日常"].tap() }
    Thread.sleep(forTimeInterval: 0.8)
    let settings = app.buttons["daily.settings"]
    for _ in 0..<12 {
      let f = settings.frame
      if settings.exists, f.height > 0, f.minY >= app.frame.minY, f.maxY <= app.frame.maxY - 110 { break }
      app.swipeDown()
    }
    XCTAssertTrue(settings.exists); settings.tap()
    // At maximum Dynamic Type the first switches are below the fold; verify the destination title.
    XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 8))
  }
  @MainActor private func shot(_ name: String, _ app: XCUIApplication) {
    Thread.sleep(forTimeInterval: 0.8) // Let sheet/navigation transitions settle before capturing.
    let item = XCTAttachment(screenshot: app.screenshot()); item.name = name; item.lifetime = .keepAlways; add(item)
  }
  @MainActor private func tap(_ id: String, _ app: XCUIApplication) {
    let exact = app.buttons[id].firstMatch
    _ = exact.waitForExistence(timeout: 2)
    let b = exact.exists ? exact : app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", id)).firstMatch
    for _ in 0..<7 where !b.isHittable { app.swipeUp() }
    for _ in 0..<12 where !b.isHittable { app.swipeDown() }
    XCTAssertTrue(b.isHittable, id); b.tap()
  }
  @MainActor private func pages(_ name: String, _ app: XCUIApplication, _ count: Int = 3) {
    shot(name + "-01", app)
    for n in 2...count { app.swipeUp(); shot(name + String(format: "-%02d", n), app) }
  }
  @MainActor func test01HubAndNineMethods() {
    let app = launch()
    pages("01-呼吸首页", app, 5)
    let methods: [(String, Int)] = [("physiologicalSigh",300),("pacedBreathing",300),("balancedBreathing",300),("boxBreathing",180),("diaphragmaticBreathing",180),("alternateNostrilBreathing",180),("meditation",300),("nsdr",600),("kegel",180)]
    for (i, pair) in methods.enumerated() {
      for _ in 0..<14 where !app.buttons["hub.quickStart"].isHittable { app.swipeDown() }
      openV4Method(pair.0, app: app)
      let prefix = String(format: "02-%02d-", i+1) + pair.0
      pages(prefix + "-详情", app, 4)
      tap("practice.\(pair.0).\(pair.1)", app)
      if app.buttons["practice.entry.skip"].waitForExistence(timeout: 1) {
        shot(prefix + "-准备入场", app); app.buttons["practice.entry.skip"].tap()
      }
      XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 10))
      shot(prefix + "-训练A", app)
      Thread.sleep(forTimeInterval: 3)
      shot(prefix + "-训练B", app)
      tap("暂停练习", app); shot(prefix + "-暂停", app)
      tap("结束", app); shot(prefix + "-结束确认", app)
      tap("practice.finish.confirm", app)
      XCTAssertTrue(app.staticTexts["practice.actualSummary"].waitForExistence(timeout: 6))
      if i == 0 { pages("03-练习反馈", app, 2) }
      tap("practice.feedback.skip", app)
      XCTAssertTrue(app.buttons["practice.saved.done"].waitForExistence(timeout: 6))
      if i == 0 { pages("03-练习已保存", app, 2) }
      tap("practice.saved.done", app)
      if app.navigationBars.buttons.firstMatch.exists { app.navigationBars.buttons.firstMatch.tap() }
    }
    openV4Records(app); pages("04-练习记录-有记录", app, 3)
  }
  @MainActor func test02DailyScoreAndTrends() {
    let app = launch(); app.tabBars.buttons["日常"].tap()
    XCTAssertTrue(app.staticTexts["78"].waitForExistence(timeout: 15))
    shot("05-日常-状态分", app)
    tap("today.evidence", app); shot("06-分数构成", app)
    tap("查看这项数据", app); shot("06-分数构成-展开", app)
    tap("status.method", app); pages("06-评分说明", app, 3)
    app.navigationBars.buttons.firstMatch.tap(); pages("05-日常-全页", app, 3)
    tap("today.trends", app); shot("07-趋势-7天", app)
    app.segmentedControls["readiness.history.range"].buttons["28 天"].tap(); shot("07-趋势-28天", app)
    let empty = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "没有状态分")).firstMatch
    if empty.exists { empty.tap(); shot("07-趋势-空白日期", app) }
    tap("status.history.legacy", app); pages("07-趋势-旧版记录", app, 3)
  }
  @MainActor func test03Drinks() {
    let app = launch(); app.tabBars.buttons["日常"].tap()
    tap("today.drinks", app); shot("08-饮品-半屏", app)
    tap("drinks.add.water", app); tap("drinks.add.coffee", app); shot("08-饮品-记录后", app)
    tap("drinks.manage", app); pages("09-饮品编辑-新增", app, 3)
    tap("drinks.edit.save", app); shot("09-饮品编辑-已保存", app)
    let entry = app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@", "drinks.edit.entry.")).firstMatch
    for _ in 0..<8 where !entry.isHittable { app.swipeUp() }
    XCTAssertTrue(entry.isHittable); entry.tap(); pages("09-饮品编辑-已有记录", app, 3)
  }
  @MainActor func test04Feelings() {
    let app = launch(); app.tabBars.buttons["日常"].tap(); tap("home.checkIn", app)
    XCTAssertTrue(app.otherElements["checkIn.emotionField"].waitForExistence(timeout: 5))
    shot("10-感受-罗盘", app)
    app.otherElements["checkIn.emotionField"].coordinate(withNormalizedOffset: CGVector(dx:0.25,dy:0.25)).tap()
    shot("10-感受-选词", app); tap("emotionWord.anxious", app)
    XCTAssertTrue(app.staticTexts["已记录此刻"].waitForExistence(timeout: 5))
    pages("10-感受-已记录与补充", app, 3)
    tap("肩颈紧", app); shot("10-感受-补充选中", app)
    tap("保存补充", app); shot("10-感受-补充保存", app)
  }
  @MainActor func test05Recovery() {
    let app = launch(); app.tabBars.buttons["日常"].tap()
    XCTAssertTrue(app.staticTexts["78"].waitForExistence(timeout: 15))
    openDailyActions(app); pages("11-轻行动-选择", app, 2)
    tap("完成", app)
    for _ in 0..<10 where !app.buttons["today.start"].isHittable { app.swipeDown() }
    tap("today.start", app); shot("11-轻行动-准备", app)
    tap("recovery.start", app); shot("11-轻行动-进行", app)
    tap("recovery.pauseResume", app); shot("11-轻行动-暂停", app)
    tap("recovery.finish", app); shot("11-轻行动-反馈", app)
    tap("recovery.skip", app); shot("11-轻行动-已保存", app)
    tap("recovery.done", app); openAuditSettings(app)
    tap("行动与反馈记录", app); shot("11-行动记录", app)
    tap("recovery.history.record", app); pages("11-行动记录-详情", app, 2)
  }
  @MainActor func test06Settings() {
    let app = launch(); openAuditSettings(app); pages("12-设置", app, 4)
    let links = ["饮品与关怀", "跨端记录状态", "恢复参考与来源", "行动与反馈记录", "历史与趋势", "隐私与数据", "诊断与导出", "方寸 Fangcun"]
    for (i, label) in links.enumerated() {
      app.terminate()
      let app = launch(); openAuditSettings(app)
      if label == "诊断与导出" && !app.buttons[label].exists { continue }
      tap(label, app); pages(String(format:"13-%02d-",i+1)+label, app, label == "饮品与关怀" ? 6 : 3)
      if label == "恢复参考与来源" {
        for _ in 0..<8 where !app.buttons["readiness.diagnostics"].isHittable { app.swipeDown() }
        tap("readiness.diagnostics", app); pages("13-数据诊断高级", app, 4); app.navigationBars.buttons.firstMatch.tap()
      }
      app.navigationBars.buttons.firstMatch.tap()
    }
  }
  @MainActor func test07EmptyAndFailure() {
    let app = launch(["--readiness-fixture=insufficient"])
    openV4Records(app); shot("14-练习记录-空", app); app.navigationBars.buttons.firstMatch.tap()
    app.tabBars.buttons["日常"].tap()
    XCTAssertTrue(app.staticTexts["status.empty"].waitForExistence(timeout: 15)); pages("14-日常-无数据", app, 2)
    tap("status.manual", app); shot("14-补记睡眠", app)
    app.terminate()
    let broken = launch(["--ui-testing-practice-save-failure-once"])
    tap("hub.quickStart", broken)
    XCTAssertTrue(broken.buttons["暂停练习"].waitForExistence(timeout:10))
    tap("结束", broken); tap("practice.finish.confirm", broken)
    XCTAssertTrue(broken.alerts["未能保留本次练习"].waitForExistence(timeout:8))
    shot("14-练习保存失败-重试弹窗", broken)
  }
  @MainActor func test08Appearance() {
    for (name, args) in [("深色",["-fangcun.dark","YES"]),("大字号",["-fangcun.largeType","YES","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"])] {
      let app = launch(args); pages("15-"+name+"-首页", app, 2)
      app.tabBars.buttons["日常"].tap(); XCTAssertTrue(app.staticTexts["78"].waitForExistence(timeout:15))
      if name == "大字号" {
        let action = app.buttons["today.start"]
        XCTAssertTrue(action.isHittable)
        XCTAssertLessThan(action.frame.height, app.frame.height * 0.28)
      }
      pages("15-"+name+"-日常", app, 3)
      app.terminate()
      let settingsApp = launch(args); openAuditSettings(settingsApp)
      pages("15-"+name+"-设置", settingsApp, 2)
      settingsApp.terminate()
    }
  }
  @MainActor func test09MenusDemonstrationAndNaturalCompletion() {
    let app = launch()
    tap("hub.filter.专注", app); pages("16-首页-专注筛选", app, 2)
    for _ in 0..<10 where !app.buttons["hub.quickStart"].isHittable { app.swipeDown() }
    tap("hub.filter.全部", app)
    openV4Method("balancedBreathing", app: app)
    if app.buttons["practice.demo"].label == "看看动作示范" { tap("practice.demo", app) }; shot("16-均衡呼吸-动作示范", app)
    let variant = app.buttons["吸 4 秒 / 呼 4 秒"].firstMatch
    for _ in 0..<8 where !variant.isHittable { app.swipeUp() }
    XCTAssertTrue(variant.isHittable); variant.tap()
    let track = app.descendants(matching: .any)["practice.phaseTrack"].firstMatch
    XCTAssertTrue(String(describing: track.value).contains("吸气4秒"))
    shot("16-均衡呼吸-4秒选项", app)
    let guide = app.buttons["引导设置"].firstMatch
    let start = app.buttons["practice.balancedBreathing.300"]
    for _ in 0..<8 where guide.frame.maxY >= start.frame.minY { app.swipeUp() }
    XCTAssertLessThan(guide.frame.maxY, start.frame.minY)
    guide.tap()
    XCTAssertTrue(app.navigationBars["均衡慢呼吸"].exists)
    shot("16-引导设置-展开", app)
    app.navigationBars.buttons.firstMatch.tap()
    for _ in 0..<12 where !app.buttons["hub.quickStart"].isHittable { app.swipeDown() }
    tap("practice.physiologicalSigh.60", app)
    XCTAssertTrue(app.buttons["practice.prepare.start"].waitForExistence(timeout: 5))
    pages("16-一分钟体验-准备与引导设置", app, 4)
    tap("practice.prepare.start", app)
    if app.buttons["practice.entry.skip"].waitForExistence(timeout: 1) { shot("16-一分钟体验-入场", app); app.buttons["practice.entry.skip"].tap() }
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 8))
    tap("practice.close", app); shot("16-关闭练习确认", app); tap("practice.finish.cancel", app)
    XCTAssertTrue(app.buttons["practice.feedback.skip"].waitForExistence(timeout: 75))
    pages("16-自然完成-反馈", app, 2)
    tap("更舒服", app); shot("16-练习反馈-选中", app)
    tap("保留这次感受", app)
    XCTAssertTrue(app.buttons["practice.saved.done"].waitForExistence(timeout: 6)); shot("16-自然完成-保存结果", app)
    tap("practice.saved.done", app); openV4Records(app)
    tap("按方法查看", app); shot("16-练习记录-筛选菜单", app)
  }
  @MainActor func test10CareDialogs() {
    let app = launch(); openAuditSettings(app); tap("饮品与关怀", app)
    tap("了解酒后危险症状", app); shot("17-关怀-危险症状说明", app); tap("完成", app)
    tap("清除关怀偏好与提醒", app); shot("17-关怀-清除确认", app)
    tap("data.clear.cancel", app); app.navigationBars.buttons.firstMatch.tap()
    tap("恢复参考与来源", app); tap("清除本地准备度资料", app); shot("17-准备度-清除确认", app)
    tap("data.clear.cancel", app)
  }
  @MainActor func test11StatusVariants() {
    for scenario in ["scoreSleep480", "scoreSleep240", "scoreSleep45", "scoreFull240", "failed", "scoreExpired", "scoreHRVOnly"] {
      let app = launch(["--readiness-fixture="+scenario]); app.tabBars.buttons["日常"].tap()
      XCTAssertTrue(app.buttons["today.start"].waitForExistence(timeout: 15))
      Thread.sleep(forTimeInterval: 2); shot("18-状态-"+scenario, app)
      if scenario == "scoreFull240" { tap("today.evidence", app); pages("18-多指标-分数构成", app, 3) }
      app.terminate()
    }
  }

  @MainActor func test12OtherActionsAndCareOptions() {
    let app = launch(); app.tabBars.buttons["日常"].tap()
    for kind in ["seatedReset", "movementBreak"] {
      openDailyActions(app)
      if kind == "movementBreak" { tap("status.environment", app); shot("19-环境-选择菜单", app); tap("可以安全走动", app) }
      tap("recovery.choose."+kind, app); shot("19-"+kind+"-准备", app)
      tap("recovery.start", app); shot("19-"+kind+"-进行", app)
      tap("recovery.finish", app); tap("recovery.skip", app); tap("recovery.done", app)
    }
    openAuditSettings(app); tap("饮品与关怀", app)
    let sleep = app.switches["使用我确认的睡眠计划"]
    for _ in 0..<8 where !sleep.isHittable { app.swipeUp() }
    sleep.tap(); shot("19-关怀-睡眠计划展开", app); app.swipeUp(); shot("19-关怀-睡眠计划与通知", app)
    app.navigationBars.buttons.firstMatch.tap(); tap("恢复参考与来源", app)
    tap("停止读取", app); shot("19-来源-暂停读取", app)
    app.navigationBars.buttons.firstMatch.tap(); tap("settings.done", app)
    for _ in 0..<12 where !app.buttons["daily.settings"].isHittable { app.swipeDown() }
    shot("19-日常-分析已暂停", app)
  }

  @MainActor func test13ResumeDraftAndNight() {
    let app = launch(); openV4Method("boxBreathing", app: app)
    tap("practice.boxBreathing.180", app)
    if app.buttons["practice.entry.skip"].waitForExistence(timeout:1) { app.buttons["practice.entry.skip"].tap() }
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout:8)); tap("暂停练习", app)
    XCUIDevice.shared.press(.home); app.terminate()
    let resumed = launch(["--ui-testing-preserve-practice-draft"])
    XCTAssertTrue(resumed.buttons["hub.resume"].waitForExistence(timeout:8)); shot("20-中断后-首页恢复入口", resumed)
    tap("hub.resume", resumed); shot("20-中断后-回到练习", resumed)
    if resumed.buttons["继续练习"].exists { tap("继续练习", resumed); shot("20-中断后-准备继续", resumed) }
    resumed.terminate()
    let night = launch(["--score-night", "-fangcun.dark", "YES"])
    night.tabBars.buttons["日常"].tap(); XCTAssertTrue(night.staticTexts["78"].waitForExistence(timeout:15))
    shot("20-夜间日常", night)
  }

  @MainActor func test14ExpandedDrinkFields() {
    let app = launch(); app.tabBars.buttons["日常"].tap(); tap("today.drinks", app)
    shot("08-饮品-半屏", app)
    tap("drinks.manage", app)
    tap("是否含咖啡因", app); shot("21-饮品-咖啡因选项", app); tap("有", app)
    shot("21-饮品-咖啡因剂量", app)
    tap("是否含酒精", app); tap("有", app); shot("21-饮品-酒精度", app)
    pages("21-饮品-复合输入", app, 2)
    let volume = app.textFields["drinks.edit.volume"]
    for _ in 0..<8 where !volume.isHittable { app.swipeDown() }
    volume.tap(); shot("21-饮品-键盘输入", app)
  }

  @MainActor func test15AboutAndDiagnostics() {
    for label in ["方寸 Fangcun", "诊断与导出"] {
      let app = launch(); openAuditSettings(app); tap(label, app)
      pages(label == "方寸 Fangcun" ? "13-08-方寸 Fangcun" : "13-07-诊断与导出", app, 4)
      app.terminate()
    }
  }

  @MainActor func test16DisabledAnalysisAndLegacyTrend() {
    let app = launch(["--readiness-disabled"]); app.tabBars.buttons["日常"].tap()
    XCTAssertTrue(app.buttons["today.start"].waitForExistence(timeout:15)); pages("22-未启用分析-日常", app, 3)
    tap("today.trends", app); pages("22-未启用分析-趋势", app, 3)
  }

  @MainActor func test17NaturalCompletion() {
    let app = launch(); tap("practice.physiologicalSigh.60", app)
    tap("practice.prepare.start", app)
    if app.buttons["practice.entry.skip"].waitForExistence(timeout:1) { app.buttons["practice.entry.skip"].tap() }
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout:8))
    XCTAssertTrue(app.buttons["practice.feedback.skip"].waitForExistence(timeout:75))
    pages("16-自然完成-反馈", app, 2); tap("更舒服", app); shot("16-练习反馈-选中", app)
    tap("保留这次感受", app); XCTAssertTrue(app.buttons["practice.saved.done"].waitForExistence(timeout:6))
    shot("16-自然完成-保存结果", app); tap("practice.saved.done", app); openV4Records(app)
    tap("按方法查看", app); shot("16-练习记录-筛选菜单", app)
  }

  @MainActor func test18KegelContractsAndOpensWithActualPhases() {
    let app = launch(); openV4Method("kegel", app: app)
    tap("practice.kegel.180", app)
    if app.buttons["practice.entry.skip"].waitForExistence(timeout: 1) { app.buttons["practice.entry.skip"].tap() }
    XCTAssertTrue(app.buttons["暂停练习"].waitForExistence(timeout: 10))
    let phase = app.staticTexts["practice.stageTitle"]
    let envelope = app.descendants(matching: .any)["practice.contractionGuide"].firstMatch
    let contract = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "轻轻收紧"), object: phase)
    XCTAssertEqual(XCTWaiter.wait(for: [contract], timeout: 15), .completed)
    Thread.sleep(forTimeInterval: 0.6)
    let contracted = envelope.frame.width
    shot("02-09-kegel-训练A", app)
    let release = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "完全放松"), object: phase)
    XCTAssertEqual(XCTWaiter.wait(for: [release], timeout: 10), .completed)
    Thread.sleep(forTimeInterval: 0.6)
    XCTAssertGreaterThan(envelope.frame.width - contracted, 75)
    shot("02-09-kegel-训练B", app)
    tap("暂停练习", app)
    let pausedWidth = envelope.frame.width
    Thread.sleep(forTimeInterval: 1)
    XCTAssertEqual(envelope.frame.width, pausedWidth, accuracy: 0.5)
    shot("02-09-kegel-暂停", app)
    tap("结束", app); shot("02-09-kegel-结束确认", app)
    tap("practice.finish.confirm", app); tap("practice.feedback.skip", app); tap("practice.saved.done", app)
  }

  @MainActor func test19AlternateGuideFitsAboveTransport() {
    let app = launch(); openV4Method("alternateNostrilBreathing", app: app)
    tap("practice.alternateNostrilBreathing.180", app)
    if app.buttons["practice.entry.skip"].waitForExistence(timeout: 1) { app.buttons["practice.entry.skip"].tap() }
    let pause = app.buttons["暂停练习"]
    XCTAssertTrue(pause.waitForExistence(timeout: 10))
    let track = app.descendants(matching: .any)["practice.phaseTrack"].firstMatch
    XCTAssertTrue(track.exists)
    XCTAssertLessThan(track.frame.maxY, pause.frame.minY)
    shot("02-06-alternateNostrilBreathing-训练A", app)
    Thread.sleep(forTimeInterval: 3)
    shot("02-06-alternateNostrilBreathing-训练B", app)
    tap("暂停练习", app); shot("02-06-alternateNostrilBreathing-暂停", app)
    tap("结束", app); shot("02-06-alternateNostrilBreathing-结束确认", app)
    tap("practice.finish.confirm", app); tap("practice.feedback.skip", app); tap("practice.saved.done", app)
  }

}
