# M3-03 建议、行动与反馈

- Core 独立 `RecoveryActionKind` 将原 PracticeKind 以稳定字符串包装；原枚举未修改。3个本地协议为120/60/120秒、内容版本1、准备说明/两段文字/安全提示；阶段按计划时间二等分。使用既有静态猫狗，无新角色原画。
- 纯函数建议接受主观目标、环境、时长、偏好与明确不适集合；驾驶/不方便不启动，座位替代可选。不从 HRV 推断心理状态。首页保留五分钟主按钮，只有一个次级建议及更换入口。
- `RecoveryStore` 原子带校验文件保存本地行动与反馈，不依赖 HealthKit/准备度模型。原 SwiftData 保存链路保留；旧练习用原 sessionID 幂等投影到行动记录，结束原因未知标 legacyUnknown，不补造反馈。
- 暂停不计时，进后台暂停；定期及退后台保存已知 checkpoint。重启只保留已知有效时长，未知间隔不补算。首次本地保存成功才出现“已记录”；失败重试沿用同一 ID。
- 反馈未回答为nil；可在行动记录编辑，保留 revision/history。不适优先过滤主动建议；5次以上同类明确回答才显示描述性计数，不含未回答，不写疗效，不改变准备度。

## 实测

`m303-core-recheck`：3项Core测试（其中3种行动参数化）通过。
`m303-tests`：2项App测试（含3种行动）+1项真实UI全流程通过，正常退出0、xcresult可读。
- `pauseEndRetryAndRestart`、`localSaveFailureRetryAndPauseHaveOneIdentity`：驾驶拒绝启动、暂停、提前结束、写失败/重试、重复结束、进程重开中断。
- `optionalFeedbackRevisionsAndDenominator`：nil、revision、4到5份明确回答门槛。
- `recommendationsRespectExplicitSafetyAndDiscomfortFirst`：走动/座位、驾驶与不适优先。
- `legacyPracticeIdentitySurvivesReconciliationAndFeedbackEdit`：旧会话稳定ID、重复导入不覆盖反馈。
- `RecoveryActionUITests.testLocalActionPauseEarlyEndSkipThenEditFeedback`：真实首页建议→准备→暂停继续→提前结束→本地保存→跳过→返回→编辑为不舒服。

初次Core编译暴露原PracticeKind并不Codable，已用新包装自己的字符串编解码解决，未更改原枚举。
`m303-build` 的旧 PracticePresentation 套件发生音频真实图启动RPC超时/测试进程重启，随后2项声音状态测试失败；本阶段未改音频实现。与M3-PRE正常通过区分记录，最终全量复验须再次确认，不能据此称全量通过。

内容初稿仍需发布前人工运动安全/措辞审查。本轮未发布、未创建HealthKit训练/正念/热量记录。
