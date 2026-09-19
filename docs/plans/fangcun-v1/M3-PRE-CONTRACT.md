# M3-PRE 契约依据

基线 b80f81c，工作区干净；Xcode 27 beta / Swift 6，既有 iOS 18 与 watchOS 11 targets 不变。工程运行于 Code/fangcun；测试/构建/结果包位于 Code scratch。设备初查中的可达 iPhone 后经 hardwareProperties.reality 复核为 simulated；当时物理 iPhone 不可达，Watch 连接不可用。交付末尾物理iPhone恢复可达后的分层实测见 M3-REVIEW。

品牌依据：`docs/CURRENT_DESIGN.md`、`web/docs/用户提供的完整设计规格.md` 1.1 和深色章节、`web/docs/方寸品牌使用规范-v1.md`。这些材料确认版画蓝 1B355A、暖纸白 FAF9F5、独立深色和局部柔橙，不支持原测试棕色契约。当前已接受原生深色/文字/橙色语义映射与网页版精确值不同，本轮保留原生选择，不整套重刷回网页颜色。

仅修改浅色次级文字：687584 → 677483（三通道各降低一级）；以 >=4.5 的原断言核验，不四舍五入通过。其他 19 个浅/深语义值仅在测试中修正为已接受的原生蓝色契约。截图使用合成模拟器状态核对浅色、深色、大字。

显示：当前 App 提供显式深色开关，未提供“跟随系统颜色”选项；测试其 light/dark 映射，不恢复强制浅色。系统无障碍字号不被 App 大字选项缩小，系统减少动态与 App 偏好取并集；真实偏好重启由既有 UI 测试覆盖。

提前结束：文案转入 String Catalog/CSV，稳定按钮标识 practice.finish.confirm。结束只转入保存/可跳过反馈流程，不能提前显示已经保存；旧精确整句断言改为 key 解析完整性、动作身份和非误导语义检查，真实保存路径由 UI 和既有持久化测试验收。

旧练习 UI：使用 practice.physiologicalSigh.60 → practice.prepare.start → practice.finish.confirm → 本地完成 → 今日真实 session ID 标记。未开始关闭则留在练习页、今日无新记录、重新进入仍为准备阶段；App 回归另确认无会话、无音频准备或残留激活。不缩短或跳过保存步骤。
