# V2-02 睡眠质量与基线核验

## 变更

- `SleepEpisodeBuilder.swift`：`ReadinessSleepQuality` 将总睡眠时长、HRV 睡眠窗口、阶段细分可用性及内部原因/用户阻断原因拆开。core/deep/rem 交叠新增仅诊断 `sleepStageOverlap`，睡着总时长用并集，inBed 不计入。
- 同源相同 syncIdentifier 的明确较新版本沿用既有去重机制；没有替换依据的 awake/asleep 交叠，从确定睡着区间移除，禁止输出精确 `actualSleepSeconds` 和综合等级。完全交叠产生空的确定区间时仍保留记录起止用于诊断，不以起止相减伪造时长。
- `BaselineBuilder.swift`：当前与历史改用相同显式质量判断；不再把一切 flags 当作整晚不可用。HRV 受睡眠窗口质量约束，其他可靠事实仍可提取。
- `ReadinessEngine.swift`：评估带 `sleepQuality`，可通过 `sleepDurationUsable`、`asleepIntervalsUsableForHRV`、`sleepStageBreakdownUsable` 访问。`sourceIdentityIncomplete` 不影响稳定可比较性时仅内部诊断。
- `ReadinessConfiguration.swift`：featureSchemaVersion=2、qualityPolicyVersion=`sleep-quality-v2`。原模型系数、28 日窗口、7/14 日门槛、目标范围和 golden fixtures 未改。
- 新字段为可选字段，旧评估/睡眠档案缺字段仍可解码；新评估保留原周期及 supersedes/revision 关系，存储不清空。
- awake 等排除记录仍加入 episode 的删除依赖；episode identity 仍由原睡着记录决定，删除冲突不会错误变成新周期。InputBuilder 的全原始依赖保留，版本去重排除的记录删除也能触发失效。
- `BaselineCoverageAudit.swift`：按同一生产路径输出本机逐日审计；真实审计仅在本机，脱敏结论见 `BASELINE_COVERAGE_FINDINGS.md`。

## 回归与结果

先在旧实现新增两项针对性回归再修改生产代码。首次运行 2 项均失败、共 5 个断言问题：阶段交叠阻断当前与历史、特征版本仍为 1、awake 冲突仍输出精确时长。修复后通过。

新增 `V2SleepQualityTests` 共 8 项：

1. `onlyStageOverlapPreservesCurrentAndHistoricalEvidence`：阶段交叠当前可评估、历史有效日保留、精确并集不重复计时。
2. `unresolvedAwakeConflictCannotPublishPreciseDuration`：冲突不出精确总时长与等级、保留冲突依赖。
3. `qualitySeparatesStageAndConflictAndSupportsEmptyConfirmedWindow`：阶段单独降级；完全 awake 覆盖无确定睡着窗口，保留其他可靠 RHR。
4. `versionedReplacementResolvesConflictButUnrelatedRecordDoesNot`：明确版本替换可消解，无共享替换依据不猜测。
5. `conflictDeletionInvalidatesAssessmentAndRebuildsSameCycle`：删除冲突使旧评估失效，并在原周期修订恢复。
6. `incompleteSourceIdentityIsDiagnosticNotAComparisonFailure`：身份细节缺失不妨碍既有稳定选源的比较。
7. `oldArchivesDecodeWithoutClearingAndNewPolicyCreatesRelatedRevision`：旧 JSON 无新增字段可读，新政策产生有关系的修订、原记录保留。
8. `auditDistinguishesUnreadMissingSourceMismatchAndRuleExcluded`：初始化、真实缺失、来源不符与规则过滤分开。

中间全量运行发现一个本次引入的删除周期关系失败：把 awake 依赖纳入 identity 导致冲突删除变成新周期。已修复为身份与删除依赖分离；未改原 M2-R01 断言。所有旧 M2-R 回归保留。

实际命令（项目根目录）：

```sh
DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer swift test --package-path InnerBalanceCore --filter V2SleepQualityTests
DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer swift test --package-path InnerBalanceCore
```

2026-09-19 最终 Core 全量：**120 tests / 25 suites 通过**（原 112 + 新 8），进程正常退出。原 `ReadinessEngineTests.originalGoldenFileThroughRawSamples` 通过，golden 文件无修改。日志留本机 `v2-sleep-core-final.log`；本阶段未宣称 App、UI 或真机新版验收通过，交由主集成阶段执行。

## UI 接口约束

优先读取 assessment 的显式可用性，不能把 `qualityFlags` 全量翻译给用户，也不能从有 sleepStartAt/sleepEndAt 推导 actualSleepSeconds。`sleepStageOverlap` 与 `sourceIdentityIncomplete` 留诊断层。少于 7 有效日不得显示个人平常范围，7–13 日仅初步比较，14 日起才成熟。旧档缺 `sleepQuality` 使用保守兼容逻辑，重新读取原始数据后生成新政策评估。
