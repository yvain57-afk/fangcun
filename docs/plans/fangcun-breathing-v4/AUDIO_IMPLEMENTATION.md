# V4 声音实现与验证边界

核验日期：2026-10-15。离线素材制作完成；真实设备长时播放与听感仍需分开验收。

## 运行时

- 语音、提示音、触觉从 `PracticeSessionViewModel.timelineSnapshot` 的同一相位/段落读取；以 `timelineGeneration + cueID` 识别恢复后的新事件，取消独立相位秒数和 NSDR 25 秒轮播。
- 快照观察间隔 25ms，属于共享逻辑时钟观察，不能宣称实际蓝牙输出已经达到 100ms。
- 长脚本资源命名 `practice_v4_<segment.id>.m4a`。NSDR10/20分钟、冥想5/10分钟、膈肌3/5分钟共62个段落各说一次，按 `elapsedInPhase` 定位恢复位置。安静段落不循环口令。
- 相位提示音不积压；新事件清除过期语音与提示音。语音 slice 严格截止当前窗口，不为播完而修改训练秒拍。暂停清空动作声音，继续重新读取安全相位或当前段落。
- 播放语音时降低环境声，结束后渐回；三层音量独立、0 是真正静音，旧模式/环境声偏好保留。
- 后台延续仍要求真实持续环境声且音量大于 0；未添加 silent 音轨。耳机移除、系统中断停止音频并暂停会话。停止/结束不播放额外庆祝音。
- 将来资源损坏/丢失时显示“完整语音尚未就绪，可跟随文字练习”，不使用系统语音补洞。

## 制作来源与音色边界

既有 `zhixingnv` 只是应用语音包 ID。原16条m4a只有Remotion/ffmpeg编码元信息，没有可溯源的语音提供商或 voice ID。本轮先保留它们；用户补充“应该是EdgeTTS”后才沿已有Edge渠道制作，没有直接换用系统朗读。

本机既有 EdgeTTS 7.2.8 列表可用但合成返回HTTP403；项目 `.build/v4-audio-production/venv` 单独安装7.3.1后，Xiaoxiao/Xiaoyi两种中文女声合成均成功。没有修改其他App的环境或服务。

对同一句“用鼻子，轻轻吸气。”进行两候选的时长和log-mel特征距离比较，Xiaoxiao更接近原片段（0.148，对比Xiaoyi0.227）。**这只是候选选择依据，不是证明原声线身份的声纹鉴定，也不是听感验收。** 正式新增片段使用 `zh-CN-XiaoxiaoNeural`、rate `-6%`、pitch `-2Hz`；源音频出处与参数显式记录于 `AUDIO_PRODUCTION.json`。原16条文件不变。

新增68条Edge离线m4a：6个短相位（停留、四种左右动作、完全放松）和62个完整引导段落，另有2条仅做响度校正的原声节律吸/呼派生文件，共70个新增/派生文件，约5MB。所有逐字脚本在原窗口内完成，无需tempo调整、截字或延长协议。新片段按-24 LUFS目标归一，接近旧吸气片段实测-24.07 LUFS；文件开头25ms淡入。对编码后成品再测量并做纯gain校正，70条最终实测-24.10～-23.85 LUFS，最高真峰值-5.27 dBTP，没有削波。旧节律吸/呼原来相差3.05 LU，改用原声的响度派生副本后也进入该范围；原文件保留，节拍和语速未改。未新增持续喵叫、犬吠或哈欠。

生成只发送开发包内通用练习文字，不发送个人健康资料、设备信息或用户记录。App本身不调用Edge或任何在线语音服务；产物随App离线打包。

## 可复现命令

在工程根目录，生产环境仅用于构建期：

```sh
python3 -m venv .build/v4-audio-production/venv
.build/v4-audio-production/venv/bin/pip install 'edge-tts==7.3.1'
.build/v4-audio-production/venv/bin/python scripts/audio/render_practice_audio_v4.py
python3 scripts/audio/validate_practice_audio_v4.py
```

`render_practice_audio_v4.py` 按内容缓存源片段，按已核验SHA复用成品，不改旧文件。生产报错隐藏URL查询参数和身份材料。

验证脚本检查每个必需离线文件的真实ffprobe时长、窗口、ffmpeg信号音量和SHA；拒绝空音频、跨窗或削波，不用静音文件填充。

## 测试与结果

- 首次验证退出1：7个旧资源可用，67个缺失；随后恢复Edge生产，新增凯格尔“完全放松”使用新V4文件，旧文件保留。
- 最终窗口验证退出0：74个必需资源全部通过，缺失0、跨窗口0。新/派生资源70个，沿用旧资源4个；其他旧片段仍保留。
- 本轮音频Swift文件 `swiftc -frontend -parse`：退出0；仅语法检查，不冒充Xcode编译/真机验收。
- 新增 `PracticeAudioV4Tests.swift` 覆盖左右顺序、变速、两次停留事件、6条引导轨资源/窗口、恢复seek与相位截断、独立音量。由主任务统一运行App测试。
- `selectedVoicePackIsComplete` 完整资源断言保留，没有删除/放宽来回避缺素材。
- `PracticePresentationTests` 旧机械轮播断言按V4契约改为实际段落边界；旧“安装新音色重置偏好”断言改为保留已有偏好。

## 仍未验证

原声线与新增Xiaoxiao之间的人工听感一致性；真实设备20分钟NSDR声音/锁屏、蓝牙输出延迟、电话/系统中断与耳机移除实机表现。音频资源完整和模拟器自动测试不能替代这些验收。

## 补充响度核验

`evidence/audio/legacy-loudness.json` 记录16个原文件真实EBU R128响度；`evidence/audio/new-loudness.json` 记录70个新/派生文件编码后的真实响度和峰值。所有相邻新提示控制在0.25 LU跨度，仍沿用的原叹息与凯格尔收紧也接近-24 LUFS。

测试编译中的Swift宏问题仅将 `allSatisfy(\.shouldSpeak)` 改为等价显式闭包 `allSatisfy { $0.shouldSpeak }`，没有减少或放宽断言。
