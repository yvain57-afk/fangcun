# M3 阶段审阅入口

本轮限定 M3-PRE、M3-01～M3-04；未进入 M4–M6。以原任务书和 `FANGCUN_M3_START_AFTER_M2R1.md` 为准。工程默认阈值仍待校准，测试通过不代表医学效度。

## 版本与工作区

- 审阅基准：`b80f81c9f4ad68381b68f6ade30c02e6848718e6`。
- 本轮开始时规范工作区 `/Users/yvainair/Code/fangcun` 为该 HEAD、无未提交修改；旧 Developer 路径未迁移、未覆盖。
- 开发分支：[codex/fangcun-v1-m0-m1](https://github.com/yvain57-afk/fangcun/tree/codex/fangcun-v1-m0-m1)。无强推、无 main 合并、无发布。
- main 核对值：`905626c6e08dc7a36ddd4e219abf6945795ac62f`。
- 最终代码 HEAD：`70deab454e21194ee4c8a1a545d417eb300c9fd0`；包含验收发现的详情展示补齐。最终交付 HEAD 由报告所在提交及交付回复给出，避免在提交内伪造自引用 SHA。

| 阶段 | 提交 | 内容与文件入口 |
|---|---|---|
| M3-PRE | `e825da5`、`3b22606` | 次级文字 token、显示策略、练习对话框/准备页标识、原测试修正；[契约依据](M3-PRE-CONTRACT.md)、[结果](M3-PRE-VERIFICATION.md) |
| M3-01 | `b535d4609cdc9c8f5ab6f5accd999ce21fb632ae` | `FangcunDiaryStorage`、Diary v2、饮品编辑；[迁移验收](M3-01-VERIFICATION.md) |
| M3-02 | `9b9dfee` | App 唯一 owner、Home/ReadinessViews、provider 回调、pipeline retire；[接线验收](M3-02-VERIFICATION.md) |
| M3-03 | `b2ff751` | Core Recovery、RecoveryCoordinator/Views、Root 原会话投影；[行动验收](M3-03-VERIFICATION.md) |
| M3-04 | `c8d26eb` | Core Sync、PhoneSyncCoordinator、WatchSyncLifecycle、旧档可选字段；[同步验收](M3-04-VERIFICATION.md) |
| M3 集成补齐 | `70deab4` | 详情统计口径/个人基线/当日背景、历史等级与legacy标签；不改模型 |

完整修改文件清单见 [M3-CHANGED-FILES.txt](M3-CHANGED-FILES.txt)。未修改原 ReadinessConfiguration、ReadinessEngine、golden fixtures、entitlements 或 Xcode project 配置；没有新增网络后端、遥测、在线 AI 或健康权限类型。角色原画、首页主结构与五分钟主入口保留。

## M3-PRE 与历史失败

原 3 项 App 失败对应 4 件处理事项：

1. 调色契约以已确认设计资料为依据修正，不按当前代码随意生成预期。
2. 浅色次级文字 `#687584 → #677483`；保留原 `>=4.5` 对比度断言，其他已接受语义色保留。
3. `FangcunDisplayPolicy` 测试显式深浅色、系统大字/减少动态与 App 偏好的组合，保留偏好重启 UI 验证，不恢复强制浅色。
4. 提前结束用稳定 key/按钮标识及实际动作检查；本地保存前不声称已保存。文案目录检查保留。

`PracticeReturnHomeUITests` 两项走完整流程：真实当前练习库→准备→开始→提前结束→保存/跳过反馈→返回今日并核对会话 ID；未开始关闭→仍在练习页、没有新完成记录，再进入仍为准备阶段。不是仅修首个定位。

M3-PRE App 全量 170/170、目标 UI 6/6，正常退出 0，结果包可读。本阶段最初 UI 定位失败与复验日志均保留。

扩大到全部45项 UI 后，26通过、19失败。固定 b80 独立编译并复跑同19项，19/19复现失败、退出65、结果包可读。现行可选感受入口缺少 `home.checkIn` 标识的4项已补标识并走到原最终断言；其余15项旧界面契约仍失败，未删测试或恢复旧UI。[逐项对照](M3-LEGACY-UI.md)。因此不宣称全仓UI全绿。

## 当前实现和存储影响

**迁移：** 原 v1/preM1 字节先备份并读回校验；目标数据、schema与迁移摘要同一次原子提交。v1饮品为权威，不从preM1复活删除。合成例迁移前后均2条，稳定ID相同，630ml/170mg咖啡因/10g酒精估值/1份糖饮；重复启动不重复。未知录入时间、糖克数保留nil。旧快照原文字、旧口径保留，不生成准备度。

**准备度：** 唯一应用级服务 owner，复用真实 pipeline/store/provider。原始样本→服务→owner→当前首页/详情/历史均有测试。六种资格、freshness和刷新失败分别呈现；HRV显示毫秒，不把对数当读数。详情展示实际睡眠/目标、取样口径与窗口、逐指标基线、来源及独立时间。历史保留空白、legacy、周期与revision，展示当天背景及行动反馈，不按新配置重算过去。停止/清除隔离旧生命周期，撤销外部摘要；明确恢复才重新读取。

**行动：** 保留原练习；增加120秒轻活动、60秒座位调整、120秒安静休息。暂停/中断不补算未知时长，保存失败可重试且ID不变。反馈可跳过、编辑留revision；明确不适优先过滤推荐，未回答不进分母，至少5个同类明确回答才显示描述性统计。没有完成奖励准备度或伪造健康记录。

**同步：** schema/epoch/eventID/entityID/revision/tombstone；本地落盘后排队，接收事务与可重试业务投影完成才ACK，收到ACK才出队。重复/乱序/离线重启/ACK丢失/未知版本/删除重放均有合成回归。即时传输失败保留outbox，有界退避、没有保活轮询。HK与WC按稳定sessionID合并；只有源端保留原HealthKit写入职责，接收端不写健康。

新增Diary v2、Recovery v1、Sync v1文件分仓；原SwiftData记录和健康写入队列继续使用。新增同步字段兼容缺失字段，损坏原字节保留报错，不清库。Watch表新增两个可选字段只通过编译，真实升级迁移未验收。

## 集成验收索引

| ID | 实际测试 / 验证层级 | 结果或边界 |
|---|---|---|
| I01 | `FangcunDiaryMigrationTests.migrationKeepsIDsTotalsWordsAndVerifiedOriginalBytes` | 合成文件重开、ID/总量/原文/备份digest一致 |
| I02 | `interruptedMigrationResumesWithoutDuplication` 三种故障；`damagedInputAndTargetNeverBecomeAnEmptyArchive`；`writeFailureRetryEditingAndUndoKeepEstimatesAndUnknowns` | 原字节保留、失败不假成功、重试幂等 |
| I03 | `ReadinessCoordinatorTests.rawProviderThroughPipelineStoreAndOwner` 六参数；`ReadinessHomeUITests.testAssessable/Provisional/Limited/Insufficient/Awaiting/Failed` | service到真实当前首页及详情；非最终标签注入 |
| I04 | `failedRefreshKeepsAnchorAndIndependentCheckTimes`；保留M2-R04移动窗口回归 | 锚点、有效期、证据时间不因查询重试延长 |
| I05 | `clockBoundariesStopAndExplicitResumeDoNotRewardPractices`；既有 freshness / 新睡眠 Core 回归 | 注入时钟owner与引擎验证18/24小时；实际UI使用前台时钟刷新，未做24小时墙钟人工驻留 |
| I06 | `latestIntentWinsAndStopIsolatesLateOwnerResults`；`changingSelectionOrStoppingDuringAQueryRejectsLateState`（source/sleep/stop/clear）；`M2ReviewR03Tests.healthEventAfterSleepReadSchedulesOneCatchup`；`ReadinessObserverTests.mergedObserverCallbacksWaitForCatchupPersistence` | 目标/来源/主睡眠最新意图与补读通过；真实系统后台到达未验证 |
| I07 | `ReadinessLifecycleTests.retiringRejectsInFlightQueuedAndFutureRefreshes`；M2-R01删除全回归；`PhoneSyncIntegrationTests`；`revocationStillReplacesTransportContextWhenDiskWriteFails` | 旧任务不复活current，摘要撤销；真机隐私传播未验证 |
| I08 | `testHistoryIdentityAndAccessibleLargeDarkLayout`，InsightsStore既有周期/修订回归 | 同ID、28天切换、非今日记录选择；legacy不补造 |
| I09–10 | `PracticeReturnHomeUITests` 两个完整流程；`testBreathingRoundTripKeepsCurrentAssessmentWithoutReward` | 实际保存返回当前今日，未开始关闭不造记录，准备度不奖励 |
| I11 | Core `pauseEndRetryAndRestart`；App `localSaveFailureRetryAndPauseHaveOneIdentity` 各3种行动；行动UI | 暂停、提前结束、重复结束、保存重试、中断重开；纯本地无健康写入 |
| I12 | `optionalFeedbackRevisionsAndDenominator`；`recommendationsRespectExplicitSafetyAndDiscomfortFirst`；`legacyPracticeIdentitySurvivesReconciliationAndFeedbackEdit`；`RecoveryActionUITests.testLocalActionPauseEarlyEndSkipThenEditFeedback` | 跳过nil、不适过滤、反馈修订与原练习ID保留 |
| I13 | `SyncReliabilityTests.durableACKLostOfflineRestartDuplicatesAndProjectionRetry` | 可控transport与真实文件，不等于实际设备送达 |
| I14 | `failedReceiverCannotACKAndDeletePrecedesStaleReplay`、`epochUnknownProtocolSummaryAndCorruptionRemainNeutral` | tombstone、旧epoch、未知协议与源队列保留 |
| I15 | 同上summary损坏/过期/未配置；App `receiverProjectsUnknownDrinkValuesAndDeduplicatesHealthSession` | 中性回退、unknown保持、HK/WC去重；App Group配置blocked |
| I16 | `FangcunDesignSystemTests`；`FangcunRedesignUITests`；大字深色历史/详情、英文长来源fixture、4项感受表单UI | 自动化AX标签/可达性和合成截图；实际VoiceOver连续朗读未人工验收，不计通过 |

## 实际命令和结果

工具链 Xcode 27 beta（27A5252f）。命令以规范仓库为工作目录，测试选择与完整脱敏输出见 `evidence/m3-*.txt`。本机原始 `.xcresult` 留在 `/Users/yvainair/Code/Codex/2026-09-19/fangcun-m3`，未上传设备标识；提交的JSON由 `xcresulttool get test-results summary` 读取成功后摘取计数。

```sh
export DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer
swift test --package-path InnerBalanceCore
xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULT_PATH" -parallel-testing-enabled NO \
  -test-timeouts-enabled YES -maximum-test-execution-time-allowance 90 \
  -collect-test-diagnostics never -only-testing:InnerBalanceTests CODE_SIGNING_ALLOWED=NO
# 完整 UI 将选择项替换为 -only-testing:InnerBalanceUITests。
# 目标复验选择项逐项列于相应日志的命令首行；没有 -skip-testing。
xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' \
  -destination 'generic/platform=watchOS Simulator' -derivedDataPath "$WATCH_DERIVED_DATA" CODE_SIGNING_ALLOWED=NO
```

`SIMULATOR_ID` 取本机可用模拟器，不将设备标识写入仓库。`-collect-test-diagnostics never` 仅关闭Xcode诊断收集，不改测试断言；本轮取得正常退出与可读结果包。

| 运行 | 结果 | 证据 |
|---|---|---|
| M3-PRE App全量 | 170/170，exit0 | [摘要](evidence/m3-pre-app-final-summary.json) |
| M3-PRE现行首页及两旧练习UI | 6/6，exit0 | [摘要](evidence/m3-pre-ui-recheck-summary.json) |
| Core全量 | 112/112，exit0 | [日志](evidence/m3-m3-core-delivery.txt) |
| App全量 | 185/185，exit0 | [摘要](evidence/m3-m3-app-final-summary.json) |
| 全部UI扩大运行 | 26/45，19失败，exit65 | [摘要](evidence/m3-m3-ui-full-summary.json) |
| b80相同19项基准复现 | 0/19，19失败，exit65 | [摘要](evidence/m3-baseline-ui-summary.json) |
| Watch模拟器 | BUILD SUCCEEDED，exit0 | [日志](evidence/m3-m3-watch-final.txt) |
| 当前交互复验 | 20/20，exit0 | [摘要](evidence/m3-m3-ui-delivery-summary.json) |
| 补齐详情/历史后复验 | 8/8，exit0；与上一行部分重叠，不相加当独立测试数 | [摘要](evidence/m3-m3-detail-delivery-summary.json) |
| 补齐后的App全量 | 185/185，exit0 | [摘要](evidence/m3-m3-app-accepted-summary.json) |
| 最后文案复验 | App185 + 首页UI1 = 186/186，exit0 | [摘要](evidence/m3-m3-copy-final-summary.json) |
| Release签名构建 | 构建/签名校验通过 | [脱敏收据](evidence/m3-device-receipt.json) |

中途失败单列：M3-02首次详情时间字段未滚动到、历史测试把凌晨前一日主睡眠错误当作今日，已保留业务语义修正定位复验；M3-03首次全量运行出现真实音频RPC超时/进程重启、3项失败，后续两轮App全量184/184与185/185包含同套测试通过。保留原日志，不把失败运行改记成功。所有初次Core编译/新增回归问题已修复，不修改golden或算法参数。

## 视觉与设备边界

合成截图目录 [screenshots/m3](screenshots/m3)：深色大字首页/详情、行动反馈前后、呼吸暂停；`home-light.png` 是明确关闭readiness的原M1视觉回归，不作新准备度证据。新增六场景截图从真实UI fixture链路采集。没有真实健康截图。

| 能力 | 本轮状态 |
|---|---|
| Release签名/本机构建 | passed；沿用本机已有签名资源，团队/证书不入Git |
| 物理iPhone覆盖安装/启动/版本回读 | passed；交付末尾经本地网络恢复可达，确认reality=physical；1.0.0 / 2026091903 |
| 真实HealthKit首次前台读取与评估落盘 | passed（本次实机）；本地核验查询成功、有实际样本、评估及独立刷新记录落盘；原始内容不入Git |
| 授权弹窗重走、来源/主睡眠/目标操作、手动刷新与回前台全流程 | implemented_unverified；首次冷启动成功不能替代这些人工交互 |
| 真实增量/删除、锁屏读取、后台事件 | implemented_unverified；保留M0/M2能力边界 |
| 物理Watch送达/锁屏/后台/旧SwiftData升级 | implemented_unverified / blocked，缺少可用配对Watch |
| 真实App Group共享与签名 | blocked，工程没有真实组配置；未配置中性回退已测 |
| 模拟ACK/事务重放 | verified，仅Core/App可控transport层 |

交付末尾物理iPhone从不可达变为已配对本地网络可达；详情探测成功后先备份本App存档，再覆盖安装并启动Release（不卸载）。回读版本1.0.0 / 2026091903。只在本机比较：原v1/preM1字节未改，迁移checksum和源digest正确、记录ID保留；旧SwiftData练习/感受/每日记录行保留、显示偏好未改。真实Insights文件checksum正确、查询尝试和成功时间存在、有实际样本、评估已保存且无refreshFailure。未输出或上传健康值、记录ID、来源设备信息或数据库。首次launch命令选项位置错误退出64，按devicectl帮助修正后正常退出0，不是App运行失败。后续仍需逐项人工检查授权弹窗、来源/主睡眠/测量时间显示、反复刷新/回前台/改来源和目标。真实增删只操作合成自有测试数据，不删用户或其他App健康记录。配对Watch送达另行验收。

真机命令（设备标识与签名资源仅在本机变量中）：

```sh
xcrun devicectl device copy from --device "$IPHONE_ID" --domain-type appDataContainer \
  --domain-identifier com.yvainair.InnerBalance --source 'Library/Application Support' \
  --destination "$PRIVATE_BACKUP"
xcrun devicectl device install app --device "$IPHONE_ID" "$SIGNED_APP"
xcrun devicectl device process launch --device "$IPHONE_ID" --terminate-existing com.yvainair.InnerBalance
xcrun devicectl device info apps --device "$IPHONE_ID" --filter "bundleIdentifier == 'com.yvainair.InnerBalance'"
```

各命令使用 `--json-output` 写本机私有结果；以上成功命令退出0。偏好plist单独备份/回读，SQLite只读比较原行、Diary/Insights解码校验只在本机完成。Git收据只含布尔核验、版本与状态，无真实记录计数、健康值、标识或存档。

## 回退和停止点

设置中明确关闭准备度功能开关回到修正M1链路；不启用Mock、不清除评估历史。停止读取撤销current和摘要，重新启用须用户明确选择。专用评估清除不删除饮品、原SwiftData或HealthKit。不要把降级安装旧二进制当作安全数据迁移回退：本轮继续在兼容v2的代码中使用功能开关，原备份只作审计/恢复依据，不盲目覆盖新记录。

本轮开发范围止于M3。真机和遗留UI未验证/未通过项如上保留；不以这些条件阻塞已可测试的独立实现，也不把它们写为通过。没有上架、TestFlight、main合并或上传健康资料。
