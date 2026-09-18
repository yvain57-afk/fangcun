# 内衡：双波 TestFlight 最终实施规划

**状态：** 产品与技术方案已收敛，等待实施确认  
**产品名：** 内衡（Inner Balance）  
**目标：** 为必须拥有 Apple Watch 的资深苹果用户，用尽量少的主动输入识别身体负荷、当下情绪与可能来源，并给出短而可执行的调节方案以及克制、可解释的前后变化证据。  
**最低系统：** iOS 18、watchOS 11  
**iOS Bundle ID：** `com.yvainair.InnerBalance`  
**发布路径：** 先做两波 TestFlight，不直接提交正式版。

---

## 1. 最终结论

本方案采纳评估中的四项核心修订：

1. Watch 上需要“身体证据”的练习使用 `HKWorkoutSession + HKLiveWorkoutBuilder` 获取高频心率；即时证据只谈心率变化，不把稀疏 HRV 当作练习前后证据。
2. 首版取消 WatchConnectivity 业务同步。结构化情绪数据随 `HKStateOfMind` metadata 写入 HealthKit；练习摘要随 `mindfulSession` metadata 写入。
3. 默认情绪登记压缩为“定位光球 + 选一个词”即完成，身体感受和来源改为提交后的可选补充。
4. TestFlight 拆为 Build 1 和 Build 2，先验证输入、解释、推荐和练习闭环，再加入提醒、趋势与生活背景。

同时修正评估中的三处过度表述：

- 不宣称 Apple 自带呼吸/正念 App 使用相同技术实现，因为公开文档没有作出该保证。
- HealthKit 会在用户的苹果设备间同步，但不保证即时到达；Watch 必须有本地待写队列和明确的“等待同步”状态。
- 样本 UUID 本身不足以解决离线重试幂等；所有本 App 写入的 HealthKit 样本使用 `HKMetadataKeySyncIdentifier` 与 `HKMetadataKeySyncVersion` 去重。

Apple 官方说明：所有 Watch workout session 都会生成高频心率样本；workout builder 可以丢弃而不保存 workout；HealthKit 允许自定义 metadata，并会在用户设备间同步健康数据。参考 [Running workout sessions](https://developer.apple.com/documentation/healthkit/running-workout-sessions)、[HKWorkoutBuilder](https://developer.apple.com/documentation/healthkit/hkworkoutbuilder)、[Metadata Keys](https://developer.apple.com/documentation/healthkit/metadata-keys) 与 [HealthKit updates](https://developer.apple.com/documentation/updates/healthkit)。

---

## 2. 产品边界

### 2.1 定位

内衡不是“压力诊断器”，也不输出一个看似精确的总压力分。它把状态分为三个可解释层面：

| 层面 | 回答的问题 | 数据来源 |
|---|---|---|
| 身体负荷 | 身体今天是否出现偏离个人基线的信号？ | Apple Watch、HealthKit |
| 主观状态 | 我现在愉快还是不愉快、激活还是低能量？ | 用户两步输入 |
| 可能来源 | 这种状态可能和什么有关？ | 用户可选补充，Build 2 加入最小化生活背景 |

推荐引擎可以组合三层信息，但 UI 始终保留原始证据和置信度，不把“身体负荷高”直接等同于“心理压力大”。

### 2.2 目标用户

- 必须拥有并已配对 Apple Watch；不要求最新型号。
- AirPods 可用于更私密、沉浸的语音练习，但 Build 1 不把 AirPods 传感器当成评估数据源。
- 用户愿意授权必要的 HealthKit 数据，并重视本地处理、可解释性和苹果原生体验。
- iPad 不做原生适配；允许系统以 iPhone 兼容模式运行，但不承诺布局体验。

### 2.3 明确不做

- 不做医疗诊断、心理治疗、疾病风险预测或“治疗有效”承诺。
- 不做账号、服务器、CloudKit、广告、第三方分析 SDK 或后台上传。
- 不做聊天机器人、自由文本日记、语音情绪识别或 AI 心理咨询。
- 不读取日历标题、参与人、地点、备注；不使用私有 API 打开或控制 Apple 正念 App。
- 不在首版使用 AirPods 头部运动或特定新型号才具备的生理传感能力。

---

## 3. 核心体验

### 3.1 首页：今天的状态

首页只呈现四件事：

1. **身体负荷**：平稳 / 留意 / 偏高 / 建立基线中，并显示置信度与 2–3 条原因。
2. **此刻感受**：最近一次情绪罗盘结果；没有记录时显示一个明确入口。
3. **建议动作**：只推荐一个最适合当下的动作，并允许展开替代选项。
4. **证据回看**：最近一次练习的主观变化；符合条件时再显示 Watch 心率变化。

不把大量图表放在首页，不用红色制造焦虑，不用“你压力过大”这类诊断式文案。

### 3.2 默认 10 秒情绪登记

默认路径只有两步：

1. 在二维罗盘上拖动光球：横轴为愉快度（HealthKit valence），纵轴为激活度（自定义 arousal）。
2. 从当前象限推荐的 4–6 个情绪词中选一个，点击后立即保存并结束。

提交后出现不阻塞的补充卡片：

- 身体感受：肩颈紧、胸口紧、胃部不适、呼吸浅、头沉、疲惫、无明显感觉等，可多选。
- 影响来源：工作、任务、健康、家庭、关系、金钱、训练、睡眠等，最多选两个。
- 用户可点“先这样”直接离开。

“都不像 / 不知道”的规则：仍写入用户已选的 valence，`labels` 为空；metadata 标记 `unclassified = true`，不能因缺少标签而跳过 HealthKit 写入。

### 3.3 Watch 最小流程

- 主页只保留“记录此刻”“开始调节”“同步状态”三个入口。
- 情绪输入使用 3×3 状态区域代替复杂二维拖动：先点区域，再点一个词，两次点击完成。
- Watch 可以独立完成记录和练习；iPhone 不在线时写入本地待处理队列，成功保存至 HealthKit 后再清理。
- Watch 上不能因为同步延迟重复弹出同一条记录。

### 3.4 冷启动第一周

从第 0 天开始即可使用：

- 情绪罗盘、练习、主观前后对比立即可用。
- 身体卡片显示“个人基线 2/5 天”这类进度，而不是只显示“数据不足”。
- 未满 5 个有效日时，可以展示原始数据和趋势方向，但不下“身体负荷偏高”结论，也不触发智能压力提醒。
- 每增加一个有效日，说明新增了哪类可用证据。

---

## 4. 身体负荷与睡眠可靠性

### 4.1 基线逻辑

从旧 App 复制纯计算逻辑到新建的 `InnerBalanceCore`，不移动、不引用旧 target 源文件：

- 14 天窗口。
- 每日先取中位数，再计算个人基线中位数。
- 至少 5 个有效日才形成基线。
- 核心信号：HRV、静息心率、主睡眠、近期训练；呼吸频率延后到 Build 2。
- 最近训练用于解释短期 HRV/心率波动，避免把正常训练反应误报为心理压力。
- 只有两项以上相互独立且可靠的信号一致偏离时，才允许显示“偏高”；否则显示“留意”或“证据不足”。

旧 App 中的逻辑位于：

- `iOSWatchApp/iOSWatchApp/HealthKitRecoveryManager.swift`
- `iOSWatchApp/iOSWatchApp/CoreLogic.swift`

复制时只带走纯模型与算法，并用测试固化现有行为；旧 App 文件不因内衡而修改。

### 4.2 睡眠纠错

为避免再次出现十几个小时的错误睡眠：

1. 只统计 `.asleepUnspecified`、`.asleepCore`、`.asleepDeep`、`.asleepREM`，不把 `.inBed` 计入睡眠。
2. 对重叠睡眠阶段做区间并集，不能简单累加各来源或各阶段。
3. 按睡眠间隔聚类为独立 episode；相隔超过 90 分钟的记录不合并，午睡不叠加到主睡眠。
4. 从最近 48 小时中选取结束时间合理、实际睡眠最长的主 episode；来源优先展示 Apple Watch，但不能用来源名替代区间去重。
5. 主睡眠少于 2 小时或超过 12 小时只显示“数据需要确认”，不进入负荷判断，不做截断伪装成正常值。
6. 数据详情页展示开始/结束时间、去重后时长、样本数、数据源与是否来自 Watch，方便用户核对健康 App。

---

## 5. 调节方案与效果证据

### 5.1 Build 1 练习库

| 练习 | 默认时长 | 是否自动推荐 | 身体证据策略 |
|---|---:|---|---|
| 生理性叹息 | 1 分钟 | 是，适合高激活、需要快速复位 | 默认只做主观前后对比；时间太短不强行解释心率 |
| 节律呼吸 | 3 / 5 分钟 | 是 | 5 分钟版本可开启 Watch 证据模式 |
| 冥想放松 | 5 / 10 分钟 | 是 | Watch 证据模式 |
| NSDR | 10 / 20 分钟 | 是，适合疲惫、低能量或恢复 | Watch 证据模式 |
| 凯格尔 | 3 分钟 | 否，单独位于“身体练习” | 只记录完成，不把它包装成减压证据 |

凯格尔必须附安全说明：疼痛、盆底持续紧张、排尿排便异常、产后或术后恢复中的用户先咨询专业人员；出现不适立即停止。它不能进入压力自动推荐规则。

### 5.2 Watch 身体证据模式

仅当练习时长和权限足够时启用：

1. 用户在 Watch 上明确点击“开始测量”，UI 持续显示正在测量。
2. 检查是否已有其他 workout session；若冲突，退化为主观模式，不抢占用户正在进行的训练。
3. 使用 `.mindAndBody` 配置启动 `HKWorkoutSession` 与 `HKLiveWorkoutBuilder`，采集高频心率。
4. 前 60 秒形成初始窗口，练习后最后 60 秒形成结束窗口；任一窗口有效样本不足则不输出身体结论。
5. 结束时调用 `discardWorkout()`，不生成一条训练记录；单独写入 `mindfulSession`。
6. 需要在授权说明和练习页明确告知：workout session 会提高传感器采样频率，HealthKit 可能保存由此产生的心率等样本；丢弃 builder 只保证不保存 workout 本身。
7. 发布前必须在真机核对健康 App：不能出现意外 workout 记录，并记录是否产生额外活动能量样本。若无法做到足够透明或审核风险不可接受，Build 1 降级为“保存 `.mindAndBody` workout 并明确展示”或关闭身体证据模式，不能偷偷运行。

### 5.3 证据文案边界

允许显示：

- “主观紧张从 7 降到 4。”
- “本次有效心率窗口：开始 78，结束 69 次/分。”
- “这只是本次练习中的变化，不能单独证明压力水平或治疗效果。”

禁止显示：

- “压力下降 35%。”
- “HRV 已恢复。”
- “焦虑得到治疗。”

HRV 只用于按天的身体负荷基线，不进入 3–20 分钟练习的即时前后对比。

---

## 6. 技术架构

### 6.1 方案比较

| 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|
| 独立 Xcode 工程 + 本地纯 Swift Package | 真正独立发布；旧 App 零耦合；iOS/Watch 共用可测试核心 | 初始工程配置稍多 | **采用** |
| 在旧 `iOSWatchApp.xcodeproj` 中加两个 target | 建立较快 | 项目继续膨胀；现有 `project.pbxproj` 已有用户改动；容易误伤旧 App | 不采用 |
| 直接从旧 App 拆页面 | 复用最多 | 继续携带行情、训练等无关依赖，无法形成清晰独立产品 | 排除 |

### 6.2 工程结构

新工程放在旧 App 同级目录，不修改旧 target：

```text
InnerBalance/
├── InnerBalance.xcodeproj
├── InnerBalanceApp/
│   ├── App/
│   ├── DesignSystem/
│   ├── Features/CheckIn/
│   ├── Features/Home/
│   ├── Features/Practice/
│   ├── Features/Diagnostics/
│   ├── Health/
│   ├── Persistence/
│   ├── Resources/
│   └── Assets.xcassets/
├── InnerBalanceWatch/
│   ├── App/
│   ├── CheckIn/
│   ├── Practice/
│   ├── Health/
│   └── Persistence/
├── InnerBalanceTests/
└── InnerBalanceUITests/

InnerBalanceCore/
├── Package.swift
├── Sources/InnerBalanceCore/
│   ├── BodyLoad/
│   ├── Emotion/
│   ├── Practice/
│   └── Recommendation/
└── Tests/InnerBalanceCoreTests/
```

### 6.3 职责边界

- `InnerBalanceCore`：纯 Foundation 算法、映射、规则与测试；不导入 HealthKit、SwiftUI、SwiftData。
- iPhone App：HealthKit 查询、首页、完整登记、推荐、趋势、本地诊断与导出。
- Watch App：快速登记、练习、实时心率、本地待写队列。
- HealthKit：跨设备事实来源；保存 State of Mind、Mindful Session 及必要 metadata。
- SwiftData：保存纯本地推荐结果、提示决策、诊断统计与尚未成功写入 HealthKit 的 pending records。

---

## 7. HealthKit 数据设计

### 7.1 授权分层

**Build 1 初始身体状态授权：**

- 读取：HRV、静息心率、睡眠、workout、State of Mind、Mindful Session。
- 写入：State of Mind、Mindful Session。

**用户首次开启 Watch 身体证据时再请求：**

- 读取：心率。
- 写入：workout 类型；这是启动 Watch workout session 的必要授权，即使最终选择丢弃 workout。

**Build 2 可选授权：**

- 呼吸频率。
- 日历读取、Focus 状态与通知。

每组授权都要先展示用途说明；拒绝任何一项都必须可降级，不重复骚扰。

### 7.2 State of Mind

- 默认即时登记写 `.momentaryEmotion`。
- Build 2 的晚间回顾写 `.dailyMood`。
- valence 直接来自横轴，范围 `-1...1`。
- labels 使用 Apple 的 `HKStateOfMind.Label`；允许空数组。
- 来源优先映射为 Apple 的 `HKStateOfMind.Association`，最多两个。
- arousal、身体感受、输入来源和关联练习 ID 使用自定义 metadata。

自定义 metadata 只使用字符串、数字和日期，key 使用反向域名前缀：

| Key | 类型 | 用途 |
|---|---|---|
| `HKMetadataKeySyncIdentifier` | String | 客户端稳定 ID，离线重试幂等 |
| `HKMetadataKeySyncVersion` | Number | 样本版本 |
| `com.yvainair.innerbalance.schemaVersion` | Number | metadata schema 版本 |
| `com.yvainair.innerbalance.arousal` | Number | `-1...1` 激活度 |
| `com.yvainair.innerbalance.bodySensationCodes` | String | 逗号分隔的稳定代码，不写自然语言 |
| `com.yvainair.innerbalance.unclassified` | Number | 是否选择“都不像” |
| `com.yvainair.innerbalance.origin` | String | `iphone` 或 `watch` |
| `com.yvainair.innerbalance.sessionID` | String | 关联练习 |
| `com.yvainair.innerbalance.phase` | String | `pre`、`post` 或 `standalone` |

隐私页必须说明：这些字段随 State of Mind 样本进入 HealthKit，其他获得相应读取权限的健康类 App 理论上也可能读取。用户若不接受，可关闭 HealthKit 心境写入并仅保存在本机，但将失去跨设备记录同步。

### 7.3 Mindful Session

每次呼吸、冥想或 NSDR 完成后写入 Mindful Session，并在 metadata 中保存：

- `sessionID`
- `practiceType`
- `protocolVersion`
- `origin`
- `evidenceMode`
- `heartRateStart`、`heartRateEnd`、`heartRateSampleCount`、`evidenceQuality`（仅有足够样本时）

只保存汇总，不复制原始逐拍心率。凯格尔不写 Mindful Session，避免把盆底训练伪装成正念分钟；它只保存在本机完成记录中。

### 7.4 同步与幂等

- Watch 每次创建记录时先生成稳定 `syncIdentifier`，再尝试保存 HealthKit。
- 保存失败则进入本地 `PendingHealthWrite`；按退避策略重试，成功后删除 pending。
- iPhone 通过 anchored query 增量读取由本 App 创建的样本，并以 sync identifier 去重构建本地缓存。
- UI 允许显示“已保存在手表，等待同步”；不能把未到达 iPhone 解释成数据丢失。
- HealthKit 同步是最终一致，不承诺秒级到达。

---

## 8. 情绪标签映射测试夹具

二维罗盘的建议词按 arousal 分组；最终 valence 始终由光球位置决定，标签不反推数值。

| 象限 | Apple labels |
|---|---|
| 高激活 / 正向 | amazed, amused, brave, excited, happy, joyful, passionate, proud, confident, hopeful, surprised |
| 低激活 / 正向 | calm, content, grateful, peaceful, relieved, satisfied |
| 高激活 / 负向 | angry, anxious, ashamed, disgusted, embarrassed, frustrated, guilty, irritated, jealous, scared, stressed, worried, annoyed, overwhelmed |
| 低激活 / 负向 | disappointed, discouraged, hopeless, lonely, sad, drained |
| 中性 / 需用户确认 | indifferent |

要求：Apple 当前公开的 38 个 label 必须在夹具中恰好出现一次；`surprised` 和 `indifferent` 这类语义可能跨象限的词，只用于候选排序，不能覆盖用户已选择的 valence/arousal。

---

## 9. 智能提醒与生活背景（Build 2）

### 9.1 触发策略

- 主触发窗为起床后：检测到新的主睡眠、夜间 HRV/静息心率已经到达且基线有效时重新计算。
- app 进入前台时必定刷新一次。
- HealthKit observer query + background delivery 只作为尽力而为的补充，不能设计成实时压力报警器。Apple 仅保证系统在有新样本时按设定频率“至多”唤醒，并不保证具体时刻；见 [Executing Observer Queries](https://developer.apple.com/documentation/healthkit/executing-observer-queries)。
- 每天最多一条身体负荷智能提醒；训练结束后的保护窗口、静默时段和置信度门槛必须生效。
- 用户可另行开启固定晚间回顾，它不是身体负荷报警；两类通知间隔不足 4 小时时合并或取消其中一条。
- 通知权限只在用户完成至少一次登记或练习、已经看到价值后再请求。

### 9.2 Calendar 与 Focus

- Calendar 只在内存中计算未来/过去数小时的忙碌分钟数、连续会议段和空档；不保存标题、地点、参与人、备注。
- Focus 只使用系统授权可提供的“当前是否处于 Focus”状态，不推断具体专注模式名称。
- 这些背景只能改变解释和提醒时机，不能直接给用户贴“工作压力”标签。
- 用户拒绝授权时，推荐系统继续使用身体与主观数据。

### 9.3 Apple 原生引导

Build 2 提供 App Intents / Shortcuts：

- “记录我此刻的状态”
- “开始一次生理性叹息”
- “开始 NSDR”

可以引导用户把入口放到快捷指令、控制中心或操作按钮，但不假设 Apple 正念 App 存在可公开调用的深链。

---

## 10. 本地诊断页

为同时满足“无遥测”和可验证性，设置页隐藏一个“TestFlight 诊断”入口，仅在测试构建显示：

- 默认登记完成时长的中位数与 P90。
- 光球完成率、情绪词完成率、可选补充完成率。
- 推荐被接受、练习开始、练习完成的本地计数。
- 主观前后对比可用率。
- 符合资格的 Watch 练习中心率窗口可用率。
- 通知已计划数与用户点击/操作数。这里的“响应率”是 `responded / scheduled` 的保守近似，不能宣称系统一定展示了每条本地通知。
- HealthKit 授权状态、最近同步时间、pending 数量与错误类别，不显示原始情绪或健康值。

支持用户主动导出聚合 JSON；详细记录默认不导出，必须再次确认。导出通过系统分享表完成，App 自己不上传。

---

## 11. 两波 TestFlight

### Build 1：验证核心闭环

范围：

- 独立 iPhone + Watch 工程、品牌与本地化骨架。
- HealthKit 分层授权与隐私说明。
- 身体负荷、睡眠纠错、5 天基线进度。
- iPhone/Watch 情绪快速登记与 metadata 同步。
- 生理性叹息、节律呼吸、冥想、NSDR、独立凯格尔。
- 主观前后对比；符合资格时提供 Watch 心率证据。
- Watch pending queue、HealthKit 幂等与 iPhone 增量读取。
- TestFlight 本地诊断页。

不包含：智能通知、趋势高级统计、Calendar、Focus、App Intents。

### Build 2：验证自动化与留存

范围：

- 起床后主触发、白天尽力而为触发和晚间回顾。
- 7/14/28 天趋势、同类练习至少 3 次后的主观效果汇总。
- 呼吸频率可选纳入身体基线。
- Calendar/Focus 最小化背景。
- App Intents、快捷指令入口。
- 根据 Build 1 诊断结果调整词表、步骤和推荐规则。

---

## 12. 实施任务与文件

以下路径均相对于仓库根目录 `.`。

### Task 1：建立独立工程与品牌骨架

**创建：**

- `InnerBalance/InnerBalance.xcodeproj/project.pbxproj`
- `InnerBalance/InnerBalanceApp/App/InnerBalanceApp.swift`
- `InnerBalance/InnerBalanceWatch/App/InnerBalanceWatchApp.swift`
- `InnerBalance/InnerBalanceApp/DesignSystem/InnerBalanceTheme.swift`
- `InnerBalance/InnerBalanceApp/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `InnerBalance/InnerBalanceApp/Resources/Localizable.xcstrings`

**步骤：**

1. 新建 iPhone 与配套 watchOS target，部署版本设为 iOS 18 / watchOS 11。
2. iPhone display name 设为“内衡”；Watch 使用同一产品名。
3. 采用深石墨背景、暖白正文、低饱和青绿色状态光，不使用医疗红绿灯风格。
4. 图标概念固定为“两个偏离后重新趋于平衡的弧面/光点”，不使用心电图、十字或大脑图标。
5. 只设置 iPhone device family；在隐私/帮助页说明 iPad 兼容模式不保证。

**验证：**

```bash
xcodebuild -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

### Task 2：建立纯计算 Core 与测试

**创建：**

- `InnerBalanceCore/Package.swift`
- `InnerBalanceCore/Sources/InnerBalanceCore/BodyLoad/BodyLoadEngine.swift`
- `InnerBalanceCore/Sources/InnerBalanceCore/BodyLoad/SleepEpisodeAnalyzer.swift`
- `InnerBalanceCore/Sources/InnerBalanceCore/Emotion/EmotionCatalog.swift`
- `InnerBalanceCore/Sources/InnerBalanceCore/Recommendation/RecommendationEngine.swift`
- `InnerBalanceCore/Tests/InnerBalanceCoreTests/BodyLoadEngineTests.swift`
- `InnerBalanceCore/Tests/InnerBalanceCoreTests/SleepEpisodeAnalyzerTests.swift`
- `InnerBalanceCore/Tests/InnerBalanceCoreTests/EmotionCatalogTests.swift`
- `InnerBalanceCore/Tests/InnerBalanceCoreTests/RecommendationEngineTests.swift`

**步骤：**

1. 先复制旧逻辑的行为测试，再复制最小纯算法；不修改旧文件。
2. 为 14 天日中位数、5 有效日、近期训练保护和部分数据缺失写失败测试。
3. 为睡眠重叠、多来源、跨午夜、午睡、>12 小时异常写失败测试。
4. 为 38 个情绪 label 恰好映射一次、未知标签降级写测试。
5. 为“凯格尔永不自动推荐”和推荐解释可追溯写测试。

**验证：**

```bash
swift test --package-path InnerBalanceCore
```

### Task 3：HealthKit 仓储、授权与幂等

**创建：**

- `InnerBalance/InnerBalanceApp/Health/HealthAuthorizationCoordinator.swift`
- `InnerBalance/InnerBalanceApp/Health/HealthKitRepository.swift`
- `InnerBalance/InnerBalanceApp/Health/StateOfMindMapper.swift`
- `InnerBalance/InnerBalanceApp/Health/HealthMetadataKeys.swift`
- `InnerBalance/InnerBalanceApp/Health/HealthSyncCursorStore.swift`
- `InnerBalance/InnerBalanceTests/Health/StateOfMindMapperTests.swift`
- `InnerBalance/InnerBalanceTests/Health/HealthMetadataTests.swift`

**步骤：**

1. 先测试 valence、空 labels、association 与 metadata round-trip。
2. 实现分层授权和逐项降级状态。
3. 使用 sync identifier/version 写入，并用 anchored query 增量读取。
4. 过滤来源，只把本 App 写入的样本重建为本地记录；Apple 健康中的其他 State of Mind 只用于用户明确开启的趋势汇总。
5. 禁止在日志中输出 health values 或 metadata 内容。

**验证：**

```bash
swift test --package-path InnerBalanceCore
xcodebuild -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

### Task 4：身体负荷与冷启动首页

**创建：**

- `InnerBalance/InnerBalanceApp/Features/Home/HomeView.swift`
- `InnerBalance/InnerBalanceApp/Features/Home/HomeViewModel.swift`
- `InnerBalance/InnerBalanceApp/Features/Home/BodyLoadCard.swift`
- `InnerBalance/InnerBalanceApp/Features/Home/BaselineProgressView.swift`
- `InnerBalance/InnerBalanceApp/Features/Home/HealthEvidenceView.swift`
- `InnerBalance/InnerBalanceTests/Features/HomeViewModelTests.swift`

**步骤：**

1. 先测试 0–4 天只显示进度、不触发偏高结论。
2. 接入 HRV、静息心率、睡眠和 workout 查询。
3. 展示数据源、最新时间、置信度与训练保护原因。
4. 加入睡眠数据核对入口。

**验证：** `swift test --package-path InnerBalanceCore`，并用含真实历史数据的 iPhone + Watch 真机核对至少三晚。

### Task 5：两步情绪罗盘

**创建：**

- `InnerBalance/InnerBalanceApp/Features/CheckIn/EmotionCompassView.swift`
- `InnerBalance/InnerBalanceApp/Features/CheckIn/EmotionWordPicker.swift`
- `InnerBalance/InnerBalanceApp/Features/CheckIn/OptionalContextSheet.swift`
- `InnerBalance/InnerBalanceApp/Features/CheckIn/CheckInViewModel.swift`
- `InnerBalance/InnerBalanceUITests/CheckInFlowUITests.swift`

**步骤：**

1. 先写 UI 测试覆盖正常词与“都不像”。
2. 完成光球拖动、动态词表、触感与 Dynamic Type。
3. 选择情绪词后立即提交；补充页失败不能回滚主记录。
4. 从打开到主记录成功计时，写入本地诊断事件。

**验证：** 在已安装的 iOS 模拟器上运行 UI tests，并用 VoiceOver、最大 Dynamic Type 和 Reduce Motion 人工核对。

### Task 6：练习与主观前后对比

**创建：**

- `InnerBalance/InnerBalanceApp/Features/Practice/PracticeLibrary.swift`
- `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSessionView.swift`
- `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSessionViewModel.swift`
- `InnerBalance/InnerBalanceApp/Features/Practice/SubjectiveComparisonView.swift`
- `InnerBalance/InnerBalanceApp/Resources/PracticeScripts.xcstrings`
- `InnerBalance/InnerBalanceTests/Features/PracticeSessionViewModelTests.swift`

**步骤：**

1. 先测试暂停、恢复、退后台、结束和中断后的状态机。
2. 加入本地脚本、音频控制、触觉节奏和 AirPods/扬声器系统路由。
3. 练习计时使用绝对开始/暂停时间计算，切换页面后不得重新开始。
4. 完成后写 Mindful Session 和主观 post 状态；写入失败进入 pending。
5. 凯格尔采用独立记录类型和安全文案。

**验证：** 锁屏、切 App、断开 AirPods、来电/音频中断后分别恢复一次；计时误差不超过 1 秒。

### Task 7：Watch 快速登记与身体证据

**创建：**

- `InnerBalance/InnerBalanceWatch/CheckIn/WatchCheckInView.swift`
- `InnerBalance/InnerBalanceWatch/Practice/WatchPracticeView.swift`
- `InnerBalance/InnerBalanceWatch/Practice/LiveHeartRateSession.swift`
- `InnerBalance/InnerBalanceWatch/Health/WatchHealthKitRepository.swift`
- `InnerBalance/InnerBalanceWatch/Persistence/PendingHealthWrite.swift`
- `InnerBalance/InnerBalanceWatch/Persistence/PendingWriteProcessor.swift`

**步骤：**

1. 先用 Core tests 固化前后窗口、样本不足和异常心率过滤规则。
2. 实现 3×3 区域 + 单词的两点击登记。
3. 实现 workout session 生命周期、冲突退化、后台继续和明确停止。
4. 结束时丢弃 workout builder，另写 Mindful Session 汇总。
5. 在断网、iPhone 不在附近、锁屏、已有 workout 四种场景真机验证。

**验证：** 必须使用真实 Apple Watch；Simulator 只用于布局。健康 App 中不得出现意外 workout 记录。

### Task 8：本地诊断与隐私页

**创建：**

- `InnerBalance/InnerBalanceApp/Persistence/DiagnosticEvent.swift`
- `InnerBalance/InnerBalanceApp/Features/Diagnostics/DiagnosticsView.swift`
- `InnerBalance/InnerBalanceApp/Features/Diagnostics/DiagnosticsExporter.swift`
- `InnerBalance/InnerBalanceApp/Features/Settings/PrivacyView.swift`
- `InnerBalance/InnerBalanceTests/Diagnostics/DiagnosticsExporterTests.swift`

**步骤：**

1. 先测试聚合导出不包含 health values、情绪词、日历内容或稳定设备标识。
2. 实现本地时长、漏斗、练习与同步错误统计。
3. 仅 TestFlight/Debug 展示诊断入口。
4. 用户主动确认后调用系统分享表；不加入网络客户端。

**验证：** 解压导出内容并人工搜索健康值、情绪、日历与设备标识，结果必须为空。

### Task 9：Build 1 真机验收与 TestFlight 材料

**创建：**

- `InnerBalance/InnerBalanceApp/Resources/PrivacyInfo.xcprivacy`
- `InnerBalance/TestFlight/BetaReviewNotes.zh-Hans.md`
- `InnerBalance/TestFlight/TestChecklist.zh-Hans.md`
- `InnerBalance/TestFlight/PrivacyPolicy.zh-Hans.md`

**步骤：**

1. 配置 HealthKit、Workout Processing、必要后台能力和两端 purpose strings。
2. 完成隐私政策 URL 准备、非医疗声明和审核说明。
3. 用空数据、部分授权、完整授权、Watch 不佩戴、同步延迟五种状态走查。
4. Archive 前运行所有 Core tests、App tests 与两端 Release build。
5. 第一版外部 TestFlight 提交 Beta App Review；Apple 要求外部测试的首个构建经过审核，见 [TestFlight](https://developer.apple.com/testflight/)。

**验证：**

```bash
swift test --package-path InnerBalanceCore
xcodebuild -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -configuration Release -destination 'generic/platform=iOS' build
xcodebuild -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' -configuration Release -destination 'generic/platform=watchOS' build
```

### Task 10：Build 2 提醒、趋势与背景

**创建：**

- `InnerBalance/InnerBalanceApp/Notifications/MorningPromptCoordinator.swift`
- `InnerBalance/InnerBalanceApp/Features/Trends/TrendsView.swift`
- `InnerBalance/InnerBalanceApp/Context/CalendarLoadProvider.swift`
- `InnerBalance/InnerBalanceApp/Context/FocusStatusProvider.swift`
- `InnerBalance/InnerBalanceApp/AppIntents/InnerBalanceShortcuts.swift`
- `InnerBalance/InnerBalanceTests/Notifications/MorningPromptCoordinatorTests.swift`

**步骤：**

1. 先测试每天一次、静默时段、训练保护、基线不足和通知合并。
2. 接入 observer query 与前台刷新，后台未唤醒时不伪造实时提醒。
3. 只保存 Calendar 聚合量，不保存事件内容。
4. 同类练习少于 3 次不展示效果趋势。
5. 加入三个 App Intents，并为无权限/Watch 不可用提供明确退化。

**验证：** Core/App tests 全通过；检查 SwiftData store 中不存在 Calendar 原文。

---

## 13. 验收闸门

### Build 1 必须满足

- 至少 5 名测试者完成首次使用；80% 无需解释即可完成第一条登记。
- 默认登记中位时长 ≤10 秒，P90 ≤15 秒；若不达标，先减词和减动画，不增加教程。
- 0–4 个有效日不会出现“偏高”结论或智能提醒。
- 多来源重叠睡眠不会重复累计；异常 >12 小时不进入负荷判断。
- 所有 HealthKit 重试无重复样本；Watch pending 最终可清零或显示可操作错误。
- 凯格尔自动推荐次数必须为 0。
- 符合资格的 5 分钟以上 Watch 证据练习中，前后心率窗口可用率目标 ≥80%；达不到时仍发布主观证据，但隐藏身体证据卖点。
- 丢弃 evidence session 后，健康 App 中意外 workout 记录为 0。
- 旧 `iOSWatchApp` 能保持原状构建；内衡开发不修改其业务源文件。

### Build 2 必须满足

- 身体负荷智能提醒每天不超过 1 条，晚间回顾遵守 4 小时间隔规则。
- 基线不足、近期训练、静默时段和通知拒绝均正确降级。
- Calendar 标题、参与人、地点、备注落盘数量为 0。
- 同类练习不足 3 次不显示趋势性效果结论。
- 诊断页可以给出登记耗时和提醒点击的本地聚合数据，导出不含健康原始值。

---

## 14. 审核、隐私与安全文案

- iPhone 和 Watch target 都配置准确、具体的 `NSHealthShareUsageDescription` 与 `NSHealthUpdateUsageDescription`。
- App 内与 App Store Connect 都提供隐私政策入口，说明数据类型、用途、本地保存、HealthKit metadata、撤销授权和删除方式。Apple 要求所有 App 提供隐私政策，并对健康测量与医学声称进行更严格审查；见 [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)。
- 首页解释统一使用“状态参考”“身体负荷信号”“本次变化”，不使用“检测焦虑”“治疗压力”。
- 对“绝望”等高风险词只显示静态、非诊断式支持入口：建议联系可信任的人和当地专业/紧急支持；不建立隐藏风险分，不自动通知第三方。
- 用户可以在设置中删除本地数据；HealthKit 样本的删除需清楚区分“本 App 写入的记录”和“其他来源记录”，绝不批量删除非本 App 数据。

---

## 15. 最终推荐的实施顺序

1. 先完成 Task 1–2，让独立工程和纯算法可构建、可测试。
2. 完成 Task 3–5，尽早把“两步登记 + HealthKit 写入 + 冷启动首页”交给测试者体验。
3. 完成 Task 6–8，闭合练习、Watch 证据和本地诊断。
4. 完成 Task 9，发布 Build 1，至少观察 3–7 天后再冻结交互。
5. 只有 Build 1 的登记耗时、练习完成率和数据可靠性达到闸门，才开始 Task 10 的 Build 2。

这个顺序优先验证产品真正的核心：用户是否愿意持续输入、是否信任解释、是否愿意执行建议，以及能否看懂练习后的变化。提醒、趋势和生活背景都不能早于这个闭环。
