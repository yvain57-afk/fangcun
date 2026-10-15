# V4 原生界面迁移记录

## 实现入口

- `App/RootView.swift`：默认呼吸页、呼吸/日常两 Tab；统一全屏会话；日常设置与练习记录；饮品通知在进行中会话结束后再处理；未处理 checkpoint 不允许被新练习覆盖。
- `PracticeLibraryView.swift`：九项目录、功能筛选、首次叹息 5 分钟/1 分钟体验、夜间与固定快捷方法、方法详情/示范/时长/均衡 5/5 或 4/4、原存储练习记录。
- `PracticePresentation.swift`：九项用途/名称/动作/使用提示/完成回顾对应包内配置；自然训练与 NSDR 的文本来自 Core 分段时间线。
- `PracticeSessionView.swift`、`PracticeSessionScreens.swift`：variant/checkpoint 传入同一 ViewModel；准备页不要求先选感受；恢复前 2 秒自然呼吸准备不计时；实际相位 elapsed 传入渲染。
- `PracticeActiveStage.swift`、`BreathingFieldPlayer.swift`、`PracticeNonBreathingStages.swift`：相位/左右/自然呼吸/身体扫描/盆底训练分开；九项引用 `PracticeCompanionV4`；不再以旧几何图案充当主画面。
- `PracticeCompletionScreens.swift`、`PracticeSessionContent.swift`：实际时长和方法、三选感受可跳过；三选结果交给持久层保存真实文本，不映射成改善分值。保存成功后才有确认页。NSDR/睡前方法安静收束。
- `FangcunTodayView.swift`：作为日常页容器保留原状态分、饮品、关怀、感受与轻行动。
- `SettingsView.swift`：日常右上设置；保留显示/动效/权限/关怀/同步/诊断；新增可达的既有声音设置；状态历史导航统一到现有分数历史，旧历史仍从明确入口可达。

## 旧入口 → 新位置

| 原入口 | 新位置 | 数据处理 |
|---|---|---|
| 今日主状态分/依据 | 日常 → 身体状态/看看分数构成 | 仍读原 owner 和原快照；不重算模型 |
| 状态分 7/28 天历史 | 日常 → 看看这一周的节奏；设置 → 历史与趋势 | 原历史与旧记录入口保留 |
| 手工补睡眠 | 日常无数据 → 补记一次睡眠；原健康设置 | 原本地睡眠记录 |
| Apple 健康/数据来源/同步 | 日常 → 状态操作、设置 → 恢复参考与来源/同步/健康权限 | 原权限范围，无练习门控 |
| 今日饮品/剂量/时间/撤销 | 日常 → 今天喝了什么 | 原 Diary/编辑弹层，无清空 |
| 饮品关怀 | 日常饮品模块下方；设置 → 关怀设置 | 原单条关怀、通知偏好 |
| 感受罗盘/补充 | 日常 → 想补充一下自己的感受 | 原 CheckInFlow 和原缓存 |
| 原五种练习 | 呼吸 → 九项目录中的正式成员 | raw value/旧参数/历史含义不改 |
| 主五分钟入口 | 呼吸主卡（首次默认叹息；可固定方法） | 与同一个实际会话协调器连接 |
| 轻行动 | 日常 → 轻行动 | 原安静休息/座位舒展/活动休息流程 |
| 练习记录 | 呼吸右上/日常首项 → 练习记录 | 读取原 SwiftData，按方法筛选、日期分项 |
| 旧轻行动记录 | 新练习记录 → 轻行动与旧记录；设置旧入口 | 原 RecoveryHistory |
| 深浅色/大字号/减少动态 | 日常右上 → 设置 | 原 AppStorage key 不变 |
| 语音/节奏/静音/环境声 | 方法详情 → 引导设置；准备页；设置 → 声音引导 | 原声音偏好 key 不变 |
| 隐私/数据/诊断导出/品牌关于 | 日常右上 → 设置 | 原入口与能力保留 |

## UI 回归迁移原则

旧 UI 测试不再假设启动就显示分数，显式切到“日常”验证既有状态/饮品/感受；旧“设置”Tab 定位改为日常设置按钮。练习完成返回“呼吸”。没有删除状态分逻辑断言、颜色门槛或 golden fixtures。旧三 Tab 和旧主观反馈文案断言按本轮产品契约改成两 Tab、真实三选感受及独立感受记录。

新增 `BreathingHubV4UITests` 验证两 Tab 与无健康门控、九项实际开始/暂停/恢复/提前结束/本地保存、功能筛选、真实保存失败后重试。该文件必须由实际 Xcode 测试目标编译运行；本记录不将源码存在当作测试通过。

## 静态检查

已执行 `swiftc -frontend -parse` 检查 UI、Root 和 UI 测试 Swift 语法，退出 0。此命令仅验证语法；整版编译、实际 UI 测试、角色素材完整性、原生视觉/录屏、音频和真机行为由总验收记录给出。

## 专项人体教学补充

`PracticePreparationComponents.swift` 的 `PracticeHumanInstruction` 为膈肌、交替鼻孔、凯格尔提供原生 Canvas 线稿，并在详情及首次准备页可达。图像只是动作位置示意，不替代角色原画，也不声称测量。

- 膈肌：放松肩膀、手轻放下肋/腹部；无强制秒拍或向内施压箭头。
- 交替鼻孔：四帧明确「你的左/右」；同向图左=用户自身左。轻遮右→左吸、轻遮左→右呼、继续遮左→右吸、换遮右→左呼。每帧独立轻遮指腹、空气方向和完整 VoiceOver 标签。
- 凯格尔：骨盆底部轻收/完全放松两个独立示意；4/8 秒、自然呼吸、不向下用力、不用腹臀腿代偿。

首页普通字号主卡改为文字/原画并排、主开始与1分钟体验并排，保留字体与点击面积；大字号纵排自然增长。最终尺寸仍需原生截图验收。

## 正式计时前入场

`PracticeSessionView.beginEntry` 保持 ViewModel 为 ready。`PracticeEntryScreen` 在 `PracticeSessionScreens.swift` 调用角色组件的 entryProgress，时长 2.4–4 秒且随时可跳过。仅 finishEntry 后启动真实计时/音频/触觉；切后台取消入场，不自动把后台时间补入训练。恢复仍使用独立 2 秒不计时准备。新增 UI 用例验证入场页可跳过且尚未出现活动会话控制。

## 原速原生录像取证测试

独立类 `PracticeV4CaptureUITests` 在 `BreathingHubV4UITests.swift` 中；常规快速 UI 回归可排除该类，最终单独运行。

- `testCaptureNinePracticeScenes`：九项＋均衡 4/4 共十段，节拍训练至少原速26秒，凯格尔38秒，膈肌62秒，冥想105秒，NSDR100秒。全部通过真实详情、入场、运行、结束、保存和返回界面。NSDR这段仅为前景身体扫描录像，不是20分钟锁屏验收。
- `testCaptureDarkLargeTypeAndStaticModes`：深色、最大 Dynamic Type、静态动态模式、App减少动态偏好各自启动并截图，运行、暂停与正常保存。未声称此flag已经改变iOS系统设置。
- `V4_CAPTURE_ENTRY_START/START/FRAME/END/EXIT_END` 输出带毫秒的ISO时间，可与simctl全程录像对应。截图保存在xcresult附件。
- 等待使用真实Date期限的XCTest expectation，没有Thread.sleep、加速或注入最终状态。所有滚动搜索有明确次数上限。

### V4 渲染调度复核
- 主卡与详情示范以真实滚动可见性控制外层刷新；离屏、后台、静态偏好或减少动态时不运行 30 fps 预览。
- 训练页面的重绘任务在后台或暂停时取消，不改变会话或音频运行；前台节拍类使用 30 fps，自然引导与 NSDR 只在脚本段开始的 2.4 秒动作窗口使用 30 fps，其余 1 Hz，并提前对齐下一脚本段边界。
- 显示始终读取 VM 的实际 phaseElapsed 和 timelineSnapshot；重绘任务只触发视图更新，不累计第二套训练时间。
- 新回归 `v4NaturalRenderingCadenceFollowsActualCue` 覆盖静止段、动作窗口、提示前 150 ms、下一段、减少动态及六种节拍方法；运行结果由主代理统一记录。

### 最终角色补充录像

`testCaptureLowFrequencyExpressions` 另行原速运行叹息与凯格尔，跨第四轮记录表情边界；用于验证低频眨眼不重复插入补吸、停留、换侧或盆底收紧指令。该类三个取证测试与正常 UI 回归分开登记，不把缺省排除当作免测。坐到躺入场补为坐姿→伏下→最终躺姿的原画关键姿势；并肩场景使用同一长垫和两个独立入场角色。

### 日常设置入口的 UI 回归定位
- 全量正常 UI 首轮为 60 项、58 通过、2 失败；轻行动弹层坐标用例修正为滚动到入口后采样，保留 ±2 pt 断言。
- RecoveryAction 原完整链的第二项失败来自新 helper 对 `isHittable` 的额外判据。已用原生 hitTest 的前后类型/尺寸/flags 对比和标准 `Button.tap()` 反证：iOS 27 在轻行动结束后误报设置图标不可点，但标准点击可正常进入设置、修改反馈，第二次关闭轻行动后仍可进入设置。
- 最终只修测试定位：按可见 frame 有界滚动，标准按钮点击后严格断言设置开关出现。完整暂停/继续/提前结束/跳过/编辑“不舒服”/推荐变化仍验收，并增加再次进入后关闭返回。未保留 toolbar、呈现迁移、命中形状等无效产品修改或 DEBUG 诊断代码。
- 失败包与反证包保留在 `.build/v4-verification`。最终 `recovery-final.xcresult` 已正常退出、结果包可读取：日常饮品/趋势/练习/设置往返 48.448 s 通过，轻行动完整链及再次关闭返回 34.703 s 通过，2/2；标准按钮点击反证包 `recovery-native-button-tap.xcresult` 为 1/1。
