# 方寸 V4 · 呼吸主场交付报告

2026-10-15。本轮交付原生 iOS 本地完整候选版，商店版本 **1.0 (2026101502)**，产品规划代号 V4。默认“呼吸／日常”两页、九项独立练习、角色分层动作、离线引导音频、真实活动时间与兼容保存均已接入。用户明确选择“本轮先交付可安装构建，真机稍后验收”；因此不是已完成真机验收或已发布版本。

- 源码：`/Users/yvainair/Code/fangcun`。
- 分支：`codex/fangcun-v4-breathing-hub`。
- 施工基准：`772644826638a420e79450716ab869cf87472d09`，开始时工作区干净；未回退 main、未清库。
- 最终源码 HEAD：以本报告所在最终本地提交及交付目录 `reports/DELIVERY_RECEIPT.json` 的 `sourceHEAD` 为准；收据在提交后生成，避免自引用 SHA。
- 交付：`/Users/yvainair/Downloads/Codex交付/方寸-V4-呼吸主场-2026-10-15`。`预览.html` 浏览截图、录像和真实语音样本；IPA 与详细报告同目录。

## 已完成范围

1. **呼吸主场**：九项功能用途、可选筛选、时长/档位、快速开始、原有记录；首页不再以健康连接或大分数为门槛。日常保留状态分、饮品、感受、轻行动、历史及设置。
2. **九项实际训练**：旧生理性叹息 3/2/7、节律 4/6、凯格尔 4/8 与旧 ID 不变；新增均衡 5/5、4/4，方块 3/3/3/3，膈肌自然引导，交替鼻孔左吸/右呼/右吸/左呼；完整冥想 5/10 分钟、NSDR 10/20 分钟脚本。
3. **角色**：保留认可原画身份，以四张母版提取 40 个透明图层。九种场景含单猫、单狗、双角色；头、眼、爪、尾、躯干、道具独立组合，胸腹局部形变，非整张立绘缩放。坐到躺有三张真实关键姿势；入场可跳过且不计训练时间。
4. **声音和时间**：所有音频离线随包；保留 16 条旧音频原字节，新增/派生 70 条。六套完整自然引导脚本。视觉、声音、触觉读取统一训练快照；暂停不累计时间、不补发旧口令，恢复安全起步。新 voice 是 Edge TTS `zh-CN-XiaoxiaoNeural`，原 `zhixingnv` 的准确生产音色编号仍未知，不能宣称与旧声线完全同源。
5. **记录兼容**：新增可选、版本化 metadata，不重写旧历史；活动区间、会话 ID、完整轮次和可选反馈可恢复；损坏草稿保留隔离，不清库。先本地保存，再处理健康同步；失败重试不重复建记录。完成练习不增加状态分。
6. **Watch 边界**：旧五项能力保留并可编译；新记录以能力协商决定同步，不把新方法改写成旧方法。此次没有声称 Watch 已支持全部九项。

## 验证与证据

实际命令、退出码、首次失败与修复见 [VERIFICATION.md](VERIFICATION.md)。逐文件清单见 [CHANGED_FILES.md](CHANGED_FILES.md)，旧入口对应见 [UI_MIGRATION.md](UI_MIGRATION.md)。时间线和数据逐项测试见 [DATA_AND_TIMELINE_VERIFICATION.md](DATA_AND_TIMELINE_VERIFICATION.md)，声音边界见 [AUDIO_DEVICE_ACCEPTANCE.md](AUDIO_DEVICE_ACCEPTANCE.md)。

原生媒体均由 iOS 模拟器实际运行采集，数据为 UI 测试合成数据；无浏览器原型截图冒充。录像不带模拟器输出音频，试听样本单列，未后期混音来伪装音画同步。录像时间标记用于裁切，不作为 ≤100ms 延迟测量证据。长录屏一次因测试 600 秒上限中止，保留原失败结果，未完成的冥想和 NSDR 独立补录；不把采集超时隐藏成通过。

评分源码、V3 固定样例、参考规则及旧音频基准保持字节一致，见 [preserved-baseline-files.json](evidence/preserved-baseline-files.json)。无新增健康授权、账户、遥测或产品后端。源图和音频生产来源及 hashes 见 [ASSET_MANIFEST.json](ASSET_MANIFEST.json)。

## 明确未验证

- 真机覆盖安装、原有用户数据/偏好回读、真实 HealthKit 写入、实际 Watch 配对及后台同步。
- NSDR 连续 20 分钟真实锁屏声音；耳机移除、电话中断、路由变化和实际恢复；静音锁屏行为的真机检查。
- 真实设备音画触觉 ≤100ms 对齐、长时能耗/温升、用户对新旧音色一致性和新角色的主观认可。
- 已完成模型/资源/模拟器检查，不等于以上设备项目通过。相关项保持 `implemented_unverified` / `deferred_by_user`。

## 安装包

签名 Development 导出，最低 iOS 18，bundle ID `com.yvainair.InnerBalance`；只适用于现有开发签名允许的设备。Archive、export、签名完整性检查均有本地证据。IPA SHA-256 与字节大小见 [build-public-receipt.json](evidence/build-public-receipt.json)。

稍后连接已登记、已解锁的 iPhone，可在 Xcode Devices and Simulators 的 Installed Apps 中选择交付 IPA 覆盖安装；不要先卸载旧方寸，以保留记录。安装完成需再回读版本/构建号、记录和偏好。此次按用户要求不进行真机安装，也没有推送 GitHub、上传 TestFlight、合并 main 或正式上架。
