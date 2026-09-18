# M2 远程审阅入口

本轮仅 M2-01 至 M2-04。分支 `codex/fangcun-v1-m0-m1`；基准 `905626c6e08dc7a36ddd4e219abf6945795ac62f`。原 M0/M1 审核补证提交 `0062d4a7c4830b81937013c279154271737dee18`。main 不合并。

读取顺序：

1. [TASKS](TASKS.md)、[VERIFICATION](VERIFICATION.md)、[CAPABILITIES](CAPABILITIES.md)
2. [原始任务书](FANGCUN_CODEX_SPEC_v1.0.md)、[原始 golden fixtures](READINESS_GOLDEN_FIXTURES.json)
3. [DECISIONS](DECISIONS.md)、[ADR-002](ADR-002-insights-store.md)
4. [Core Readiness 源码](../../../InnerBalanceCore/Sources/InnerBalanceCore/Readiness)、[Core 测试](../../../InnerBalanceCore/Tests/InnerBalanceCoreTests/Readiness)
5. [HealthKit adapter 与 service 工厂](../../../InnerBalance/InnerBalanceApp/Health/Readiness)、[真实 HK 对象测试](../../../InnerBalance/InnerBalanceTests/Features/ReadinessHealthKitProviderTests.swift)
6. [脱敏日志](evidence)

主链路：`ReadinessServices.make()` → `ReadinessHealthKitProvider` → `ReadinessPipeline.refresh()` → 标准化 / 选源 / 主睡眠 / 当前指标 / 基线 → `ReadinessEngine` → `InsightsStore.commit()`。所有时钟和日历可注入。Service 未接入 RootView，不改变现有 UI 或健康授权。

GPT 可直接通过此开发分支的 raw 地址读取文件，例如：

- [M2 任务状态 raw](https://raw.githubusercontent.com/yvain57-afk/fangcun/codex/fangcun-v1-m0-m1/docs/plans/fangcun-v1/TASKS.md)
- [M2 验证 raw](https://raw.githubusercontent.com/yvain57-afk/fangcun/codex/fangcun-v1-m0-m1/docs/plans/fangcun-v1/VERIFICATION.md)
- [ReadinessEngine raw](https://raw.githubusercontent.com/yvain57-afk/fangcun/codex/fangcun-v1-m0-m1/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/ReadinessEngine.swift)
- [InsightsStore raw](https://raw.githubusercontent.com/yvain57-afk/fangcun/codex/fangcun-v1-m0-m1/InnerBalanceCore/Sources/InnerBalanceCore/Readiness/InsightsStore.swift)

`ai/` 分卷和旧 FILE_INDEX 仍对应此前公开基线，本轮不将其当作 M2 源码副本。通过上述开发分支目录或 raw 路径审阅最新原文件。仓库仅纳入合成或已脱敏核验材料；真实健康数据、设备标识、签名、凭证和原始 xcresult 均不上传。
