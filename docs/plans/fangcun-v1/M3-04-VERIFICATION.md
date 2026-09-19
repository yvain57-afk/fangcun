# M3-04 跨端记录与摘要基础

## 实现

Core `SyncModels / SyncStore / SyncService / WatchConnectivityTransport / SummaryCache`；手机 `PhoneSyncCoordinator`；Watch `WatchSyncLifecycle`。仅最小生命周期与接收持久化，未改 Watch 首页、计时器、后台模式或增加 Widgets。

- schema v1 packet/event/summary；稳定 eventID/entityID、安装 epoch、实体 revision、tombstone、显式撤销恢复。
- 本地事件与实体一起原子落盘后进入 outbox；接收端在同一事务保存实体、去重表、receipt，投影成功才 ACK。ACK 校验原始事件摘要，源端收到后才释放。
- updateApplicationContext 只发布手机权威的最新摘要；事件走 sendMessageData 加速/transferUserInfo 回退。系统安排传输不代表业务收到。出队以应用 ACK 为准。
- 失败保留队列；持久化有界退避（最多8次自动机会，每次最多20条），由激活/可达变化/业务操作触发，另有手动重试；没有保活轮询。
- 重复、乱序、较低修订不能覆盖新事实。删除阻断旧事件；用户明确撤销删除以更高 revision 和 explicitRestore 表示，与网络重放区分。
- 新安装握手退役旧 peer epoch、撤销旧接收摘要；旧 epoch 重放被拒绝。未知协议原字节进入隔离区，未 ACK，源 outbox 保留。
- 反馈备注仅本机；DTO 去除当前与历次 localNote。摘要小于4KB，不含原始体征、来源、健康 UUID 或个人文字。

## 业务接线与健康写入归属

- iPhone 原 SwiftData 与新本地行动仍是各自保存入口；SyncStore 持久化事件事实，Diary/RecoveryStore 为可重试投影。接收路径没有 HealthKit 写入调用。
- 手机用既有 mindful read 权限读取本 App 已有稳定 sessionID 的会话，按同一 ID 与 WC 合并；先 HealthKit 后 WC、重复 WC、删除后再读 HealthKit均有测试。缺失计划时长标 unknown，结束原因 legacyUnknown，不猜测反馈。
- Watch 完成本地保存后排队，不替代其原 HealthKit 写入链路。旧 Watch 表新增两个可选字段保留已知开始与计划时长；老记录仍可解码、未知明确标记。不改原运行时钟。
- Diary v2 新增默认空的 syncRevisions；Recovery v1 新增可选同步修订和 tombstone。原字节不清除；存储损坏报错保留，旧归档无新字段的兼容与损坏字节保留有回归。
- 停止读取/清除/选源/目标变化撤销外部摘要；收到过期摘要读取为 neutral，不沿用旧等级。

## 验证

- Core `SyncReliabilityTests` 4项：离线重启/丢ACK/重复/投影重试；写失败不ACK/删除先到/乱序/显式撤销；epoch/未知协议/损坏/过期/未配置共享容器；摘要写失败仍发送撤销。
- App `PhoneSyncIntegrationTests` 2项：实际 diary/recovery store 投影、未知酒精/录入时间保持nil、HK与WC稳定ID合并、停止后摘要撤销、删除防复活、撤销编辑使用新的传输revision。
- M3-04 targeted App 9项通过（含既有迁移及行动回归）。Core全量与App全量、完整UI及Watch结果汇总在 M3-REVIEW。

## 尚未验证

- 真实 Watch 配对送达、锁屏后台与平台传输调度：implemented_unverified，当前物理 Watch 不可用。模拟 ACK 不等于真实送达。
- 工程未配置真实 App Group；factory只读取已有 `FangcunAppGroupIdentifier` 并解析系统容器，不使用假组名。不配置时共享缓存 unavailable，本机缓存可用；正式共享/签名与 Widget验收留待实际条件和M5。
- M0/M2未验证的能力保持原级别，未因本阶段编译成功升级。

阶段全量：Core `m3-core-delivery` 112/112；App `m3-app-final` 185/185；Watch `m3-watch-final` BUILD SUCCEEDED。初次扩大UI为26/45，19项旧约定失败保留，固定基准复现与当前可达入口复验结果见最终 M3-REVIEW。Release签名构建/校验已通过；物理iPhone不可达，不能宣称安装或健康读取通过。
