# V4 音频与设备验收记录

记录日期：2026-10-15。本轮用户选择先交付可安装构建，真机体验稍后验收。本文只登记已经取得的资源、单元测试和模拟器音频图证据；不将签名归档或模拟器运行视为真机通过。

## 证据范围

- `AUDIO_ASSETS.json`：`validate_practice_audio_v4.py` 已实际执行，退出0；74个必需资源通过，missing=0、window_overflow=0、signal_invalid=0。这里74包含70个新增/派生文件及4个仍沿用的旧文件。
- `AUDIO_PRODUCTION.json`：68个Edge TTS新片段（6条动作口令＋62条完整段落）、2个原声响度派生文件，逐项记录文本、真实时长、来源类型及SHA。原16条旧文件保留。
- `evidence/audio/new-loudness.json`：对70个成品AAC实际复测，综合响度−24.10～−23.85 LUFS，跨度0.25 LU；最高真峰值−5.27 dBTP，没有削波。`legacy-loudness.json`保留原文件对照。没有通过改变方法秒拍修正声音。
- 本轮已运行的测试日志：工程本地 `.build/v4-verification/full-regression.log`；结果包 `.build/v4-verification/full-regression.xcresult`。本次读取日志确认 `PracticeAudioV4Tests` 六项通过、`Practice presentation` 套件通过；日志中的具体通过记录见下表对应测试名。本文不据此推断尚在进行或其他套件的整体结果，整版退出码由总验证报告登记。
- 前一轮 `.build/v4-verification/app-and-v4.log` 的整体运行曾失败，其中包含非音频问题；不能因为音频测试通过而将那轮标为全量通过。本轮不重复运行已通过的资源检查或Xcode任务。

源代码测试路径：

- `InnerBalance/InnerBalanceTests/Features/PracticeAudioV4Tests.swift`
- `InnerBalance/InnerBalanceTests/Features/PracticePresentationTests.swift`
- `InnerBalance/InnerBalanceTests/Features/PracticeSessionViewModelTests.swift`

## A01—A07 对照

| 编号 | 已有实现与实际证据 | 本轮判定与保留项 |
|---|---|---|
| A01 九项声音路线、口令不跨相位、声线稳定 | 74必需资源检查通过；`selectedVoicePackIsComplete` 实际通过；`alternateVoiceOrderDoesNotAlternateNaively`、`balancedVariantUsesSharedSnapshot`、`holdsAreDistinctTimelineEvents`、`resumeSlicesDoNotReplayOrCrossPhase` 全部通过。左右四个口令各有文件，恢复按当前片段定位，播放slice不得越过相位窗口。 | **资源和逻辑通过；听感部分待验。** 原`zhixingnv`不能追溯为确切voice ID。新片段选用Xiaoxiao，原16文件保留；没有宣称新旧一定同一声线。连续实际听音的一致性/接缝仍未由用户确认。 |
| A02 完整NSDR10/20、冥想5/10段落 | `everyGuidedSegmentHasAnExactResourceAndWindow`、`nsdrGuidanceAdvancesWithinThirtySeconds`（名称沿用，断言已迁为完整段落）、`nsdrGuidanceClosesBeforeTheSessionEnds` 实际通过。六条完整脚本（另含膈肌3/5）共62段与窗口一一对应，不循环旧六句填充；编码成品逐项时长通过。 | **资源与段落逻辑通过。** 不等于已实际完整听完20分钟，也不是锁屏播放验收。 |
| A03 guided/rhythmOnly/silent与标注一致 | `soundModeChoosesAudioLayers`、`unavailableVoiceModeFallsBackHonestly`、`guidedVoiceIsThePreferredDefault`、`independentLayersPreserveMutedPreference`、`selectedVoicePackActivatesGuidanceOnlyOnce` 实际通过。silent为空音频层；0音量保留为静音；缺文件会展示未就绪/文字路线，不偷偷改用系统嗓音。 | **自动化逻辑通过。** 全部模式在真机扬声器/耳机上的可听行为仍待验收。交替鼻孔仅节奏模式仍需要看左右文字，铃声不冒充语言指令。 |
| A04 声音/角色/触觉共享时间、≤100ms | `nsdrPresentationFollowsTheAudioPhase` 的13个边界样例实际通过；相位/段落和恢复generation读取同一`timelineSnapshot`，音频与触觉不各自累计练习秒数。 | **共享时间语义通过；≤100ms目标未验证。** 25ms快照观察间隔不是扬声器/蓝牙/触觉实测误差。未测端到端声画延迟，不登记达标。 |
| A05 NSDR实际20分钟锁屏；静音锁屏暂停 | `realAudioGraphStartsContinuousAmbience`、`runningSessionStartsTheAudioController`、`backgroundPolicyRequiresContinuousAudio` 实际通过。源码要求持续真实环境声且其音量>0才允许后台继续；silent、关闭环境声或连续音频不可用会暂停。没有添加静音循环保活。 | **implemented_unverified（设备项）。** 用户推迟真机，实际20分钟声音/锁屏未执行。模拟器短时音频图、加速时钟和预制20分钟时间表都不能替代。 |
| A06 拔耳机、来电、中断、回前台 | `backgroundPolicyRequiresContinuousAudio` 包含`oldDeviceUnavailable`应暂停断言并通过；`engineConfigurationChangeRebuildsActiveAudio`、`repeatedEngineConfigurationChangesAreCoalesced`、`cancelledAudioPreparationDoesNotReactivateSession`、`engineConfigurationChangeRequiresARebuild` 实际通过。生命周期在系统中断began或耳机移除时停止输出并暂停，不自动补播历史口令；继续由用户触发。 | **自动化与模拟器图恢复通过；真实设备中断未验证。** 没有声称已实际拔耳机、接打电话或验证蓝牙重新连接。 |
| A07 安静结束、不自动亮屏、不庆祝、保留记录 | 源码复核：`PracticeAudioController` 在comparison/saved/ready调用stop；未安排完成庆祝音，也未添加亮屏API。`cancelledAudioPreparationDoesNotReactivateSession`通过；`PracticeSessionViewModelTests` 的实际活动时间/暂停恢复样例通过，结束走既有本地保存链。 | **实现已核对；整机闭环待验。** 没有专门的真机“锁屏完成后不亮屏且保存成功”通过证据，不能由普通保存单测代替。此项不登记设备通过。 |

## 后续真机验收的具体动作（本轮尚未执行）

1. 使用本轮实际签名构建，先记录版本/构建号与安装回读结果；在扬声器和常用耳机分别试听旧叹息、新方块/左右口令、NSDR与冥想开头，确认声线与响度能接受。
2. NSDR20分钟使用真实时间，开启实际环境声后锁屏；中间检查引导段落、末段温和返回、最终本地实际时长与记录，不能用加速测试代替。
3. 静音、关闭环境声、环境声音量0分别切后台：应暂停活动时间，回前台后只有用户继续才恢复；不补算离开时间。
4. 运行中拔耳机、系统来电/音频中断、蓝牙路线变化，确认立即停止敏感播报、会话暂停、继续后不积压播放。屏息/盆底动作应从安全动作恢复，长段落恢复当前位置。
5. 真实测量扬声器与蓝牙各自的声画触觉延迟，单独记录设备与结果；结束时确认无额外庆祝声、无自动亮屏且本地保存成功。尚未执行这些步骤时保留`implemented_unverified`。

上述设备结果只需登记合成练习会话及必要状态，不把用户健康样本或设备标识放进公开材料。

## 音频来源记录

新语音来源为Edge TTS，构建期使用`edge-tts 7.3.1`、`zh-CN-XiaoxiaoNeural`、rate `−6%`、pitch `−2Hz`，文字来自本开发包；App运行时使用随包离线文件。两条节律派生文件来自项目既有语音，只做响度处理。这里记录技术来源与制作方式，不提供供应商授权或许可范围的保证。原音色身份及用户听感认可仍按上表单独登记。
