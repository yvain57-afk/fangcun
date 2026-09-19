# M3-02 手机统一准备度

范围：App 生命周期唯一 `ReadinessCoordinator`，复用原 factory / pipeline / store。未改准备度算法、配置常数或 golden fixtures。原页面结构、角色和五分钟主入口保留。

- App 初始化持有服务；首页重绘不会重建数据库。回前台、下拉刷新、授权完成、来源/睡眠/目标变更和真实 observer 触发刷新。observer 从 owner 取最新上下文并从已提交 store 接收结果，不用 `.processed` 推导查询成功。
- 请求版本约束；选源过程隔离 observer 的迟到结果；Core pipeline `retire()` 拒绝旧、排队和未来请求。停止读取撤销 current，清除额外清除专用评估库，保留饮品、SwiftData 和 HealthKit。恢复读取必须显式选择。
- 前台时钟更新 freshness；18/24 小时语义沿用原参数。等级存在也必须当前有效才显示整体结论。失败缓存保留原证据锚点。
- HRV 显示 `displayValue` 毫秒；两类基线日数独立展示。详情分别列测量、证据查询、刷新尝试/成功、计算、睡眠结束。所有新增文案入 catalog / COPY_REVIEW。
- 7/28 天等尺寸图标区分完整、初步、有限、等待、失败、无资料与旧记录；点击日期查看所有已存周期/修订。没有安装前补算。
- 设置支持真实已读来源、近48小时主睡眠、7–10小时目标、停止/清除。`readiness.enabled=false` 是明确的 M1 回退；数据不足不会自动回退。回退保留评估历史且不启用 Mock。

## 验证入口

- Core `ReadinessLifecycleTests.retiringRejectsInFlightQueuedAndFutureRefreshes`：挂起查询、排队健康事件、retire、迟到返回和后续调用；无落盘结果。
- App `ReadinessCoordinatorTests.rawProviderThroughPipelineStoreAndOwner`：6组原始合成样本经真实 pipeline/store/owner；HRV显示值不同于内部对数。
- 同套 `failedRefreshKeepsAnchorAndIndependentCheckTimes`：无新资料检查和失败缓存。
- `clockBoundariesStopAndExplicitResumeDoNotRewardPractices`：注入时钟跨18/24小时；停止/明确恢复/清除。
- `settingsVersionAndSourcesPersistWithoutChangingGoldenParameters`、`latestIntentWinsAndStopIsolatesLateOwnerResults`：目标、来源、主睡眠、存储重开、慢旧请求。
- UI `ReadinessHomeUITests`：同一原始 fixture provider 经真实 service 到现行首页及详情，未注入展示状态。历史及大字检查另列最终证据。

首轮 `m302-tests`：App 4/4通过，UI一个含6场景的测试在详情列表尚未滚动至时间字段处失败。保留断言，补滚动并拆为6个独立场景；不把首次失败计通过。Core `m302-core` 正常退出0，1/1通过。最终结果见阶段证据和 M3-REVIEW。

## 验证边界

fixture 仅 DEBUG 显式启动参数启用，并使用独立临时 store。既有 M1 UI 套件显式传 `--readiness-disabled`；新准备度验收单独运行。合成测试不证明真机 HealthKit、锁屏或后台查询。

阶段复验：`m302-recheck` 5项App（含6个参数场景）+6项UI通过；`m302-history` App 5项通过，历史UI首次因凌晨的主睡眠属于前一天而错误查找今日行失败。保留空白日语义，测试显式选择有记录的日期，`m302-history-recheck` 1/1通过。所有运行正常结束、结果包可读。实际命令见 evidence 日志，原始 xcresult 留本机 scratch。

最终集成核对补齐详情：实际睡眠/该次目标、主睡眠内SDNN中位数与RHR最近值口径、样本数/覆盖、窗口、基线中心及中心上下一个稳健尺度。HRV基线由内部对数还原到ms；明确不是医学正常范围，不更改计算模型。历史等尺寸标记区分等级，保留资料资格；当天背景记录列训练、饮品、已保存行动/反馈，未读到不等于没有活动。App实测验证HRV基线还原，UI保留睡眠、参考与时间字段断言。最终结果见M3-REVIEW。
