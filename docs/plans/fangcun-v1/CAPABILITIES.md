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
