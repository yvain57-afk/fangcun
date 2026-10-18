# 角色素材与动作

所有新图通过内置 image_gen 生成，参考工程中已认可的完整猫狗原图；透明背景，保留版画蓝/橙/奶油白，未用 SVG 或几何动物替代。原六张完整角色素材保留。

新增资产：
- Assets.xcassets/PracticeV5-cat-loaf.imageset/Artwork.png：闭眼蜷卧小猫，冥想与感受记录。
- Assets.xcassets/PracticeV5-dog-sleep.imageset/Artwork.png：脸枕前爪、身体趴卧小狗，节律长呼气和 NSDR。

生成参照：PracticeV4R-cat-sit、PracticeV4R-dog-sit。原始输出 exec-444972b3-2664-41bf-987a-1155f7ab2d28.png、exec-e228dd5d-8965-4d57-9e3c-0bb7dbc1c594.png。

提示词记录（生产约束）：
猫：Production asset for Fangcun iOS breathing app. Preserve approved hand printed cobalt/navy grainy thick outline, ivory solid body, orange right triangular ear, tiny round eyes and smiling w mouth, two short whiskers. ONE complete cozy curled loaf resting, head upright, eyes closed, forepaws tucked together, curled tail around left side. Connected silhouette, no seams/detached head/ears. No text, props, ground, shadows, gradients, 3D. Transparent outside, opaque ivory body. 10 percent margin. Meditation and resting pose, not a sprite sheet.
狗：Production illustration for Fangcun breathing app. Match approved pudgy ivory dog, grainy blue printed contour, left ivory floppy ear/right orange floppy ear. ONE complete puppy lying on belly, head on left resting on two short forepaws, oval body to right, folded hind paw and orange tail. Closed crescent eyes. Attached ears, connected silhouette, no extra limbs. No scene, text, clothing, gradients, shadows, 3D. Transparent outside, opaque ivory body. For NSDR and long exhale.

## 九方法导演映射
- 生理性叹息：完整坐姿猫闻花；胸腹 0→0.82→1→0 的连续起伏，补吸更小；呼气花茎轻动。
- 节律：新趴卧狗，背腹沿 4/6 节拍展开回落。
- 均衡：猫狗并肩，按所选 5/5 或 4/4 同步。
- 方块：完整坐姿猫，两种停留分别保留充盈/回落形态。
- 膈肌：原侧卧狗，腹部示意起伏，明确按自己的节奏，未添加定时吸呼指令。
- 交替：坐姿狗，左右叶子与文字指示对应用户的左右；无新增屏息。
- 冥想：新蜷卧猫，低幅安静陪伴，跟随原自然呼吸引导。
- NSDR：新趴睡狗，原身体扫描段落与整体进度；不添加强制呼吸节拍。
- 凯格尔：原教练狗，爪子与旗子提示轻收/释放；不引导收腹或憋气。外侧提示随轻收向内、随放松舒展。

局部 Metal 连续形变只作用指定区域，不拆分五官、耳朵或身体；自然呼吸动态是示意，并非测量。暂停保持采样姿态；减少动态及低电量不持续形变，仍展示阶段文字。
