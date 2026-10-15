# V4 实际验证记录

执行日期：2026-10-15（Asia/Shanghai）。项目基准 `772644826638a420e79450716ab869cf87472d09`，当前开发分支 `codex/fangcun-v4-breathing-hub`。Xcode 27 SDK；iPhone 16 / iOS 27 模拟器用于 UI，Core 使用宿主 Swift。模拟器标识、签名资料及原始完整日志只留本地 gitignored `.build/`。下述命令中的 `$SIM` 指对应已创建模拟器；命令结构与真实运行一致，省略设备 ID 是脱敏，不代表换了测试环境。

## 测试结果

| 验证 | 实际结果 | 证据 |
|---|---|---|
| Core 完整回归 | exit 0；167 tests / 33 suites 全过 | `evidence/core-session-review-tests.log`（本地原始日志），Core 源测试可复跑 |
| 最终 App 单元测试 | exit 0；216 tests / 33 suites 全过 | `evidence/final-app.json`；`.build/v4-verification/final-app.xcresult` |
| V3 参考规则 | exit 0；14 tests 全过；24 组固定样例不变 | `.build/v4-verification/` 本地日志；`evidence/preserved-baseline-files.json` |
| 完整普通 UI + App | exit 65；275 项中 273 通过、2 失败；其中普通 UI 60 项中 58 通过，后续两项专项分别登记 | `.build/v4-verification/full-regression.xcresult` |
| 九种方法实际开始/暂停/恢复/结束/保存 | 普通 UI `testAllNineMethodsStartPauseAndSaveWithoutHealth` 通过，真实 UI 路径而非注入最终展示状态 | 完整普通 UI 结果包 |
| 角色第四轮表情补录 | exit 0；1 test 通过，生理性叹息与凯格尔原速超过第四轮 | `evidence/expression-capture.json`；`.build/v4-verification/expression-capture.xcresult` |
| 深浅色/最大字号/static/减少动态录屏 | 1 test 通过，四种模式实际运行 | `testCaptureDarkLargeTypeAndStaticModes`，同下结果包 |
| 第一轮长录屏 | exit 65；2 tests 中 1 通过、1 超时，非全部通过 | `evidence/native-capture-initial-limit.json`；`.build/v4-verification/native-capture-final.xcresult` |
| 冥想/NSDR/暂停继续补录与坐标专项 | exit 0；2/2 通过，保留 ±2 pt 坐标断言 | `.build/v4-verification/guided-final-capture.xcresult` |
| 最终轻行动和日常导航专项 | exit 0；2/2 通过，原记录/反馈/推荐断言及第二次进入关闭路径均通过 | `evidence/recovery-final.json`；`.build/v4-verification/recovery-final.xcresult` |
| Watch 模拟器 | exit 0；BUILD SUCCEEDED | `.build/v4-verification/watch-build.log` |
| Release archive / development export | exit 0 / 0；签名完整性 exit 0 | `.build/v4-release/archive-delivery2.log`、`export-delivery2.log`；`evidence/build-public-receipt.json` |
| 资源完整性 | 74 个当前训练必需音频全部存在，时间窗和响度检查通过；40 个角色图层有来源/hash | `AUDIO_ASSETS.json`、`ASSET_MANIFEST.json`、`evidence/audio/` |
| 原数据与参数保护 | 25 个基准文件逐字节相同；未清库；无 entitlements 扩权 | `evidence/preserved-baseline-files.json` |

## 可复现命令

```sh
swift test --package-path InnerBalanceCore --scratch-path /tmp/fangcun-v4-core-session-build
python3 -m unittest discover -s docs/plans/fangcun-score-v3 -p test_reference_score_v3.py
python3 docs/plans/fangcun-breathing-v4/validate_spec.py
```

附件 validator 只验证附件结构/配置，不把它当 App 验收。下面输出目录应选不存在的新名称，避免覆盖既有结果。

```sh
xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath .build/v4-final-unit \
  -resultBundlePath .build/v4-verification/final-app.xcresult \
  -parallel-testing-enabled NO -only-testing:InnerBalanceTests CODE_SIGNING_ALLOWED=NO

xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath .build/v4-derived \
  -resultBundlePath .build/v4-verification/full-regression.xcresult \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 600 -collect-test-diagnostics never \
  -skip-testing:InnerBalanceUITests/PracticeV4CaptureUITests CODE_SIGNING_ALLOWED=NO

xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath .build/v4-final-unit \
  -resultBundlePath .build/v4-verification/guided-final-capture.xcresult \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 1200 -collect-test-diagnostics never \
  -only-testing:InnerBalanceUITests/PracticeV4CaptureUITests/testCaptureGuidedScenesAndPauseResume \
  -only-testing:InnerBalanceUITests/FangcunResponseLoopUITests/testActionChooserKeepsScorePositionStable \
  CODE_SIGNING_ALLOWED=NO

xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' \
  -destination 'generic/platform=watchOS Simulator' -derivedDataPath .build/v4-watch \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO
```

录屏使用 `xcrun simctl io "$SIM" recordVideo --codec=h264 …` 与 XCTest 同时执行。原始视频、时间标记和测试结果包保留 `.build/v4-verification/`；交付裁切视频不变速、不加假音频。最初长录屏使用 `test-without-building` / `.build/v4-capture-final`，最后一项因 600 秒上限中止；修复后原测试明确 1200 秒上限，缺失自然引导另作独立补录，不重跑未受影响的整套媒体。

签名归档运行 `xcodebuild archive … -destination generic/platform=iOS -archivePath .build/v4-release/Fangcun-V4-Delivery2.xcarchive CURRENT_PROJECT_VERSION=2026101502`，随后 `xcodebuild -exportArchive …`，使用已有自动开发签名，无 `-allowProvisioningUpdates`，未上传外部。私有 ExportOptions 不入库。签名复核 `codesign --verify --deep --strict …/InnerBalance.app`。

## 失败、原因与修复

- 首次 App + V4 UI：220 项，217 通过、3 失败，exit 65；证据 `evidence/initial-regression.json`。一项测试固定数组时钟被新增读取耗尽，改显式推进时钟并加强真实时长断言；凯格尔旧摘要断言按 V4 摘要迁移，4/8 与不屏息断言保留；保存失败后 UI 同一行三段文字共享标识造成计数 3，产品行合并 accessibility children，保留“仅一条记录”断言。最终 App 216 项与 V4 六项均已覆盖修复。
- 普通 UI 中轻行动坐标：测试在滚动前采样、滚动后比较，差值是滚动距离。修为滚到入口后采样，保留 ±2 pt 门槛与主行动可达断言；专项复验独立登记。未降低对比度或删除断言。
- 媒体单测试超过十分钟：XCTest allowance 600 秒导致强制超时，发生在冥想 t28 后。前七种方法（含均衡两档）和四种外观的有效截图/录像保留。冥想、NSDR 与暂停恢复在最终代码独立补录。不是产品崩溃，也不写成整次通过。
- 早期角色采集在发现坐姿过渡/垫子细节后主动取消（exit 75），后续最终媒体取代；早期 archive/export 候选亦被 Delivery 版本取代。手动签名导出初次失败因为现有 profile 为 Xcode managed，改使用现有自动签名导出成功，没有新增授权。
- UI 系统输出 QoS、未配对 Watch 等运行警告单独保留，不当作功能通过或断言失败。原始日志可读取，未删除失败结果。

## 验收项对应与边界

- H01–H06：六项 V4 UI 与原生首页、九种方法录像；H03 实际测试使用无健康合成环境，离线资源随包，无 App 语音网络调用；真实系统拒绝权限的界面待真机。
- H07–H08：既有饮品、历史、设置、恢复、通知/会话路由等测试迁移到日常，具体入口见 UI_MIGRATION；OS 推送真实投递不由模拟器测试证明。
- T01–T11、D01–D08：逐项测试名称和代码路径见 DATA_AND_TIMELINE_VERIFICATION。216 项最终 App 中精确结束测试覆盖 19 方法/时长/档位组合 × 准时/迟到两路，共 38 路径；真实 20 分钟连续播放仍未测试。
- M01–M06：40 图层、9 场景真实原速录像；检查角色支点、补吸、停留、侧别和分段焦点。第四轮表情修复只在吸气起点允许眨眼；最终凯格尔素材以 expression 录像为准。目视抽查未发现重复肢体/明显裂缝；不等于所有硬件帧率和光栅化行为都已穷尽。
- M07–M09：保存失败/重试 UI、实际暂停恢复/提前结束录像、四种外观采集；标准/温和/静态与离屏调度有代码与展示测试，低电量能耗未真机实测。
- A01–A07：详见 AUDIO_DEVICE_ACCEPTANCE。完整脚本、窗口、音频峰值/响度、资源可用性有证据；新旧声线主观一致性、≤100ms 对齐、20 分钟锁屏、电话/耳机中断和安静结束的实际设备结果均为 `implemented_unverified`。
- D01 真机旧库与覆盖安装、D06 真实权限、D07 实际 Watch 配对由用户推迟；无健康资料上传，无 main 合并、远程推送或 TestFlight/App Store 发布。

## 最终运行收据

- 完整回归：12:44:10–13:17:45，exit 65；275 个测试名称 273 通过、2 失败。参数化展开为 330 次执行/328 通过，不混用为测试项数。普通 UI 60 个名称中 58 个通过；App 此次 215 个通过（新增终点测试后的最终 App 专项为 216/216）。见 [full-regression.json](evidence/full-regression.json)。
- 最终自然引导补录与坐标专项：exit 0、2/2。见 [guided-final.json](evidence/guided-final.json)，可读 `.build/v4-verification/guided-final-capture.xcresult`。
- 已整理 100 张原生截图、11 段原速 H.264 录像，所有视频 ffprobe 可读、没有音频流。来源和 SHA-256 在交付目录 `reports/MEDIA_RECEIPT.json`；截图包含合成记录，不含用户健康截图。

### 轻行动返回设置：原实现反证

完整 UI 的第二项失败来自本轮新增测试 helper 的 `isHittable` 判据。相同 `scoreSleep375` 场景中，按钮进入轻行动前查询为 true，结束后为 false，但原生 hitTest 的命中视图、祖先、尺寸和交互标志前后一致，主行动及记录仍可点。工具栏位置、全屏呈现层、点击形状等诊断候选均未解决查询差异，已全部撤回，未保留猜测性产品修改。

在原产品实现上直接调用标准 `app.buttons["daily.settings"].tap()`（非坐标点击）后，设置页真实出现；原完整流程、编辑“不舒服”、推荐变化，以及第二次进入准备页关闭后再打开设置均通过。`recovery-native-button-tap.xcresult` 正常退出 0、1/1，详见 [recovery-native-button-tap.json](evidence/recovery-native-button-tap.json)。这是 iOS 27 模拟器 AX 可点击查询的假阴性反证，不能据此宣称产品本来存在触摸遮挡。

最终 helper 改为有界滚动使控件 frame 位于可视范围，再使用标准 Button.tap 并严格断言设置页目标；原记录数量、反馈、推荐及关闭行为断言保留。没有坐标注入、删除旧行为断言或降低颜色/字号标准。其余诊断失败结果 `recovery-diagnostic`、`recovery-targeted`、`recovery-presentation-scope`、`recovery-hit-baseline`、`recovery-hit-timeline`、`recovery-hit-shape`、`recovery-navbar-owner`、`recovery-root-presentation`、`recovery-native-hittest`、`recovery-native-hittest-file` 均保留本地 `.build/v4-verification/`；这些 exit 65 的原判据失败不改写为通过。临时 App hitTest 采样代码已移除。

清理诊断后的 `recovery-final.xcresult` 正常退出 0，两个测试均通过（83.151 秒）：`RecoveryActionUITests/testLocalActionPauseEarlyEndSkipThenEditFeedback`、`FangcunRedesignUITests/testNativeTodayDrinksTrendsPracticeAndSettings`。结果包结束于 13:42:18，能由 xcresulttool 读取。使用与上文相同 xcodebuild test 参数、`.build/v4-derived`，分别通过两个 `-only-testing:` 选择器执行，结果目录为 `.build/v4-verification/recovery-final.xcresult`。见 [recovery-final.json](evidence/recovery-final.json)。

因此，普通 UI 60 项已有 58 项整版通过证据，另外两项原失败分别有最终专项通过证据；未受修改影响的通过项不重复执行。没有遗留的已知测试失败待修，但不能把第一次全套命令写成 60/60 一次通过。最终生产源码没有上述诊断候选或临时采样；签名包重新归档为 Delivery2，保证交付与最终生产源码一致。

提交前校验：74 个必需音频与最终归档逐文件 hash 匹配，25 个保护文件与基准一致，签名检查 exit 0；没有暂存 IPA、profile、私钥、ExportOptions 或结果包。`git diff --cached --check` 仅报告原附件 `完整规划_合订本.md` 自带的 EOF 空行（已与原 zip 逐字节核对，故保留原文）；排除这一原始附件后检查 exit 0，生产脚本的尾随空格已清理。
