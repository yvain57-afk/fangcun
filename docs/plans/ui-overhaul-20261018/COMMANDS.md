# 验证命令

在 `/Users/yvainair/Code/fangcun` 执行。以下保留实际参数；`$SIMULATOR_UUID` 表示本轮专用的 Fangcun UI Audit（iPhone 18 Pro，iOS 27.0）模拟器。签名身份及详细设备标识不写入交付文档。结果和完整本地日志位于 `.build/ui-overhaul-20261018/`。

```sh
cd InnerBalanceCore
swift test
```

```sh
xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UUID" \
  -derivedDataPath .build/ui-overhaul-20261018/Derived \
  -resultBundlePath .build/ui-overhaul-20261018/RegressionSerial.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:InnerBalanceTests \
  -only-testing:InnerBalanceUITests/PracticeVisualRepairUITests \
  -only-testing:InnerBalanceUITests/PracticeReturnHomeUITests \
  -only-testing:InnerBalanceUITests/FangcunAppearanceUITests \
  -only-testing:InnerBalanceUITests/DrinkEditorUITests \
  -only-testing:InnerBalanceUITests/HomeEvidencePipelineUITests CODE_SIGNING_ALLOWED=NO
```

随后 `FinalRegression.xcresult` 使用相同测试设置，测试选择为 App 全量、DrinkEditorUITests、PracticeVisualRepairUITests/testActualSessionShowsLargeBreathMovementAndStopsOnPause、OverhaulInteractionUITests。`LayoutFinal.xcresult` 复验最大字号以及 DrinkEditorUITests。结果对应 REVIEW.md，不将这些不同轮次混记为一次全绿运行。

```sh
xcodebuild build -project InnerBalance/InnerBalance.xcodeproj \
  -scheme 'InnerBalance Watch App' -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath .build/ui-overhaul-20261018/WatchDerived CODE_SIGNING_ALLOWED=NO

python3 scripts/ui-inventory/capture-ui.py --simulator "$SIMULATOR_UUID" --output .build/ui-overhaul-20261018/capture
python3 scripts/ui-inventory/record-motion.py --simulator "$SIMULATOR_UUID" --output .build/ui-overhaul-20261018/motion
```

Release 归档与导出使用工程既有 Apple Development 身份，`MARKETING_VERSION=1.0.0 CURRENT_PROJECT_VERSION=2026101906`，`archive` 然后 `-exportArchive`，导出 method 为 debugging。未使用 upload destination 或自动签名上传选项。完整归档命令与签名日志仅保留在本机 `.build/ui-overhaul-20261018/archive-delivery06.py` 及 `*.private.log` 中。

```sh
codesign --verify --deep --strict \
  .build/ui-overhaul-20261018/Fangcun-UI-Delivery06.xcarchive/Products/Applications/InnerBalance.app

git diff --check
```


最终独立 App 全量使用 `-only-testing:InnerBalanceTests`，结果 `AppFinal.xcresult`。补录命令使用同一 capture runner 的 `--only test09MenusDemonstrationAndNaturalCompletion --only test19AlternateGuideFitsAboveTransport`，以及单独的 `--only test08Appearance`。减少动态复验使用 `-only-testing:InnerBalanceUITests/OverhaulInteractionUITests/testReducedMotionKeepsInstructionsWithoutContinuousResizing`，结果 `ReducedMotion.xcresult`。

录像逐文件完整解码验证（输出丢弃，不改写原文件）：
```sh
ffmpeg -hide_banner -loglevel error -xerror -err_detect explode -i INPUT.mp4 -vf fps=30 -f null -
```
尺寸、时长和退出码见 `motion-validation.json`。截图和视频逐文件 SHA-256 见交付目录清单。
