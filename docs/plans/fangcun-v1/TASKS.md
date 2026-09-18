# 执行状态

本轮按 START_CODEX 完成 M0–M1；M2–M6 后续分阶段执行，M7 暂缓。

| 任务 | 状态 | 证据/下一步 |
|---|---|---|
| M0-01 | verified | BASELINE.md |
| M0-02 | verified | 64 Core + 27 App + 3 UI；SCREENSHOTS.md |
| M0-03 | implemented_unverified | CAPABILITIES.md；SDK/Widget build 通过，物理 Watch blocked |
| M1-01 | verified | 67 Core + 31 App；12 个原始数据输入情景 |
| M1-02 | verified | 时间分离、观察状态、legacy 保留及备份回归 |
| M1-03 | verified | 7 UI tests；原始 provider 输入至首页，真机已安装启动 |
| M2-01 | implemented_unverified | 标准化、选源、去重、HK anchored adapter 单测/编译通过；事务锚点联测在 M2-04 |
| M2-02 | in_progress | 主睡眠与同源基线 |
| M2-03 | not_started | ReadinessEngine / golden fixtures |
| M2-04 | not_started | 独立存储与事务恢复 |
| M3 | not_started | 版本化存储及手机完整闭环 |
| M4 | not_started | 腕上会话、反馈及幂等同步 |
| M5 | not_started | 活动提醒及 Widgets |
| M6 | not_started | 端到端验收、独立 Live Activity 验收 |
| M7 | not_started | 按规格明确暂缓 |
