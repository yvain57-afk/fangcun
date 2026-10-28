# 方寸：给 GPT / AI 的项目入口

> 当前工作分支 `codex/little-exhale-2` 正在交付 **Little Exhale 2.0.0（2026102801）**：英文优先的呼吸与放松产品，沿用方寸原 App 身份、本地数据及所有训练参数。首页为 Breathe，日常记录与可选身体线索在 Daily；分数模型保留，首页不放大分数。最新事实以 [2.0 验证](docs/releases/little-exhale-2/VERIFICATION.md)、[发布状态](docs/releases/little-exhale-2/release-state.json) 和 [范围契约](docs/plans/LITTLE-EXHALE-2.md) 为准。当前已生成并验证开发签名归档；Xcode 缺少开发者账号和分发证书，尚未上传 TestFlight 或提交本次审核。

仓库：<https://github.com/yvain57-afk/fangcun>

本文 raw 地址：<https://raw.githubusercontent.com/yvain57-afk/fangcun/codex/little-exhale-2/AI_CONTEXT.md>

## 阅读顺序

1. [README](README.md)：产品、运行方式、当前目录。
2. [当前验证与安装状态](docs/verification/STATUS.md)：区分源码、测试、真机安装和商店发布。
3. [设计决策](docs/CURRENT_DESIGN.md)：已确认方向与历史版本优先级。
4. [原始完整设计规格](web/docs/用户提供的完整设计规格.md)：设计目标；不是完成声明。
5. [架构与数据流](docs/ARCHITECTURE.md)：原生真实数据和网页 Mock 的边界。
6. 下列索引与源码分卷是此前快照，尚未包含本轮所有文件；当前改版优先直接读取本分支源码及 `docs/content/little-exhale-2/`。

[所有文件索引](FILE_INDEX.md)：每个源文件及图片的可点击链接。
7. [分卷源码](ai/README.md)：原生代码、Core、网页与设计文字的纯文本分卷，适合无法递归遍历仓库的阅读工具。

所有文件均可通过 `https://raw.githubusercontent.com/yvain57-afk/fangcun/codex/little-exhale-2/<文件路径>` 读取。中文和空格路径需要 URL 编码。分卷文件使用 ASCII 文件名；文件索引同时提供原文件和 raw 链接。

## 目标与明确偏好

Little Exhale 为海外英语用户提供日常可用的短暂呼吸和放松空间。英文内容按真实使用情景重写；不强迫先选心情，不以打卡压力驱动使用。身体线索是可选补充，缺数据时不能伪造结论。

界面轻松、安静、有趣；猫狗是情境陪伴。角色的原画、耳朵、花纹、五官和身形不能被随意重画；允许局部动作，脚底固定，避免全身夸张缩放与持续摇晃。猫狗需要独处场景，不必每次一起出现。

## 当前实现入口

- `InnerBalance/InnerBalanceApp/App/RootView.swift`：Breathe / Daily 两页，真实数据与练习持久化连接。
- `Features/Home/FangcunTodayView.swift`：Daily 页面，身体线索默认折叠。旧 `HomeView.swift` 保留但不是根入口。
- `Features/Home/FangcunDrinkSheet.swift`、`FangcunDrinkEditor.swift`、`Persistence/FangcunDiary.swift`：剂量、酒精度、可撤销且幂等的饮品命令与旧档兼容。
- `Features/Home/BeverageCareCoordinator.swift`、`CareNotificationClient.swift`：本机关怀回执、主动开启的通知、默认锁屏隐私。Core 的 `BeverageCareEngine`、`CareAttentionPolicy`、`CareNotificationPlanner` 不做 IO。
- `Features/Readiness/ReadinessCoordinator.swift`：独立数值引擎、逐指标发布、磁盘快照和失败保留。
- `Features/Readiness/DailyStatusViews.swift`、`DailyStatusHistoryView.swift`：整数状态分、实际构成权重、数值历史和旧记录分离。
- `InnerBalanceCore/Sources/InnerBalanceCore/StatusScore/`：V3 睡眠/HRV/RHR 提取、参数、引擎、版本化快照与最小跨端 DTO。
- `Features/Home/FangcunTrendsView.swift`：周视图与真实已存记录。
- `DesignSystem/PracticeCompanionV4.swift`、`FangcunCompanion.swift`：生成透明原画的刚性分层动作，禁止整脸拉伸和白色抠像。
- `Features/Practice/PracticeSessionView.swift`：练习完整流程；`PracticeAudioCoordinator.swift` 将可能阻塞的音频 session 准备移出主线程。
- `DesignSystem/FangcunDisplayPreferences.swift`：深浅色、字号、减少动态。

上面相对 `Features/`、`DesignSystem/`、`Persistence/` 的路径均位于 `InnerBalance/InnerBalanceApp/` 内。

## 事实边界

- 原生：HealthKit 真实数据查询与本机记录。UI 测试可注入合成原始数据场景；正式首页不展示演示开关。
- 网页：Mock 数据、浏览器本地记录，用来讨论设计与交互。
- 饮品：杯量及成分估算，不等同实测浓度；不会仅凭一杯咖啡把健康压力结论强行改成偏高。
- 历史：日状态从实际记录开始积累，空白日期不推测过去。
- 当前安装和测试详情见 STATUS；不能把 GitHub 上传或真机开发安装称为 App Store 上架。
- 旧设计文档中的 BLOCKED / PROGRESS 只描述当时阶段。发生矛盾时，以本文件、STATUS、当前源码和最新用户指示为准。

## 后续修改原则

保留原有健康权限边界、SwiftData 数据与用户记录。不添加遥测、账户、在线 AI 或新网络调用，除非另有授权。验证受影响的 iOS / watchOS 编译和相关交互。角色与产品审美参考 `docs/CURRENT_DESIGN.md`，先读现有代码再改。
