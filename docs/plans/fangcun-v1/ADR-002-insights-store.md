# ADR-002：独立本机评估存储

状态：M2 采用；既有 SwiftData、Diary、练习、饮品及偏好存储不迁移、不清空。

## 选择与范围

采用 `InsightsStore` actor，位于 App 的 Application Support/FangcunInsights。M2 的对象是规范化健康样本、锚点、选源、睡眠段、版本化评估与删除审计；没有新增背景事件、跨端 outbox、提醒 ledger 或 Widget 文件，这些仍属于后续阶段。

与扩展旧 SwiftData schema 相比，独立 Codable 快照无需迁移用户旧记录。当前只缓存四类低频资料及 35 天原始样本，整份原子快照可审查、可注入故障。将来引入高频数据或较长历史时应重新测量规模，再决定数据库迁移，不能把当前方案视为无限容量方案。

## 文件及提交协议

- `insights-v1.json`：schemaVersion、校验和及 payload；样本、游标、来源、评估在同一个原子替换中发布。
- `insights-v1.previous.json`：上一次完整快照，作为损坏恢复入口。
- `deletions-v1.json`：优先提交的删除屏障，只保存 UUID tombstone 和 clear epoch。它不能提供数值、设备身份或健康结论。
- 每个目录由一个应用级 actor 独占；generation 比较防止迟到任务覆盖切源、删除和清除。M2 不支持两个进程共同写入此 store；Widget 不应打开业务库。
- iOS/watchOS 文件采用 completeFileProtectionUntilFirstUserAuthentication，目录 0700、文件 0600，并排除系统备份。不增加 App Group、HealthKit 或后台权限。

先提交删除屏障，再清理旧快照／备份，然后发布新快照。任何恢复都先应用屏障；初始化完成中断删除的磁盘清理。损坏 primary 可从 previous 恢复，但清空锚点、撤销当前资格并要求重新查询。删除 journal 损坏、未知 schema 或两份快照均坏时失败关闭，保留文件，不伪装空的健康状态。

明确清除递增 epoch，阻止在途旧事务；保留无数值 tombstone 防止旧样本重放。35 天限制针对原始样本，评估修订与最小删除标记不会按日默默清除。显式用户清除移除评估和旧审计，只保留删除屏障。

## 评估修订和重放

同周期相同输入保留 assessmentID/revision；语义输入改变生成递增 revision 和 supersedesID。输入摘要包括指标、样本标识、来源段、来源说明、基线、睡眠、配置和时区，不包括查询/计算刷新时钟。删除影响过的旧评估只留 ID、周期、revision、原因，不保留数值或来源摘要。

`ReadinessPipeline` 对并发刷新单飞；按类型最多读取 100 页、每页平台上限 500 项，单次没有无限循环。每次提交只推进已纳入事务的页面。失效锚点仅重试一次无锚点回读，清掉该指标旧缓存后重建，不能把上次未返回的值继续当当前输入。空读不推断授权拒绝。

## 实测依据与边界

`InsightsStoreTests` 覆盖提交前失败、发布后返回前失败、删除屏障后中断、主文件损坏、journal 损坏、未知 schema、分页删除、迟到修订、重复刷新、切源/清除与旧请求竞争、单飞和失效锚点回读。

故障实验使用真实临时文件和合成数据；故障点通过可控异常模拟进程中断。没有声称已经完成断电硬件实验、锁屏保护真机实验、系统后台交付或多设备同步。UI 与生命周期尚未接入新 service；M2 交付的是可调用、可持久化、可重放的数据链路，M3 之后才替换页面消费者。
