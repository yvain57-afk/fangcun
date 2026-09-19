# 当前交付与验证状态

最新入口：[2026-09-19 V2 审阅与实际状态](../plans/fangcun-experience-v2/REVIEW.md)。下面保留 2026-09-18 的历史记录，不代表当前阶段或安装版本。

最新开发分支已完成 v1.0 任务书的 M0 基线及 M1 数据语义修复，iPhone 安装版为 **1.0.0 (2026091802)**。Core 67、App 31、UI 7 项测试通过。详见 [本轮验收](../plans/fangcun-v1/VERIFICATION.md)、[任务状态](../plans/fangcun-v1/TASKS.md) 和 [截图](../plans/fangcun-v1/SCREENSHOTS.md)。M0 的物理 Watch 能力验证仍待设备，M2–M6 未实施。

以下内容保留为此前完整 UI 改版的基线记录。

## 真机

最终修复版已覆盖安装到配对的 iPhone 16 Pro，开发工具确认安装成功并启动 `com.yvainair.InnerBalance`。未卸载 App，保留现有数据。最终包含后台音频 session 准备、取消处理、呼吸页标题与舞台收尾修复。

这是开发安装，不是 TestFlight / App Store 上架。签名 App、原始安装回执、设备标识和原始 `.xcresult` 留在开发者本机，公开仓库只提供代码、模拟器截图和摘要。

## 独立仓库可运行性

从当前 App 工程与网页原型整理出独立目录后，重新执行：

| 检查 | 结果 |
| --- | --- |
| `swift test --package-path InnerBalanceCore` | 64 项测试通过 |
| `xcodebuild build ... -scheme InnerBalance -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO` | 构建成功，包含 Watch companion target |
| `cd web && npm ci --no-audit --no-fund` | 安装成功 |
| `cd web && npm test` | 9 项模型测试通过 |
| `cd web && npm run build` | 应用、角色工作室、品牌工作室打包成功 |

验证工具链：Xcode 27 beta / Swift 6；Swift Package 要求 Swift 6.2+。个人 Team 配置在公开工程中留空，真机需自行签名。

## 改版功能验证

- 真机 App 单元测试：饮品组合、撤销、持久化、跨日、损坏存档保护与练习时钟，合计 7 项通过。
- 音频：真实音频图、运行中启动、配置变化恢复、通知合并、取消后迟到结果、无可恢复配置时暂停，6 项通过。
- UI 情景：平稳 / 偏高 / 数据不足，深色与较大字号测试通过。
- UI 完整链路：首页 → 饮品增加与撤销 → 趋势 → 直接开始呼吸 → 暂停 / 继续 → 提前结束 → 保存 → 返回首页 → 设置，通过。
- 动效开启：进入呼吸、等待阶段变化、暂停、提前结束，通过。

最初一次完整 UI 测试曾在开始练习时因同步音频 session 等待而失败；修复后上述链路重新通过。失败历史没有作为通过记录混算。

## 截图索引

| 内容 | 截图 |
| --- | --- |
| 今日 | [首页](screenshots/259B610F-B230-4660-BA62-2D0D341B50E9.png) |
| 饮品 | [增减与撤销](screenshots/DCC9B472-D944-49A8-A9C5-7F53D8E8FE03.png) |
| 呼吸 | [动效开启](motion/E40F80CA-3DE4-47EB-A25A-1FEFBE3D2D38.png) / [暂停](motion/43469171-776F-413B-8EBE-C71693ECC76F.png) |
| 保存 | [提前结束后的保存](screenshots/C7AA995E-6B86-4149-9790-12BAB3159022.png) |
| 趋势 | [真实空白与已记录饮品](screenshots/55CA0D4C-2D70-4009-A957-B3C606E760E7.png) |
| 设置 | [显示与偏好](screenshots/F4D2DA51-6C45-4F1D-8D75-10A75370A2CA.png) |
| 三情景 | [平稳](scenarios/9D1B4C1D-54EA-4EFA-A4BE-F1F2610C9EFE.png) / [偏高深色](scenarios/514611FA-A1C6-418D-B60E-64FB2EFE16B4.png) / [数据不足大字](scenarios/2910023E-1EC2-466A-94A4-D5A806B51868.png) |

截图来自模拟器与独立 UI 测试存储。三情景截图包含专门注入的演示状态；不上传真实个人健康数据。

## 纳入与排除

纳入当前原生源码与测试、网页源码与测试、确认角色、品牌资产、设计原文、历史方案、模拟器截图。旧方案保留但不作为当前定案。

排除签名文件、账号凭证、设备标识、真实健康导出、构建缓存、依赖目录、来源不明的工作区改动和无关 App。重复打包 / 源码备份以已展开、可阅读的当前文件提供，避免 GPT 只能看到压缩包。

## 尚不能从本次验证推导的结论

没有完成商店审核或上架；没有宣称医学诊断能力；没有把网页 Mock 判定当成原生实测结果。当前物理设备的每个手势和后台场景没有全部自动化验收，自动化 UI 完整链路主要在 iPhone 16 Pro 模拟器验证。
