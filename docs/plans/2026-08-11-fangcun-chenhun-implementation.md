# 方寸「晨昏纸境」实施计划

**目标：** 在保留现有健康数据与练习闭环的前提下，把 iPhone + Watch 的可见产品改为「方寸」，让首页先提供每日获得感，并撤掉系统合成语音。

**架构：** 每日内容选择逻辑放入 `InnerBalanceCore`，SwiftUI 负责自适应主题和叙事层级；现有 HealthKit repository、SwiftData 模型、同步标识与推荐引擎不改。行为变化严格按 RED–GREEN–REFACTOR 实施。

**方案：** 采用已批准的 A「晨昏纸境」。不推倒工程，不新增第三方依赖，不接入网络。

---

### Task 1：每日之言纯 Swift 核心

**文件：**
- 新建：`InnerBalanceCore/Sources/InnerBalanceCore/Reflection/DailyReflection.swift`
- 新建：`InnerBalanceCore/Tests/InnerBalanceCoreTests/DailyReflectionTests.swift`

**步骤：**
1. RED：添加“同一自然日结果稳定”的单个失败测试并运行。
2. GREEN：实现最小模型、主题和稳定选择器，使测试通过。
3. RED：逐个添加状态主题映射、跨日变化、通用降级与署名边界测试。
4. GREEN：逐个补齐本地句库和选择逻辑。
5. REFACTOR：消除选择器重复，保持全部 Core 测试通过。

**验证：** `swift test --package-path InnerBalanceCore`

### Task 2：首页新体验与晨昏主题

**文件：**
- 修改：`InnerBalance/InnerBalanceUITests/CheckInFlowUITests.swift`
- 修改：`InnerBalance/InnerBalanceApp/DesignSystem/InnerBalanceTheme.swift`
- 修改：`InnerBalance/InnerBalanceApp/Features/Home/HomeView.swift`
- 修改：`InnerBalance/InnerBalanceApp/Features/Home/BodyLoadCard.swift`

**步骤：**
1. RED：先添加首页必须出现“今日之言”“身体来信”“今日一事”的 UI 断言并运行，确认失败。
2. GREEN：加入自适应纸白/墨黑语义色和四段首页结构，使断言通过。
3. 保留基线 X/5、睡眠核对、证据来源/时间/可靠性与权限安全降级。
4. REFACTOR：提取小型 SwiftUI section，保证 44pt 点击区、Dynamic Type 与 VoiceOver 顺序。

**验证：** `xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:InnerBalanceUITests`

### Task 3：品牌、导航与产品语言

**文件：**
- 修改：`InnerBalance/InnerBalance.xcodeproj/project.pbxproj`
- 修改：`InnerBalance/InnerBalanceApp/App/RootView.swift`
- 修改：`InnerBalance/InnerBalanceApp/Features/Settings/SettingsView.swift`
- 修改：`InnerBalance/InnerBalanceApp/Features/CheckIn/OptionalContextSheet.swift`
- 修改：`InnerBalance/InnerBalanceApp/Resources/Localizable.xcstrings`
- 修改：`InnerBalance/InnerBalanceWatch/App/WatchRootView.swift`
- 修改：`InnerBalance/InnerBalanceWatch/Features/Practice/WatchPracticeView.swift`
- 修改：`InnerBalance/InnerBalanceWatch/Features/Sync/WatchSyncStatusView.swift`

**步骤：**
1. RED：更新 UI 测试，要求“今日 / 调节 / 我的”导航和“方寸”品牌，确认旧版失败。
2. GREEN：修改 iPhone/Watch 显示名、可见文案和导航标签，Bundle ID 与内部 target 名不变。
3. Watch 首页加入当天短句，但仍保留记录、调节、同步三个独立入口。
4. REFACTOR：检查所有用户可见“内衡”残留，只保留代码模块与兼容标识。

**验证：** `rg -n '内衡' InnerBalance/InnerBalanceApp InnerBalance/InnerBalanceWatch InnerBalance/InnerBalance.xcodeproj/project.pbxproj`

### Task 4：无语音调节体验

**文件：**
- 修改：`InnerBalance/InnerBalanceUITests/CheckInFlowUITests.swift`
- 修改：`InnerBalance/InnerBalanceApp/Features/Practice/PracticeLibraryView.swift`
- 修改：`InnerBalance/InnerBalanceApp/Features/Practice/PracticeSessionView.swift`
- 删除：`InnerBalance/InnerBalanceApp/Features/Practice/PracticeVoiceGuide.swift`
- 修改：`InnerBalance/InnerBalanceApp/Features/CheckIn/CheckInFlowView.swift`

**步骤：**
1. RED：添加进入真实练习后不存在“语音引导”、仍存在“触觉节奏”的 UI 测试，确认失败。
2. GREEN：删除语音状态、开关、播报、音频中断监听和音频会话代码。
3. 使用视觉提示、呼吸光晕和可关闭触觉维持节奏；Reduce Motion 时停止缩放动画。
4. 调节库、情绪登记和播放器移除强制深色并跟随晨昏主题。
5. REFACTOR：清除未使用的 AVFoundation 引用与失效清理路径。

**验证：** `rg -n 'PracticeVoiceGuide|AVSpeech|语音引导|AVAudioSession' InnerBalance/InnerBalanceApp`

### Task 5：回归、构建与真机前闸门

**文件：**
- 按测试失败最小修复上述文件；不修改 `iOSWatchApp`。

**步骤：**
1. 运行 Core 全套测试。
2. 运行 iPhone App 单元测试与 UI 测试。
3. 严格运行 Swift Format。
4. 构建 iPhone Debug/Release 与 Watch Debug/Release。
5. 在浅色、深色和大号 Dynamic Type 下采集首页截图做人工核对。
6. 独立代码审查，修复全部 Critical/Important 后重跑受影响验证。

**验证：**
- `swift test --package-path InnerBalanceCore`
- `swift format lint --recursive --strict InnerBalanceCore/Sources InnerBalanceCore/Tests InnerBalance/InnerBalanceApp InnerBalance/InnerBalanceWatch InnerBalance/InnerBalanceTests InnerBalance/InnerBalanceUITests`
- `xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- `xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`
- `xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' -configuration Release -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO`

