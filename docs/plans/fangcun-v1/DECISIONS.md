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
