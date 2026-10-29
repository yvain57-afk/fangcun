# Little Exhale 2.0 · 发布结果

2026-10-29 实际核验。版本 **2.0.0**，构建 **2026102801**。仍是原方寸 App，App ID 6818437987、Bundle ID 不变。

## 发布状态

- **TestFlight 内部测试已开放**：原“开发自测”组，1 个既有测试员，构建 2.0.0（2026102801）显示“正在测试”。可在该账号的 TestFlight 查看新版。本轮没有替用户操作手机安装，不能声称手机已更新。
- **App Store 已提交正式审核**，状态“正在等待审核”。审核单：5fe3a7f4-812c-42a7-898c-513b019d22c0。通过后按既有自动发布设置发布，当前线上 1.0 保持可用。
- [查看正式审核单](https://appstoreconnect.apple.com/apps/6818437987/distribution/reviewsubmissions/details/5fe3a7f4-812c-42a7-898c-513b019d22c0)
- 外部“朋友体验”组提交仍返回 Apple 的“处理你的请求时出错。请稍后再试。”，未成功进入 Beta 审核，不能声称外部公开测试已开放。已复验会话与测试资料，不继续无信息重试。

## 商店资料

Little Exhale 名称、副标题、英文描述、关键词、更新内容和审核说明已保存并随更新提审。中英文商店页各关联 6 张新版 1206×2622 原生 iPhone 截图，Watch 各关联 1 张 416×496 英文截图，均远程回读确认。旧版截图仅移除页面引用，原件仍在 Apple 素材库。

主语言切换为英语被 Apple 的“所有版本必需截图”校验拒绝，现保留简体中文主语言；独立美国英文商店本地化已随 2.0 提交，App 自身为英文界面和引导。没有为改语言撤回审核。

## 内容和验证

- 完整英文品牌、Breathe／Daily、十种练习与 171 条英文离线语音；保留原训练参数、节拍、用户记录、偏好及健康模型/golden fixtures。
- 猫狗使用已认可原画的透明分层，动作按训练时间线驱动。
- 55 张原生截图、10 段训练/暂停/继续录像，均为合成测试数据；原图原录像和 provenance 哈希记录保留。
- 已完成验证：Core 173 项通过，App 235 项通过，选定原生 UI 最新 25 项通过，商店手机截图专项 1/1 通过，Watch 模拟器编译通过，Release 分发签名和 171 音频资源校验通过。发布续办未改生产代码，不重复重跑已通过测试。
- 上传命令 exit 0，Apple 处理完成；内部测试组“正在测试”和正式审核“等待审核”分别核验。

## 验收边界

本轮没有真机升级、锁屏/蓝牙音频、实际触觉、真实 HealthKit 或 Watch 同步验收。录屏不是硬件音频/触觉证据。语音实际来源仍为 Edge TTS；商业分发权未独立核验，未作新的权利声明。无新增收费、订阅、后台或监控任务。

## 交付文件

- 正式审核提交回执.png、TestFlight内部测试回执.png：Apple 后台真实回执。
- 原生界面与动作验收.html：55 张截图与 10 段录像总览。
- screenshots/、videos/ 及 provenance.json：原始媒体与来源。
- 商店截图清单.json：已上传并回读的 6 张原生商店截图。
- 工程：/Users/yvainair/Code/fangcun，独立分支 codex/little-exhale-2。
- 分发包：/Users/yvainair/Code/fangcun/.build/little-exhale-2/DistributionR2/InnerBalance.ipa。
- 实时发布记录：/Users/yvainair/Code/fangcun/docs/releases/little-exhale-2/release-state.json。
