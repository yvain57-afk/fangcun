# M3 合成截图

所有图片均来自独立 UI 测试存储和合成 provider，不包含真实健康信息、个人笔记或物理设备标识。

- `readiness-home-*.png`：六种原始fixture经实际pipeline/store/owner形成现行首页；按钮保持五分钟主入口。
- `readiness-dark-large-home.png` / `readiness-dark-large-detail.png`：大字号、深色、长英文来源。来源名是明确的Synthetic名称。截图采集后将旧“夜间中位数”标签统一为“主睡眠内中位数”，支持白天主睡眠语义，未改布局或计算。
- `readiness-detail-times.png`：滚动后的实际详情时间字段。
- `action-feedback.png` / `action-feedback-after-edit.png`：本地行动结束、跳过/编辑反馈与不适过滤。
- `breathing-paused.png`：原呼吸练习暂停。
- `home-light.png`：明确readiness关闭的M1视觉回归，不能作为新准备度接入证据。

当前首页6场景和详情/历史测试证据：`m3-detail-delivery.xcresult`；最终主睡眠标签复验：`m3-copy-final.xcresult`。原始结果包和附件manifest含模拟器标识，仅留在本机scratch；仓库只保留这些合成PNG和脱敏测试摘要。
