# V4 角色与视觉引导修正 · 2026-10-15

## 问题与修正

用户在真机上指出猫狗变形、呼吸训练缺少可辨认的视觉辅助。本轮以 `8e88d40fa43b8155360b7ec3fb2d59265b0cafc1` 为起点，在原 `codex/fangcun-v4-breathing-hub` 分支修正。

旧实现将独立生成的头、耳朵、爪、躯干按不同框比例拼接，导致颈部接缝、耳根分离和身体比例不一致。旧胸腹遮罩同时削弱了轮廓位移，屏幕上只剩非常细小的变化。不能凭用户的静态截图判定其系统动态设置，本轮没有改写用户偏好。

1. 使用内置 image_gen，以用户认可的原画为参照，生成六张完整透明原画：坐姿猫、闭眼猫、坐姿狗、枕爪狗、前爪搭下肋的侧卧狗、握旗小狗。拒绝带蓝色光晕的候选，不把不合格图带入产品。素材直接复制为 RGBA；没有程序重画动物，也没有把身体白色抠掉。
2. 用连续原画轮廓替代拼接身体。胸腹局部 shader 保留头、耳根和脚的支撑；新握旗原画中爪和旗相连，局部动作不作用于腹部。角色没有整图呼吸缩放。
3. 新增独立、明显的视觉引导圈：直径 174～274 pt，吸气展开、补吸仅追加最后 18%、呼气收拢，停留阶段大小保持。外弧表示当前阶段进度，底部显示阶段秒数与本轮顺序。全都读取现有 PracticeTimeline，未新增独立训练时钟。
4. 交替鼻孔显示“你的左侧／你的右侧”，顺序保持左、右、右、左。凯格尔用向内轻收、向外舒展的辅助箭头和握旗动作，腹部不随收缩鼓起。膈肌只做明确标注的动作示范，保留自然呼吸、无强制吸呼秒拍。
5. 动作示范页也使用同一视觉引导。暂停停止推进；静态、减少动态和低电量模式保留阶段姿势、文字、阶段秒数。所有原有偏好保持不变。
6. 修正膈肌示范标签和角色被分别施加最小高度、把角色推到屏幕外的问题。将其收在同一个 VStack；测试检查角色完整位于控制按钮上方。阶段标题改成立即切换，避免交叠的两条指令。

## 修改范围

- `DesignSystem/PracticeCompanionV4.swift`、`FangcunCompanion.metal`：完整原画舞台和局部动作。
- 新增 `PracticeVisualMotion.swift`、`PracticeVisualGuide.swift`：相位驱动、引导圈、收放辅助和阶段信息。
- `Features/Practice/BreathingFieldPlayer.swift`、`PracticeNonBreathingStages.swift`、`PracticeActiveStage.swift`、`PracticeLibraryView.swift`：训练与示范接入、膈肌布局、标题切换。
- `PracticePresentation.swift`、`PracticeSessionScreens.swift`：膈肌示范连续刷新，仍使用原 ViewModel 时间源。
- 六组 `Assets.xcassets/PracticeV4R-*.imageset`，清单见 ASSETS.json；提示词和候选取舍见 GENERATION.json。
- 新增 `PracticeVisualMotionTests.swift`、`PracticeVisualRepairUITests.swift`。

健康评分、golden fixtures、练习参数、音频资源、用户记录存储、权限和数据迁移均未改动。没有清库，也没有加入网络能力。

## 实际验证

| 检查 | 结果 |
|---|---|
| Core 全量 | 167 通过，0 失败 |
| App 全量 | 220 通过，0 失败；包括 4 项新增相位回归 |
| 九种练习、均衡 4/4 和 5/5 连续原生运行与保存 | 通过，使用真实计时，含两轮吸呼和三轮凯格尔 |
| 深色、最大字号、静态、减少动态 | 原生流程通过，并保留截图 |
| 冥想、NSDR 真实语音段落时间线及暂停恢复 | 最终复验通过 |
| 新增实际尺寸变化与暂停测试 | 最终通过：真实引导圈尺寸差大于 75 pt，暂停前后尺寸差不超过 0.5 pt |
| 最终握旗狗、枕爪狗真实轮次 | 通过，保留最终录像和截图 |
| 膈肌角色和说明完整可见 | 最终通过，角色在暂停按钮上方，说明可见 |
| 本地签名归档、导出 | `1.0.0 (2026101504)`；本地开发签名，不上传 TestFlight |

UI 共 6 个不同测试用例取得通过结果；分批运行，共 7 次通过执行。第一次视觉测试最后一个辅助功能断言失败：父容器没有独立暴露阶段秒数。增加 children: .contain 后原断言复验通过，没有删除或放宽断言。先前的“圈幅度”和“暂停冻结”断言在失败批次已经通过。

首次归档缺少 DEVELOPMENT_TEAM 命令参数，失败；从现有已签名包读取团队配置后正常归档，没有新增签名账号或申请权限。按用户“暂停”指令中断过一次布局复验；该中断不计通过，恢复后使用独立结果包正常完成。

人工复核还发现了膈肌标签占高问题，修复并补充可见性回归。中间版 2026101503 曾覆盖安装；最终 2026101504 已覆盖安装；设备回读版本为 1.0.0（2026101504），正常启动并确认同一进程在运行。脱敏回执见交付 DEVICE_INSTALL_RECEIPT.json。

## 可复现命令

以下 `$SIM` 使用现有测试模拟器，结果包目录须使用新名字。原始命令和结果保存在项目忽略目录 `.build/v4-visual-repair/`，不包含在公开材料中。

```sh
swift test --package-path InnerBalanceCore

xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath .build/v4-final-unit \
  -resultBundlePath .build/v4-visual-repair/final-unit.xcresult \
  -parallel-testing-enabled NO -only-testing:InnerBalanceTests CODE_SIGNING_ALLOWED=NO

xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath .build/v4-derived \
  -resultBundlePath .build/v4-visual-repair/visual-ui.xcresult \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 1200 -collect-test-diagnostics never \
  -only-testing:InnerBalanceUITests/PracticeVisualRepairUITests \
  -only-testing:InnerBalanceUITests/PracticeV4CaptureUITests/testCaptureNinePracticeScenes \
  -only-testing:InnerBalanceUITests/PracticeV4CaptureUITests/testCaptureDarkLargeTypeAndStaticModes CODE_SIGNING_ALLOWED=NO
```

最终针对性复验沿用上述 xcodebuild test 参数：

- `final-ui.xcresult`：`PracticeVisualRepairUITests`（当时含吸呼尺寸／暂停与握旗／枕爪两个测试）及 `PracticeV4CaptureUITests/testCaptureGuidedScenesAndPauseResume`，3 通过。
- `layout-resumed.xcresult`：`PracticeVisualRepairUITests/testNaturalBreathingArtworkStaysVisibleWithItsExplanation` 及 `testActualSessionShowsLargeBreathMovementAndStopsOnPause`，2 通过；超时上限 240 秒。使用相同真实应用入口，未注入最终展示状态。
- `xcresulttool get test-results summary` 读取上述结果包确认结果。
- 归档：`xcodebuild archive ... -destination generic/platform=iOS -archivePath .build/v4-visual-repair/Fangcun-V4-1504.xcarchive CURRENT_PROJECT_VERSION=2026101504 DEVELOPMENT_TEAM=<现有配置> CODE_SIGN_STYLE=Automatic`；随后 `xcodebuild -exportArchive`，沿用既有私有导出配置。
- `codesign --verify --deep --strict` 校验应用。手机安装使用 `devicectl device install app`，不卸载；随后 `info apps`、`process launch`、`info processes` 分别核对版本、启动和进程。

## 交付与待验收

交付目录：`/Users/yvainair/Downloads/Codex交付/方寸-V4-角色与呼吸引导修正-2026-10-15`。包括六张角色原画、原生截图、连续录屏、预览页面、签名 IPA 和安装回执。录像来自真实运行的 iOS 模拟器，保持正常速度；模拟器录屏无声音，没有伪造音轨。最终布局与握旗录像替换了对应中间证据，其余未受影响场景复用已验证录像。

真实手机的主观可爱程度、动画舒适度、用户记录界面核对、锁屏音频及真实 HealthKit／Watch 仍不能由模拟器证据代替。Watch 代码未改，本轮没有重新做 Watch 真机验收。未推送远端、未合并 main、未上传 TestFlight 或 App Store；用户提供的健康截图和设备标识未写入项目。
