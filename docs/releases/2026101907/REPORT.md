# 方寸 2026101907：TestFlight 与正式上架准备

核验日期：2026-10-19。App Store ID：6818437987；Bundle ID：com.yvainair.InnerBalance。

## 当前实际状态
- 1.0.0（2026101906）和 1.0.0（2026101907）上传正常退出，Apple 已处理完成。
- 最新 2026101907 已加入原“开发自测”和“朋友体验”；外部组后台回读“正在测试”，自动通知开启。旧构建保留。
- 邀请入口：https://testflight.apple.com/join/tt8NVFJE 。上传、处理和分组已验证；本次没有把测试员实际下载安装写成通过。
- 正式 App Store 仍为“准备提交”，未提交正式审核，也未正式发布。用户选择先保留 TestFlight，待另行解决配音授权后继续正式上架。

## 这次代码改动与数据边界
仅在 SettingsView.swift 的“隐私与数据”增加“完整隐私政策”和“使用支持与联系”两个系统 Link 及辅助功能标识。打开网页由用户点击触发，没有引入后台网络服务、广告或遥测。
训练方法、参数、Core 模型、golden fixtures、权限、存储字段和迁移均未修改。没有清库，没有重新安装到手机；手机此前的 2026101906 开发安装与本次 TestFlight 分发是独立步骤。

## 已完成的商店准备
- “方寸”名称已被占用，成功保存品牌名称“方寸 Fangcun”，副标题“呼吸与身心练习，猫狗陪你放松”。
- 主类别健康健美，按实际功能回答年龄问卷，Apple 计算为 13+；不作医疗器械声明。保留现有 DSA 资料。
- 版本设为 1.0.0，中文描述、推广文案、关键词、技术支持/营销网址、版权年份、审核路径及既有审核联系人已保存；无需登录。
- 价格 $0.00，全部 175 个国家或地区，包含中国大陆。供应选择不等于已获各地区上架批准；未填写虚构备案号，也未自动排除中国大陆。
- 发布隐私标签“未收集数据”，保存公开政策 URL。该标签对应设备内数据处理、没有开发者后台接收健康或个人记录；不是“App 不读取健康数据”。
- 七张 1206×2622、无 alpha 的真实模拟器界面截图已上传到 iPhone 中等灵动岛显示屏组；使用合成记录。Watch 商店截图、最终构建绑定及正式提交完整性检查尚未完成；正式提交按用户要求暂停。
- 网站经用户明确批准发布，允许公开现有 TestFlight 反馈邮箱。GitHub Pages 的首页、privacy.html、support.html 均 HTTP 200，内容与批准的本机版本一致。
- 网站独立分支 codex/store-support-site，提交 c3043d032d4a8955a96d70aa368dd96d17386a70；没有合并 main。

## 验证
1. App 回归：xcodebuild test，InnerBalance scheme，iOS Simulator，only-testing:InnerBalanceTests，CODE_SIGNING_ALLOWED=NO。正常退出 0；PrivacyUpdate.xcresult 可读取，220 个测试函数，283 次运行，0 失败、0 跳过。
2. UI：xcodebuild test，only-testing:InnerBalanceUITests/FangcunAppearanceUITests/testCriticalScreensInCurrentAppearance，CODE_SIGNING_ALLOWED=NO。正常退出 0；PrivacyUI.xcresult 可读取，1/1 通过。覆盖首页、练习、日常、设置与隐私等关键页面的既有测试。
3. Release：xcodebuild archive，generic/platform=iOS，MARKETING_VERSION=1.0.0，CURRENT_PROJECT_VERSION=2026101907，正常退出 0；含 Watch companion 的归档成功。
4. 分发：xcodebuild -exportArchive，method=app-store-connect，导出正常退出 0；codesign --verify --deep --strict 通过；上传正常退出 0，2026-10-19 13:59:31 +08:00 显示 Upload succeeded，随后后台核对外部“正在测试”。
5. git diff --check 通过。当前改动不涉及 Core；不把此前 Core/全九项 UI 验证写成本次重新执行。

完整命令与结果摘要在 verification.json；结果包和含签名信息的原始日志只留在项目忽略目录 .build/appstore-release-20261019，不进入公开 Git。
运行时有既有模拟器 Watch 未配对消息及测试优先级反转警告；它们未造成测试失败。真实 Watch 后台同步、触觉、锁屏音频和 07 真机下载安装仍未本轮验收。

## 正式上架停止点
新引导的生产脚本使用 Edge TTS zh-CN-XiaoxiaoNeural；旧短句的原始音色来源也没有完整授权凭据。工程记录能证明生成来源，不能单独证明可公开随 App 分发的权利。未把它定性为侵权，也未勾选未经确认的“拥有第三方内容必要版权”。用户确认无现成授权，选择另行解决正式版配音。
之后需完成有明确分发权的声音方案及用户试听、必要替换构建、Watch 商店素材、最终正式提交完整性检查，再提交 Apple 审核。本轮没有擅自替换或移除声音。

## 链接
- TestFlight：https://testflight.apple.com/join/tt8NVFJE
- 隐私：https://yvain57-afk.github.io/fangcun/privacy.html
- 支持：https://yvain57-afk.github.io/fangcun/support.html
- Apple 截图规范：https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Apple 隐私规则：https://developer.apple.com/app-store/review/guidelines/#privacy
- Microsoft Q&A 授权询问（答复未提供可用授权文件，不能作为许可）：https://learn.microsoft.com/en-us/answers/questions/6032190/commercial-use-rights-for-microsoft-edge-read-alou
