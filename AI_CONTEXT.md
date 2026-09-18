# 方寸：给 GPT / AI 的项目入口

> 开发分支 `codex/fangcun-v1-m0-m1` 已接收用户的 v1.0 开发交付包。本轮范围与真实进展见 [任务状态](docs/plans/fangcun-v1/TASKS.md)、[决策记录](docs/plans/fangcun-v1/DECISIONS.md) 和 [验收](docs/plans/fangcun-v1/VERIFICATION.md)。M2-01 至 M2-04 数据链路及 M2-R01～R05 补修已实施；最新入口为 [M2-R1 补修报告](docs/plans/fangcun-v1/M2-R1-RESULTS.md)。原阶段证据见 [M2 审阅入口](docs/plans/fangcun-v1/M2-REVIEW.md)；M3–M6 未开始。新准备度尚未接入首页，保留 M1 UI。本分支应优先阅读实际源文件；`ai/` 分卷和下方 `main` raw 链接仍是先前公开基线，不能据此推断 M1/M2 代码。

仓库：<https://github.com/yvain57-afk/fangcun>

本文 raw 地址：<https://raw.githubusercontent.com/yvain57-afk/fangcun/main/AI_CONTEXT.md>

## 阅读顺序

1. [README](README.md)：产品、运行方式、当前目录。
2. [当前验证与安装状态](docs/verification/STATUS.md)：区分源码、测试、真机安装和商店发布。
3. [设计决策](docs/CURRENT_DESIGN.md)：已确认方向与历史版本优先级。
4. [原始完整设计规格](web/docs/用户提供的完整设计规格.md)：设计目标；不是完成声明。
5. [架构与数据流](docs/ARCHITECTURE.md)：原生真实数据和网页 Mock 的边界。
6. [所有文件索引](FILE_INDEX.md)：每个源文件及图片的可点击链接。
7. [分卷源码](ai/README.md)：原生代码、Core、网页与设计文字的纯文本分卷，适合无法递归遍历仓库的阅读工具。

所有文件均可通过 `https://raw.githubusercontent.com/yvain57-afk/fangcun/main/<文件路径>` 读取。中文和空格路径需要 URL 编码。分卷文件使用 ASCII 文件名；文件索引同时提供原文件和 raw 链接。

## 目标与明确偏好

方寸帮助一部分需要缓释压力的人理解身体线索并开始一个合适的练习。用户重视明确且有依据的结论，不希望首页强迫从“绷着”等预设标签中选心情。缺少数据必须如实表示缺少数据，不能用虚假的确定性补齐。

界面轻松、安静、有趣；猫狗是情境陪伴。角色的原画、耳朵、花纹、五官和身形不能被随意重画；允许局部动作，脚底固定，避免全身夸张缩放与持续摇晃。猫狗需要独处场景，不必每次一起出现。

## 当前实现入口

- `InnerBalance/InnerBalanceApp/App/RootView.swift`：今日 / 练习 / 设置，真实数据与练习持久化连接。
- `Features/Home/FangcunTodayView.swift`：新首页与依据详情。旧 `HomeView.swift` 保留但不是根入口。
- `Features/Home/FangcunDrinkSheet.swift`、`Persistence/FangcunDiary.swift`：饮品、撤销、日快照。
- `Features/Home/FangcunTrendsView.swift`：周视图与真实已存记录。
- `DesignSystem/FangcunCompanion.swift`、同名 Metal shader：确认原画的局部动效。
- `Features/Practice/PracticeSessionView.swift`：练习完整流程；`PracticeAudioCoordinator.swift` 将可能阻塞的音频 session 准备移出主线程。
- `DesignSystem/FangcunDisplayPreferences.swift`：深浅色、字号、减少动态。

上面相对 `Features/`、`DesignSystem/`、`Persistence/` 的路径均位于 `InnerBalance/InnerBalanceApp/` 内。

## 事实边界

- 原生：HealthKit 真实数据查询与本机记录。UI 测试可注入三种演示场景；正式首页不展示演示开关。
- 网页：Mock 数据、浏览器本地记录，用来讨论设计与交互。
- 饮品：杯量及成分估算，不等同实测浓度；不会仅凭一杯咖啡把健康压力结论强行改成偏高。
- 历史：日状态从实际记录开始积累，空白日期不推测过去。
- 当前安装和测试详情见 STATUS；不能把 GitHub 上传或真机开发安装称为 App Store 上架。
- 旧设计文档中的 BLOCKED / PROGRESS 只描述当时阶段。发生矛盾时，以本文件、STATUS、当前源码和最新用户指示为准。

## 后续修改原则

保留原有健康权限边界、SwiftData 数据与用户记录。不添加遥测、账户、在线 AI 或新网络调用，除非另有授权。验证受影响的 iOS / watchOS 编译和相关交互。角色与产品审美参考 `docs/CURRENT_DESIGN.md`，先读现有代码再改。
