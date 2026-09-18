# M1 决策记录

1. **范围**：遵循交付包 START，本轮先 M0–M1。保留原生入口、版画猫狗、品牌色、练习/健康写入/饮品/设置；不启动全部重构。M2 golden fixtures 原样入库但未用新算法实现，不能声称准备度已上线。
2. **资格与结论正交**：新增 Core `BodyLoadDataAvailability`（insufficient / limited / buildingBaseline / available）。只有当前可靠、不同种类至少两类，且有 HRV 或静息心率，才能输出旧整体判断。不可用时保守返回旧 `buildingBaseline` level 保持旧调用兼容；新首页首先解释 availability，不能把它统一写成“基线积累中”。
3. **当前与历史分离**：历史天数只计算前 14 天且不含今天。M1 沿用原心血管 36 小时窗口；最近主睡眠也加 36 小时资格门控，超过窗口仍可展示原测量日期，但不参与当前判断。M2 再实现规范的主睡眠、24 小时准备度、来源一致性和置信度，不把旧阈值说成医学定论。
4. **失败优先**：provider 若将某种查询标为 unavailable，即使夹带旧数组也不能用于评估或冒充新读数。空结果不等于未授权，UI 不推断权限。
5. **时间**：`fetchedAt` 是查询，`computedAt` 是本次计算完成时的注入时钟；`measuredAt` 保留原始记录时间，聚合判断的 `assessmentMeasuredAt` 单独保留其最新样本时间。首页显示最近测量日期；详情展示查询、计算和每项测量。兼容只读 `lastUpdated` 仅给旧诊断调用，文案不称“同步”。
6. **运动保护**：暂保留旧 18 小时 / 45 分钟筛选，但保留 `workoutExcludedEvidenceIDs`。若过滤后本会落到 steady，则降低为 limited；原始偏离和训练背景继续展示。有独立未过滤偏离仍可保留 watch/elevated，不能因运动清空全部事实。
7. **观察不等于偏高**：新首页增加 watch 和 limited。至少两类合格证据、一项偏离为“轻度留意”；两项偏离才是“偏高”；不称心理压力诊断。身体线索卡的第二项换为实际 RHR/HRV，不再复制主状态作独立证据。
8. **旧快照**：缺失 `semanticsVersion` 的快照标为 legacy，原文字及旧短标题保留；新 M1 快照为 version 1。相同日期刷新不删除 legacy，旧记录不送入准备度。首次覆盖已有本机 archive 前保留 preM1 原始字节，坏数据保持不覆盖。完整 versioned storage 仍属 M3。
9. **测试边界**：12 组 DEBUG-only 原始 fixture 通过 provider→HomeViewModel→Core→FangcunDayState→SwiftUI；单元测试和 UI 测试的预期不放在 provider。原三状态视觉预览保留但限制 DEBUG，仅作视觉检查。Release 禁用 UI 测试入口。
10. **文案**：新增中文集中为稳定 key + String Catalog + COPY_REVIEW.csv。新增 UI 选择器使用稳定 accessibilityIdentifier，改文案不需要改算法、协议或选择器。

## M2-01

- 独立 Readiness 数据域，不修改 M1 provider 或首页。HealthKit adapter 仅查已在原授权范围内的 SDNN、系统 RHR、睡眠与 workout；不新增正念读取授权。已知本机练习时段作为计算输入传入。
- Source key 包含指标、bundle、product/model、可得设备 identity 的本地摘要、采样口径与兼容段。应用版本仅保留，不默认破坏基线；同源 identityIncomplete 不自动认定不可用，实际 ambiguity 单独处理。
- 明确手动切源优先于保持原源；日常保持已选源，即使临时缺失。镜像去重仅在显式来源对策略下执行，数值相同本身不构成重复。
- anchored predicate 的起点随锚点一起持久化，避免每次改变 predicate 破坏增量语义；本机样本缓存滚动裁剪到 35 天。一次最多 500 项，分页由事务协调器接续；锚点和样本必须一起提交。
- observer 注册幂等、及时确认，不开启后台交付新权限，不承诺后台唤醒；生命周期接线保留至 M3。M2 公开独立 service 入口并测试完整数据链路。

## M2-02：睡眠与基线边界

- 本地日期以主睡眠结束日归属，前 28 日期各取最长段；时区只影响日归属，不生成新的睡眠周期 ID。历史资料限定在当前主段开始之前，排除当前样本 UUID。
- 同段修订的 50% 重叠用两段跨度的较大值作为分母（任务书未指定分母）；存在多匹配一律待复核。
- 极端有限值的绝对边界在任务书中未给数值。最小补充为 HRV >10,000 ms 或 RHR >1,000 bpm 标记 extremeValue，不截断；集中工程配置、待校准，不能视为医学阈值。相对 HRV 高值仍严格执行第 4 章规则。
- 去重改为 UUID / 同源同步标识集合，只有显式跨源镜像策略才做区间对照。合成 20 日基线测试由约 13.65 秒降至 0.052 秒；模型和输出不变。

## M2-03: deterministic assessment

- Tests load the original G01-G10 JSON and generate raw sleep, SDNN, and RHR inputs. No copied expected-result table.
- A 1e-12 numerical tolerance handles log/exp round trips at exact severity boundaries; no model threshold changes.
- Availability, level, freshness, and sync state are orthogonal. Partial evidence remains visible without a level. A failed refresh preserves valid cached timestamps; invalidation and a newer sleep take precedence.
- Current sleep uses 48 hours; historical episodes use the bounded 35-day cache. Old malformed nights do not invalidate a separate current night. Training never hides observed deviations; drinks and completion counts are not scoring inputs.

## M2-04：存储与数据链路

采用 [ADR-002](ADR-002-insights-store.md) 的独立 Insights store。`ReadinessServices.make()` 提供 HealthKit adapter → ReadinessPipeline → 独立 store 入口，创建不申请权限或启动 observer。原首页、用户记录、练习及显示偏好继续使用原入口。

修订、输入摘要、配置版本、来源摘要、时间范围、资料质量和新鲜度随结果保存。规则参数进一步集中到 ReadinessConfiguration。删除优先于缓存，损坏恢复撤销当前资格；失效锚点重读时清理该项旧缓存。全部实现停在 M2，不接入 M3 页面、不做 M4 同步或 M5 通知。

## M2-R01：完整删除依赖

审阅成立。记录有界评估输入中 sleep/SDNN/RHR/mindful UUID 的保守依赖超集，包括基线睡眠、冲突、去重候选和被质量过滤的记录。它只用于失效，不参与指纹或模型参数。可能对未最终采用的候选多做一次失效/重算，避免漏撤销；不保存额外健康值。

新增可选 dependencyVersion；旧 schema 1 文件可读，缺少该字段的旧评估遇到删除一律保守撤销。新评估依赖已排除 tombstone，重算可以重新合格。删除、失败缓存和恢复都经过同一 redact 路径，不清库。

## M2-R02：分页发现与稳定选源分离

审阅成立。新增按指标持久化的可选 initialization（unread / inProgress / complete），与样本/游标同事务提交。仅完整读完首次发现才默认选源；失败或 100 页工作预算耗尽保留 inProgress 并续读。已选稳定来源和显式手动来源始终保留，失效锚点只重建读取进度，不自动切源。旧 schema 1 缺字段时可正常解码；已有来源继续权威，缺来源等待一次完整发现，不清库。

## M2-R03：有语义的单飞与一个待执行批次

审阅成立。比较配置、完整 Calendar/时区、排序后的练习区间与读取到的 store generation。同语义普通刷新共享在途任务；不同语义或 healthDataChanged 请求进入最多一个 pending 批次，串行补读。待执行设置被更新设置替换时明确返回 superseded，不冒充已经应用。多个同语义事件合并进同一个补读；补读期间的新事件可要求下一次有界读取，每个事件最多加入一个后续批次。没有自动失败重试循环；每轮仍有限页数。observer 接线将在 R05 使用 healthDataChanged 路径。

原 generation 提交校验保留，切源/删除/清除仍可拒绝旧结果。这里没有接入 App 生命周期或扩大后台权限。

## M2-R04：证据身份与刷新时刻分离

审阅成立。仅指纹投影使用固定逻辑 RHR 上界 sleepEnd+3h；真实抽取仍严格使用 min(now, sleepEnd+3h)，输出 feature.window 仍报告实际截止时间，未接受未来样本或改变门槛。新增可选 lastRefreshAttemptAt / lastSuccessfulRefreshAt 表示刷新尝试/成功检查时间；assessment.queriedAt 保留样本携带的证据读取时间。旧文件缺字段可解码为空，无迁移清库。

## M2-R05：完成处理之后确认 observer

审阅成立。SDK completion 由专用一次性锁保护适配器持有；处理任务使用 defer 在正常、读取错误、处理失败和取消收尾之后确认。Swift 6 SDK 的旧 block typedef 没有 Sendable 注解，无法直接标成 @Sendable 或 sending：仅这一外部回调适配器使用 @unchecked Sendable，所有私有可变状态由 NSLock 保护，取出置空后在锁外调用；没有关闭工程并发检查。

公开的 startObserving 接受 pipeline 和实时 context，事件强制走 healthDataChanged 的 pending 补刷新入口。保留最近 observer outcome；失败时 observerNeedsRefresh 为真。读取失败由 pipeline 存入评估，未提交的 cursor 不推进；存储失败不能伪称已经持久化。注册仍是显式调用，未接到 App 生命周期，未启用后台投递权限，未承诺系统唤醒。

2026-09-18 核对本机 HKObserverQuery.h 及 Apple [completion handler](https://developer.apple.com/documentation/healthkit/hkobserverquerycompletionhandler) / [observer queries](https://developer.apple.com/documentation/healthkit/executing-observer-queries)；确认是在处理资料完成后确认。官网普通页面依赖 JS，读取其官方 Markdown 版本核验正文。


### M2-R03 补充：失败缓存也需同一上下文

最终检查复现：练习排除区间改变后的睡眠查询失败仍返回旧 usual 缓存。新增可选 evidenceContextVersion（完整 Calendar 与排序的实际排除区间摘要），失败缓存仅在摘要已知且相同时复用。配置、来源、删除和新睡眠边界校验继续保留；不改模型参数。旧 schema 1 缺摘要仍可读取，不清库；遇读取失败时不将未知上下文缓存作为新请求结果。旧存储回归同时移除所有本轮可选新字段，核验兼容。
