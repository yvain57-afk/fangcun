# 方寸 Fangcun｜M2 远程代码审阅与补修任务 R1

审阅日期：2026-09-18（Asia/Singapore）  
仓库：`yvain57-afk/fangcun`  
分支：`codex/fangcun-v1-m0-m1`  
固定审阅 HEAD：`b69b4cc26520bc42e9c742ba67ed26e81714a84d`  
main 基准：`905626c6e08dc7a36ddd4e219abf6945795ac62f`

## 0. 本轮结论与执行范围

M2 的独立数据域、准备度引擎和评估存储已经有实际代码，服务未接入首页符合停止点。无需推倒重做，也不需要更换视觉体系。

**建议先完成 M2-R 补修，再进入 M3。此次交给 Codex 的执行范围仅为本文件的 M2-R，不自动启动 M3–M6，不合并 main。**

以下发现来自固定提交的源码、测试代码、原任务书和交付记录之间的对照。它们是可按控制流定位的边界问题，尚未在本轮运行原工程或在物理设备上复现。Codex 必须先在自己的原工程中增加针对性回归，保留修复前失败与修复后通过的证据。如果某项判断不成立，用同一场景的实际测试和代码路径证明，不必为了服从审阅而改出新问题。

本轮没有修改 GitHub、没有重新执行 Core/Xcode 测试、没有重新安装手机或手表。仓库报告的 Core 93、UI 8、App 160/163 是交付方结果，不能改写成审阅者独立重跑结果。

本文件是原 `FANGCUN_CODEX_SPEC_v1.0.md` 的补充，不替换第 4 章模型，不改变权重、门槛或已有产品承诺。

## 1. 已核对并应保留的工作

- 开发分支指向上述 HEAD，main 仍指向上述基准。
- `ReadinessPipeline`、标准化/选源、睡眠识别、逐源基线、`ReadinessEngine`、`InsightsStore` 已形成独立链路。
- availability、level、freshness 与 syncState 分开；规则集中配置；未加入练习奖励分。
- 存储已有原子替换、前一版本备份、删除日志、generation 校验和修订关系；这些结构应继续利用。
- 正常路径、合成样本、原 golden fixtures 与若干故障注入已有测试。测试通过不涵盖下述尚需补充的交错场景。
- 真实 HealthKit 增量、锁屏访问和 Watch 后台/传输仍属于未验证能力，不用编译成功替代。

依据：[交付入口](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/docs/plans/fangcun-v1/M2-REVIEW.md)、[核验记录](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/docs/plans/fangcun-v1/VERIFICATION.md)、[能力矩阵](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/docs/plans/fangcun-v1/CAPABILITIES.md)。

## 2. M2-R01｜补齐评估的间接数据依赖与删除失效

**优先级：P1；进入 M3 前完成。**

### 当前代码路径

`BaselineBuilder.build` 使用历史睡眠段决定纳入哪些日期、哪些 HRV/静息心率样本。`ReadinessEngine.evaluate` 生成 `contributingSampleIDs` 时，仅收集当前睡眠样本、当前体征样本和基线体征样本，没有包含构建基线所使用的历史睡眠样本。

`InsightsSnapshot.redact` 又只根据 `contributingSampleIDs` 与 tombstone 的交集移除评估。因此，删除一条参与基线的历史睡眠记录，可能移除原始样本和 episode，却保留仍依赖这条睡眠的 current assessment、旧基线日数和历史结果。

### 最小复现场景

1. 使用现有 `ReadinessFixture.records()` 建立 20 日成熟基线及合格当前评估。
2. 删除历史睡眠 UUID，例如现有 fixture 的 `f.id(101)`；该样本属于前一日睡眠，不是当前睡眠或体征。
3. 通过 `InsightsStore.deleteSamples` 注入删除，在重新计算前读取 snapshot。
4. 检查原 current 是否失效、受影响历史评估是否已撤销为最小审计信息。
5. 再刷新、重启、注入查询失败或主文件损坏，确认旧备份不能把未撤销结果恢复为当前合格结论。

### 修复要求

建立完整的评估依赖集合，至少覆盖参与基线的历史主睡眠样本 UUID。可以使用依赖摘要/图或扩展 contributing IDs；不要求保存额外健康原始值。

同时核对用于睡眠冲突、质控、样本排除和主段选择的间接依赖。会改变评估资格或计算输入的记录，不应仅因未成为最终显示值而脱离失效关系。

删除后立即撤销受影响结果的当前资格，清理受影响旧结果，保留最小 audit 与 revision/supersedes 关系。重算完成后，剩余资料仍充分时允许生成新的合格结果；禁止把“删除后暂时失效”误实现为“以后永远不给等级”。

删除、备份恢复与失败缓存保留使用同一套依赖判定。对历史睡眠的删除也应适用，不仅测试删除当前 HRV。

### 验收

`R01a` 删除历史基线睡眠后，原 current 不再可作为有效结果返回。  
`R01b` 重算后基线日数相应变化；仍成熟时可重新得到 usual，但必须具有正确新依据及修订关系。  
`R01c` 故障恢复和失败查询不能恢复未撤销的旧评估；原始记录与历史派生内容不从备份复活。

定位：[BaselineBuilder](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/BaselineBuilder.swift)、[ReadinessEngine](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/ReadinessEngine.swift)、[InsightsStore](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/InsightsStore.swift)。

## 3. M2-R02｜首次分页未完成时，不固化不完整的主来源选择

**优先级：P1；进入 M3 前完成。**

### 当前代码路径

`ReadinessPipeline.run` 会先把成功页的样本和 cursor 写入 candidate。后续页发生错误时跳出循环，但仍继续调用 `StableSourceSelector.select`，随后提交 candidate。

`StableSourceSelector.select` 对 existing 直接返回，符合日常稳定选源要求。但首次读取未完成时，先到的一小部分数据也可能被固化成 existing。后续续读拿到历史覆盖更充分的来源后，不会重新完成首次选源。

### 最小复现场景

同一个指标的第一页仅包含来源 A 的少量样本，`hasMore=true`；第二页本应包含来源 B 的完整 20 日历史，但第一次请求该页失败。

第一次刷新保存进度，第二次刷新从已提交 cursor 继续并完成全部数据。验证最终首次主源按完整候选集合选择 B，而非永久停留在 A。

### 修复要求

对每个指标记录初始化/重建状态，例如 unread、inProgress、complete；名称可调整。只有该指标的首次有界读取完成后，才冻结默认主源。

允许持久化中间样本和事务性 cursor，以便继续分页；但初始化进度与“可以得出合格结论”必须分开。达到页数/工作预算上限也属于仍需续读，不得当作完整来源发现。

手动来源选择继续优先；已经完成初始化的稳定来源不得因为一次失败而清空或自动换源。该修复针对首次不完整来源发现，也应审视失效锚点重建的同类情况，不取消已有稳定选源原则。

### 验收

`R02a` 第一页成功、第二页失败后，恢复续读仍能正确完成首次选源。  
`R02b` 分页未结束时不输出虚假的 assessable/provisional。  
`R02c` 完成初始化后，主源暂时缺数据仍不自动切换。  
`R02d` 显式手动选择不会被初始化完成后的自动选择覆盖。

定位：[ReadinessPipeline.run](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/ReadinessPipeline.swift)、[StableSourceSelector](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/ReadinessSamples.swift)。

## 4. M2-R03｜单飞合并必须识别请求语义变化，并补做新事件刷新

**优先级：P1；进入 M3 前完成。**

### 当前代码路径

`ReadinessPipeline.refresh` 只要发现已有 `flight`，便直接返回其结果，没有比较 configuration、calendar/time zone、interventions 等输入。

例如第一轮按睡眠目标 8 小时计算尚未完成；用户改为 10 小时后触发第二轮，第二轮仍可能得到第一轮 8 小时的结果。generation 校验只覆盖 store generation 的变化，单独变更函数参数不会自动改变 generation。

类似地，在第一轮已经读完睡眠之后收到新的睡眠事件，第二次刷新若只是加入旧 flight，没有 dirty/pending 机制，就可能不在这一轮读取到新事件。之后再有刷新机会才会补上。

### 最小复现场景

使用可暂停的 provider：A 请求 configuration 为 8 小时，暂停其第一次查询；B 请求 configuration 为 10 小时；恢复 provider。B 不能以“已处理新配置”的语义返回 A 的旧配置结果。

另建事件交错测试：先完成睡眠查询、暂停后续指标查询，再注入睡眠新增事件并请求刷新；当前轮结束后必须有一次能处理该变化的刷新。

### 修复要求

为请求定义可比较的语义身份，至少涵盖配置版本、来源/存储 generation、时区以及影响取样的已知练习上下文版本。不要仅按函数名把所有调用视为同一个请求。

同语义请求可以共享在途结果；不同语义请求须串行接续、重新启动，或明确返回 superseded 并由协调器重试，不能悄悄作为已完成返回旧结果。

当在途期间收到相关变化，记录 dirty/pending 状态，并在当前轮之后进行有界的合并补刷新。避免每个回调都启动全量查询，也不能无限重试。source selection、clear/delete 的迟到请求保护继续保留。

### 验收

`R03a` 同输入并发仍可合并。  
`R03b` 8 小时请求与 10 小时请求不能无差别共享旧结果；最终可见结果对应最新有效设置。  
`R03c` 在途期间出现新的相关健康事件，完成后补刷新，不依赖用户再拉一次页面。  
`R03d` 来源切换、删除、清除之后，迟到请求不能覆盖新事实。

定位：[ReadinessPipeline.refresh](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/ReadinessPipeline.swift)、[现有并发测试](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Tests/InnerBalanceCoreTests/Readiness/InsightsStoreTests.swift)。

## 5. M2-R04｜修订身份应由有效证据决定，不由移动的读取窗口决定

**优先级：P2，但应在首页、历史和同步接入前完成。**

### 当前代码路径

`CurrentMetricExtractor` 的静息心率窗口终点为 `min(now, sleepEnd + 3h)`，符合当前取样规则。`ReadinessEngine` 计算 inputFingerprint 时，只清除了顶层 now/queriedAt，仍编码完整 feature.window。

因此，在睡眠结束后第 0.5–3 小时内，即使所有样本、来源、配置和质量状态都不变，时间推进也会改变 RHR window.end、fingerprint，并使 `InsightsSnapshot.record` 创建新 revision。

现有存储重复刷新测试使用 `ReadinessFixture` 默认数据，主睡眠结束已过去 4 小时；该场景中窗口已经封闭，不能覆盖上述问题。

### 最小复现场景

将现有 fixture 全部样本时间向后平移 2 小时，使当前主睡眠结束距 now 为 2 小时。不要改变样本 ID、值和来源。分别在 now 与 now+60 秒执行完整 provider→pipeline→store 刷新，期间 provider 不提供任何新样本。

预期同一个 assessmentID、revision、inputFingerprint，validUntil 不延长。再加入真实新样本，才应按实际证据变化判断是否生成修订。

### 修复要求

将稳定的评估证据身份与“本次查到哪个时刻”的运行信息分开。fingerprint 保留实际采用的样本、来源、基线、配置、逻辑取样范围与资格等语义；滚动查询截止时间不应单独造成修订。

不能为修复指纹而放宽静息心率当前窗口、接受未来样本或改变原模型。也不能简单禁止修订，导致晚到睡眠、删除、来源变化和真实新证据无法被记录。

查询时间另需核对：`ReadinessInputBuilder` 目前从样本 `queriedAt` 取最大值；无新增样本的成功查询不会更新该值。界面接入时区分“该评估证据被读取的时间”与“最近一次检查/刷新时间”，不要互相冒充。

### 验收

`R04a` 醒后 2 小时与 2 小时 1 分、完全相同样本，身份与修订保持一致。  
`R04b` 醒后 3 小时边界仍保持证据身份稳定；18/24 小时可以正常改变新鲜度和空态，但不把单纯时间流逝当作新的健康证据。新周期或真正资格变化仍可形成相应记录，不强制所有过期状态沿用原 ID。  
`R04c` 真正新增证据、删除或变更配置仍按语义正确修订；有效期限不随刷新延长。

定位：[CurrentMetricExtractor](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/BaselineBuilder.swift)、[指纹生成](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/ReadinessEngine.swift)、[ReadinessFixture](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalanceCore/Tests/InnerBalanceCoreTests/Readiness/ReadinessFixture.swift)。

## 6. M2-R05｜修正 observer 完成回调顺序，作为生命周期接入前置条件

**优先级：接入前必须完成；目前未启用后台投递，不能据此声称真机已经丢失更新。**

### 当前代码路径与官方边界

`ReadinessHealthKitProvider.startObserving` 先调用 `completion()`，随后才在 Task 中 `await onChange()`。

Apple 关于 HealthKit observer 的公开文档要求，在处理新资料之后调用相应完成处理器。这是向系统确认本次后台处理已完成；“及时确认”不能理解成“开始处理之前先确认”。

参考：[Executing Observer Queries](https://developer.apple.com/documentation/healthkit/executing-observer-queries)、[HKObserverQueryCompletionHandler](https://developer.apple.com/documentation/healthkit/hkobserverquerycompletionhandler)。本轮查询日期：2026-09-18。

### 修复要求

明确每个回调的所有者与结束路径。在一次有界的读取/处理/持久化工作结束后再确认；错误和取消同样要有可靠收尾，不能忘记回调，也不能重复回调。

结合 R03 的 pending/dirty 机制处理合并事件：不能仅等待一轮早于新事件的旧查询，就声称新事件已处理。无法完成时保留可恢复进度和失败状态，不无界占用后台。

本任务不要求擅自新增后台权限或保证唤醒。生命周期、正式授权和后台交付配置仍按原阶段进行；真实系统行为继续标注待真机。

### 验收

`R05a` 用可控制的处理器验证事件顺序：收到事件→处理/持久化结束→确认。  
`R05b` 正常、错误、取消、多个合并回调均恰当收尾，且每个 completion 最多调用一次。  
`R05c` 在已经读过某一指标后又收到该指标变化，能通过补刷新处理，不靠提前确认掩盖遗漏。

定位：[ReadinessHealthKitProvider.startObserving](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/InnerBalance/InnerBalanceApp/Health/Readiness/ReadinessHealthKitProvider.swift)。

## 7. 三项既有 App 失败的处理方式

核验报告已经说明这些失败在 M2 前提交也存在。不能把它们说成 M2 引入，也不能用“原来就失败”代替后续修复。

- `approvedPaperPalette` 中的旧版棕色色值预期，应与当前已确认蓝色视觉契约逐一核对；不得退回旧主题。
- 其中浅色次级文字对比度 4.4631 低于当前测试 4.5，属于真实可访问性问题。可在 M3 前置的独立维护提交中作最小 token 修正，保留原风格并补看实际截图。不得降低测试门槛换绿灯。
- `paperAppearanceDoesNotInvertAtNight` 的固定浅色模式预期，应改成当前用户偏好/系统适配的行为测试，不能删除测试或强制禁用深色模式。
- `finishDialogCopyMatchesTheNextStep` 应测试操作语义及稳定标识，并保留文案目录契约检查，不锁死已经计划人工调整的整段旧文案。

本轮 M2-R 不顺带开展整体 UI 改版。若上述维护未执行，继续如实报告全量 App 的已知失败，不把局部通过写成全仓全绿。

依据：[完整核验报告](https://github.com/yvain57-afk/fangcun/blob/b69b4cc26520bc42e9c742ba67ed26e81714a84d/docs/plans/fangcun-v1/VERIFICATION.md)。

## 8. 实施与交付要求

1. 先读取当前工作区、AGENTS 与本审阅版本差异。工作区若已有新修复，逐项核对，不能回退到旧 HEAD 或重复覆盖。
2. 保留原任务书与 golden fixtures；将本文件保存为 `docs/plans/fangcun-v1/M2-GPT-REVIEW-R1.md`。
3. 每条 M2-R 先写回归/重现，再作最小修复。测试不能只注入最终结论，涉及 pipeline/store 的必须经过实际领域链路。
4. 不重写算法、不改现有 UI、不删除用户资料、不修改其他应用的 HealthKit 数据、不增加在线 AI 或后端。
5. 使用独立提交，写清 M2-R01～R05 对应文件、测试和结果。新增状态或存储字段涉及 schema 时处理旧文件读取、备份和故障恢复，不清库。
6. 更新 TASKS、DECISIONS、VERIFICATION、CAPABILITIES，区分实现完成、合成测试通过、SDK 编译通过和真机验证。
7. 运行 Core 全量、新增回归、App 全量、现有首页/练习 UI 回归及 Watch 模拟器编译。现有失败与新增失败分开列出；不要求为了 M2-R 伪造 Watch 真机验收。
8. 将明确属于本轮的提交推送到原开发分支，不强推、不合并 main，不上传健康值、设备标识、签名、凭证或真实健康截图。
9. 返回最终 HEAD、各 M2-R 的证据、未验证项和是否满足 M3 前置条件。**完成后停止，暂不实施 M3–M6。**

### 建议的交付摘要格式

| 项目 | 重现/反证 | 修复提交 | 测试名称 | 实际结果 | 未验证部分 |
| --- | --- | --- | --- | --- | --- |
| M2-R01 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 |
| M2-R02 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 |
| M2-R03 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 |
| M2-R04 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 |
| M2-R05 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 |

## 9. 补修通过后的下一阶段边界（仅用于导航，不是本轮启动指令）

M3 再完成安全迁移、手机首页/详情/7与28天历史、建议/轻活动/反馈，以及 DTO、outbox/ACK 和本机摘要接口。继续保留原视觉，先让手机消费统一评估结果，不同时重做 Watch 和小组件。

Watch 的新界面与离线会话仍属于 M4，系统提醒/组件属于 M5，Live Activity 和整体交付属于 M6。

当前新数据服务未接入首页是按计划实施，并非漏做；修复数据层边界后再接入，可以避免把同一种错误扩散到多个端。
