# 方寸 2026102001：TestFlight 分发记录

核验日期：2026-10-21（Asia/Taipei）。版本 1.0.0（2026102001）；Bundle ID com.yvainair.InnerBalance。

## 已完成

- 复用已安装到 iPhone 的已验证签名归档，重新导出 App Store Connect 分发包。归档源码提交 9c3ad57d09e92e9846ca5225403ee9935e954612；本轮开始的 HEAD 698ceae62b2364f7cf13c39d33306ae9a557b98c 相对它仅有安装验收文档变化，没有改训练参数、节拍、语音、数据或权限。
- xcodebuild 分发导出与上传均正常退出 0，上传日志明确 Upload succeeded。分发 IPA 的 codesign --verify --deep --strict 正常退出 0；包内 140 个新音频 SHA256 与已审阅版本的生产清单全部一致。
- App Store Connect 从“正在处理”转为可配置的构建，保存简体中文测试内容后，将新构建加入原有“开发自测”和“朋友体验”；保留所有旧构建与现有测试员，没有新建分组或扩大人数上限。
- 保留勾选的“自动通知测试员”，提交 TestFlight 测试审核。主构建列表回读 2026102001 为“正在测试”，关联两个原有组。
- 单独进入“朋友体验 → 构建版本”再次核验：1.0.0（2026102001）显示“正在测试、90 天后过期”。这不是仅凭内部测试状态推断外部可用，也不把“正在测试”等同正式 App Store 上架或人工完成了全部审核。
- 原公开邀请链接仍为 https://testflight.apple.com/join/tt8NVFJE ，页面可见原上限 20 人；未修改该上限。

## 测试说明

已保存本轮新版九项引导、可暂停/跳过且不占训练时间的开场、按方法记住跳过、独立十分钟肌肉放松和日间/睡前结尾。文案见 metadata/what-to-test.zh-Hans.txt。

本次只有重签名与分发，没有改 App 源码，因此不重复此前已通过的 Core 170、App 228 及相关 UI 回归；它们的实际结果见 docs/content/guidance-integration-20261020/VERIFICATION.json。上传、Apple 处理、分组和外部状态均为本次重新核验。

## 分发命令与证据边界

实际执行两次 xcodebuild -exportArchive，源归档均为 .build/guidance-integration-20261020/Fangcun-2026102001-verified.xcarchive：

1. -exportPath .build/testflight-20261021/Distribution -exportOptionsPlist .build/testflight-20261021/ExportOptions.private.plist -allowProvisioningUpdates，method=app-store-connect，destination=export。
2. -exportPath .build/testflight-20261021/Upload -exportOptionsPlist .build/testflight-20261021/UploadOptions.private.plist -allowProvisioningUpdates，method=app-store-connect，destination=upload。

manageAppVersionAndBuildNumber=false，保留原 2026102001 构建号。私有签名选项、完整上传日志、分发 IPA 与归档仅留本机忽略目录；公开回执仅含版本、散列、退出码与脱敏状态。不上传手机健康数据、容器备份、个人健康截图、设备标识或凭证。

## 尚未发生的事项

正式 App Store 仍未提交或发布。此前用户要求另行解决正式版配音授权，此停止点保留。

本轮没有再次操作手机或替换用户记录。此前同版本的本地覆盖安装与数据保留已经验证，但本轮没有将测试员真实从 TestFlight 下载、安装、首次启动或完整试听写成通过。真实锁屏/来电/耳机声音和 Watch 验收边界不变。
