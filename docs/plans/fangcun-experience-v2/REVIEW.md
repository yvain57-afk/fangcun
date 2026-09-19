# 方寸体验与饮品关怀 V2 交付审阅

本轮已将 v2.0 任务书接入原生 iPhone App，按 V2-00～V2-07 分阶段实现并保留原有记录、画风与模型。工程交付已形成；**全仓旧 UI 尚有 15 项遗留失败，真实通知与人工体验验收尚未通过**。

基准 `99ebe69f30a2a502225e913a9dfd35f54101dabd`；开发分支 [`codex/fangcun-v1-m0-m1`](https://github.com/yvain57-afk/fangcun/tree/codex/fangcun-v1-m0-m1)。没有强推、合并 main、上架或上传健康资料。分阶段提交见 [TASKS](TASKS.md)，最终 HEAD 由该文档所在提交及交付回复确定，避免自引用 SHA。

## 可以看到的变化

- 今日页明确区分“恢复接近平常 / 今天建议放缓一点 / 今天优先安排恢复”和“基于睡眠的今日建议”。最多两条理由，保留五分钟呼吸入口。数据不足不会包装成平稳。
- 解释页先回答结论、理由和行动；技术身份、查询/计算时间留在设置的诊断页。个人范围仍严格遵守 7/14 日门槛，历史按恢复周期收起旧修订。
- 原有六类猫狗画面配有限时局部动作。删除角色观看/重播；记水成功、咖啡酒中性确认、撤销、练习保存各用对应事件。静态/减少动态/低电量策略不排动画队列。
- 饮品容量与剂量分开：每杯 140 mg 咖啡改杯量仍是 140 mg；明确浓度才随容量计算。酒精按新记录容量与度数估算，旧记录估值保持。未知不是零。记录/编辑/撤销以成功提交为界。
- 水、咖啡、酒精关怀在本机计算；最多一条、可以忽略、不会制造欠水或恢复加分。只有主动开启才请求 iPhone 本地通知；默认锁屏通用文案、静默、每天及滚动 24h 双预算。
- 最大字号饮品界面改为完整纵向滚动，记录、汇总和撤销都可到达。原尺寸仍保留轻量弹层。

[真实原生截图和录屏](evidence/final-native/README.md) · [全部 45 项验收](ACCEPTANCE_RESULTS.md) · [文案清单](COPY_REVIEW.csv) · [动作限制](MOTION_REVIEW.md)

## 数据与存储

基线追查确认了实际误排原因：旧代码混淆阶段交叠与 awake/asleep 冲突，历史又用 flags.isEmpty 排除整晚。现按质量维度过滤；可靠睡眠并集保留，真冲突仍限制评估。同一批本机数据回放后有效覆盖增加，未改 7/14 日门槛或原模型参数。[脱敏调查](BASELINE_COVERAGE_FINDINGS.md)。

Diary 仍是唯一饮品权威，扩展兼容字段、原子命令回执与撤销修订；原迁移备份保留。Insights 使用 featureSchemaVersion 2 与 sleep-quality-v2，旧档可解码；不清库。Care 单独保存设置和注意力回执，不生成虚假饮品。新饮品同步等待对端 beverage-v2 能力，旧 Watch 不理解时保留待发，不降级成水。未增加 HealthKit 饮食权限、网络服务、遥测或签名权限。

主要修改路径：`Features/Readiness/DayGuidancePresentation.swift`、`ReadinessViews.swift`、`Features/Home/FangcunTodayView.swift`、`FangcunDrinkSheet.swift`、`FangcunDrinkEditor.swift`、`FangcunDiary.swift`、`BeverageCareCoordinator.swift`、`BeverageCareViews.swift`、`CareNotificationClient.swift`、`DesignSystem/FangcunCompanion.swift/.metal`，以及 Core 的 `Readiness/`、`BeverageModels.swift`、`BeverageCareEngine.swift`、`CareNotificationPlanner.swift`、`CompanionMotionPolicy.swift`、`Sync/`。完整文件清单见仓库根 `FILE_INDEX.md`。

## 实际验证

| 项目 | 结果 |
|---|---|
| Core | 145 项 / 28 套通过，exit 0，包含原 golden/M2-R 与新质量/饮品/预算/动效边界 |
| App 功能全量 | 195 项 / 31 套通过，exit 0，结果包可读 |
| UI 全量首次 | 46 项：28 通过、18 失败，exit 65，结果包可读 |
| 本轮三项 UI 回归修复 + 场景复验 | 10 项通过，exit 0；实际 60 秒练习完成，无跳过计时 |
| 最大字号布局修复后 | 3 项通过，exit 0；实际记水→汇总→撤销与饮品编辑复验 |
| Watch 模拟器 | 编译成功，exit 0 |
| iPhone | 签名 Release 覆盖安装成功，版本回读 1.0.0（2026091904）；原有文件/偏好安装前后相同 |

三项本轮 UI 失败均已修复；剩余 15 项与 M3 已复现的旧界面契约失败相同，未删测试或恢复旧产品语义。最大字号挤压是查看真实截图发现的额外问题，现已修复并补完整操作验证。完整命令、测试名、失败分类与证据见 [VERIFICATION](VERIFICATION.md)。

## 尚未验证 / 停止点

手机安装时处于锁屏，系统拒绝启动（Locked），已请求用户解锁。安装保存与版本已核验；新版本首次启动后的 HealthKit 刷新、权限弹窗、通知冷启动/后台/锁屏送达、真实 VoiceOver/减少动态/低电量及物理磁盘失败恢复均未记为通过。真实 Watch 送达和 App Group 条件仍单独未验证。

深浅色截图和录屏是人工评审材料。“可爱自然”“三秒看懂”和用户是否把限定建议当完整评估仍需用户确认，未开展或伪造用户实验。饮品及作息阈值是待校准工程初值，不是医学判定标准。此轮停止于 V2，不自动进入后续阶段。
