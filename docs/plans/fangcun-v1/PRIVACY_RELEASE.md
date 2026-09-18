# M0–M1 隐私与发布检查

- 无新网络调用、账号、遥测、联网 AI 或付费依赖。
- 无新增 HealthKit 读取/写入类型、后台模式、App Groups 或通知授权。能力探针不加入正式 App。
- 测试截图全部为空数据或 Synthetic Watch 合成数据；不上传真机健康截图。
- 不提交证书、描述文件、设备唯一标识、签名团队、本机配置或本地 archive。
- DEBUG fixture 与 preview 参数不会进入 Release；真机运行使用现有 HealthKit provider。
- 本轮没有 App Store / TestFlight 上传；M2–M6 未实施部分保持未完成。
