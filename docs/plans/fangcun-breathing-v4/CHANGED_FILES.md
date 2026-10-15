# V4 修改文件

比较基准：`772644826638a420e79450716ab869cf87472d09`。开始施工时工作区干净，未回退旧 main；本表只列本轮项目变更。构建、签名文件与原始结果包在 gitignored `.build/`，不列为仓库源码。

旧入口迁移表见 [UI_MIGRATION.md](UI_MIGRATION.md)。评分和旧音频逐字节保留证明见 [preserved-baseline-files.json](evidence/preserved-baseline-files.json)。

| 文件 | 修改原因 |
|---|---|
| `"docs/plans/fangcun-breathing-v4/00_\345\205\210\350\257\273_\344\272\244\344\273\230\350\276\271\347\225\214.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/01_\344\272\247\345\223\201\344\270\216\344\272\244\344\272\222\350\247\204\346\240\274.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/02_\344\271\235\351\241\271\347\273\203\344\271\240\344\270\216\345\212\237\350\203\275\346\226\207\346\241\210.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/03_\347\214\253\347\213\227\345\212\250\344\275\234\345\257\274\346\274\224\344\270\216\347\264\240\346\235\220\350\247\204\350\214\203.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/04_\351\237\263\351\242\221\344\270\216\350\212\202\346\213\215\350\247\204\346\240\274.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/05_\345\267\245\347\250\213\345\256\236\347\216\260\344\270\216\345\205\274\345\256\271.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/06_\346\225\264\347\211\210\351\252\214\346\224\266\344\270\216\344\272\244\344\273\230\346\270\205\345\215\225.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/07_\350\265\204\346\226\231\344\270\216\346\240\270\345\257\271\350\214\203\345\233\264.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/CODEX_\346\211\247\350\241\214\346\217\220\347\244\272\350\257\215.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/\345\256\214\346\225\264\350\247\204\345\210\222_\345\220\210\350\256\242\346\234\254.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `"docs/plans/fangcun-breathing-v4/reference/\346\226\271\345\257\270App\347\216\260\347\212\266\344\270\216\350\256\276\350\256\241\347\273\206\350\212\202_GPT\350\247\204\345\210\222\347\211\210.md"` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `InnerBalance/InnerBalanceApp/App/RootView.swift` | 呼吸/日常两页；复用统一会话、记录和通知路由，未完草稿不被覆盖。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-body.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-body.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-closed.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-closed.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-crouch.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-crouch.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-exhale.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-exhale.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-flower.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-flower.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-head.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-head.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-leaf.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-leaf.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-mat.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-mat.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-paw-left.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-paw-left.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-paw-right.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-paw-right.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-poster.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-poster.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-tail.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-cat-tail.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-body.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-body.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-closed.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-closed.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-crouch.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-crouch.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-ear-left.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-ear-left.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-ear-right.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-ear-right.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-flag.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-flag.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-head.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-head.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-leaf.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-leaf.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-paw-left.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-paw-left.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-paw-right.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-paw-right.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-poster.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-poster.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-tail.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-dog-tail.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-blanket.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-blanket.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-body.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-body.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-closed.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-closed.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-crouch.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-crouch.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-ear-left.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-ear-left.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-ear-right.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-ear-right.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-head.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-head.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-legs.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-legs.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-paw.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-paw.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-pillow.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-pillow.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-poster.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-poster.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-prone.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-rest-prone.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-torso-cat-side.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-torso-cat-side.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-torso-cat.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-torso-cat.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-torso-dog-side.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-torso-dog-side.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-torso-dog.imageset/Artwork.png` | 独立透明角色/表情/道具生产像素，来源、裁切和 SHA 见素材清单。 |
| `InnerBalance/InnerBalanceApp/Assets.xcassets/PracticeV4-torso-dog.imageset/Contents.json` | 声明对应原画图层的原生图片资源。 |
| `InnerBalance/InnerBalanceApp/DesignSystem/FangcunCompanion.metal` | 追加脚底/颈部锚定的 V4 胸腹形变，旧角色 shader 保留。 |
| `InnerBalance/InnerBalanceApp/DesignSystem/PracticeCompanionV4.swift` | 原画分层、九项场景、坐到躺关键姿势、局部教学与有限表情。 |
| `InnerBalance/InnerBalanceApp/Features/Home/BodyLoadSectionComponents.swift` | 新增方法枚举穷尽分支；保留原状态模块行为。 |
| `InnerBalance/InnerBalanceApp/Features/Home/FangcunTodayView.swift` | 原状态分、饮品、感受与轻行动聚合到日常；补记录与设置入口。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/BreathingFieldPlayer.swift` | 相位主提示和原画猫狗读取实际训练时钟。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeActiveStage.swift` | 按真实方法选择专用播放器，保持动态字号和教学文字。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeAudioController.swift` | 独立分层音量、真实环境声、ducking、按相位截断。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeAudioCoordinator.swift` | 同一快照驱动的音频事件调度及恢复 generation。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeAudioLifecycle.swift` | 中断/耳机移除停止，静音后台暂停，有可听环境声才后台继续。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeAudioPlan.swift` | 离线逐字语音与相位/段落映射、seek 与窗口截止。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeCadenceController.swift` | 触觉读取共享时间线，不补发过期节拍。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeCompletionSaveController.swift` | 统一 UUID 保存、反馈可跳过、失败不报成功，保存后清理对应草稿。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeCompletionScreens.swift` | 实际时长、三选/跳过反馈及保存成功确认。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeLibraryComponents.swift` | 原目录组件接新方法语义，保留既有样式与可达性。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeLibraryView.swift` | 九项主页/筛选/详情/时长/档位/原记录，预览按可见性调度。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeNonBreathingStages.swift` | 自然训练、身体扫描与盆底收放各自独立语义/场景。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticePreparationComponents.swift` | 膈肌、交替鼻孔、凯格尔人体动作教学与可访问说明。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticePresentation.swift` | 九项用途/步骤/提示、真实完成语义及渲染节奏决策。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSessionContent.swift` | 新版准备/训练/反馈/保存成功状态组合。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSessionDialogs.swift` | 提前结束和保存失败的真实可恢复路径。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSessionDraftStore.swift` | 确认时间点保存/恢复；损坏草稿保留隔离；UI 测试使用独立存储。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSessionScreens.swift` | 可跳过入场、恢复前准备、可取消前台重绘。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSessionView.swift` | 同一会话传递档位/草稿，正式训练前收稳入场。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSessionViewModel.swift` | 单调活动时间、相位恢复、真实区间、幂等结束与可恢复草稿。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSoundControls.swift` | 真实模式标签、资源可用性及三层音量控制。 |
| `InnerBalance/InnerBalanceApp/Features/Practice/PracticeSoundPreferences.swift` | 声音包升级保留旧静音/节奏选择，新增音量不覆盖原偏好。 |
| `InnerBalance/InnerBalanceApp/Features/Recovery/RecoveryCoordinator.swift` | 新增方法兼容旧轻行动协调器，不改评分模型。 |
| `InnerBalance/InnerBalanceApp/Features/Settings/SettingsView.swift` | 从日常可达，原显示/权限/诊断/关怀保留，声音入口补齐。 |
| `InnerBalance/InnerBalanceApp/Persistence/PracticeCompletion.swift` | 可选版本化 metadata、旧记录读取、幂等保存和真实 HealthKit 活动区间。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_180_0.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_180_1.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_180_2.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_180_3.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_180_4.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_180_5.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_180_6.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_300_0.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_300_1.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_300_2.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_300_3.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_300_4.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_300_5.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_diaphragmaticBreathing_300_6.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_hold.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_kegel_release.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_left_exhale.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_left_inhale.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_300_0.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_300_1.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_300_2.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_300_3.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_300_4.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_300_5.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_300_6.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_300_7.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_600_0.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_600_1.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_600_2.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_600_3.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_600_4.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_600_5.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_600_6.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_600_7.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_meditation_600_8.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_0.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_1.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_10.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_11.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_12.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_13.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_14.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_15.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_2.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_3.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_4.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_5.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_6.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_7.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_8.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_1200_9.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_0.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_1.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_10.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_11.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_12.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_13.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_14.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_2.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_3.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_4.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_5.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_6.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_7.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_8.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_nsdr_600_9.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_paced_exhale.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_paced_inhale.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_right_exhale.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceApp/PracticeVoice/practice_v4_right_inhale.m4a` | 新增离线引导或原声响度派生片段；逐字脚本、窗口和 SHA 见 AUDIO_ASSETS.json。 |
| `InnerBalance/InnerBalanceTests/FangcunResponseLoopTests.swift` | 覆盖所修改的协议、计时、资源、存储/同步或展示行为；具体测试见验证索引。 |
| `InnerBalance/InnerBalanceTests/Features/PracticeAudioV4Tests.swift` | 覆盖所修改的协议、计时、资源、存储/同步或展示行为；具体测试见验证索引。 |
| `InnerBalance/InnerBalanceTests/Features/PracticePresentationTests.swift` | 覆盖所修改的协议、计时、资源、存储/同步或展示行为；具体测试见验证索引。 |
| `InnerBalance/InnerBalanceTests/Features/PracticeSessionViewModelTests.swift` | 覆盖所修改的协议、计时、资源、存储/同步或展示行为；具体测试见验证索引。 |
| `InnerBalance/InnerBalanceTests/Features/RecoverySessionTests.swift` | 覆盖所修改的协议、计时、资源、存储/同步或展示行为；具体测试见验证索引。 |
| `InnerBalance/InnerBalanceTests/Persistence/PracticeCompletionStoreTests.swift` | 覆盖所修改的协议、计时、资源、存储/同步或展示行为；具体测试见验证索引。 |
| `InnerBalance/InnerBalanceUITests/BreathingHubV4UITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/CheckInFlowUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/DrinkEditorUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/ExperienceV2SceneUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/ExperienceV2UITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/FangcunAppearanceUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/FangcunRedesignUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/FangcunResponseLoopUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/HomeEvidencePipelineUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/PracticeReturnHomeUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/ReadinessHomeUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/RecoveryActionUITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceUITests/StatusScoreV3UITests.swift` | 按新两页入口迁移真实 UI 行为回归；保留相关断言，新增 V4/录像验收。 |
| `InnerBalance/InnerBalanceWatch/Features/Practice/WatchPracticeView.swift` | 新增枚举兼容；Watch 仍只执行原五项，不冒充九项上线。 |
| `InnerBalanceCore/Sources/InnerBalanceCore/Practice/PracticeBreathGuide.swift` | 新增停留/左右/自然语义，旧节拍保持。 |
| `InnerBalanceCore/Sources/InnerBalanceCore/Practice/PracticeCatalog.swift` | 保留旧目录参数并提供 V4 九项目录。 |
| `InnerBalanceCore/Sources/InnerBalanceCore/Practice/PracticeHapticCadence.swift` | 依照新相位和盆底收放发出触觉计划，不独立累计训练时间。 |
| `InnerBalanceCore/Sources/InnerBalanceCore/Practice/PracticeKind.swift` | 新增四个稳定方法 ID，保留旧五个 raw value 与 Watch 可执行边界。 |
| `InnerBalanceCore/Sources/InnerBalanceCore/Practice/PracticeSessionMetadata.swift` | 共享协议版本、活动区间、档位、轮次与实际反馈载体。 |
| `InnerBalanceCore/Sources/InnerBalanceCore/Practice/PracticeTimeline.swift` | 九项实际相位、变速档位与六条完整自然引导时间线。 |
| `InnerBalanceCore/Sources/InnerBalanceCore/Sync/SyncModels.swift` | 增加 V4 练习记录能力声明。 |
| `InnerBalanceCore/Sources/InnerBalanceCore/Sync/SyncService.swift` | 按对端能力决定新记录发送；降级清理能力缓存。 |
| `InnerBalanceCore/Sources/InnerBalanceCore/Sync/SyncStore.swift` | 保留不支持的新方法记录等待安全同步。 |
| `InnerBalanceCore/Tests/InnerBalanceCoreTests/PracticeCatalogTests.swift` | 覆盖所修改的协议、计时、资源、存储/同步或展示行为；具体测试见验证索引。 |
| `InnerBalanceCore/Tests/InnerBalanceCoreTests/PracticeTimelineV4Tests.swift` | 覆盖所修改的协议、计时、资源、存储/同步或展示行为；具体测试见验证索引。 |
| `InnerBalanceCore/Tests/InnerBalanceCoreTests/Sync/PracticeSyncV4Tests.swift` | 覆盖所修改的协议、计时、资源、存储/同步或展示行为；具体测试见验证索引。 |
| `README.md` | 当前入口和核验指向 V4，旧图与旧发布记录明确为历史。 |
| `docs/plans/fangcun-breathing-v4/ASSET_MANIFEST.json` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/AUDIO_ASSETS.json` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/AUDIO_DEVICE_ACCEPTANCE.md` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/AUDIO_IMPLEMENTATION.md` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/AUDIO_PRODUCTION.json` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/CHANGED_FILES.md` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/DATA_AND_TIMELINE_VERIFICATION.md` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/IMPLEMENTATION.md` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/PACKAGE_MANIFEST.json` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/PROTOCOL_SESSION_NOTES.md` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/REPORT.md` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/SPEC_VALIDATION.txt` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/UI_MIGRATION.md` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/VERIFICATION.md` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/art/PRODUCTION_PROMPTS.json` | 原画母版、提示词及图层来源；不覆盖已认可旧原画。 |
| `docs/plans/fangcun-breathing-v4/art/cat-atlas-source.png` | 原画母版、提示词及图层来源；不覆盖已认可旧原画。 |
| `docs/plans/fangcun-breathing-v4/art/dog-atlas-source.png` | 原画母版、提示词及图层来源；不覆盖已认可旧原画。 |
| `docs/plans/fangcun-breathing-v4/art/layers.json` | 原画母版、提示词及图层来源；不覆盖已认可旧原画。 |
| `docs/plans/fangcun-breathing-v4/art/rest-atlas-source.png` | 原画母版、提示词及图层来源；不覆盖已认可旧原画。 |
| `docs/plans/fangcun-breathing-v4/art/torso-atlas-source.png` | 原画母版、提示词及图层来源；不覆盖已认可旧原画。 |
| `docs/plans/fangcun-breathing-v4/config/companion_scenes.v4.json` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/config/copy.zh-Hans.v4.json` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/config/guided_scripts.zh-Hans.v4.json` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/config/practices.v4.json` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `docs/plans/fangcun-breathing-v4/evidence/audio/candidate-comparison.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/audio/candidate-xiaoxiao.mp3` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/audio/candidate-xiaoyi.mp3` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/audio/legacy-loudness.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/audio/new-loudness.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/build-public-receipt.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/expression-capture.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/final-app.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/full-regression.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/guided-final.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/initial-regression.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/native-capture-initial-limit.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/preserved-baseline-files.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/recovery-final.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/evidence/recovery-native-button-tap.json` | 合成测试/保留基准/构建核验材料；原始设备与签名材料留 .build。 |
| `docs/plans/fangcun-breathing-v4/validate_spec.py` | 本轮附件规格、实现/迁移说明或实际核验记录。 |
| `scripts/art/build_practice_asset_manifest.py` | 可复现原画裁切或素材来源与校验清单生成。 |
| `scripts/art/slice_practice_atlas.swift` | 可复现原画裁切或素材来源与校验清单生成。 |
| `scripts/audio/check_practice_audio_loudness.py` | 构建期离线音频生产、窗口和响度校验；不是 App 网络功能。 |
| `scripts/audio/render_practice_audio_v4.py` | 构建期离线音频生产、窗口和响度校验；不是 App 网络功能。 |
| `scripts/audio/validate_practice_audio_v4.py` | 构建期离线音频生产、窗口和响度校验；不是 App 网络功能。 |
