# M0–M2 核验与交付 — 2026-09-18

## 已交付

M0 基线提交 `cf5c87d`；M1 在 `codex/fangcun-v1-m0-m1` 分支提交。初次 M1 交付时未推送；本轮按用户授权推送同一独立开发分支，保持 `main` 不变。未上架或上传 TestFlight。

- 当前证据资格门控：历史充分但近期为空、读取失败、全部过期不能显示 steady；一项体征/只有睡眠/不够可靠显示 limited。
- watch / elevated 分开；运动保护不伪装正常；主卡用测量日期，详情区分查询/计算/测量；睡眠标“最近主睡眠”与结束日期。
- 第二条身体线索显示实际 HRV/RHR 及测量时间；新文案 40 个稳定 key，与 COPY_REVIEW.csv 一一对应。
- legacy 快照保留原内容和旧标题，同日刷新不会删除旧记录；首写前保留已有 archive 原始备份。
- 原猫狗图像、动效、主题 token 和练习流程未改。未扩大健康权限或添加产品网络请求。

## 实际验证

| 检查 | 结果 | 证据 |
|---|---|---|
| Core | 67 tests / 13 suites passed | evidence/m1-core.txt |
| App 最终代码 | 31 tests / 4 suites passed，含 12 个 provider fixture 参数案例 | evidence/m1-final-unit.txt |
| UI | 7 tests passed，12 个原始输入情景；深浅色、大字、时戳分离与原练习保存链路通过 | evidence/m1-final.txt |
| Watch scheme | Debug watchOS Simulator 构建通过 | evidence/m1-watch.txt |
| iOS + 嵌入 Watch | 最终 Release 真机构建通过 | evidence/device-receipt.json；含签名的完整日志只留本机 |
| Release mock 排除 | 二进制没有 health-fixture、preview-state、UI-testing 内存模式入口；HealthKit entitlement 存在 | 构建后检查及 device-receipt.json |
| 文案 | Catalog 40 个 body.* key 和 CSV 完全匹配；代码静态 key 均存在 | 构建前后脚本检查 |
| 差异 | git diff --check cf5c87d 通过（M1 改动） | 提交前检查 |
| 真机安装 | iPhone 16 Pro 覆盖安装、启动成功，版本回读 1.0.0 (2026091802) | evidence/device-receipt.json |

UI 最终截图使用最终界面源代码；随后仅补齐 Release 的持久化测试入口隔离，并把文案 helper 移入既有 DesignSystem 目录。最终 Debug App 单元测试及 Release iOS/Watch 构建再次通过；无需因此重复全部 UI 场景。

## 重放测试

先设置实际 `DEVELOPER_DIR`，用 `xcrun simctl list devices available` 选择本机真实存在的设备，把 ID 放入 `IOS_SIMULATOR_ID`。不要复制他人的设备标识。

```sh
swift test --package-path InnerBalanceCore
xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -configuration Debug -destination "platform=iOS Simulator,id=$IOS_SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" -resultBundlePath "$EVIDENCE/m1-final.xcresult" \
  -parallel-testing-enabled NO -test-timeouts-enabled YES -maximum-test-execution-time-allowance 90 \
  -only-testing:InnerBalanceTests/HomeViewModelTests \
  -only-testing:InnerBalanceTests/HomeEvidencePipelineTests \
  -only-testing:InnerBalanceTests/FangcunDiaryTests \
  -only-testing:InnerBalanceTests/PracticeSessionViewModelTests \
  -only-testing:InnerBalanceUITests/FangcunRedesignUITests \
  -only-testing:InnerBalanceUITests/HomeEvidencePipelineUITests CODE_SIGNING_ALLOWED=NO
xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' \
  -configuration Debug -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath "$WATCH_DERIVED_DATA" CODE_SIGNING_ALLOWED=NO
xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -configuration Release -destination 'generic/platform=iOS' -derivedDataPath "$DEVICE_DERIVED_DATA" \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$LOCAL_TEAM" CURRENT_PROJECT_VERSION=2026091802
xcrun devicectl device install app --device "$IPHONE_ID" "$DEVICE_DERIVED_DATA/Build/Products/Release-iphoneos/InnerBalance.app"
xcrun devicectl device process launch --device "$IPHONE_ID" com.yvainair.InnerBalance
xcrun devicectl device info apps --device "$IPHONE_ID" --bundle-id com.yvainair.InnerBalance
```

最终补测使用相同 App 四个 suite，去掉两个 UI selector，结果包为 `m1-final-unit.xcresult`。原始日志、签名产物、设备回执及 xcresult 留在本机 `/Users/yvainair/Code/Codex/2026-09-18/fangcun-v1/`；公开可提交证据经过路径/设备标识删减、行尾空白规范化，所有截图均为模拟器合成数据。

## 已知验证边界

- 基线与本轮无签名模拟器测试宿主都出现 HealthKit entitlement 的环境日志；fixture 用注入的原始记录，不把这种运行当成真实 HealthKit 授权验证。最终签名真机产物另行核验 HealthKit entitlement 存在。
- Xcode beta 既有 deprecation、调试器与模拟器系统服务告警未导致测试失败；没有删除测试或放宽断言换取通过。
- 真机安装/启动及版本回读，不等同真机逐屏人工验收或健康数据准确性验证。
- 物理 Watch 的腕下运行、触感、系统失效和跨端送达仍 blocked；Widget/通知仅完成独立编译实验。
- M2 新准备度、M3 全量存储迁移/28 天趋势及取消分类柱高、M4 Watch 离线会话与同步、M5 系统入口、M6 完整验收与 Live Activity 尚未实施；M7 暂缓。

## M0–M1 逐项复核（M2 前置，2026-09-18）

| 用户核验项 | 现有测试名称及结果 | 证据 |
|---|---|---|
| 历史充分，当前无可靠资料不平稳 | BodyLoadEngineTests.historyWithoutCurrentEvidence(0/4/5/14)、HomeEvidencePipelineTests.rawInput(noCurrentHistory/stale/failed)、HomeEvidencePipelineUITests.testHistoryFailureAndLimitedEvidence 均通过 | m1-core.txt、m1-final-unit.txt、m1-final.txt |
| 睡眠单项、体征单项为有限 | currentEvidenceGate、rawInput(sleepOnly/oneCardio/unreliablePair)、testHistoryFailureAndLimitedEvidence 通过 | 同上 |
| 运动保护不表达正常 | recentWorkoutSuppressesElevatedConclusion、rawInput(workoutProtected) 通过；本次给 testQualifiedEvidenceAndWorkoutProtection 增加首页保护说明断言，通过 | m1-audit.txt：该 test passed（同次其他测试有失败，未混算） |
| 非最近一夜不叫昨晚 | rawInput(previousSleep) 验证 stale；本次在 testPreviousSleepAndIncompleteBaselines 验证真实首页卡片包含“最近主睡眠”和 9月16日，且不含“昨晚”，通过 | m1-audit.txt |
| 测量/查询/计算分离 | timeSeparation、testMeasurementTimeDoesNotBecomeQueryTime 通过，验证原时间不随刷新延长 | m1-final-unit.txt、m1-final.txt |
| provider→VM→当前首页 | HomeEvidencePipelineUITests 四个 test，共 12 种 raw fixture；入口为 --health-fixture，未使用 --preview-state | m1-final.txt；HomeHealthFixture.swift 与 RootView.swift |
| 练习无回归 | PracticeSessionViewModelTests 全套；testNativeTodayDrinksTrendsPracticeAndSettings；testBreathingWithMotionEnabledCanPauseAndExit 通过 | m1-final-unit.txt、m1-final.txt |
| 饮品/记录无回归 | compositeDrinkUndoAndReload、dayBoundariesAndUnknownHistory、unreadableArchiveIsNotOverwritten、legacySnapshotKeepsItsMeaningAndSurvivesSameDayRefresh 通过 | m1-final-unit.txt |
| 显示偏好 | 原 testAcceptedSoloAndDuoScenesInDarkAndLargeType 通过；新增 testDisplayPreferencesSurviveRelaunch 验证三个开关即时值及重启保留，通过 | m1-preferences.txt |

补测命令使用相同 InnerBalance scheme、Debug、专用 iPhone 模拟器及 CODE_SIGNING_ALLOWED=NO，仅选择上述两个 HomeEvidencePipelineUITests test 和新偏好 test（完整参数见日志）。第一次偏好测试点到 SwiftUI Switch 行中央，未实际切换；修正为控件右侧，并增加即时值断言后单独重跑通过。保留首次失败日志，不把整次失败的 test run 标成通过。未修改 App 行为。

原 M0–M1 的代码验收成立；平台能力验收仅按 CAPABILITIES 的具体层级登记，不包含 Watch 后台或跨端送达的真机成功。

## M2-01 初步证据

`ReadinessSourceTests.sourceDefinitionsAndRevisions / noSilentSwitchAndManualRebaseline / uuidSyncVersionAndExplicitMirrors / deletionWinsAndCacheIsBounded` 通过，Core 共 71 项。`ReadinessHealthKitProviderTests.actualHKObjectsNormalizeWithoutWritingHealthStore` 通过，覆盖实际 HKQuantitySample 单位换算、原 UUID/时间/同步元数据及 inBed 类别保留，不写 HealthKit。SDK 适配器和观察器编译通过。

首次 adapter 测试错误假定“未保存的 HKSample 已有来源 bundle”，SDK 实际为空。改为断言原样保留来源并且不能被选择为合格主源，重跑通过；没有给未保存对象编造来源。失败与复验日志均保留在 evidence/m2-01-*.txt。真机 HealthKit 增量、后台回调尚未验证，事务/锚点提交验收在 M2-04 完成。

## M2-02 核验

命令：`swift test --package-path InnerBalanceCore`。最终 78 tests / 15 suites 通过，证据 [m2-02-core-recheck.txt](evidence/m2-02-core-recheck.txt)。

新增 `ReadinessFeatureTests`：`sleepUnionDoesNotMixSourcesOrCountAwake`、`lateSleepKeepsCycleAndAmbiguousMatchesRequireReview`、`shiftWorkNapManualChoiceAndArrival`、`excessiveFutureAndConflictingSleep`、`sparseCoverageInterventionAndRestingReuse`、`baselineHasIndependentDaysNoCurrentOrFutureAndMADFloors`、`daylightSavingBucketsAreAbsoluteAndCycleIsTimezoneIndependent`。最后一项当前覆盖换时区与绝对桶，实际夏令时重复小时在 M2-03 补充。

首轮同小时 fixture 误放在整点边界两侧，实际属于两个绝对小时；测试失败如实保留 [m2-02-core.txt](evidence/m2-02-core.txt)。调整合成采样时刻，使 3 样本确实在同一小时，未放宽生产规则。

## M2-03 verification

Command: `swift test --package-path InnerBalanceCore`. 86 tests / 16 suites passed: [log](evidence/m2-03-core-recheck.txt).

`ReadinessEngineTests.originalGoldenFileThroughRawSamples` reads the original G01-G10 JSON, generates 20 days of source-specific history and four current HRV samples across three absolute hours, then compares all ten results.

Other tests: `independentBaselineBoundariesAndCurrentCoverage` (6/7/8/13/14/28 days, 1/2/3 samples, independent 8/20-day eligibility); `enoughHistoryCannotInventCurrentAndPartialDataStayLimited`; `nonFiniteNegativeManualAmbiguousAndExtremeValuesDoNotBecomeUsual`; `noSilentFallbackAndSourceSwitchRebuildsOnlyNewSourceHistory`; `queryFailureCacheInvalidationAndFreshnessBoundaries` (18/24 hours, original cached timestamps); `trainingAndBackgroundEventsDoNotSuppressOrReward`; `arrivalBufferAndRealDSTRepeatedHour` (New York repeated 01:00 hour on 2026-11-01).

The first run matched every golden level but failed ten coverage-count assertions: the fourth synthetic timestamp was in the wrong hour bucket. The fixture was corrected, without relaxing production rules. [Initial log retained](evidence/m2-03-core.txt).

## M2 最终交付核验 — 2026-09-18

### 结果与边界

| 检查 | 真实结果 | 证据 |
|---|---|---|
| Core 最终版本 | 93 tests / 17 suites 全通过 | [m2-core-delivery](evidence/m2-core-delivery.txt) |
| App 全量单元测试 | 163 项，160 通过，3 失败（23 个断言）；不能称全绿 | [m2-app-acceptance](evidence/m2-app-acceptance.txt) |
| M2 前基线独立复验 | 在 `0062d4a` 隔离 worktree 运行涉及的两个 suite：54 项，51 通过，同样 3 失败、23 个断言 | [pre-m2-regression](evidence/pre-m2-regression.txt) |
| 首页及界面回归 | 8 UI tests / 0 failures；包含原始 provider → ViewModel → 当前真实首页、复合饮品/撤销、趋势、练习、显示偏好跨重启 | [m2-ui-acceptance](evidence/m2-ui-acceptance.txt) |
| iOS SDK / App | 全量 App 测试已编译并运行新 adapter、service 工厂以及 Core | 同 App log；无签名模拟器 |
| Watch scheme | Debug watchOS Simulator build succeeded | [m2-watch](evidence/m2-watch.txt) |
| 真机 / 平台后台 | 本轮未验证，不计入通过 | CAPABILITIES.md |

M2 增量只涉及 Readiness 领域、新 adapter/service、测试和文档。既有 App Features、DesignSystem、Persistence、资源/权限均无差异。原始任务书及 golden 文件未修改。

### 基线失败，未掩盖或修改断言

- `FangcunDesignSystemTests.approvedPaperPalette`：旧版棕色 palette 预期与既有新版蓝色资产不符（20 个色值断言）；另有浅色次级文字对比度 4.4631，低于该测试 4.5 门槛。这一项是真实既有可访问性不足，不只是测试过期。
- `FangcunDesignSystemTests.paperAppearanceDoesNotInvertAtNight`：测试仍要求源码固定 `.preferredColorScheme(.light)`，与既有可切换深色模式不符。
- `PracticePresentationTests.finishDialogCopyMatchesTheNextStep`：固定旧字符串预期与既有提前结束文案不符。

以上在本轮 M2 开发前提交上同样失败；相关源码及测试与本轮无差异。保留这些失败，不为追求绿灯放宽测试，也不在“保留现有 UI”的 M2 任务中重写配色/文案。M0–M1 和 M2 的定向功能核验已通过，**并不表示仓库全量 App 测试通过**。后续 UI 维护应明确修复对比度并统一已确认设计与测试契约。

开发中曾出现 Swift 6 actor 初始化的 `&&` autoclosure 隔离编译错误，已将隔离属性先读为局部值修复。保留 [Core 首次编译失败](evidence/m2-04-core-final.txt) 与 [App 首次编译失败](evidence/m2-app-final.txt)，修复后 Core、iOS 和 Watch 均完成编译；未放宽 Swift 并发检查。

### 任务书用例映射

| 样例 | 实际覆盖 |
|---|---|
| G01–G10 | `ReadinessEngineTests.originalGoldenFileThroughRawSamples`，读取原 JSON，经规范化样本、选源、睡眠、逐源基线与 Engine 全链路 |
| D01–D05 | `enoughHistoryCannotInventCurrentAndPartialDataStayLimited`、`independentBaselineBoundariesAndCurrentCoverage`，包括独立 8/20、20/3 日、7/13/14 日、2/3 样本 |
| D06–D08 | `ReadinessSourceTests.sourceDefinitionsAndRevisions`、`noSilentSwitchAndManualRebaseline`、`uuidSyncVersionAndExplicitMirrors`；手动切源加 `noSilentFallbackAndSourceSwitchRebuildsOnlyNewSourceHistory` |
| D09–D10 | `ReadinessFeatureTests.sleepUnionDoesNotMixSourcesOrCountAwake` |
| D11 | `shiftWorkNapManualChoiceAndArrival`，非夜间候选、两个长段歧义、人工短睡与缓冲 |
| D12 | `lateSleepKeepsCycleAndAmbiguousMatchesRequireReview`、`InsightsStoreTests.providerToStorePaginationRevisionsAndDeletion`；同周期 revision 2 / supersedes；M2 没有通知发送代码 |
| D13 | `excessiveFutureAndConflictingSleep` |
| D14 | `sparseCoverageInterventionAndRestingReuse`；Pipeline 对前周期已用 UUID 传递排除集合 |
| D15–D16 | `baselineHasIndependentDaysNoCurrentOrFutureAndMADFloors`、`nonFiniteNegativeManualAmbiguousAndExtremeValuesDoNotBecomeUsual` |
| D17 | G10 及 `nonFiniteNegativeManualAmbiguousAndExtremeValuesDoNotBecomeUsual` |
| D18–D19 | `trainingAndBackgroundEventsDoNotSuppressOrReward`；45 分钟训练不移除观测；评估没有饮品或完成次数加减分参数 |
| D20 | `deletionWinsAndCacheIsBounded`、`deletionBarrierSurvivesInterruptedPublishAndCorruptPrimary`、`providerToStorePaginationRevisionsAndDeletion` |
| D21 | `daylightSavingBucketsAreAbsoluteAndCycleIsTimezoneIndependent`、`arrivalBufferAndRealDSTRepeatedHour`（真实重复本地小时，绝对时长 3 小时） |
| D22 | `failureKeepsOriginalCacheButEmptyInitialReadIsNotPermissionDenial`、`queryFailureCacheInvalidationAndFreshnessBoundaries`；保护状态是合成错误重放，非实际锁屏验证 |
| D23 | `sourceChangeAndClearRejectLateRequests`、`concurrentRefreshCoalescesAndInvalidAnchorRebuildsCurrentEvidence` |
| D24 | `queryFailureCacheInvalidationAndFreshnessBoundaries`、`providerToStorePaginationRevisionsAndDeletion`；重刷不延长 validUntil，不重复增加 revision |

其他存储测试：`transactionFaultsKeepCursorsAndAssessmentTogether`、`corruptedJournalAndUnknownSchemaFailClosedWithoutWiping`。故障恢复实际操作临时文件，数据全合成。没有断电硬件实验、真实授权撤销或 HealthKit 后台到达验证。

### 最终实际命令

以下仅把本机路径和模拟器标识替换为变量；使用 Xcode 27 beta、已有 schemes。`EVIDENCE` 和 `DERIVED_DATA` 都在 Code scratch，未入库。App 全量及基线复验预期结果如上，不能把命令可运行当作测试全通过。

```sh
swift test --package-path InnerBalanceCore
xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$IOS_SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" -resultBundlePath "$EVIDENCE/m2-app-acceptance.xcresult" \
  -parallel-testing-enabled NO -only-testing:InnerBalanceTests CODE_SIGNING_ALLOWED=NO
xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$IOS_SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" -resultBundlePath "$EVIDENCE/m2-ui-acceptance.xcresult" \
  -parallel-testing-enabled NO -only-testing:InnerBalanceUITests/HomeEvidencePipelineUITests \
  -only-testing:InnerBalanceUITests/FangcunRedesignUITests CODE_SIGNING_ALLOWED=NO
xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' \
  -destination 'generic/platform=watchOS Simulator' -derivedDataPath "$DERIVED_DATA" CODE_SIGNING_ALLOWED=NO
# In the detached 0062d4a worktree, with a separate BASELINE_DERIVED_DATA:
xcodebuild build-for-testing -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$IOS_SIMULATOR_ID" -derivedDataPath "$BASELINE_DERIVED_DATA" \
  -only-testing:InnerBalanceTests/FangcunDesignSystemTests \
  -only-testing:InnerBalanceTests/PracticePresentationTests CODE_SIGNING_ALLOWED=NO
xcodebuild test-without-building -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$IOS_SIMULATOR_ID" -derivedDataPath "$BASELINE_DERIVED_DATA" \
  -resultBundlePath "$EVIDENCE/pre-m2-regression.xcresult" -parallel-testing-enabled NO \
  -only-testing:InnerBalanceTests/FangcunDesignSystemTests \
  -only-testing:InnerBalanceTests/PracticePresentationTests CODE_SIGNING_ALLOWED=NO
```

分阶段提交：M1 补证 `0062d4a`，M2-01 `9157b8d`，M2-02 `058a3e8`，M2-03 `1906270`；M2-04 提交见同分支历史。最终 HEAD 在交付回复提供。main 基准保持 `905626c6e08dc7a36ddd4e219abf6945795ac62f`。
