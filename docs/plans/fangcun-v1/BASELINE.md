# M0 基线 — 2026-09-18

- 独立仓库：`/Users/yvainair/Code/fangcun`（实目录，无符号链接）。开始时 `main` 干净。
- HEAD：`905626c6e08dc7a36ddd4e219abf6945795ac62f`，与任务书固定版本一致。
- 工作分支：`codex/fangcun-v1-m0-m1`。旧 Developer 工作区的未提交内容保留，未复制覆盖。
- 入口：`RootView` → `FangcunTodayView`；健康数据 `HealthKitRepository` → `HomeViewModel` → `BodyLoadEngine`。
- Xcode 27.0 (27A5252f)，`DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer`。
- schemes：`InnerBalance`、`InnerBalance Watch App`、`InnerBalanceCore`；最低 iOS 18 / watchOS 11。
- 专用模拟器 Fangcun UI Review：iPhone 16 Pro / iOS 27，已启动。watchOS 26.5 模拟器可用。
- 物理 iPhone 16 Pro 当前可用；未发现可用物理 Apple Watch。公开仓库不记录设备标识、个人签名或健康数据。
- `DEVELOPMENT_TEAM` 在公开工程为空；模拟器不签名。真机仅通过本机命令覆盖签名配置。

## 行为修改前验证

- Core：64 tests / 13 suites passed。
- App：27 tests / 3 suites passed（HomeViewModelTests、FangcunDiaryTests、PracticeSessionViewModelTests）。
- UI：FangcunRedesignUITests 3 tests passed。三种首页、深色、大字、饮品复合增减撤销、历史、呼吸暂停/继续/退出/保存、设置及启用动效的呼吸均覆盖。
- 基线截图 11 张见 [SCREENSHOTS](SCREENSHOTS.md)。基线场景用最终状态注入，不能证明数据资格正确；M1 必须新增原始输入回归。
- 完整去主机信息日志在 [evidence](evidence/)，原 xcresult 保留在本机任务输出目录。

## 实际命令（本机路径/设备标识以变量表示）

```sh
swift test --package-path InnerBalanceCore
xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance \
  -configuration Debug -destination "platform=iOS Simulator,id=$IOS_SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" -resultBundlePath "$EVIDENCE/baseline.xcresult" \
  -parallel-testing-enabled NO -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 90 \
  -only-testing:InnerBalanceTests/HomeViewModelTests \
  -only-testing:InnerBalanceTests/FangcunDiaryTests \
  -only-testing:InnerBalanceTests/PracticeSessionViewModelTests \
  -only-testing:InnerBalanceUITests/FangcunRedesignUITests CODE_SIGNING_ALLOWED=NO
xcrun xcresulttool export attachments --path "$EVIDENCE/baseline.xcresult" --output-path "$EVIDENCE/baseline-attachments"
```
