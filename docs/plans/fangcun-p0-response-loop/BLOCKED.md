# BLOCKED

## 2026-08-29 任务 0 流程证据

- 流程偏差：只读的符号链接探测命令误用了任务书禁止的 `readlink . || true`。该命令没有改动文件，也没有用于验收判定；后续不再使用 `|| true`。
- 命令失败：首次生成 `/tmp/fangcun-p0-protected.sha256` 时使用普通 `xargs`，含空格的 `iOSWatchApp/iOSWatchApp Watch App/**` 被拆分，输出 `Is a directory` / `No such file or directory`。该清单当场判定无效；现已改为逐行引用路径重建，105 个文件全部回读 `OK`，受影响的哈希基线已恢复。
- 影响：无生产代码改动；三个指定文件的 SHA-256 均与任务书一致。
- 诊断后固定哈希复核时，首条命令对 entitlements 和隐私清单使用了不存在的假定路径，退出码 1；该命令未读到这两个文件，不是哈希不匹配。随即用 `rg --files` 解析真实路径并重跑，`project.pbxproj`、`InnerBalance.entitlements`、`PrivacyInfo.xcprivacy` 三者哈希均与任务书精确一致，无文件改动。

## 2026-08-29 任务 2 UI 验收上限

- 接线后第 1 次完整 UI 验收在运行测试前被 Simulator `Busy` 阻断，退出码 65。
- 第 2 次为 15/16；14 个既有 UI 测试与新增“详细→快捷”通过，新增“快捷→详细”仍显示旧的“平静”。
- 只把新测试从“元素已经存在”改为等待标签成为“焦虑”，没有放宽最终断言；第 3 次仍为 15/16，同一测试失败，结果包为 `/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_19-46-36-+0800.xcresult`。
- 处理：遵守同一验收命令三次失败后切换任务的规则，停止重跑并进入任务 3；最终全量回归前再做一次针对性根因修复。

## 2026-08-29 任务 3 流程偏差

- 新增 6 个 App 测试和 1 个 UI 测试均先于生产实现写入；完整 App 命令随后给出正确行为 RED。
- 但 UI 新测试没有在生产实现前单独执行；第一次实际完整 UI 运行发生在实现之后，并因目标流程/可访问元素查询失败而红。该次不能作为严格的“生产实现前 UI RED”证据，因此不宣称完全符合这一过程条件。

## 2026-08-29 最终 UI 阻塞（三轮上限）

- 第 1 轮结果包：`/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_20-01-13-+0800.xcresult`，15/17；两个目标 UI 流程失败。
- 第 2 轮结果包：`/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_20-08-05-+0800.xcresult`，16/17；“快捷→详细”和“练完→先完成→首页”通过，仅“详细→快捷”失败。随后修正快捷点击的真实 `updatedAt`。
- 第 3 轮结果包：`/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_20-13-37-+0800.xcresult`，运行 2221.232 秒后退出码 65。两条状态反向路径均通过；失败分散为 4 个既有测试和跳过路径，错误包含应用未运行、事件合成超时、UI 查询超时，属于本轮 Simulator/XCTest 失稳表现。
- 限定性诊断（不是第 4 轮完整回归）：以原命令参数对上述 5 个失败项逐一加 `-only-testing:<class>/<method>` 执行，5/5 均退出 0。结果包为 `...22-07-45-+0800.xcresult`、`...22-08-36-+0800.xcresult`、`...22-10-42-+0800.xcresult`、`...22-11-51-+0800.xcresult`、`...22-13-00-+0800.xcresult`。
- 诊断时 Xcode 再次对 Clone 2 报 xctrunner 启动失败与 `Invalid device state`，实际在 Clone 1 上的目标测试仍通过。因此不改产品源码，也不改既有测试。
- 结论：达到任务书最多 3 轮后停止，不再重跑或扩大到清理/重启模拟器。剩余工作仅为在模拟器恢复稳定后重新执行原始完整 UI 命令，确认 17/17；当前不能声称 Core/App/UI 全绿。

## 2026-08-29 Goal 第 3 回合阻塞审计

- 权威当前状态：所有可用 iOS 模拟器为 Shutdown，活跃 `xcodebuild`/XCTest 进程数为 0；不存在可重新连接或继续等待的验收会话。
- 第 3 轮完整结果包 `/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_20-13-37-+0800.xcresult` 已不存在；后续 5 个单项结果包占据了 `Logs/Test` 现存的 5 个保留位，判定为 Xcode DerivedData 结果轮换。本文档中的当时退出码、失败数和错误摘要仍保留，但不再声称该结果包可现场回读。
- `xcresulttool get test-results summary` 对现存 `22-07-45`、`22-08-36`、`22-10-42`、`22-11-51`、`22-13-00` 五个结果包均返回 `result: Passed`、`totalTestCount: 1`、`passedTests: 1`、`failedTests: 0`、`skippedTests: 0`。
- 同一阻塞已连续出现三个 Goal 回合：第 1 回合在第 3 轮完整 UI 失败后达到上限；第 2 回合证明 5 个失败项单独均绿，但完整 17/17 仍缺；本回合复核后条件未改变。
- 真实难点是任务书同时要求“完整 UI 全绿”和“最多 3 轮即停”。继续必须获得用户对第 4 次完整 UI 命令的明确授权，否则无法同时满足两条。

## 2026-08-29 阻塞已解除

- 用户已明确授权额外执行 1 次原始完整 UI 验收命令，因此上述“三轮上限”权限阻塞解除。
- 该额外命令退出码 0，结果包 `/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_23-27-44-+0800.xcresult` 当前可回读；摘要为 17 passed、0 failed、0 skipped。
- 随后 Core 为 53/53 通过，App 结果包 `/tmp/fangcun-p0-derived/Logs/Test/Test-InnerBalance-2026.08.29_23-31-48-+0800.xcresult` 为 124 passed、0 failed、0 skipped。
- 历史失败和流程偏差保留在本文件中，未删除或改写；当前无剩余阻塞项。
