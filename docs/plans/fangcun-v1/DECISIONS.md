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
