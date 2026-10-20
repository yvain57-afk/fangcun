import Foundation

/// User-approved 2026-10-20 listening draft. Existing nine protocol timings are unchanged.
public enum PracticeGuidanceContent {
  public static let version = "fangcun-guidance-20261020"
  public static func introduction(for kind: PracticeKind, variantID: String? = nil) -> String {
    switch kind {
    case .physiologicalSigh: "先找个能坐稳或靠好的位置，让双脚和背部有一点支撑。\n你不必先把心情整理好，也不用马上放下手里的烦心事。我们先只做一件小事：留意呼吸。\n这一轮，会先用鼻子轻轻吸气，再补一小口，接着用嘴慢慢呼出去。第二口只是一点补充，不用吸得更满。\n呼气时，让空气缓缓出来，不用把胸口里的空气挤干净。肩膀和下颌可以少用一点力。\n屏幕会带你走完每一段。前两轮，我会出声陪你；之后把更多时间留给你自己。\n\n练习中，以舒服为准。如果头晕、胸闷、疼痛，或觉得呼吸越来越费力，就停下来，恢复平时的呼吸。"
    case .pacedBreathing: "让身体坐稳，或靠在能支撑你的地方。把手放在舒服的位置，眼睛可以轻轻闭上，也可以保持睁开。\n接下来，我们用四秒吸气、六秒呼气的节奏练习，中间不需要屏住呼吸。\n四秒说的是时间，不是要吸进很多空气；六秒也不要求你把气呼尽。每一口都轻一点，留一点余地。\n如果脑子里还有事情在转，就让它暂时待着。现在只要跟上这一口，再跟上下一口。\n前两轮有声音陪你，之后继续跟着节奏，慢慢来。\n\n练习中，以舒服为准。如果头晕、胸闷、疼痛，或觉得呼吸越来越费力，就停下来，恢复平时的呼吸。"
    case .balancedBreathing: variantID == "easy_4_4" ? "先把身体放稳。背部有支撑，双手自然地放着，肩膀不用撑起来。\n这次吸气四秒，呼气也四秒。吸气和呼气一样长，中间不停留。选好之后，就跟着同一个节奏来回。\n不用把每一口做得很深，也不用证明自己能坚持得更久。能轻松地吸进来，再轻松地呼出去，就够了。\n把注意力放在空气经过鼻端的感觉，或者胸腹很小的起伏。选一个容易感觉到的地方，不必同时照顾全部。\n前两轮跟着声音熟悉，之后给自己一点安静。\n\n练习中，以舒服为准。如果头晕、胸闷、疼痛，或觉得呼吸越来越费力，就停下来，恢复平时的呼吸。" : "先把身体放稳。背部有支撑，双手自然地放着，肩膀不用撑起来。\n这次吸气五秒，呼气也五秒。吸气和呼气一样长，中间不停留。选好之后，就跟着同一个节奏来回。\n不用把每一口做得很深，也不用证明自己能坚持得更久。能轻松地吸进来，再轻松地呼出去，就够了。\n把注意力放在空气经过鼻端的感觉，或者胸腹很小的起伏。选一个容易感觉到的地方，不必同时照顾全部。\n前两轮跟着声音熟悉，之后给自己一点安静。\n\n练习中，以舒服为准。如果头晕、胸闷、疼痛，或觉得呼吸越来越费力，就停下来，恢复平时的呼吸。"
    case .boxBreathing: "找一个坐得稳的位置，先让手和肩膀安顿下来。\n这一轮有四段：吸气三秒，停留三秒，呼气三秒，再停留三秒。屏幕会提示每一次转换，你不用自己数。\n停留是短暂地不吸也不呼，不需要咬紧牙、绷住胸口，更不用往极限撑。吸气和呼气都轻一点，不必吸满，也不必呼尽。\n可以先熟悉前两轮。如果任何一段停留让你觉得憋闷，就恢复自然呼吸，结束或换一种不含停留的方法。\n注意力跑开时，回来看看现在走到哪一段，再从这里跟上。\n\n停留不需要忍耐。不舒服时恢复自然呼吸，可换不含停留的均衡慢呼吸。练习中，以舒服为准。如果头晕、胸闷、疼痛，或觉得呼吸越来越费力，就停下来，恢复平时的呼吸。"
    case .diaphragmaticBreathing: "可以坐着，也可以舒服地躺下。选一个让背部和双腿都能得到支撑的姿势。\n这次没有需要追上的秒数。呼吸照自己的节奏进行，我们只是借助手掌，感觉它怎么发生。\n手轻轻放在腹部或两侧下肋，不向里面按，也不刻意把肚子顶出来。肩膀不需要跟着抬高。\n感觉不明显时，可以把动作做得更小，或者暂时只感受手掌和衣服的接触。轻松比幅度更重要。\n\n不压腹部，不强行深吸，不故意鼓大肚子。练习中，以舒服为准。如果头晕、胸闷、疼痛，或觉得呼吸越来越费力，就停下来，恢复平时的呼吸。"
    case .alternateNostrilBreathing: "先坐稳，让拿来换边的那只手能轻松靠近鼻子。手臂可以得到一些支撑，另一只手自然放着。\n接下来，左右都指你自己的身体方向。先轻遮右鼻孔，用左边吸气；再轻遮左边，用右边呼气。接着仍用右边吸气，再换左边呼气。\n每一段都是三秒，没有屏息。换边时手指轻放，只遮一边，不同时堵住两边，也不挤压鼻子。\n如果鼻塞、鼻子不舒服，或者这次不方便用手，可以选择其他呼吸练习。\n开始之后，每次换边都会有短提示。偶尔跟丢了，先把手放下、自然呼吸，暂停后准备好了再继续，不必赶着补上。\n\n鼻塞或鼻部不舒服时换其他方法。手指轻放，不挤压鼻子，不同时遮住两侧。练习中，以舒服为准。如果头晕、胸闷、疼痛，或觉得呼吸越来越费力，就停下来，恢复平时的呼吸。"
    case .meditation: "找一个可以安稳待一会儿的地方。坐姿舒服就好，不需要把身体摆成某个标准样子。\n你可以闭眼，也可以把视线轻轻落在前方。接下来的几分钟，我们会感觉身体的支撑，留意自然呼吸，也给念头留一点空间。\n不需要把脑子清空。发现自己走神时，再回来，就是这次练习的一部分。\n声音停下来的时候，你可以安静待着，直到下一次提示。\n\n可以睁眼。不舒服时看看周围、活动手脚，并结束练习。"
    case .nsdr: "找一个安全、可以躺稳休息的地方，让头、背部和双腿都有支撑。姿势不舒服时，随时可以调整。\n这段休息不要求你入睡，也不要求你一直保持清醒。声音会带着你慢慢注意身体的不同地方，呼吸按自己的节奏来。\n你不用努力让身体变重、变热，也不用逐一检查自己有没有放松。能感觉到多少，就先感觉多少。\n中间会有安静的时间。听漏一句也没关系，不用回想，听见下一句时再跟随就好。\n\n在安全、能休息的地方使用，不在驾驶或操作设备时练习。NSDR 不能代替正常睡眠。"
    case .kegel: "先找个能稳定支撑身体的坐姿或躺姿。这是盆底肌控制练习，不需要配合吸气或呼气来收紧。\n可以想象轻轻忍住排气，再把盆底向身体里面提起一点。注意力放在骨盆底部，腹部、臀部和大腿尽量保持放松。\n每轮轻收四秒，再松开八秒。收紧不追求最大力气，放松也不向下推、不用力往外顶。呼吸一直照常。\n如果你还分不清在哪里用力，可以先看动作说明，或请专业人员帮助确认，不必靠夹腿、收腹来完成。\n前两轮会有声音带你，之后跟着画面和节奏继续。保持不住四秒时，可以提前松开，在本轮剩余时间里休息，不需要硬撑。\n\n不在排尿时练习。持续盆底紧张或疼痛、排尿排便异常，或处于产后、术后恢复期时，先按专业人员的建议练习。"
    case .progressiveMuscleRelaxation: "找一个可以安全休息的地方，坐靠好，或舒服地躺下。让头、背部和双腿得到支撑。\n接下来会依次练习几组肌肉，每组只做一次很轻的收紧，然后留出更长时间松开。不需要憋气，也不追求明显的力量。\n受伤、疼痛、容易抽筋的部位，可以直接跳过收紧，只跟随放松。如果你近期做过手术，或专业人员限制你用力，先按照对方的建议来。\n如果收紧带来疼痛、抽筋或其他不舒服，立刻松开并跳过这个部位；不必等提示结束。你也可以随时结束整段练习。"
    }
  }
  public static func introductionResource(for kind: PracticeKind, variantID: String? = nil) -> String {
    let suffix = kind == .balancedBreathing ? "_" + (variantID == "easy_4_4" ? "easy_4_4" : "equal_5_5") : ""
    return "guide20_intro_" + kind.rawValue + suffix
  }
  public static func completion(for kind: PracticeKind) -> String {
    switch kind {
    case .physiologicalSigh: "让呼吸回到自己的节奏。先不用急着判断有没有变好。\n可以留意一下肩膀、下颌，或此刻的呼吸。比刚才松一点、差不多，都是可以如实记录的感受。\n这段时间已经结束。准备好时，再继续接下来的事。"
    case .pacedBreathing: "现在，让计数停下来。呼吸可以长一些，也可以短一些，回到你自己的节奏。\n你可以感受一下身体接触椅子或床面的地方。暂时没有明显变化，也不需要补做什么。\n如果接下来准备休息，就让自己继续安静待着；如果还要做事，给自己一点起身的时间。"
    case .balancedBreathing: "现在，放下固定的节拍，让呼吸自然地继续。\n留意一下，从跟随节奏回到自己呼吸的这一小段变化。不一定会特别平静，也不用去找一个正确的感受。\n准备好时，轻轻活动一下手脚，结束这次练习。"
    case .boxBreathing: "四段节奏到这里结束。让呼吸自然地继续，不用再等下一次停留。\n可以把视线落在身边一个普通的东西上，看看它的颜色和轮廓。\n不需要马上进入一个很专注的状态。准备好时，只选接下来要做的一件事就好。"
    case .diaphragmaticBreathing: "结束之后，不用刻意保持某一种呼吸姿势。\n也许你已经找到一点轻轻展开、自然回落的感觉；还没有找到也没关系，下次仍然可以从一口普通的呼吸开始。"
    case .alternateNostrilBreathing: "现在，把手放下来，让两侧鼻孔都自然地呼吸。\n感觉一下手臂和肩膀，给它们一个不用保持姿势的机会。\n不用比较哪边做得更好。你已经结束这段练习，接下来慢慢回到身边就好。"
    case .meditation: "这次练习已经结束。你可以稍微留意此刻，也可以不作评价。\n如果愿意，记下一个真实的感受；暂时说不出来，就让它先停留在身体里。"
    case .nsdr: "结束之后，先给自己一点转换的时间。坐起或站起时，慢慢来。\n这段休息是否带来了变化，你可以按自己的感觉判断，不需要用分数证明它。"
    case .kegel: "现在，把收紧的动作停下来，让盆底休息。保持几口自然呼吸。\n这次练习到这里结束。无需立刻再做一组，也不用收紧来检查自己有没有练到。\n如果没有清楚感受到收放，下次可以先确认动作，慢慢练清楚。"
    case .progressiveMuscleRelaxation: "这次练习结束了。先给自己一点时间，准备好时，再慢慢活动或继续休息。"
    }
  }
  public static func phaseResource(for kind: PracticeKind, cycle: Int, index: Int) -> String {
    "guide20_phase_" + kind.rawValue + "_" + String(min(1, max(0, cycle))) + "_" + String(index)
  }
  public static func phaseTexts(for kind: PracticeKind, cycle: Int) -> [String] {
    switch kind {
    case .physiologicalSigh: cycle == 0 ? ["轻轻鼻吸。", "补一小口。", "慢慢呼气，让肩膀歇一歇。"] : ["轻轻吸气。", "补一小口。", "缓缓呼出，不必用力。"]
    case .pacedBreathing: cycle == 0 ? ["轻轻吸气。", "慢慢呼气，不必呼尽。"] : ["吸气，轻一点。", "缓缓呼气，让这一口走完。"]
    case .balancedBreathing: cycle == 0 ? ["轻轻吸气。", "缓缓呼气。"] : ["吸气，不必吸满。", "呼气，轻轻放开。"]
    case .boxBreathing: cycle == 0 ? ["轻轻吸气。", "轻松停留。", "慢慢呼气。", "轻松停留。"] : ["轻轻吸气。", "停一会儿。", "慢慢呼气。", "停一会儿。"]
    case .alternateNostrilBreathing: cycle == 0 ? ["左侧吸气。", "右侧呼气。", "右侧吸气。", "左侧呼气。"] : ["左侧吸气。", "右侧呼气。", "右侧吸气。", "左侧呼气。"]
    case .kegel: cycle == 0 ? ["轻收，向内提。", "松开，让这里休息。"] : ["轻轻提起。", "放松，呼吸照常。"]
    default: []
    }
  }
  public static func segments(for kind: PracticeKind, duration: TimeInterval, variantID: String? = nil) -> [PracticeGuidedSegment] {
    switch (kind, duration) {
    case (.diaphragmaticBreathing, 180): [
      .init(id: "diaphragmaticBreathing_180_0", start: 0, end: 25, focus: "settle", text: "坐稳，或舒服地躺好。一只手轻放在腹部或下肋，只是接触，不向里按。先感觉一次平时的呼吸。"),
      .init(id: "diaphragmaticBreathing_180_1", start: 25, end: 50, focus: "lowerRibs", text: "下一次自然吸气时，留意手下有没有一点展开。也许在腹部，也许在两侧下肋。幅度很小也可以，肩膀不用跟着抬高。"),
      .init(id: "diaphragmaticBreathing_180_2", start: 50, end: 85, focus: "release", text: "呼气自己发生时，感觉手下慢慢回落。不必收腹，也不用把气挤出去。让这一口按自己的速度结束，再等下一口到来。"),
      .init(id: "diaphragmaticBreathing_180_3", start: 85, end: 120, focus: "natural", text: "接下来，把节奏交回身体。手掌只是感觉，不负责推动。没有明显起伏时，也不用加大呼吸。"),
      .init(id: "diaphragmaticBreathing_180_4", start: 120, end: 155, focus: "relax", text: "留意一下下颌和肩膀。如果它们正在帮忙用力，可以少做一点。让每一口保持舒服，不追求更深。"),
      .init(id: "diaphragmaticBreathing_180_5", start: 155, end: 175, focus: "independent", text: "如果方便，把手放回舒服的位置。呼吸照常，不用继续检查动作。安静待几口呼吸。"),
      .init(id: "diaphragmaticBreathing_180_6", start: 175, end: 180, focus: "finish", text: "练习结束，慢慢来。"),
    ]
    case (.diaphragmaticBreathing, 300): [
      .init(id: "diaphragmaticBreathing_300_0", start: 0, end: 30, focus: "settle", text: "坐稳，或舒服地躺好。让背部得到支撑，一只手轻放在腹部或下肋。先不改变呼吸，只感觉手掌接触身体的位置。"),
      .init(id: "diaphragmaticBreathing_300_1", start: 30, end: 60, focus: "lowerRibs", text: "下一次自然吸气时，留意下肋或腹部有没有一点展开。动作可以很小，手不往里按，肩膀也不用向上抬。"),
      .init(id: "diaphragmaticBreathing_300_2", start: 60, end: 120, focus: "release", text: "呼气自己发生时，感觉手下慢慢回落。你不用主动收腹，也不用把气呼尽。轻轻看着这一口结束，再等下一口自然到来。"),
      .init(id: "diaphragmaticBreathing_300_3", start: 120, end: 185, focus: "natural", text: "现在，让呼吸按自己的节奏继续。留意一两次展开和回落，然后把判断做得对不对的念头暂时放下。感觉不明显也可以。"),
      .init(id: "diaphragmaticBreathing_300_4", start: 185, end: 245, focus: "relax", text: "把一点注意力带到下颌、肩膀和胸口。看看有没有不必要的用力。可以少用一点，也可以调整姿势，让支撑更舒服。"),
      .init(id: "diaphragmaticBreathing_300_5", start: 245, end: 285, focus: "independent", text: "如果方便，把手放回舒服的位置。接下来的时间，不再检查幅度，只让呼吸自己发生。听见结束的提示时，再慢慢回来。"),
      .init(id: "diaphragmaticBreathing_300_6", start: 285, end: 300, focus: "finish", text: "听听身边的声音，轻轻活动双手。准备好时，结束这段练习。"),
    ]
    case (.meditation, 300): [
      .init(id: "meditation_300_0", start: 0, end: 25, focus: "settle", text: "找一个舒服、能坐稳的姿势。手自然放好，眼睛可以闭上，也可以轻轻看着前方。此刻不必急着平静。"),
      .init(id: "meditation_300_1", start: 25, end: 55, focus: "support", text: "感觉一下身体与椅子或垫子接触的地方。重量可以先交给这里。肩膀和下颌如果愿意，也可以少用一点力。"),
      .init(id: "meditation_300_2", start: 55, end: 100, focus: "breath", text: "留意一口自然的呼吸。你可以感觉鼻端的空气，也可以感觉胸腹很小的起伏。选一个容易感觉到的地方，不用改变呼吸。"),
      .init(id: "meditation_300_3", start: 100, end: 145, focus: "return", text: "也许注意力已经跟着某个念头走了一会儿。发现了，就先停在这里，不用责怪自己。再感觉下一口自然的呼吸。"),
      .init(id: "meditation_300_4", start: 145, end: 200, focus: "allow", text: "念头还会出现。有些像一句话，有些像一个画面。暂时不用把它处理完。知道它在，再把注意力放回身体。"),
      .init(id: "meditation_300_5", start: 200, end: 260, focus: "return", text: "如果刚才一直在用力专注，现在可以轻一点。感觉身体仍被支撑着，呼吸也还在。接下来，安静待一会儿。"),
      .init(id: "meditation_300_6", start: 260, end: 285, focus: "breath", text: "留意接下来的几口自然呼吸。不用把每一口都抓住，能回来一次，就是一次。"),
      .init(id: "meditation_300_7", start: 285, end: 300, focus: "finish", text: "听听身边的声音。准备好时，慢慢睁眼。"),
    ]
    case (.meditation, 600): [
      .init(id: "meditation_600_0", start: 0, end: 30, focus: "settle", text: "找一个能安稳待着的姿势。双手自然放好，眼睛可以闭上，也可以把视线放低。带着现在的心情开始就好。"),
      .init(id: "meditation_600_1", start: 30, end: 70, focus: "support", text: "感觉身体与椅子或垫子接触的地方。留意脚底、坐骨，或者背部的支撑。选一个清楚的位置，在这里停一会儿。"),
      .init(id: "meditation_600_2", start: 70, end: 140, focus: "breath", text: "把注意力轻轻带到呼吸。鼻端的空气，或者胸腹的起伏，都可以。呼吸长短由身体决定，你只需要感觉它正在发生。"),
      .init(id: "meditation_600_3", start: 140, end: 220, focus: "return", text: "如果发现自己在想别的事，不用把那件事解决完才回来。先知道自己走神了，再感觉此刻身体的支撑，或下一口呼吸。"),
      .init(id: "meditation_600_4", start: 220, end: 300, focus: "allow", text: "有些念头可能会反复出现。你不必赶走它，也不必接着往下想。可以在心里轻轻说一句：我注意到了。然后把一点注意力带回身体。"),
      .init(id: "meditation_600_5", start: 300, end: 400, focus: "support", text: "再看看有没有为了专注而绷紧的地方。眉心、下颌、肩膀，可以少用一点力。现在的姿势若不舒服，也可以慢慢调整。"),
      .init(id: "meditation_600_6", start: 400, end: 500, focus: "return", text: "接下来的时间，我们继续练习回来。走神、发现、再回来，不需要计算次数。即使刚才大部分时间都在想事情，也仍然可以从此刻继续。"),
      .init(id: "meditation_600_7", start: 500, end: 565, focus: "breath", text: "暂时把方法也放轻一点。感觉几口自然的呼吸，听见声音来，又离开。剩下的时间，就在这里安静待着。"),
      .init(id: "meditation_600_8", start: 565, end: 600, focus: "finish", text: "慢慢感觉身边的空间。听听近处和远处的声音，轻轻动动手脚。准备好时，睁开眼睛，不用急着起身。"),
    ]
    case (.nsdr, 600): [
      .init(id: "nsdr_600_0", start: 0, end: 30, focus: "settle", text: "找个可以躺稳的位置，让头、背部和双腿都有支撑。姿势不舒服时，可以随时调整。接下来这段时间，先留给休息。"),
      .init(id: "nsdr_600_1", start: 30, end: 60, focus: "settle", text: "眼睛可以轻轻闭上，也可以保持微微睁开。你不用一直看屏幕，也不需要努力入睡。听见声音时，再慢慢跟随。"),
      .init(id: "nsdr_600_2", start: 60, end: 90, focus: "face", text: "把注意力带到眼睛周围和眉心。看看能不能少用一点力。牙齿不必咬在一起，舌头可以自然地待着。"),
      .init(id: "nsdr_600_3", start: 90, end: 130, focus: "shoulders", text: "注意两侧肩膀，还有背部与下面的接触。你不用主动把肩膀往下压。只是让支撑接住一点重量，能放下多少都可以。"),
      .init(id: "nsdr_600_4", start: 130, end: 170, focus: "arms", text: "沿着上臂、前臂，慢慢注意到双手。手指可以自然弯着。如果有地方不舒服，调整一下，或者把注意力移到舒服的位置。"),
      .init(id: "nsdr_600_5", start: 170, end: 210, focus: "hands", text: "留意手掌与床面、衣服的接触。也许温热，也许只是普通的触感，没有明显感觉也可以。现在不用抓住任何东西。"),
      .init(id: "nsdr_600_6", start: 210, end: 250, focus: "breath", text: "感觉一口自然的呼吸。它不必变深，也不需要和我的说话同步。你可以只是知道，身体正在吸气，也正在呼气。"),
      .init(id: "nsdr_600_7", start: 250, end: 290, focus: "belly", text: "把注意力放到腹部和腰背。腹部不需要主动收紧，下面有支撑。让呼吸带着一点自然的起伏，幅度小一些也没关系。"),
      .init(id: "nsdr_600_8", start: 290, end: 330, focus: "hips", text: "感觉骨盆与床面或垫子接触的地方。臀部可以少用一点力，不必特意向下沉。先在被支撑的感觉里停一会儿。"),
      .init(id: "nsdr_600_9", start: 330, end: 370, focus: "legs", text: "注意双腿，从大腿慢慢到小腿。膝盖保持舒服，不用绷直。双腿此刻不需要带你去任何地方，可以先歇一会儿。"),
      .init(id: "nsdr_600_10", start: 370, end: 415, focus: "feet", text: "把注意力带到脚踝、脚背和脚趾。看看有没有可以少用的力气。脚朝哪个方向自然落着都可以，不需要摆成一样。"),
      .init(id: "nsdr_600_11", start: 415, end: 460, focus: "whole", text: "现在，感觉整个身体与下面的支撑。也许有些地方松了，有些地方仍然紧着。都先让它在，不用逐一改好。"),
      .init(id: "nsdr_600_12", start: 460, end: 510, focus: "breath", text: "再留意一口自然的呼吸。如果思绪走远了，不用追着找回来。听见这句话，就从此刻的呼吸或接触感重新开始。"),
      .init(id: "nsdr_600_13", start: 510, end: 570, focus: "quiet", text: "接下来，我们安静休息一会儿。你不需要一直集中注意，听漏也没关系。下次听到声音时，再慢慢回来。"),
      .init(id: "nsdr_600_14", start: 570, end: 600, focus: "return", text: "慢慢感觉身边的空间。轻轻动动手指、脚趾。准备好时，睁开眼睛，先躺一会儿，不急着起身。"),
    ]
    case (.nsdr, 1200): [
      .init(id: "nsdr_1200_0", start: 0, end: 45, focus: "settle", text: "找一个安全、可以躺稳的位置，让头、背部和双腿得到支撑。姿势舒服比保持不动更重要。这二十分钟，先给自己留一点休息的空间。"),
      .init(id: "nsdr_1200_1", start: 45, end: 90, focus: "settle", text: "眼睛可以轻轻闭上，也可以保持微微睁开。你不用努力睡着，也不用检查自己是否足够清醒。声音停下的时候，就安静待着。"),
      .init(id: "nsdr_1200_2", start: 90, end: 150, focus: "face", text: "慢慢注意眼睛周围、眉心和额头。看看它们是否还在帮忙用力。可以少做一点。下颌松一些，牙齿不必咬在一起，舌头自然地放着。"),
      .init(id: "nsdr_1200_3", start: 150, end: 230, focus: "shoulders", text: "把注意力带到肩膀，再到背部与下面的接触。你不必把肩膀压低，也不需要让背部贴得更紧。感觉哪里已经得到支撑，先从那里休息。"),
      .init(id: "nsdr_1200_4", start: 230, end: 310, focus: "arms", text: "从上臂慢慢到前臂，再感觉双手。也许左右感觉不同，也许一边更清楚。都不用比较。手臂可以保持舒服的弯曲，不需要摆得笔直。"),
      .init(id: "nsdr_1200_5", start: 310, end: 390, focus: "hands", text: "留意手掌、指腹，以及它们接触到的床面或衣服。温度、轻重、柔软或粗糙，感觉到哪一种都可以。没有特别的感觉，也可以在这里安静停留。"),
      .init(id: "nsdr_1200_6", start: 390, end: 470, focus: "breath", text: "现在，把一点注意力放到自然呼吸。感觉空气经过鼻端，或者身体很小的起伏。不需要把呼吸做深，也不用配合声音改变速度。"),
      .init(id: "nsdr_1200_7", start: 470, end: 550, focus: "belly", text: "注意腹部、两侧腰部和后腰。看看支撑在哪里。腹部不用主动收紧，也不必向外推。让下一口呼吸自己到来，再自己离开。"),
      .init(id: "nsdr_1200_8", start: 550, end: 640, focus: "hips", text: "把注意力带到骨盆和臀部与下面接触的地方。可以感受一点重量，也可以只知道这里被托住。不需要向下压，不需要用力找到放松。"),
      .init(id: "nsdr_1200_9", start: 640, end: 720, focus: "legs", text: "从大腿慢慢到膝盖，再到小腿。双腿可以弯一点，也可以自然伸着。先找一个不费力的位置。现在暂时不需要用双腿去做下一件事。"),
      .init(id: "nsdr_1200_10", start: 720, end: 810, focus: "feet", text: "慢慢感觉脚踝、脚背、脚底和脚趾。它们也许有不同的温度或触感。脚趾不用伸直，脚踝也不用保持角度，就让双脚按舒服的方式待着。"),
      .init(id: "nsdr_1200_11", start: 810, end: 900, focus: "whole", text: "把注意力从一个部位放宽到整个身体。头、背、骨盆和双腿，都与下面有着接触。无需每一处都感觉清楚，知道自己在这里，就可以了。"),
      .init(id: "nsdr_1200_12", start: 900, end: 1000, focus: "breath", text: "再感觉一口自然的呼吸。如果某个念头反复出现，可以先让它待在一旁。你无需在这段时间里想通什么。回来感觉呼吸，或者身体的支撑。"),
      .init(id: "nsdr_1200_13", start: 1000, end: 1100, focus: "quiet", text: "接下来，留一段安静。可以清楚地听着，也可以偶尔走神。此刻不需要再完成一个动作，听到下一次提示时，再慢慢回来。"),
      .init(id: "nsdr_1200_14", start: 1100, end: 1170, focus: "whole", text: "慢慢再感觉一次整个身体。看看姿势是否仍然舒服。如果想调整，可以小幅度动一动。再留一点时间，不急着结束休息。"),
      .init(id: "nsdr_1200_15", start: 1170, end: 1200, focus: "return", text: "现在，听听身边的声音，感觉周围的空间。轻轻活动手指和脚趾。准备好时，慢慢睁眼，先躺一会儿，再决定什么时候起身。"),
    ]
    case (.progressiveMuscleRelaxation, 600): pmrSegments(sleep: variantID == "pmr_sleep")
    default: []
    }
  }
  private static func pmrSegments(sleep: Bool) -> [PracticeGuidedSegment] {
    let shared: [PracticeGuidedSegment] = [
      .init(id: "pmr_i01", start: 0, end: 30, focus: "pmr_settle", text: "先让身体安顿下来。你可以坐靠着，也可以躺着。看看头、背部和双腿有没有得到支撑，姿势不舒服时，随时调整。"),
      .init(id: "pmr_i02", start: 30, end: 55, focus: "pmr_settle", text: "这次不用先平静，也不用清空念头。我们只借助一点轻轻的用力，再感觉松开。全程自然呼吸，不屏住，也不勉强。"),
      .init(id: "pmr_i03", start: 55, end: 80, focus: "pmr_settle", text: "如果某个部位受伤、疼痛，或者不适合用力，就跳过收紧，只感觉它被支撑着。准备好了，我们先从双手开始。"),
      .init(id: "pmr_m01_a", start: 80, end: 100, focus: "pmr_m01_prepare", text: "让双手自然地放着，手腕保持舒服。等会儿，只把手指轻轻握拢，不用把指甲压进手心。"),
      .init(id: "pmr_m01_b", start: 100, end: 105, focus: "pmr_m01_gentle_tension", text: "轻轻收紧。"),
      .init(id: "pmr_m01_c", start: 105, end: 130, focus: "pmr_m01_release", text: "现在松开，让手指自然散开。留意手心和手背，也许温热，也许轻一点，也许没有明显变化。都可以，先不做下一步。"),
      .init(id: "pmr_m02_a", start: 130, end: 150, focus: "pmr_m02_prepare", text: "注意上臂。肘部轻轻弯着，让手臂有支撑。等会儿，像很轻地弯一下手臂，让上臂稍微用力，不握紧双手，也不向下压。"),
      .init(id: "pmr_m02_b", start: 150, end: 155, focus: "pmr_m02_gentle_tension", text: "轻轻收紧。"),
      .init(id: "pmr_m02_c", start: 155, end: 180, focus: "pmr_m02_release", text: "松开，手臂回到有支撑的位置。前臂、手掌都不用维持动作。感觉刚才用力的地方，给它一点休息的时间。"),
      .init(id: "pmr_m03_a", start: 180, end: 200, focus: "pmr_m03_prepare", text: "把注意力带到额头。等会儿，眉毛只向上轻轻抬一点，像有一点点惊讶。眼睛不用挤紧，头也不向后仰。"),
      .init(id: "pmr_m03_b", start: 200, end: 205, focus: "pmr_m03_gentle_tension", text: "轻轻收紧。"),
      .init(id: "pmr_m03_c", start: 205, end: 230, focus: "pmr_m03_release", text: "松开，让眉毛回到自然的位置。额头不用再抬着。眼睛可以继续轻轻闭着，也可以放松地睁开，感觉适合自己的状态。"),
      .init(id: "pmr_m04_a", start: 230, end: 250, focus: "pmr_m04_prepare", text: "现在注意嘴唇和面颊。等会儿，只把嘴唇轻轻抿拢。牙齿保持分开，不咬紧下颌，也不需要把整张脸挤到一起。"),
      .init(id: "pmr_m04_b", start: 250, end: 255, focus: "pmr_m04_gentle_tension", text: "轻轻收紧。"),
      .init(id: "pmr_m04_c", start: 255, end: 280, focus: "pmr_m04_release", text: "松开，让嘴唇恢复自然的接触。牙齿不必碰在一起，舌头也不用顶住。暂时不需要摆出任何表情。"),
      .init(id: "pmr_m05_a", start: 280, end: 300, focus: "pmr_m05_prepare", text: "注意两侧肩膀。等会儿，朝耳朵方向轻轻抬起一点点。脖子不扭转，也不往后仰。高度不用多，能感觉到就够了。"),
      .init(id: "pmr_m05_b", start: 300, end: 305, focus: "pmr_m05_gentle_tension", text: "轻轻收紧。"),
      .init(id: "pmr_m05_c", start: 305, end: 330, focus: "pmr_m05_release", text: "松开，让肩膀自然落回舒服的位置，不用往下压。感觉肩膀和手臂的重量，再留一点时间，什么也不补做。"),
      .init(id: "pmr_m06_a", start: 330, end: 350, focus: "pmr_m06_prepare", text: "把注意力带到大腿。膝盖保持舒服，可以微微弯着。等会儿，轻轻绷一下大腿前侧，不必把腿绷直，也不抬腿。"),
      .init(id: "pmr_m06_b", start: 350, end: 355, focus: "pmr_m06_gentle_tension", text: "轻轻收紧。"),
      .init(id: "pmr_m06_c", start: 355, end: 380, focus: "pmr_m06_release", text: "松开，让大腿回到被支撑的位置。膝盖保持舒服，臀部也可以休息。留意用力前后有没有一点区别，没有也不用找。"),
      .init(id: "pmr_m07_a", start: 380, end: 400, focus: "pmr_m07_prepare", text: "注意小腿。等会儿，脚尖只向自己靠近一点点，感觉小腿轻微用力。不要勾到尽头，容易抽筋时就跳过。"),
      .init(id: "pmr_m07_b", start: 400, end: 405, focus: "pmr_m07_gentle_tension", text: "轻轻收紧。"),
      .init(id: "pmr_m07_c", start: 405, end: 430, focus: "pmr_m07_release", text: "松开，让脚踝回到自然的角度。小腿不再保持牵拉。感觉它与下面的接触，等一等，不急着做下一组。"),
      .init(id: "pmr_m08_a", start: 430, end: 450, focus: "pmr_m08_prepare", text: "最后是脚趾。等会儿，只把脚趾轻轻蜷起一点，不抓紧、不绷脚背。这个动作容易让你抽筋的话，直接略过。"),
      .init(id: "pmr_m08_b", start: 450, end: 455, focus: "pmr_m08_gentle_tension", text: "轻轻收紧。"),
      .init(id: "pmr_m08_c", start: 455, end: 480, focus: "pmr_m08_release", text: "松开，让脚趾自然待着，不需要主动伸直。双脚朝舒服的方向落下。收紧的部分到这里已经全部结束。"),
      .init(id: "pmr_w01", start: 480, end: 510, focus: "pmr_quiet", text: "现在，所有收紧的动作都结束了。感觉双手、面部、肩膀，还有双腿。哪里松了一些，哪里仍有紧张，都可以先知道，不需要再用力修改。"),
      .init(id: "pmr_w02", start: 510, end: 540, focus: "pmr_quiet", text: "让注意力慢慢放宽到整个身体。呼吸照自己的节奏发生。接下来的时间，没有需要完成的动作，只是在这里休息。"),
    ]
    let ending: [PracticeGuidedSegment]
    if sleep {
      ending = [
        .init(id: "pmr_n01", start: 540, end: 570, focus: "pmr_sleep", text: "如果你准备睡觉，就继续保持舒服的姿势。有没有睡意都可以，眼下不必再做什么。让手脚休息，呼吸也照常。"),
        .init(id: "pmr_n02", start: 570, end: 600, focus: "pmr_sleep", text: "接下来，声音会慢慢停下来。不需要回应，也不用睁眼确认。你可以继续安静躺着，把剩下的时间留给休息。"),
      ]
    } else {
      ending = [
        .init(id: "pmr_d01", start: 540, end: 570, focus: "return", text: "慢慢注意身边的声音，感觉自己所在的空间。你可以先轻轻动动手指和脚趾，再看看身体是否想换一个姿势。"),
        .init(id: "pmr_d02", start: 570, end: 600, focus: "return", text: "准备好时，慢慢睁开眼睛。先坐稳，或者先侧身，再按自己的速度起身。这次练习结束了，不用立刻判断效果。"),
      ]
    }
    return shared + ending
  }
}
