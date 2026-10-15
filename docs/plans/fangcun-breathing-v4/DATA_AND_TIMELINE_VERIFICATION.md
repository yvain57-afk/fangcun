# V4 数据与训练时间线核验

核验日期：2026-10-15。范围对应 `06_整版验收与交付清单.md` 的 T01–T11、D01–D08。本表记录当前已有证据，不把代码实现、单元测试、模拟器编译和真机验收混为一项通过。

## 已读取的执行证据

- Core：`swift test --package-path InnerBalanceCore --scratch-path /tmp/fangcun-v4-core-session-build`，退出码 0，**167 tests / 33 suites passed**。永久日志：[core-session-review-tests.log](evidence/core-session-review-tests.log)。最初执行的同范围日志为 [core-session-tests.log](evidence/core-session-tests.log)。这些日志是实际执行输出，本文没有重新运行测试。
- App：`.build/v4-verification/full-regression.log` 第 1299 行，**215 tests / 33 suites passed after 10.984 seconds**。这是本次完整运行中的 App Swift Testing 结果。结果包为 `.build/v4-verification/full-regression.xcresult`；本文核验时后续完整 UI 测试仍在执行，**不据此宣称整个 xcodebuild 已正常退出或所有 UI 已通过**。最终状态以整版 `VERIFICATION.md` 为准。
- Watch：`.build/v4-verification/watch-build.log` 末尾 **BUILD SUCCEEDED**。命令：`xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme "InnerBalance Watch App" -configuration Debug -destination "generic/platform=watchOS Simulator" -derivedDataPath .build/v4-watch ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO`。这是 Watch 模拟器编译，不是真表配对、后台同步或签名证明。
- App 命令：`xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination "platform=iOS Simulator,id=<本地模拟器>" -derivedDataPath .build/v4-derived -resultBundlePath .build/v4-verification/full-regression.xcresult -parallel-testing-enabled NO -test-timeouts-enabled YES -maximum-test-execution-time-allowance 600 -collect-test-diagnostics never -skip-testing:InnerBalanceUITests/PracticeV4CaptureUITests CODE_SIGNING_ALLOWED=NO`。设备标识在这里省略；Capture 套件是另行生成媒体的入口，此处没有据此免除产品行为验收。

## 测试源码索引

下面的简称是文件路径；测试函数名可以在对应文件直接定位。

| 简称 | 仓库相对路径 |
|---|---|
| CoreTimeline | `InnerBalanceCore/Tests/InnerBalanceCoreTests/PracticeTimelineV4Tests.swift` |
| CoreCadence | `InnerBalanceCore/Tests/InnerBalanceCoreTests/PracticeHapticCadenceTests.swift` |
| CoreSync | `InnerBalanceCore/Tests/InnerBalanceCoreTests/Sync/PracticeSyncV4Tests.swift` |
| Session | `InnerBalance/InnerBalanceTests/Features/PracticeSessionViewModelTests.swift` |
| Audio | `InnerBalance/InnerBalanceTests/Features/PracticeAudioV4Tests.swift` |
| Presentation | `InnerBalance/InnerBalanceTests/Features/PracticePresentationTests.swift` |
| Completion | `InnerBalance/InnerBalanceTests/Persistence/PracticeCompletionStoreTests.swift` |
| Recovery | `InnerBalance/InnerBalanceTests/Features/RecoverySessionTests.swift` |
| Migration | `InnerBalance/InnerBalanceTests/Persistence/FangcunDiaryMigrationTests.swift` |
| PendingHealth | `InnerBalance/InnerBalanceTests/Persistence/PendingHealthWriteTests.swift` |
| Authorization | `InnerBalance/InnerBalanceTests/Health/HealthAuthorizationCoordinatorTests.swift` |
| Insights | `InnerBalanceCore/Tests/InnerBalanceCoreTests/Readiness/InsightsStoreTests.swift` |
| Score | `InnerBalanceCore/Tests/InnerBalanceCoreTests/StatusScoreV3Tests.swift` |

## T01–T11：方法与时钟

“自动测试通过”只指该行列出的断言；末列说明尚未被这些断言证明的部分。

| 编号 | 已有测试与结果 | 实现路径与验收边界 |
|---|---|---|
| T01 | CoreTimeline `catalog`、`boundaries` 通过：旧默认 60 秒与 V4 默认 300 秒并存；3/2/7 相位起止和下一轮正确。 | `PracticeCatalog.swift`、`PracticeTimeline.swift`。新增 Session `allV4DurationTargetsKeepExactActivity` 已写入 60 秒 5 轮、300 秒 25 轮的独立精确断言，最终 App 复跑已通过。使用注入时钟，不是长时间设备实测。 |
| T02 | CoreTimeline `catalog`、`boundaries` 通过；CoreCadence `pacedBreathingGuideTracksTheCurrentBreath`、`cueBoundariesAreStable` 通过。九项中仅原节律方法使用 4/6。 | `PracticeCatalog.swift` 保留旧 180 秒默认，V4 默认 300 秒；`PracticeTimeline.swift` 保留 4/6。实际全程跟练舒适度待真机体验。 |
| T03 | CoreTimeline `boundaries` 对 5/5、`easy_4_4` 两种相位通过；Audio `balancedVariantUsesSharedSnapshot` 通过。Session `v4NaturalPauseAndTarget` 验证共享会话计时在目标处封顶。 | `PracticeSessionViewModel.swift` 的目标时长与相位时钟分开；不向上凑整周期。新增 Session `allV4DurationTargetsKeepExactActivity` 已覆盖 5/5 与 4/4 两档的 180/300 秒终点；4/4 分别为 22/37 个完整周期，终点停在下一次呼气起点，明确不延长到完整轮。新增测试最终 App 复跑已通过。 |
| T04 | CoreTimeline `boundaries`、Audio `holdsAreDistinctTimelineEvents`、Session `v4HoldRecoveryAndIntervals` 通过：两种停留独立；恢复从安全吸气起点，活动时间不归零。 | `PracticeTimeline.swift`、`PracticeSessionViewModel.swift`。暂停不继续发出停留节拍；猫狗停留姿态的实际画面需结合原生录像核验，单测不证明美术质量。 |
| T05 | CoreTimeline `boundaries`、Audio `alternateVoiceOrderDoesNotAlternateNaively` 通过，明确左吸→右呼→右吸→左呼，侧别左/右/右/左。 | `PracticeTimeline.swift`、`PracticeAudioPlan.swift`。声音规划与相位一致；真人听感及角色左右可读性仍需视觉/设备验收。 |
| T06 | CoreTimeline `naturalAndBodyScan`、Session `v4NaturalPauseAndTarget`、Presentation `v4NaturalRenderingCadenceFollowsActualCue` 通过：膈肌引导没有伪造吸呼相位，按真实段落推进。 | `PracticeTimeline.swift` 中 `guidedNatural` 的 `phase == nil`；准备示范与正式训练分离。示范标签、无传感器暗示属于界面文案/视觉检查，不由这些时间线单测全部覆盖。 |
| T07 | CoreTimeline `naturalAndBodyScan` 覆盖冥想 300/600、NSDR 600/1200 的完整连续段落；Audio `everyGuidedSegmentHasAnExactResourceAndWindow`；Presentation `nsdrPresentationFollowsTheAudioPhase`（13 个边界样例）、`nsdrVisualFocusAndReturnAreActionable` 均通过。凯格尔由 `catalog`、`boundaries` 与 Session `v4PelvicRecovery` 覆盖。 | 九项均有独立协议，不以卡片占位。注入时间的脚本覆盖不等于连续 20 分钟真机播放；完整 UI 执行结果由整版验收补记。 |
| T08 | CoreTimeline `boundaries`：收紧 4 秒、放松 8 秒；Session `v4PelvicRecovery`；Presentation `kegelUsesAPlainBodyPracticeDescription`、`kegelSafetyCopyCoversThePlannedConditions` 通过。 | 使用 `.contract/.release`，不是吸气/屏息编码。恢复先完整放松 8 秒，再开始一轮；被打断的部分轮次不累计为完整轮。新增 Session `allV4DurationTargetsKeepExactActivity` 已写入 180 秒 15 轮的明确断言，最终 App 复跑已通过；这仍不等于实际 3 分钟真机过程。 |
| T09 | Session `pauseAndResumeKeepAccurateTime`、`v4HoldRecoveryAndIntervals`、`v4PelvicRecovery`、`nsdrPausePreservesTheSharedPhase`；Presentation `closingReadyPreparationHasNoSessionOrAudio`；Audio `resumeSlicesDoNotReplayOrCrossPhase` 通过。 | 总活动时间与相位锚分别保存；节律恢复重锚，自然脚本从原段位置继续；过期语音不补播，语音按当前窗口截止。示范没有开始真实会话。实际音频/触觉前台误差 ≤100ms 尚未仪器或设备实测。 |
| T10 | Session `sceneInterruptionPausesSession`、`v4NaturalPauseAndTarget`、`checkpointNeverBackfillsWallTime`、`checkpointCannotCrossCycleBoundaryBetweenReads`；Completion `v4MetadataAndPausedHealthIntervals` 通过。 | 生产活动计时使用单调时钟，墙上时间只作为区间日期。重启仅恢复确认区间，保持暂停，不补离开时长。实际强杀、锁屏、系统终止及 NSDR 20 分钟锁屏路线未真机验证。 |
| T11 | Completion `concurrentV4CompletionIsIdempotent`、`breathingWritesMindfulSessionOnce`；Presentation `cancelledAudioPreparationDoesNotReactivateSession`、`repeatedEngineConfigurationChangesAreCoalesced`、`audioCueIdentityTracksPhaseBoundaries`；CoreCadence `phaseHapticConsumptionIsStateful` 通过。 | 固定 session UUID、每 UUID 合并保存任务、结束阶段守卫、音频事件身份去重。覆盖并发保存/迟到准备回调，不将其扩大为所有高速点击设备情形已穷举；完整 UI 回归待最终结果。 |

Core 实现路径前缀：`InnerBalanceCore/Sources/InnerBalanceCore/Practice/`；App 练习实现路径前缀：`InnerBalance/InnerBalanceApp/Features/Practice/`。

### 补齐完整目标边界（最终复跑已通过）

`Session.allV4DurationTargetsKeepExactActivity` 是九种方法参数化测试，独立列出全部目录时长和期望完整轮次；均衡同时覆盖 `equal_5_5`、`easy_4_4`。共 19 种方法/时长/档位组合，每种分别模拟准时和迟到 17 秒的结束回调，共 38 条可控时间路径。每条断言：

- 目标前 0.25 秒仍运行，剩余 0.25 秒，尚无 completion。
- 到目标时活动时长封顶、剩余为零；迟到回调不能增加实际时长。
- 保存仍采用原目标时长，完整轮次符合独立期望，恰好一个起止准确的活动区间，无额外反馈。
- 继续推进时钟并重复结束，completion 与用于 HealthKit 的区间不变。

仅新增测试，未改旧断言、方法参数或模型。`swiftc -frontend -parse InnerBalance/InnerBalanceTests/Features/PracticeSessionViewModelTests.swift` 退出码 0；随后包含新测试的完整 App 回归已正常退出 0，216 项全部通过，见 `evidence/final-app.json`。此前 215 项结果不是本新增回归的证据。此测试检查 HealthKit 写入的数据来源区间，真正的 writer 映射由已有 Completion 存储测试覆盖，不声称本测试调用了真实 HealthKit。

## D01–D08：数据、旧功能与权限

| 编号 | 已有测试与结果 | 范围及仍未验证事项 |
|---|---|---|
| D01 | Migration `migrationKeepsIDsTotalsWordsAndVerifiedOriginalBytes`、`interruptedMigrationResumesWithoutDuplication`（3 个故障点）、`damagedInputAndTargetNeverBecomeAnEmptyArchive`；Completion `latestCompletionRoundTrips`；Presentation `selectedVoicePackActivatesGuidanceOnlyOnce`；Audio `independentLayersPreserveMutedPreference` 通过。 | 合成数据的逻辑 ID/内容、迁移故障恢复和已有声音偏好有覆盖。**用户本轮推迟真机安装：覆盖安装及真实旧库/全部偏好回读状态为 deferred_by_user / unverified，不记通过。** 新模型中的 legacy nil 测试也不能替代真实旧版 SQLite 覆盖迁移。 |
| D02 | CoreTimeline `legacyAndUnknown`、`catalog`；Completion `v4MetadataAndPausedHealthIntervals`、`corruptMetadataDoesNotInventLegacySemantics`；Recovery `legacyPracticeIdentitySurvivesReconciliationAndFeedbackEdit` 通过。 | 五种旧 raw value 保持，`buildOne` 保留旧参数；旧记录 metadata=nil，不推断补齐 V4 节拍或疗效；没有清库流程。实现见 `PracticeKind.swift`、`PracticeCatalog.swift`、App `Persistence/PracticeCompletion.swift`。 |
| D03 | Score `independentPackageFixtures`（24 组）、`rawSleepThroughStoreProduces78WithoutCardio`、`boundariesCircularClockAndInvalidInput` 通过。 | 原 375/480 仅睡眠时长样例仍为 78。当前差异清单未修改状态分实现或其 fixtures。模型测试通过不意味着医学有效性验证，原工程默认阈值性质不变。 |
| D04 | Completion `localFailureStopsCompletion`、`finalStatusFailurePreservesCompletion`、`v4MetadataAndPausedHealthIntervals`、`concurrentV4CompletionIsIdempotent`、`kegelNeverWritesMindfulSession`；PendingHealth `failedWriteIsQueued`、`repeatedFailureIsDeduplicated`、`successfulRetryRemovesPendingWrite` 通过。 | 先本地后 HealthKit；V4 按实际活动区间写正念，各区间稳定 ID 重试；凯格尔不写正念。PendingHealth 旧回归主要为 State of Mind 队列，不能单独宣称 V4 每种 HealthKit 系统故障已覆盖；真实 HealthKit 权限/写入/跨进程重试待设备验证。 |
| D05 | Session `v4NaturalPauseAndTarget`、`v4PelvicRecovery`；`FangcunResponseLoopTests.unselectedStartingValueStaysAbsent`（`InnerBalance/InnerBalanceTests/FangcunResponseLoopTests.swift`）；Recovery `v4ProjectionKeepsTrueMethodPartialEndAndLaterFeedback` 通过。 | 未选反馈保持 nil；V4 三选反馈保存真实文字，不编造压力变化数值，不因练习完成自动加分。凯格尔不生成主观压力证据。全界面是否出现误导性图表需结合交付截图检查，不能只由持久化测试推出。 |
| D06 | Insights `failureKeepsOriginalCacheButEmptyInitialReadIsNotPermissionDenial`；Authorization `initialAuthorizationIsMinimal`、`statusQueryErrorIsRetryable` 通过。 | 空读为数据不足，查询失败仍可重试；未添加训练查询授权。当前变更清单无 entitlements/健康授权计划扩权。真实设备系统授权对话框与拒绝后行为仍未验证。 |
| D07 | CoreTimeline `legacyAndUnknown`；CoreSync `unknownPeerPreservesNewMethodUntilRecordCapabilityArrives`；Watch 模拟器构建 **BUILD SUCCEEDED**。 | 旧 Watch 仅能启动旧五种；新方法与 V4 记录待 peer 声明 `practice-record-v4` 才发送；能力降级后重新停止发送。未知方法保留 raw 字符串而不硬映射。真实旧版 Watch 配对升级/降级及离线投递未验证。 |
| D08 | `PrivacyManifestTests.appBundlesAnAppLocalUserDefaultsReason`（`InnerBalance/InnerBalanceTests/Compliance/PrivacyManifestTests.swift`）通过；本次数据时间线回归使用合成时钟/记录和 mock writer。 | 本范围没有新增账户、遥测或健康外发；练习音频在本地读取。本文及 Core 测试日志不含个人健康资料/设备标识。隐私清单测试不是全仓库内容审计；最终媒体和交付材料仍需主交付检查，不能在 UI/媒体未完成时声称全部已脱敏验收。 |

## 保存格式、恢复与同步约定

1. **兼容保存**：`StoredPracticeCompletion` 新增可选 `protocolMetadata: Data?`。V4 metadata 包含协议版本、variant、scene、完成状态、完整轮次、实际活动区间、可选反馈。旧 nil 保留旧语义；不存在批量回填、历史重解释或清库。
2. **损坏不是旧格式**：不可解码 metadata 保留原始字节，不降级为 nil 后重写 HealthKit。`corruptMetadataDoesNotInventLegacySemantics` 覆盖此边界。
3. **本地成功与健康成功分别记录**：稳定会话 UUID 与区间 ID 使同一请求可重试。本地保存失败不报告完成，也不先写健康数据；健康状态更新失败不丢弃已成功保存的本地记录。
4. **草稿只包含已确认活动**：`PracticeSessionDraftStore.swift` 保存 schema 1 checkpoint；恢复为暂停，保持同一 UUID。活动区间顺序、重叠、非有限值及目标范围由 checkpoint 验证。损坏草稿读取失败时保留原字节；新草稿写入前将损坏内容隔离到 `.unreadable.<UUID>` 键；只允许匹配 UUID 的清除，避免旧会话误清新草稿。`checkpointStorageIsConservative` 覆盖损坏保存与错 UUID 清除。
5. **计时和轮次同一瞬间冻结**：checkpoint 只读取一次当前活动时刻生成区间及轮次，避免两次读取跨过周期边界。`checkpointCannotCrossCycleBoundaryBetweenReads` 使用 11.999→12.001 秒时钟复现并防回归。
6. **崩溃恢复限制**：运行期间约每 5 秒请求 checkpoint，暂停/结束等关键转换也保存。UserDefaults 没有提供本实现可保证的即时落盘上界，因此不承诺强杀最多损失 5 秒；宁可少恢复未确认活动，也不按离开时间补完成。
7. **Watch 能力协商**：`InnerBalanceCore/Sources/InnerBalanceCore/Sync/SyncService.swift` 把最新 hello 的 capabilities 当作权威快照；即使 installation ID 相同，缺少 capability 的 hello 也清除旧能力缓存。新记录保留队列，等待支持端；不把均衡呼吸等新 ID 映射成旧节律呼吸。`InnerBalance/InnerBalanceWatch/Features/Practice/WatchPracticeView.swift` 保持旧五项启动边界。

## 本轮发现并复验的问题

- `PracticeCompletionRecord` 的初始化隔离：补显式 nonisolated 初始化，兼容从持久化记录计算属性读取。后续 App 编译和上述 215 个测试通过。
- 旧测试时钟 fixture 使用两项数组 `removeFirst()`，新增活动时间读取导致数组耗尽。改成明确推进的稳定时钟，保留原“未选状态不算输入”断言，并验证实际 30 秒及区间总和；没有降低断言。
- 凯格尔旧 summary 断言把步骤文案当成功能摘要。按 V4 明确摘要与 4/8 自然呼吸步骤分别断言，仍验证不作压力关系/屏息解释。不是恢复旧 UI，也未删减安全断言。
- 集成审查修复能力缓存降级、损坏草稿覆盖和 checkpoint 双时钟读取，均有上表专用回归。

## 不可从当前证据推断的通过项

真机覆盖安装与旧库回读（用户推迟）、真实 HealthKit 写入、实际 Watch 配对/后台、签名安装、NSDR 连续 20 分钟声音与锁屏、耳机/电话/路由恢复、前台音画触觉 ≤100ms 均保留 **unverified**。完整 UI 套件实际结果与专项修复登记见 VERIFICATION.md；不能将专项通过改写为原全套命令一次通过。没有上传 TestFlight 或上架动作。

## 最终 App 专项复跑

`.build/v4-verification/final-app.xcresult` 已正常退出 0，可由 xcresulttool 读取；**216 项 / 33 组全部通过**，含 `allV4DurationTargetsKeepExactActivity(_:)` 的 9 方法参数、19 个方法/时长/档位组合及准时/迟到两路共 38 路径。脱敏结果见 [final-app.json](evidence/final-app.json)。前文 215 项是此前完整 UI 运行中的 App 快照，不再作为新增边界测试的状态；新增精确终点测试已通过。此注入时钟回归仍不等于真实 20 分钟锁屏验证。
