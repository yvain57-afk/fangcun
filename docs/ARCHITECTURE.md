# 架构与数据流

## 原生

`InnerBalance.xcodeproj` 包含 iOS App、Watch App、App 单元测试与 UI 测试，通过相邻的 `InnerBalanceCore` Swift Package 共享类型安全的领域模型和逻辑。最低 iOS 18、watchOS 11，Swift 6 并发检查。

```text
HealthKitRepository → HomeViewModel → FangcunTodayView
                                    ├→ FangcunEvidenceDetail
                                    └→ FangcunDiary（日状态快照）

FangcunDrinkSheet → FangcunDiary（UserDefaults Codable）
                   └→ FangcunTrendsView

今日 / 练习库 → PracticeLaunch → PracticeSessionViewModel
                              ├→ 共享时钟 → 文字、触感、呼吸角色
                              ├→ PracticeAudioController → AudioCoordinator
                              └→ CompletionSaveController → SwiftData / Health write queue
```

原来的 SwiftData schema 与既有用户数据保留。新饮品、日状态快照使用独立本机存档，损坏存档不静默覆盖。撤销按操作保存最近状态，咖啡因估值记在每条记录中，改变设置不会重算旧记录。

音频 session 的激活 / 停用可能同步阻塞，因此通过串行后台队列执行。UI 控制器处理任务取消和迟到的准备结果，避免退出后重新激活状态。AVAudioEngine 与 UI 协调仍由现有控制层管理。

角色使用原画资源与 Metal 局部采样变形。练习中胸腹变化取自同一个呼吸阶段时钟；有限动作结束后停帧；不可见、后台或减少动态时不持续播放。

## 网页

React、Tailwind、Framer Motion、Lucide 与 Vite。页面、可复用组件、数据模型与 Tokens 位于 `web/src/`。入口有应用、角色工作室和品牌工作室三个。无后端，Mock 健康数据和 localStorage 状态均为演示；不会同步用户的真实 HealthKit 数据。

## 公共仓库与本机项目

这是从已验证工作区整理出的独立源码项目。Xcode 中的个人 DEVELOPMENT_TEAM 已清空，签名文件、手机标识、健康数据与构建缓存未纳入。Bundle Identifier 保留历史配置供理解引用关系，其他开发者真机运行需选择自己的签名配置。

图片、SVG 和本地语音作为普通文件纳入 Git；无需 LFS。完整路径索引和源码分卷用于远程 AI 阅读。原始 `.xcresult` 和开发安装回执留在本机，仓库中仅存可公开的验证摘要与模拟器截图。
