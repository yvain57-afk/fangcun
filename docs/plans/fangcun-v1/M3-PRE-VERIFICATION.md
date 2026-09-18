# M3-PRE 验证（2026-09-19）

基线 b80f81c，初始工作区干净。Xcode 27 beta，使用既有 scheme/部署版本。一个 iPhone 连接可见，Watch 未连接；未据此宣称签名或真实查询已验收。

- App 最终全量 **170/170、退出 0**：[日志](evidence/m3-pre-app-final.txt)、[结果包摘要](evidence/m3-pre-app-final-summary.json)。含新增未开始无会话/无音频测试，原 3 项失败已修复。此前运行 169 通过，新增测试后完整重跑为 170。
- UI 最终 **6/6、退出 0**：[日志](evidence/m3-pre-ui-recheck.txt)、[结果包摘要](evidence/m3-pre-ui-recheck-summary.json)。旧练习两项走完最终行为，另 4 项为原改版交互与偏好。
- 第一次定位调整 **2/6、退出 65**：[失败日志](evidence/m3-pre-ui.txt)。容器标识覆盖开始按钮、系统确认弹层两层辅助功能包装导致失败；调整标识作用范围及稳定 ID firstMatch，未改变行为断言。混合运行中的 Swift Testing 单函数选择器没有匹配，日志为 0 tests；最终通过 App 全量补验，不将空选择器计为通过。

使用 `xcodebuild test`，project `InnerBalance/InnerBalance.xcodeproj`、scheme `InnerBalance`，模拟器和 DerivedData 沿用前轮。完整脱敏命令在日志首行。选项为 `-parallel-testing-enabled NO -test-timeouts-enabled YES -maximum-test-execution-time-allowance 90 -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO`。App 选择 `InnerBalanceTests`；UI 选择 `PracticeReturnHomeUITests` 与 `FangcunRedesignUITests`。两次最终运行正常结束，未被终止；`xcrun xcresulttool get test-results summary --path <bundle>` 实际读取成功，摘要去掉设备标识。

已查看模拟器合成截图：[浅色](screenshots/m3-pre/light.png)、[深色](screenshots/m3-pre/dark.png)、[大字](screenshots/m3-pre/large.png)、[保存返回](screenshots/m3-pre/practice-return.png)。前 3 张是既有 UI 情景注入，只作为视觉证据，不冒充 M3 服务链路。主动作可达、原画与风格保持。颜色和偏好依据见 [契约](M3-PRE-CONTRACT.md)。
