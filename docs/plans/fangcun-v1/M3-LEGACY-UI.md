# M3 旧 UI 基准对照

固定基准 `b80f81c9f4ad68381b68f6ade30c02e6848718e6` 使用独立 detached worktree 和 DerivedData 编译；无生产文件修改。选择扩大 UI 中失败的同一 19 个方法，19/19 再现失败，xcodebuild 正常退出 65，结果包可读取。当前扩大 UI 26/45，通过项含本轮全部新增 UI。

当前补回 `home.checkIn` 标识后，下列4个完整感受记录流程通过；没有删除、跳过或放宽旧断言。其余15项保留为基准遗留失败，不能称全仓UI通过。

| 测试 | b80 基准 | 当前扩大运行 | 补标识复验 |
|---|---|---|---|
| `CheckInFlowUITests.testBottomChromeDoesNotInterceptHomeScroll` | failed | failed | 未重跑，旧界面契约未改 |
| `CheckInFlowUITests.testEchoImmediatelyPersonalizesTheSentenceAndRecoveryAction` | failed | failed | 未重跑，旧界面契约未改 |
| `CheckInFlowUITests.testEmotionCompassDragCommitsItsEndpoint` | failed | failed | passed |
| `CheckInFlowUITests.testEmotionFieldRemainsUsableAtAccessibilityTextSizes` | failed | failed | passed |
| `CheckInFlowUITests.testFangcunNavigationUsesProductLanguage` | failed | failed | 未重跑，旧界面契约未改 |
| `CheckInFlowUITests.testHomeLeadsWithOneStressDecision` | failed | failed | 未重跑，旧界面契约未改 |
| `CheckInFlowUITests.testHomeResponseRemainsReachableAtAccessibilityTextSizes` | failed | failed | 未重跑，旧界面契约未改 |
| `CheckInFlowUITests.testPracticeLibraryOpensARealSession` | failed | failed | 未重跑，旧界面契约未改 |
| `CheckInFlowUITests.testPracticeLibraryStartsFromTheOutcomeInsteadOfAPlainCatalog` | failed | failed | 未重跑，旧界面契约未改 |
| `CheckInFlowUITests.testSelectingSuggestedWordImmediatelySavesPrimaryRecord` | failed | failed | passed |
| `CheckInFlowUITests.testStatusNeedsNoWritingAndDoesNotCreateAChoreList` | failed | failed | 未重跑，旧界面契约未改 |
| `CheckInFlowUITests.testUnclassifiedStillSavesSelectedValence` | failed | failed | passed |
| `FangcunAppearanceUITests.testCriticalScreensInCurrentAppearance` | failed | failed | 未重跑，旧界面契约未改 |
| `FangcunResponseLoopUITests.testDetailedThenQuickImmediatelyShowsOnlyTheQuickState` | failed | failed | 未重跑，旧界面契约未改 |
| `FangcunResponseLoopUITests.testFinishThenSkipFeedbackReturnsHomeWithCompletedOnly` | failed | failed | 未重跑，旧界面契约未改 |
| `FangcunResponseLoopUITests.testQuickThenDetailedImmediatelyShowsOnlyTheDetailedState` | failed | failed | 未重跑，旧界面契约未改 |
| `FangcunResponseLoopUITests.testSavedPostPracticeFeelingImmediatelyUpdatesHome` | failed | failed | 未重跑，旧界面契约未改 |
| `FangcunResponseLoopUITests.testSelectedPressureSourceImmediatelyUpdatesTheWholeHomeResponse` | failed | failed | 未重跑，旧界面契约未改 |
| `FangcunResponseLoopUITests.testStateChoicesStayInPlaceAfterResponding` | failed | failed | 未重跑，旧界面契约未改 |

证据：[基准日志](evidence/m3-baseline-ui.txt)、[基准结果包摘要](evidence/m3-baseline-ui-summary.json)、[扩大运行](evidence/m3-m3-ui-full.txt)。最终20项复验结果见 M3-REVIEW。

遗留原因：旧首页 home.echo.state 预设、home.stressConclusion、旧品牌 AX 类型、“此刻”导航与旧练习库文案不再对应已接受的界面。部分旧响应测试还期望主观状态直接改写首页结论，不能借本轮将其恢复到准备度模型。另有当前可选感受表单的4项定位问题已修复并走到原最终断言。

这些测试继续存在且完整扩大运行过；未将它们作为永久排除名单。后续若要更新其产品契约，应单独审阅，不能将本报告当作通过证明。
