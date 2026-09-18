# M2-R1 补修交付

范围：仅 M2-R01～M2-R05；M3–M6 未启动。2026-09-18。

## 基线与工作区

- 审阅基线：`b69b4cc26520bc42e9c742ba67ed26e81714a84d`。开始时本地 HEAD 与该基线相同，工作区干净，无后续或无关修改需要回退。
- 原开发分支：[codex/fangcun-v1-m0-m1](https://github.com/yvain57-afk/fangcun/tree/codex/fangcun-v1-m0-m1)。main 基准保持 `905626c6e08dc7a36ddd4e219abf6945795ac62f`。不合并、不强推。
- 原任务书及原 golden fixtures 保持原样；原审阅文件原样存为 [M2-GPT-REVIEW-R1.md](M2-GPT-REVIEW-R1.md)。
- 没有修改 UI、练习、饮品、原用户记录、模型参数或健康权限；没有清库、后端或在线 AI。新准备度服务仍未接入首页。

## 逐项审阅结果

五项均在原工程重现后修复，没有更换模型。每项修复前/后命令输出及中间失败见 [VERIFICATION](VERIFICATION.md)。输入均为合成样本，日志脱敏；本机 xcresult 和真机标识不入库。

| 编号 | 复现与修复 | 提交 | 测试与证据 |
|---|---|---|---|
| R01 | 删除历史睡眠未撤销旧评估；补齐历史、冲突和排除记录依赖，旧文件无依赖元数据时保守失效 | `7c7e232` | `M2ReviewR01Tests`：历史睡眠删除、20→19 日重算、supersedes、重启/损坏恢复/失败缓存、旧文件兼容；[red](evidence/m2-r01-red.txt) / [green](evidence/m2-r01-green.txt) |
| R02 | 首次分页失败固化 A 源；按指标保存初始化进度，全部读完才默认选源 | `dee4fa8` | `M2ReviewR02Tests`：恢复后选 B、手动 A 不覆盖、100 页预算续读；[red](evidence/m2-r02-red.txt) / [green](evidence/m2-r02-green.txt) |
| R03 | 配置及事件共享旧请求；按配置、Calendar、区间、generation 比较，串行有界补读；失败缓存也核对上下文 | `c4d77b4`、`a01860a` | `M2ReviewR03Tests` + 原 `InsightsStoreTests`：同输入合并、设置/时区/区间、读后新睡眠事件、切源/清除保护；[red](evidence/m2-r03-red.txt) / [green](evidence/m2-r03-green-recheck.txt)；缓存补验 [red](evidence/m2-r03-cache-red.txt) / [green](evidence/m2-r03-cache-green.txt) |
| R04 | 醒后两小时空增量随时钟创建 revision；指纹仅固定逻辑窗口，真实抽取仍受当前时刻限制 | `1a94809` | `M2ReviewR04Tests`：2/3 小时边界、18/24 小时 freshness、新样本/配置修订、不延长有效期；[red](evidence/m2-r04-red-recheck.txt) / [green](evidence/m2-r04-green-recheck.txt) |
| R05 | observer 提前确认；处理与持久化结束后由一次性 owner 确认，合并事件等待补读 | `b780466` | App `ReadinessObserverTests` 6 项：顺序、错误、真实取消、并发一次性确认、合并补读与重启；[red](evidence/m2-r05-red-order.txt) / [green](evidence/m2-r05-green-final.txt) |

## 最终验证

| 范围 | 实际结果 | 证据 |
|---|---|---|
| Core 全量 | 103/103 通过，含 10 项本轮新增回归及原 golden | [完整输出](evidence/m2-r1-core-final.txt) |
| App 全量 | 166/169 通过；3 项既有失败、23 issues；R05 六项全部通过 | [完整输出](evidence/m2-r1-app-final.txt) |
| 首页及交互 UI | 原验收的 HomeEvidencePipeline 与 FangcunRedesign 共 8/8 通过 | [完整输出](evidence/m2-r1-ui-final.txt) |
| 扩大练习 UI | PracticeReturnHome 两项均在旧按钮定位失败；审阅基准上独立复现同一失败 | [基准结果](evidence/m2-r1-baseline-ui.txt) |
| Watch 模拟器 | BUILD SUCCEEDED | [完整输出](evidence/m2-r1-watch-final.txt) |

本轮新增回归最终无失败。既有 App 失败为 `approvedPaperPalette`、`paperAppearanceDoesNotInvertAtNight`、`finishDialogCopyMatchesTheNextStep`，保留原断言。新增发现的两项既有 UI 失败发生在返回首页验证之前，不能声称这两项行为已验收。原 UI 命令全部测试结束后卡在 Xcode 收集诊断，停止后退出 143；上述 UI 计数来自完整控制台输出，未冒充完整 xcresult。基准命令关闭额外诊断收集后正常退出 65。命令、失败分类与定位见 [VERIFICATION](VERIFICATION.md)。

## 文件与存储影响

生产修改集中在 Core 的 `ReadinessEngine.swift`、`ReadinessPipeline.swift`、`InsightsStore.swift`，以及 App 的 `ReadinessHealthKitProvider.swift` 和新 `ReadinessObserverCompletion.swift`。测试新增 `M2ReviewProvider`、`M2ReviewR01Tests`～`R04Tests` 与 App `ReadinessObserverTests`。

继续使用独立 Insights schema 1；新字段全部可选：assessment 的 `dependencyVersion`、`evidenceContextVersion`，snapshot 的逐指标 `initialization`、`lastRefreshAttemptAt`、`lastSuccessfulRefreshAt`。旧文件缺字段可解码，不迁移清库，不触碰原 SwiftData 用户记录。已选或手动来源保持权威；缺数据不自动换源；初次发现未完成保存 cursor 与进度，保留失败/无等级状态。

旧评估未知完整依赖时遇删除保守撤销；未知上下文的失败缓存不作为新请求有效结果。正常新评估仍可由剩余充分数据重新得到等级。沿用删除屏障、原子发布、备份恢复与 generation 校验。测量、评估证据读取、刷新检查、计算时间分别保存。

## 未验证与停止点

合成数据重放不代表医学效度；默认阈值继续待校准。真实 HealthKit 增量/删除/锁屏/后台回调、系统终止与文件保护仍 `implemented_unverified`。Watch 后台、触感和跨设备送达/恢复仍 `blocked`，缺物理配对验证条件。没有通过本次模拟器测试声称后台真实可靠，见 [CAPABILITIES](CAPABILITIES.md)。

M2-R 的五项数据层前置修复已完成，可供 M3 开工前审阅；不等于全仓无失败或真机验收完成。审阅第 7 节的三项 App 既有失败及本轮扩大核验发现的两项既有 UI 失败继续作为独立维护事项，其中次级文字对比度问题确实存在。本轮停止在 M2-R，不实施 M3。
