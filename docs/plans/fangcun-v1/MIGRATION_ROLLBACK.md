# M1 数据影响与回退

- 未改 HealthKit 类型/授权、SwiftData 模型、练习写入与去重、Watch 传输、饮品单位或旧条目。
- `fangcun.native.diary.v1` 的日快照新增可选 `semanticsVersion`；旧 JSON 缺少该字段仍可解码，阅读本身不重写 archive。
- 旧版 steady / elevated / insufficient 原始值保留；旧标题、summary、sleep、training 不回算。当天已有 legacy 时，新版另存 M1 快照，并保留旧版供查看。
- 第一次改写已有 archive 前，原数据写到本机 `fangcun.native.diary.preM1`，后续不覆盖备份；备份和健康数据都不会上传 Git。
- 新增 watch / limited 原始值旧 App 不认识，因此**不能只退二进制并继续读取新版 archive**。需要回退时先导出当前完整 archive 留存新增饮品/快照，再在单独受控步骤恢复 preM1 字节；这会回到备份时点，不能无提示丢弃期间新记录。优先采用向前修复。
- 本轮不自动执行恢复/清库。M3 再做完整版本化存储及显式迁移工具。
- 回归覆盖：原 v1 读取不修改字节、legacy 原语义、同日新旧共存、原始备份不被第二次写覆盖、复合饮品撤销与跨日行为、损坏数据不覆盖。
- 代码按 M0、M1 独立提交；`main` 保持基线。未 reset/stash/clean 原 Developer 工作区。
