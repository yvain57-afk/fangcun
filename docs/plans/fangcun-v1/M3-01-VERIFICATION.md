# M3-01：饮品与旧历史迁移

采用独立 `FangcunDiaryStorage`，保留 SwiftData schema、原练习/健康写入队列与原 UserDefaults 字节。先保存 v1 和 preM1 的受保护原始备份，读回校验，再解码导入；目标 envelope 包含 schema 2、payload 校验和、导入源摘要，与记录同一次原子替换。没有单独提前写“已迁移”标志。

当前 v1 的饮品集合为权威；preM1 只补充旧快照，不复活后来删除的饮品。快照保留原文字、semanticsVersion 和 legacy 标记，不转换为准备度。ID 与旧固定杯量/咖啡因估值保持；consumedAt 来自原 date，未知 recordedAt 和糖克数保持 nil。新增成分仍为估算。容量编辑仅缩放该条记录，未知酒精仍 nil；汇总对部分未知酒精另有提示。

写入失败不发布内存成功状态；可重新读取并重试。损坏源、损坏目标和未知 schema 保持原字节，明确只读错误，不自动清空。没有卸载 App。生产存档在 App Application Support 的受保护目录，测试使用独立 defaults / 临时目录。

UI 保留快捷复合记录，新增“补记或编辑”入口：今天及前 6 天、时间/容量、编辑和撤销。新记录含录入时间；旧记录不伪造录入时间。时间/容量校验不改变准备度模型。

验证：

- 原 4 个 FangcunDiaryTests 继续通过：[首次回归](evidence/m3-m301-existing.txt)。
- 最终 **9 App tests + 1 UI test，退出 0**：[日志](evidence/m3-m301-final.txt)、[可读取结果包摘要](evidence/m3-m301-final-summary.json)。`FangcunDiaryMigrationTests` 覆盖稳定 ID、2 条记录合计 630 ml / 170 mg / 10 g / 1 糖饮份、原文和备份摘要、三处中断重启、损坏源/目标、写失败重试、7 天/未来边界、容量编辑、撤销、未知量和 preM1 不复活删除。
- `DrinkEditorUITests.testCapacityEditingUndoAndQuickLogShareTheSameRecords` 实际从首页快捷记 250 ml，再进入编辑新增 500 ml，编辑为 750 ml 后撤销，回弹层验证总量 750 ml。
- 命令是 `xcodebuild test`，项目/方案/工具链与 M3-PRE 相同；选择 `InnerBalanceTests/FangcunDiaryTests`、`InnerBalanceTests/FangcunDiaryMigrationTests`、`InnerBalanceUITests/DrinkEditorUITests`。完整脱敏命令在日志首行。中间新增 8 项 App 回归也通过，最终补入防复活用例后为 9 项。

目前未操作真实用户记录，也未把本机存档上传。现有旧档从升级前版本读取仍可保留；本轮功能回退使用同一 v2 存档，不用旧模型重写历史。
