# V2 验收目录逐项结果

原始 `ACCEPTANCE_CASES.json` 保持原样，它是要求目录。以下才是本次运行记录。自动化通过只针对写明的层级；“待真机/待人工”不计作验收通过。

证据简称：C = [Core 145 项](evidence/tests/core-v2-acceptance.txt)，A = [App 195 项](evidence/tests/v2-app-final.txt)，U = [最终 10 项 UI](evidence/tests/v2-ui-final.txt)，L = [最大字号修复后 3 项 UI](evidence/tests/v2-ui-accessible.txt)。所有测试方法名均可在源码中搜索。

| ID | 状态与证据 | 实际覆盖 / 未覆盖 |
|---|---|---|
| T01 | 自动化通过 C `noRecordsMeansInvitationNotDehydration` | 无记录 11:30 给 W01 邀请；文案 key 对应记录范围，不诊断脱水 |
| T02 | 自动化通过 C `coffeeCountsFluidAndUnknownAlcoholDoesNot` | 咖啡 300 ml 计非酒精饮品，白水仍为 0；未知酒精不冒充补水 |
| T03 | 自动化通过 A `acknowledgeAndMuteNeverWriteDiaryAndSurviveRestart`；C `restrictionAndAcknowledgementSuppressWaterWithoutChangingFacts` | 确认喝过只写关怀状态，抑制 3 小时，重启保留 |
| T04 | 自动化通过 C `referenceRequiresAcceptanceAndNeverCreatesDebt`、`recentFluidAndReferenceMetCancelWaterAndRestrictionWins` | 明确接受参考才用目标；达量停止当天推动，记录按钮不受目标禁用 |
| T05 | 自动化通过 C `restrictionAndAcknowledgementSuppressWaterWithoutChangingFacts`、`recentFluidAndReferenceMetCancelWaterAndRestrictionWins` | 限液跨水/酒关怀适用；无定量饮水 push |
| T06 | 自动化通过 C `doseMethodsAndABVAreExplicit`；A `testDilutingPerServingCoffeeKeepsDose` | 300/500 ml 每杯咖啡因均 140 mg；有红灯回归 |
| T07 | 自动化通过 C `doseMethodsAndABVAreExplicit` | 浓度 32 mg/100 ml：250→500 ml 时 80→160 mg |
| T08 | 自动化通过 C `lateCaffeineUsesConsumedTimeAndConfirmedSleep`、`amountAndLateMergeUnknownQualifiedAndBackfillPassive` | 使用 consumedAt；上午消费晚补记不称刚喝晚咖啡；补记被动提示 |
| T09 | 自动化通过 C `lateCaffeineUsesConsumedTimeAndConfirmedSleep` | 16:00 140 mg 与已确认 23:30 睡眠关联，只一条晚咖啡候选 |
| T10 | 自动化通过 C `midnightBelongsToOngoingSleepAndExpires` | 00:30 关联进行中的睡眠周期；醒后过期 |
| T11 | 自动化通过 C `lateCaffeineUsesConsumedTimeAndConfirmedSleep` | 晚窗 10 mg 不触发 50 mg 工程阈值；未作零影响承诺 |
| T12 | 自动化通过 C `amountAndLateMergeUnknownQualifiedAndBackfillPassive`；A `unknownDoseProjectionAndLegacyBeerNeverBecomeZeroOrRecalculated` | unknown 保留 nil，累计带未知部分说明 |
| T13 | 自动化通过 C `amountAndLateMergeUnknownQualifiedAndBackfillPassive`；A `noPromptAtStartupAndDeniedNeverRequestsAgain` | 量多且晚合并 C03；未主动开启无通知 |
| T14 | 自动化通过 C `doseMethodsAndABVAreExplicit`；A `testNewBeerUsesVolumeAndABV`、`unknownDoseProjectionAndLegacyBeerNeverBecomeZeroOrRecalculated` | 新酒 13.0185 g；旧 10 g 不重算 |
| T15 | 自动化通过 C `twoAlcoholRecordsAcrossMidnightKeepSixHourTotal` | 23:00/01:00 各 15 g，6h 合计 30；过窗不保留超量判断 |
| T16 | 自动化通过 C `alcoholUnknownNotExcessWaterCannotCancelAndSafetyWins` | 未知酒精为一般建议，不声称精确超量 |
| T17 | 自动化通过同上；原 readiness golden 不变 | 后记水不移除酒精事实；无准备度加分接口 |
| T18 | Core 通过；真实安全卡人工检查待验 | 同上验证 A05 优先；代码静态安全出口并禁用普通建议/首页呼吸入口；未做真机严重症状交互验收 |
| T19 | 自动化通过 A `committedCommandsAreDurableAndUndoIsANewRevision`；C `commitsDeduplicateAndBackgroundDoesNotQueue` | 原子发布前失败不新增，重试同命令一次提交；同事件不重播 |
| T20 | 模拟自动化通过；配对 Watch 待验 | C `failedReceiverCannotACKAndDeletePrecedesStaleReplay`、`durableACKLostOfflineRestartDuplicatesAndProjectionRetry`、`unknownOldWatchKeepsNewBeverageQueuedThenCapabilityUnlocks`；不复活、不降级、不远端庆祝 |
| T21 | 自动化通过 C `priorityDismissAndSameBasisDoNotReplay` | 酒优先于咖啡/水，一条；关闭不马上轮播下一条 |
| T22 | 分层自动化通过；真实拒绝授权组合待验 | A 饮品/关怀测试不依赖 HealthKit；`rawProviderToOwnerProducesScopedLanguage` 的 insufficient 不捏造评估；未实际更改用户健康权限 |
| T23 | 注入客户端通过 A `noPromptAtStartupAndDeniedNeverRequestsAgain`；真机待验 | 拒绝后无排程/循环索权；首次仅明确开启时请求 |
| T24 | 注入客户端通过 A `foregroundCareIsSilentAndSchedulingIsNotDelivery`；真机待验 | 本功能前台空 presentation options；其他模块保持原行为 |
| T25 | 自动化通过 C `twoReservationsAndAlcoholRequestCannotAddAThirdOrDeferIt`、`threeDayOneShotPlansReserveBothBudgetsAndCooldown` | 已有两次预算、滚动 24h、4h 冷却及静默时段；不能深夜延后补发 |
| T26 | 自动化通过 C `recentFluidAndReferenceMetCancelWaterAndRestrictionWins`；A `plansCancelOnlyOwnedRequestsAndClearRetainsOtherFeatures` | 新非酒精饮品抑制近 2h；取消仅 own prefix，其他模块保留 |
| T27 | 文案与排程自动化通过；App 终止后系统送达待验 | C planner 默认 generic 文案，无实时无记录断言；未证明系统会按时投递 |
| T28 | 客户端/文案通过；真实锁屏待验 | A `plansCancelOnlyOwnedRequestsAndClearRetainsOtherFeatures`；默认无剂量/饮酒/身体状态 |
| T29 | 自动化通过 C `muteSurvivesRestartAndTimezoneChange`、`threeDayOneShotPlansReserveBothBudgetsAndCooldown` | 绝对时间抑制保存，滚动预算不随日界重置翻倍；物理改时区未做 |
| T30 | 分层覆盖，真机撤回待验 | 编辑/撤销事实与重新排程分别由 A 饮品命令、C planner、A own-only 清理测试覆盖；已读无法撤回，不能把取消当未曝光；未声称端到端锁屏撤回通过 |
| T31 | UI 通过 U `testFirstExperienceDelivery`、`testDistinctCurrentConclusionsAndSceneEntry` | 删除观看/重播入口；装饰角色 AX hidden。真实 VoiceOver 朗读待验 |
| T32 | 自动化通过 C `tenRefreshesDoNotQueueAndRapidCommitsReplace` | 同事件十次只启动一次，快速提交替换当前，无十份队列 |
| T33 | U/L `testWaterCoffeeAlcoholAndUndoShowCommittedFeedback`；C `distinctDrinkGesturesAndBreathPriority` | 提交/反馈/撤销真实链路；动作自然可爱仍待人工 |
| T34 | 自动化通过 U `testBreathingWithMotionEnabledCanPauseAndExit` 及现有 session 测试 | 呼吸共用练习 expansion，暂停冻结；正常/提前退出均走真实保存链路 |
| T35 | Core 通过；物理设置待验 | C `accessibilityFailureAndRemoteNeverCelebrate`、`staticLowPowerCoveredOffscreenAndGentleAreExplicit`；静态/呼吸无装饰 Timeline；真实低电量/耗能未测 |
| T36 | 原画未改；截图已检查，用户视觉验收待定 | [深色大字](evidence/final-native/README.md)。已修复发现的弹层挤压；未把视觉舒服/蓝色夜间可见性判作用户通过 |
| T37 | 自动化通过 A `rawProviderToOwnerProducesScopedLanguage`；U `testDistinctCurrentConclusionsAndSceneEntry` | 原始 provider→coordinator→真实首页有 usual/reduced/low 三个结论 |
| T38 | 自动化通过 A 同上 oneDay；L `testOneDayDarkMaximumTypeHasScopedFactsAndNoPersonalRange` | 一日无个人范围，仍给限定的睡眠建议；大字实际记水/汇总/撤销通过 |
| T39 | 自动化通过 C `onlyStageOverlapPreservesCurrentAndHistoricalEvidence`、`unresolvedAwakeConflictCannotPublishPreciseDuration` | 阶段并集保时长；awake/asleep 真冲突不捏造精确时长 |
| T40 | 自动化通过 C `onlyStageOverlapPreservesCurrentAndHistoricalEvidence`、`auditDistinguishesUnreadMissingSourceMismatchAndRuleExcluded` | 当前/历史共用质量过滤，另有本机只读真实样本回放，公开版仅脱敏结论 |
| T41 | 自动化通过 C `incompleteSourceIdentityIsDiagnosticNotAComparisonFailure` | 可比较来源的 incomplete identity 留内部诊断 |
| T42 | 自动化通过 C 原 M2-R01～R05 全套、`oldArchivesDecodeWithoutClearingAndNewPolicyCreatesRelatedRevision` | 删除/修订/并发/旧缓存回归继续通过；原 golden 未改 |
| T43 | 最大字号自动化通过 L；VoiceOver 真人朗读待验 | 默认详情不堆技术字段，按钮能滚动到；未用 AX 查询代替听读验收 |
| T44 | 真实录屏已交付；用户可爱/自然验收待定 | [六场景及饮品变体](evidence/final-native/README.md)，包含真实计时完成；不能用测试数量代替认可 |
| T45 | 待用户/普通用户人工验收 | 需复述“结论、理由、现在可做什么”，并能分清睡眠建议与完整评估；未开展用户实验 |

停止于 V2-07。缺失的物理与人工验收明确保留，不将其自动转为通过，也未扩展到新后端、远程推送或后续阶段。
