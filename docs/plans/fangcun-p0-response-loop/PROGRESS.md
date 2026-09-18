# 方寸 P0 此刻回应闭环进度

## 任务理解（10 行内）

1. 目标：用户表达此刻后，方寸仅给出一个有身体背景依据的主动作，练完即有本地记录。
2. 状态来源：快捷与详细不合并；同日最近主动表达生效，同时间详细优先，跨日失效。
3. 身体数据只解释和调整动作，不命名情绪；未授权、加载、零基线、读取失败不得下确定结论。
4. 完成与反馈解耦：计时结束或确认早停先幂等保存，反馈可跳过且只更新同一 session。
5. 顺序：任务 0 保护基线 → 任务 1 纯 Swift 决策 → 任务 2 首页统一装配 → 任务 3 完成/反馈解耦 → 全量验收。
6. 每项先新建测试并保留正确红灯，再最小实现到全绿；禁止修改现有测试或放宽断言。
7. 最大风险：工作树既有大量用户改动，必须通过白名单、基线哈希和小差异避免覆盖。
8. 范围：不改 Watch、工程配置、权限/隐私、旧测试、工具、角色素材和旧设计；不提交、推送、上传或删数据。

## 任务 0：保护基线（已完成）

- 时间：2026-08-29（Asia/Shanghai）
- 真实路径：`.`（非符号链接）
- 保护清单：`/tmp/fangcun-p0-protected.sha256`，105 个文件；`shasum -a 256 -c` 全部 `OK`。
- `project.pbxproj`：`a42a3275d23188568e7f71ce31791bcdef6d82c6eba213929094e31bc5d53e49` — 匹配。
- iOS entitlements：`e82a7f6e130b0fe65a40214c15b4116c5245125329c63954d9ccdd9cc80f039e` — 匹配。
- privacy manifest：`a331d51864743ebe4e00dd22360b4a538b6b3ac26a6b3eb54094e60a36959a12` — 匹配。
- 流程偏差与首次清单失败证据保留于 `BLOCKED.md`；重建后未留下未解决的受影响项。

### `git status --short --branch` 基线

```text
## codex/inner-balance
 M Tools/MARKET_SERVICE.md
 M Tools/install_market_service.sh
 M Tools/market_service.py
 M iOSWatchApp/iOSWatchApp.xcodeproj/project.pbxproj
 M iOSWatchApp/iOSWatchApp/ContentView.swift
 M iOSWatchApp/iOSWatchApp/HealthKitRecoveryManager.swift
 M iOSWatchApp/iOSWatchApp/Info.plist
 M iOSWatchApp/iOSWatchApp/MarketDashboardView.swift
 M iOSWatchApp/iOSWatchApp/MarketDataManager.swift
 M iOSWatchApp/iOSWatchApp/PomodoroSessionView.swift
 M iOSWatchApp/iOSWatchApp/RecoveryStatusView.swift
 M iOSWatchApp/iOSWatchApp/iOSWatchAppApp.swift
?? .agents/
?? InnerBalance/
?? InnerBalanceCore/
?? Tools/AI_STOCK_POOL_NOTICE.md
?? Tools/Tests/
?? Tools/requirements-personal-os.txt
?? competitor-profiles/
?? docs/design/
?? docs/plans/2026-08-10-inner-balance-testflight-plan.md
?? docs/plans/2026-08-11-fangcun-chenhun-implementation.md
?? docs/plans/2026-08-12-fangcun-personalized-home-design.md
?? iOSWatchApp/iOSWatchApp/CoreLogic.swift
?? iOSWatchApp/iOSWatchApp/EdgeSpeechProtocol.swift
?? iOSWatchApp/iOSWatchApp/EdgeSpeechWebSocketTransport.swift
?? iOSWatchApp/iOSWatchApp/EdgeTextToSpeechServiceClient.swift
?? iOSWatchApp/iOSWatchApp/IndustryHeatViews.swift
?? iOSWatchApp/iOSWatchApp/MarketResearchStore.swift
?? iOSWatchApp/iOSWatchApp/MarketResearchViews.swift
?? iOSWatchApp/iOSWatchApp/SpeechAudioPlayer.swift
?? iOSWatchApp/iOSWatchApp/TextToSpeechCore.swift
?? iOSWatchApp/iOSWatchApp/TextToSpeechFeature.swift
?? iOSWatchApp/iOSWatchApp/TextToSpeechServiceClient.swift
?? iOSWatchApp/iOSWatchApp/TextToSpeechView.swift
?? iOSWatchApp/iOSWatchApp/TrainingPlan.swift
?? iOSWatchApp/iPadApp/
```

## 当前位置

## 任务 1：统一当前状态决策（已完成）

- RED：新建 `CurrentMomentDecisionTests.swift`，6 个 `@Test` 声明。首次 Core 命令退出码 1，混入新测试 helper 的 `static member ... cannot be used on instance` 错误，判定为无效红灯；只修正 helper 作用域。
- 正确 RED：第二次 `swift test --package-path InnerBalanceCore --scratch-path /tmp/fangcun-p0-core` 退出码 1；失败核心是 `cannot find 'CurrentMomentDecisionEngine' in scope`、`CurrentMomentQuickState`、`CurrentMomentDetailedState`。
- GREEN：新建 `Recommendation/CurrentMomentDecision.swift`，实现同日最近者胜、同时间详细优先、跨日失效、无状态、四档身体负荷、稳定 reason code/规则版本及凯格尔禁荐。
- 首次绿灯：完整 Core 命令退出码 0，`Test run with 53 tests in 13 suites passed`。
- 反向验证：故意把“更新的详细登记胜出”断言改为 `.quick(.tired)`，完整 Core 命令退出码 1，53 个测试仅该测试 1 issue；实际值为 `.detailed(...)`。
- 恢复与整理后：两次完整 Core 命令均退出码 0，最新为 `Test run with 53 tests in 13 suites passed`；53 个 `@Test` 声明，0 failure，无 skip/disabled/TODO。

## 当前位置

## 任务 2：首页统一装配（App 已完成，UI 反向路径留待全量修复）

- RED：在指定新文件加入 6 个 App 测试与 2 个 UI 测试。App 首次完整命令退出码 65，核心失败为缺少 `TodayCoordinator` / `TodayBodyContext`；UI 首次完整命令退出码 65，既有 14 个 UI 测试全过，仅两个新 `home.currentState` 场景失败。
- GREEN（App）：新增 `TodayCoordinator` / `TodayViewState`，Root 只注入依赖与导航；Home 统一装配单一状态、单一解释、单一动作及当日最近练习。两次完整 App 命令退出码均为 0，最新 `** TEST SUCCEEDED **`。
- UI 接线：快捷与详细两条反向路径已接入同一 `TodayCoordinator`；“详细→快捷”新测试和 14 个既有 UI 测试均通过。
- UI 验收上限：接线后的三次完整 UI 命令均已使用。第 1 次在测试前被 Simulator `Busy` 阻断；第 2 次 15/16，通过项包含“详细→快捷”，失败项是“快捷→详细”读到旧的“平静”；只修正新测试的等待条件后，第 3 次仍为 15/16，同一场景失败。
- 按任务书不再重复该验收命令；该单一 UI 反向路径进入最终回归修复清单，不把 Task 2 宣称为 UI 全绿。

## 当前位置

## 任务 3：完成与反馈解耦（实现与 App 验收完成）

- RED：在指定新文件加入 6 个 App 测试与 1 个 UI 测试。首次完整 App 命令退出码 65，编译器明确报 `nil is not compatible with expected argument type 'Int'` 与 `Missing argument for parameter 'afterRating'`，命中“无反馈完成记录”缺口。
- 实现：完成记录的练前/练后值可缺省；默认练前值不再当作输入；结束后先用固定 sessionID 幂等保存本地 completion 与 Mindful Session；“保留这次变化”只更新同一记录并写 post State of Mind；“先完成”不写 post、不造前后差。
- SwiftData：保留唯一 sessionID，已有对象原位更新，不删记录、不删库重建；可选字段对旧非空值保持可读。
- App GREEN：修正一个新增测试宏对 throwing expression 的写法后，完整 App 命令退出码 0，随后多次完整命令均 `** TEST SUCCEEDED **`；最新结果包 `/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_20-12-58-+0800.xcresult`。
- 重复保存反证：故意把唯一 completion 行数断言从 1 反转为 2，完整 App 命令退出码 65，唯一失败为 `repeatedCompletionIsIdempotent()`；恢复为 1 后完整 App 命令退出码 0。实际为 1 条 completion、1 次 Mindful 写入。
- UI 路径：第 1 轮 15/17；第 2 轮新增“练完→先完成→首页”通过，首页可访问文本包含“已完成”且不含“持平”。UI 测试没有在生产实现前单独执行，流程偏差已写 `BLOCKED.md`。

## 最终三轮全量回归

- 第 1 轮 UI：15/17；失败为两个目标流程。根因分别是 Home 使用页面启动时刻作为决策 `now`，以及最新练习的 UI 查询类型过窄。
- 第 2 轮 UI：16/17；“快捷→详细”和“练完→先完成→首页”均通过，只剩“详细→快捷”。根因是快捷保存仍把页面启动时刻写为 `updatedAt`。
- 第 3 轮 UI：两条状态反向路径均通过，但 Simulator/XCTest 运行 2221 秒后出现 5 个分散基础设施失败：`application ... is not running`、`Timed out while synthesizing event`、`Timed out while evaluating UI query` 等；退出码 65。按“三轮即停”不再重跑。
- Core 最终命令退出码 0：`Test run with 53 tests in 13 suites passed`。
- App 最终命令退出码 0：`** TEST SUCCEEDED **`；124 个测试声明。
- UI：17 个测试声明，skip 扫描 0；最新完整命令未全绿，因此不宣称达到最终 UI 验收条件。
- 保护清单：`shasum -a 256 -c /tmp/fangcun-p0-protected.sha256` 105/105 `OK`。
- 固定哈希：pbxproj、iOS entitlements、privacy manifest 分别仍为任务书给定的 `a42a…53e49`、`e82a…f039e`、`a331…a12`。
- 白名单审计：以 `PROGRESS.md` 创建时间 `2026-08-29 19:23:42 +0800` 为界，源码/测试/本任务文档共 17 个更新文件，全部位于允许清单；白名单外更新 0。

## 当前位置

- 已按最大三轮规则停止完整 UI 回归。对第 3 轮的 5 个失败项逐一使用 `-only-testing` 诊断，5/5 单独通过：新增跳过反馈路径 14.434 秒、呼吸阶段 11.207 秒、辅助功能字号 28.452 秒、声音/触觉引导 15.407 秒、建议词立即保存 20.632 秒。
- 单项结果包依次为 `/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_22-07-45-+0800.xcresult`、`...22-08-36-+0800.xcresult`、`...22-10-42-+0800.xcresult`、`...22-11-51-+0800.xcresult`、`...22-13-00-+0800.xcresult`，均为 `** TEST SUCCEEDED **`。
- 诊断过程中 Xcode 仍对非实际承载测试的 Clone 2 报 `Invalid device state` / runner launch 失败，而 Clone 1 的目标测试通过；证据支持 Simulator/XCTest 克隆设备失稳，未见产品行为回归。
- 功能实现、Core、App、计数、skip、保护哈希和白名单审计达标；但最新完整 UI 命令退出码仍为 65，不以单项绿灯替代 17/17 完整验收，证据与剩余工作见 `BLOCKED.md`。
- 诊断后最新审计：保护清单 105/105 `OK`；三个固定哈希精确匹配；测试声明 53/124/17；skip/disabled/TODO 匹配 0；以 `2026-08-29 19:23:42 +0800` 为界共 17 个更新文件，白名单外 0。
- Goal 第 3 个连续回合复核：当前 iPhone 17 Pro 与其他模拟器均为 Shutdown，活跃 `xcodebuild`/XCTest 进程 0，无可继续等待的任务。
- 后续 5 个单项 `.xcresult` 将 DerivedData 中第 3 轮完整 UI 结果包轮换清理；完整命令的失败输出仍保留在本文档和 `BLOCKED.md`，但当前文件系统已无该完整结果包。现存 5 个单项结果包经 `xcresulttool` 回读均为 1 passed、0 failed、0 skipped。
- 完成条件仍缺原始完整 UI 命令 17/17 绿灯；任务书又明确“最多 3 轮，满 3 轮即停”。在不获得突破该上限的新授权时，已无合规的验收动作可执行，不能标记完成。

## 用户授权的额外完整验收（已完成）

- 授权：用户明确允许“突破三轮上限，额外执行一次原始完整 UI 验收命令”；本次只执行该 1 次，未改命令参数，未先清理或重置模拟器。
- UI：原始完整命令退出码 0，`** TEST SUCCEEDED **`，耗时 206.789 秒；结果包 `/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_23-27-44-+0800.xcresult`。`xcresulttool` 回读为 `totalTestCount: 17`、`passedTests: 17`、`failedTests: 0`、`skippedTests: 0`，两条状态反向路径与“练完→先完成→首页”均通过。
- Core：紧随 UI 后重跑 `swift test --package-path InnerBalanceCore --scratch-path /tmp/fangcun-p0-core`，退出码 0，`Test run with 53 tests in 13 suites passed`。
- App：原始完整 App 命令退出码 0，`** TEST SUCCEEDED **`；结果包 `/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_23-31-48-+0800.xcresult`。`xcresulttool` 回读为 `totalTestCount: 124`、`passedTests: 124`、`failedTests: 0`、`skippedTests: 0`。
- 最终审计：保护清单 105/105 `OK`；三个固定 SHA-256 精确匹配；测试声明 53/124/17；skip/disabled/TODO 匹配 0；更新文件 17，白名单外 0；仓库未配置 Swift lint/format 命令。
- 完成判定：任务书的 Core/App/UI、数量、skip、保护哈希、白名单与两条目标 UI 流程已全部有当前绿灯证据；未提交、推送、上传或删除数据。
