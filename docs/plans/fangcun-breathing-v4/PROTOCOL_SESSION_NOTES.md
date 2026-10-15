# V4 协议、会话与保存实现记录

日期：2026-10-15。此记录属于本轮整版开发的内部验证材料，不代表整版或真机验收已完成。

## 实现

- `PracticeKind` 保留原 5 个 raw value，新增均衡、方块、膈肌、交替鼻孔 4 项。
- `PracticeCatalog.buildOne` 保留旧 5 项、旧时长顺序与默认值，供旧 Watch 使用；`v4` 提供 9 项、明确的新 iPhone 默认时长。旧叹息 3/2/7、节律 4/6、盆底 4/8 不变。
- `PracticeTimeline` 是视觉、声音、触觉共用的确定性相位与段落来源；支持均衡 5/5 和 4/4、方块两种停留、交替鼻孔侧别。自然呼吸与 NSDR 的 `phase` 为 nil，使用真实脚本文字及 focus，不伪装成吸气循环。
- `PracticeSessionViewModel` 使用活动单调时钟，暂停区间排除。恢复时呼吸从吸气开始、盆底先完整放松 8 秒，活动时长不回退；暂停打断的半轮不算完成轮次。结束后结果冻结，重复结束不扩展时长。
- UUID、协议版本、变体、场景、完成/提前结束、完整轮次、确认活动区间、真实三档反馈写入可选 metadata。旧记录 metadata 为空，仍是 legacy，不补写为 V4。SwiftData 仅添加可选 Data 列，不清库。
- V4 正念写入按真实活动区间拆分，所有段共享会话关联 ID、各自稳定 syncIdentifier；重试依赖既有 HealthKit 同步 ID 去重，并合并同一 coordinator 的并发完成请求。凯格尔不写正念。先本地保存，再健康写入。
- 新反馈保存用户选择的“更舒服／差不多／不舒服”，不生成前后数字或虚构 State of Mind。原始数值反馈和历史保留。
- 单一可恢复 draft 每 5 秒及状态变化保存已确认区间。重启恢复为暂停（已经结束但未保存则进入保存流程），离开期间墙钟不算活动。损坏/未知 draft 保留原字节。保存成功后仅清同一 UUID 的 draft。
- Watch 保持 5 项执行；新增类型没有可执行指令。新协议记录等待 `practice-record-v4` 能力，旧端/未知端保持本地队列，不改写为其他练习。现有 score-v3 和 beverage-v2 协商保留。
- `RecoveryCoordinator` 的 V4 投影保留真实协议版本与完成状态，并同步真实主观选择；不改状态分。

## 当前验证

命令：`swift test --package-path InnerBalanceCore --scratch-path /tmp/fangcun-v4-core-session-build`

结果：167 tests / 33 suites 通过，退出码 0。日志：`evidence/core-session-tests.log`。原状态分固定样例仍在同次 Core 全量测试中执行，没有修改数值模型或 fixtures。

新增 Core 回归：`PracticeTimelineV4Tests.catalog / boundaries / naturalAndBodyScan / legacyAndUnknown`，`PracticeSyncV4Tests.unknownPeerPreservesNewMethodUntilRecordCapabilityArrives`。

新增 App 回归已加入原测试目标：`v4HoldRecoveryAndIntervals`、`v4PelvicRecovery`、`v4NaturalPauseAndTarget`、`checkpointNeverBackfillsWallTime`、`checkpointStorageIsConservative`、`v4MetadataAndPausedHealthIntervals`、`corruptMetadataDoesNotInventLegacySemantics`、`concurrentV4CompletionIsIdempotent`。运行结果以主任务最终 Xcode 结果包为准，本文件不提前声称通过。

旧 NSDR 暂停测试从 25 秒重复扫描契约迁移到 V4 完整脚本 89→90 秒边界，仍验证暂停不前进、恢复同段、下一秒进入正确段落；未删除暂停断言。旧 catalog 全枚举等于 5 项的断言改为明确保留原 5 项，同时新增 V4 全 9 项及新默认值断言。

## 仍需整体验证

- 主任务 Xcode App/UI 全回归及 Watch 模拟器编译。
- 覆盖安装后的真实旧 SwiftData 数据库轻量迁移与逻辑记录核对；单元测试可证明新结构对 legacy 记录/空 metadata 的兼容，不能代替真实旧库覆盖安装。
- 真机/蓝牙相位端到端延迟、后台/锁屏持续播放与系统终止后的 draft 恢复。
- 真机 HealthKit 多活动区间写入与故障重试；模拟 writer 不能代替 Apple 健康回读。
- UserDefaults checkpoint 为确认过的保守草稿，异常强杀可能缺失最近未持久化检查点的活动，不会补造离开期间活动。

## 集成后专项审查

已按真实调用链审查并修复三处缺陷：

1. `PracticeSessionDraftStore.save` 原先会在下一次新会话开始时覆盖无法解码的 draft。现在先把原始字节放入独立 `unreadable` 隔离键，确认保留后才允许保存新草稿。`checkpointStorageIsConservative` 已增加“坏草稿后正常开练仍可找回原字节”断言。
2. `checkpointValue` 原先对活动区间与轮次分别读钟，恰逢完整周期边界可能保存不足一轮的时间却记成一轮。现在轮次由本次冻结区间总时长计算。新增 `checkpointCannotCrossCycleBoundaryBetweenReads`，用 11.999→12.001 秒的读钟边界覆盖。
3. `SyncService.receive` 原先对相同 installation ID 的旧版 hello（无 capability 列表）沿用旧缓存能力。Watch 降级时可能误发 V4 记录。现在 fresh hello 的 nil 能力即清空；已有 `PracticeSyncV4Tests` 增加同 ID 升级后降级、仍保留队列的断言。

复验 Core：167 tests / 33 suites 通过，退出码 0；永久日志 `evidence/core-session-review-tests.log`。App 新增/扩展回归由主任务集中 Xcode 执行，本次未并行启动 Xcode。

审查确认：训练画面读取 `phaseElapsed`，音频及触觉读取同源 `timelineSnapshot`；自然脚本恢复时保持真实活动进度；呼吸重锚与盆底先放松不重置 `elapsedActive`；完整轮次累计排除被暂停打断的半轮；正念重试保持每一活动区间的稳定 syncIdentifier。真机线路延迟与 HealthKit 外部幂等仍须设备实测。

草稿的 5 秒是检查节流周期，不是对强杀/断电持久化损失上限的保证。异常退出可能缺失最后尚未持久化的活动，但不会补计离开期间墙钟。
