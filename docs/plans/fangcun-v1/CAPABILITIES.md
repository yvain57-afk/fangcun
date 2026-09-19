# M0 平台能力矩阵

| 能力 | 本次实验 | 已确认 | 未验证/阶段 |
|---|---|---|---|
| 扩展运行 | Watch SDK 以 watchOS 11 最低版本、Swift 6 typecheck `WKExtendedRuntimeSession` 及 delegate | 符号与签名通过 | 物理 Watch 未连接；未验证腕下、切 App、资源失效、触感。M4 前必须实测，不能声称后台持续运行 |
| Widget target | 独立 `WidgetProbe` app-extension，iOS 18，XcodeGen + xcodebuild | `.appex` 编译成功，主屏/锁屏 families 可编译 | 未嵌入方寸、未装真机、无共享存储；M5 实施 |
| 通知动作 | iOS/watchOS SDK 分别 typecheck category + foreground action | 符号可编译 | 未申请授权、未安排通知、未触发系统 action；M5 验证 |
| WatchConnectivity | iOS/watchOS typecheck context、userInfo、reachable message，含 activation/reachability guard | 三种传输 API 可编译 | 未跨物理设备发送/接收；送达、去重、恢复待 M4，不把可编译说成可靠同步 |
| iPhone | devicectl 当前发现已配对设备 | 安装条件存在 | M1 产物仍须单独安装回执 |

## 可重放实验

`probes/` 是独立实验，不属于正式 App target，不改变权限、后台配置或发送数据。复制到本机 scratch 后运行：

```sh
xcodegen generate --spec "$PROBES/project.yml"
xcodebuild build -project "$PROBES/FangcunCapabilityProbe.xcodeproj" -scheme WidgetProbe \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$PROBE_DERIVED_DATA" CODE_SIGNING_ALLOWED=NO
xcrun swiftc -typecheck -swift-version 6 -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -target arm64-apple-ios18.0-simulator "$PROBES/PlatformProbe.swift"
xcrun swiftc -typecheck -swift-version 6 -sdk "$(xcrun --sdk watchsimulator --show-sdk-path)" \
  -target arm64-apple-watchos11.0-simulator "$PROBES/PlatformProbe.swift"
```

## 文档和当前配置边界

核对本机 WatchKit 头文件及 [Apple extended runtime 文档](https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions)（2026-09-18 读取官方 Markdown）。正念扩展会话属于 frontmost；必须在 active 时启动，需相应后台模式，可能因系统/资源限制失效。不能据此保证离开 App 后持续运行。当前正式 Watch 仅有既有 workout-processing，M0 不擅自开启 mindfulness。

SDK 成功记录见 `evidence/*probe.txt`。物理 Watch 实验保持 `blocked`；不阻止 M1 数据修正。

## M2 前逐项状态复核

| 实验 | 状态 | 证据层级与仍缺条件 |
|---|---|---|
| 扩展运行 API 小实验 | implemented_unverified | Watch SDK typecheck passed；需要真实 Watch、mindfulness 配置后验证腕下/退出/失效/触感。此运行验证 blocked |
| Widget target 小实验 | implemented_unverified | 独立 WidgetProbe appex build passed；需 M5 嵌入、签名安装及系统 family/刷新测试 |
| 通知动作小实验 | implemented_unverified | iOS/watchOS category/action typecheck passed；需 M5 授权、系统投递与动作回调测试 |
| WC 传输小实验 | implemented_unverified | 三种传输 API typecheck passed；需配对物理 Watch，覆盖断连、送达、重复、乱序及 ACK。跨设备验证 blocked |
| iPhone M1 安装/启动 | verified | device-receipt.json；仅证明安装、启动和版本回读，不推导 Watch 行为 |

上述未验证项不阻塞纯数据与本机持久化的 M2。

## M2 能力与验证层级

| 能力 | 当前状态 | 已核验 / 未核验 |
|---|---|---|
| 领域标准化、稳定选源、主睡眠、基线、ReadinessEngine | verified | 合成原始样本、原 G01–G10 和边界重放；不代表医学效度 |
| HealthKit anchored / observer adapter | implemented_unverified | 真正 HK 对象换算、SDK 编译通过；真实授权后的增量、删除、锁屏回读和 observer 到达时机尚待真机 |
| 本机 Insights store / pipeline | verified（本机文件与合成提供层） | 原子发布、删除屏障、修订、损坏恢复、并发旧请求保护；实际断电及锁屏文件保护未真机验证 |
| 手机首页消费新准备度 | not_started | 按本轮停止点保留 M1 页面；M3 才接入生命周期与 UI |
| Watch 后台 / 触感 / 跨设备 ACK | blocked | 缺少可用于配对实验的物理 Watch；既有 API 实验只算 implemented_unverified |
| Widget / 系统通知运行 | implemented_unverified | 保留 M0 探针状态；M5 尚未开始 |

工程默认阈值未校准；不宣称医学标准或产品健康判断效度。本轮不新增授权类型、后台模式、遥测或后端。

## M2-R1 补修能力

- 新增删除依赖、分页状态、语义单飞、稳定修订：合成提供层与本机文件回归通过，不代表健康模型已经校准。
- Observer 顺序：共用实际 callback owner 的 6 项模拟器测试通过，含取消/错误/合并事件和存储；SDK 编译层面可用。
- Observer 真实 HealthKit 后台送达、系统终止、锁屏/低电量时机仍 `implemented_unverified`，没有新增 background delivery 授权。物理 Watch 后台/同步仍 `blocked`，缺少可用配对验证条件。
- 最终 Core 103、App 新增 observer 6、原首页/交互 UI 8 项通过；Watch 模拟器再次 BUILD SUCCEEDED。App 全量保留 3 项既有失败；额外两项旧练习 UI 定位失败已在审阅基准重现。具体结果与运行器诊断收集限制见 [M2-R1-RESULTS](M2-R1-RESULTS.md)，不扩大上述能力层级。

## M3-02 接入状态
- 手机准备度 service→store→owner→现行首页/详情/历史：合成数据及模拟器集成已验证；实际 HealthKit 授权读取与锁屏后台仍 implemented_unverified。
- 不新增健康权限类型、App Group、后台模式；模型阈值仍待校准。

## M3-03 / M3-04
- 本地轻行动、可选反馈、迁移与核心同步协议：合成Core/App/模拟器UI已验证，不代表内容安全已完成人工发布审查。
- WatchConnectivity生产适配：iOS/watchOS编译通过，持久化与可控transport通过；真实跨设备送达 implemented_unverified，物理Watch不可用。
- App Group共享：blocked（工程无可用组配置）；未配置/损坏/过期中性回退已测。正式Widget未开始。
- 签名Release构建通过；早期可达条目为simulated。交付末尾物理iPhone经本地网络恢复可达，reality=physical复核、覆盖安装/启动/版本回读、真实首次前台查询与评估落盘通过；旧记录/偏好保留在本机核验。授权弹窗重走、来源/目标UI、锁屏/后台/真实增删仍未验收。设备检查不得仅按deviceType推断真机。
