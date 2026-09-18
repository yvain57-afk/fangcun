# 执行状态

M0–M1 已补核验；按用户本轮边界仅推进 M2-01 至 M2-04。M2 数据链路完成后停止，M3–M6 不展开，M7 暂缓。

| 任务 | 状态 | 证据/下一步 |
|---|---|---|
| M0-01 | verified | BASELINE.md |
| M0-02 | verified | 64 Core + 27 App + 3 UI；SCREENSHOTS.md |
| M0-03 | implemented_unverified | CAPABILITIES.md；SDK/Widget build 通过，物理 Watch blocked |
| M1-01 | verified | 67 Core + 31 App；12 个原始数据输入情景 |
| M1-02 | verified | 时间分离、观察状态、legacy 保留及备份回归 |
| M1-03 | verified | 7 UI tests；原始 provider 输入至首页，真机已安装启动 |
| M2-01 | verified（合成数据链路） | 标准化、选源、去重、增量/删除与事务锚点联测通过；真实 HK 增量/后台仍 implemented_unverified |
| M2-02 | verified | ReadinessFeatureTests；78 Core 测试通过，原始合成输入 |
| M2-03 | verified | 86 Core；原文件 G01–G10 从原始样本重放 |
| M2-04 | verified（本机重放） | 独立存储、版本修订、事务恢复与并发保护；见 ADR-002 / VERIFICATION |
| M3 | not_started | 版本化存储及手机完整闭环 |
| M4 | not_started | 腕上会话、反馈及幂等同步 |
| M5 | not_started | 活动提醒及 Widgets |
| M6 | not_started | 端到端验收、独立 Live Activity 验收 |
| M7 | not_started | 按规格明确暂缓 |

注意：verified 表示所列范围的定向验证，不表示全仓库无失败。最终 Core 93、UI 8 通过；App 全量 163 中 3 个既有测试失败，在 M2 前提交独立复现，见 VERIFICATION。Watch/HealthKit 真机未验证能力不计入已通过。

## M2-R 补修

- R01：已重现并修复；历史及间接依赖删除回归通过，兼容旧评估。
仅本轮 M2-R，不进入 M3。
- R02：已重现并修复，分页失败/重启/预算续读及手动来源测试通过。
- R03：已重现并修复；语义变化串行补读、同语义共享、旧请求保护及跨上下文失败缓存隔离通过。
- R04：已重现并修复；移动截止时间不新增修订，新增证据仍可修订。
- R05：已重现并修复，6 项 App 回调/取消/合并补读测试通过；系统后台仍未真机验证。
