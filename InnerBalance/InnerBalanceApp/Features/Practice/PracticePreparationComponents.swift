import InnerBalanceCore
import SwiftUI

struct PracticePreparationHero: View {
  let kind: PracticeKind
  let duration: TimeInterval

  var body: some View {
    HStack(alignment: .center, spacing: FangcunLayout.spacing(5)) {
      PracticeFieldGlyph(kind: kind, size: 96)
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
        Text(kind.outcomeTitle)
          .font(.caption.weight(.bold))
          .foregroundStyle(InnerBalanceTheme.emphasis)
        Text(kind.title)
          .font(.title.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.ink)
        Text(PracticeDurationFormatter.text(duration))
          .font(.subheadline.monospacedDigit())
          .foregroundStyle(InnerBalanceTheme.mutedInk)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(FangcunLayout.spacing(5))
    .fangcunLevelOneSurface(cornerRadius: FangcunLayout.spacing(5))
  }
}

struct PracticeIntroductionCard: View {
  let kind: PracticeKind

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(5)) {
      Text(kind.summary)
        .font(.title3.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.ink)
        .fixedSize(horizontal: false, vertical: true)

      explanation("这个练什么", kind.purpose, systemImage: "scope")
      explanation("适合什么时候", kind.bestFor, systemImage: "clock")
      explanation("怎么做", kind.steps, systemImage: "list.number")
      explanation("开始前", kind.preparation, systemImage: "checkmark.shield")
    }
    .padding(FangcunLayout.spacing(5))
    .fangcunLevelOneSurface(cornerRadius: FangcunLayout.spacing(5))
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("practice.introduction")
  }

  private func explanation(_ title: String, _ detail: String, systemImage: String) -> some View {
    HStack(alignment: .top, spacing: FangcunLayout.spacing(3)) {
      Image(systemName: systemImage)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.emphasis)
        .frame(width: 24, height: 24)
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
        Text(title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(InnerBalanceTheme.ink)
        Text(detail)
          .font(.subheadline)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

struct PracticeStartingPicker: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Binding var value: Double

  var body: some View {
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        VStack(spacing: FangcunLayout.spacing(2)) { choices }
      } else {
        HStack(spacing: FangcunLayout.spacing(2)) { choices }
      }
    }
    .sensoryFeedback(.selection, trigger: Int(value))
  }

  @ViewBuilder private var choices: some View {
    ForEach(PracticeStartingChoice.allCases, id: \.self) { choice in
      Button(choice.title) { value = Double(choice.rating) }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(
          isSelected(choice) ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink
        )
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(
          isSelected(choice) ? InnerBalanceTheme.strongFill : InnerBalanceTheme.subtleFill,
          in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
              isSelected(choice) ? InnerBalanceTheme.strongFill : InnerBalanceTheme.hairline,
              lineWidth: 1
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected(choice) ? .isSelected : [])
        .accessibilityHint("选择后作为练习前的主观参照")
    }
  }

  private func isSelected(_ choice: PracticeStartingChoice) -> Bool {
    Int(value.rounded()) == choice.rating
  }
}

struct PracticeHapticToggle: View {
  @Binding var isOn: Bool

  var body: some View {
    Toggle(isOn: $isOn) {
      Label {
        VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
          Text("触觉提示").font(.headline)
          Text("每次换动作时轻触一下")
            .font(.caption)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
        }
      } icon: {
        Image(systemName: "waveform.path")
          .foregroundStyle(InnerBalanceTheme.emphasis)
      }
    }
    .tint(InnerBalanceTheme.strongFill)
    .padding(FangcunLayout.spacing(5))
    .fangcunLevelOneSurface(cornerRadius: 20)
    .accessibilityHint("在节奏切换处提供轻触感，可独立关闭")
    .accessibilityIdentifier("practice.haptics")
  }
}

/// Human teaching diagrams supplement the approved characters; they do not measure the body.
struct PracticeHumanInstruction: View {
  let kind: PracticeKind
  @Environment(\.dynamicTypeSize) private var typeSize
  var body: some View {
    Group {
      switch kind {
      case .diaphragmaticBreathing:
        VStack(alignment: .leading, spacing: 12) {
          Text("手放在哪里？").font(.headline)
          HumanTeachingFigure(diagram: .torso).frame(height: 210)
          instruction("肩膀", "自然落下，不向耳朵耸起。")
          instruction("双手", "轻放在腹部或两侧下肋，不向里压。")
          instruction("吸气 / 呼气", "感受下肋和腹部轻轻展开，再自然回落。不故意鼓肚子。")
          Text("动作示意，按自己的节奏；不是呼吸深度测量。")
            .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
        }.fangcunPaperCard().accessibilityIdentifier("practice.teaching.diaphragm")
      case .alternateNostrilBreathing:
        VStack(alignment: .leading, spacing: 12) {
          Text("换边顺序，先看一遍").font(.headline)
          Text("同向示意：图左是你的左鼻孔，图右是你的右鼻孔。不是镜中左右。")
            .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
          LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 14) {
            ForEach(0..<4) { step in
              VStack(alignment: .leading, spacing: 8) {
                Text(nostrilTitle(step)).font(.subheadline.weight(.semibold))
                HumanTeachingFigure(diagram: .nostril(step)).frame(height: 140).accessibilityHidden(true)
                Text(nostrilAction(step)).font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
              }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(InnerBalanceTheme.subtleFill, in: RoundedRectangle(cornerRadius: 16))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(nostrilTitle(step) + "。" + nostrilAction(step))
                .accessibilityIdentifier("practice.teaching.nostril.\(step + 1)")
            }
          }
          Text("指腹只需轻遮。不压迫鼻子，换边不屏息；鼻塞或鼻部不舒服时换其他方法。")
            .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
        }.fangcunPaperCard().accessibilityIdentifier("practice.teaching.nostrils")
      case .kegel:
        VStack(alignment: .leading, spacing: 12) {
          Text("盆底轻收，呼吸照常").font(.headline)
          Text("下图只示意骨盆底部的收放方向，肩膀、腹部、臀部与大腿不用一起使劲。")
            .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
          if typeSize.isAccessibilitySize {
            VStack(spacing: 12) { pelvicFrame(contract: true); pelvicFrame(contract: false) }
          } else {
            HStack(alignment: .top, spacing: 12) { pelvicFrame(contract: true); pelvicFrame(contract: false) }
          }
          Text("每次完全放松 8 秒，再进入下一轮。不要向下用力，也不要在排尿时练习。")
            .font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk)
        }.fangcunPaperCard().accessibilityIdentifier("practice.teaching.pelvicFloor")
      default: EmptyView()
      }
    }
  }
  private func instruction(_ title: String, _ text: String) -> some View {
    VStack(alignment: .leading, spacing: 3) { Text(title).font(.subheadline.weight(.semibold)); Text(text).font(.subheadline).foregroundStyle(InnerBalanceTheme.mutedInk) }
  }
  private func nostrilTitle(_ step: Int) -> String {
    ["1 · 你的左侧吸气", "2 · 你的右侧呼气", "3 · 你的右侧吸气", "4 · 你的左侧呼气"][step]
  }
  private func nostrilAction(_ step: Int) -> String {
    ["轻遮右鼻孔，从左鼻孔吸气。", "换遮左鼻孔，从右鼻孔呼气。", "保持轻遮左鼻孔，从右鼻孔吸气。", "换遮右鼻孔，从左鼻孔呼气。"][step]
  }
  private func pelvicFrame(contract: Bool) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(contract ? "轻收 · 4 秒" : "完全放松 · 8 秒").font(.subheadline.weight(.semibold))
      HumanTeachingFigure(diagram: .pelvis(contract)).frame(height: 160)
      Text(contract ? "盆底轻轻向内、向上收。" : "松开收紧，让盆底自然回落。")
        .font(.caption).foregroundStyle(InnerBalanceTheme.mutedInk)
    }.frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
  }
}

private struct HumanTeachingFigure: View {
  enum Diagram { case torso, nostril(Int), pelvis(Bool) }
  let diagram: Diagram
  var body: some View {
    Canvas { context, size in
      let ink = InnerBalanceTheme.strongFill
      let accent = InnerBalanceTheme.emphasis
      let muted = InnerBalanceTheme.mutedInk
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * size.width, y: y * size.height) }
      func line(_ points: [(CGFloat, CGFloat)], color: Color? = nil, width: CGFloat = 2) {
        guard let first = points.first else { return }
        var path = Path(); path.move(to: point(first.0, first.1))
        for next in points.dropFirst() { path.addLine(to: point(next.0, next.1)) }
        context.stroke(path, with: .color(color ?? ink), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
      }
      func curve(_ from: (CGFloat, CGFloat), _ to: (CGFloat, CGFloat), _ c1: (CGFloat, CGFloat), _ c2: (CGFloat, CGFloat), color: Color? = nil, width: CGFloat = 2) {
        var path = Path(); path.move(to: point(from.0, from.1))
        path.addCurve(to: point(to.0, to.1), control1: point(c1.0, c1.1), control2: point(c2.0, c2.1))
        context.stroke(path, with: .color(color ?? ink), style: StrokeStyle(lineWidth: width, lineCap: .round))
      }
      func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, filled: Bool = false) {
        let path = Path(ellipseIn: CGRect(x: x * size.width, y: y * size.height, width: w * size.width, height: h * size.height))
        if filled { context.fill(path, with: .color(accent)) }
        else { context.stroke(path, with: .color(ink), lineWidth: 2) }
      }
      func label(_ text: String, _ x: CGFloat, _ y: CGFloat) {
        context.draw(Text(text).font(.caption).foregroundStyle(muted), at: point(x,y))
      }
      func arrow(_ x: CGFloat, from: CGFloat, to: CGFloat) {
        line([(x,from),(x,to)], color: accent, width: 2.5)
        let direction: CGFloat = to < from ? 1 : -1
        line([(x - 0.035,to + direction * 0.045),(x,to),(x + 0.035,to + direction * 0.045)], color: accent, width: 2.5)
      }
      switch diagram {
      case .torso:
        oval(0.43, 0.02, 0.14, 0.18)
        line([(0.46,0.20),(0.46,0.25),(0.32,0.29),(0.25,0.40),(0.23,0.72)])
        line([(0.54,0.20),(0.54,0.25),(0.68,0.29),(0.75,0.40),(0.77,0.72)])
        curve((0.34,0.36),(0.34,0.92),(0.40,0.58),(0.30,0.75))
        curve((0.66,0.36),(0.66,0.92),(0.60,0.58),(0.70,0.75))
        // The two hands lie lightly on the lower ribs; no inward pressure arrows.
        curve((0.23,0.72),(0.43,0.58),(0.26,0.80),(0.37,0.64))
        curve((0.77,0.72),(0.57,0.58),(0.74,0.80),(0.63,0.64))
        for y in [CGFloat(0.60),0.63,0.66] {
          line([(0.38,y),(0.45,y - 0.025)], color: accent)
          line([(0.62,y),(0.55,y - 0.025)], color: accent)
        }
        curve((0.39,0.48),(0.61,0.48),(0.43,0.56),(0.57,0.56))
        curve((0.43,0.76),(0.57,0.76),(0.46,0.80),(0.54,0.80), color: accent)
        arrow(0.29, from: 0.21, to: 0.30); arrow(0.71, from: 0.21, to: 0.30)
        label("松肩",0.17,0.26); label("下肋",0.84,0.58); label("腹部",0.84,0.80)
        line([(0.72,0.58),(0.65,0.58)],color: accent, width: 1)
        line([(0.74,0.80),(0.59,0.77)],color: accent, width: 1)
      case .nostril(let step):
        // Four explicitly authored steps: open sides L/R/R/L. Coordinates are body-relative.
        let openLeft = step == 0 || step == 3
        let inhale = step == 0 || step == 2
        let openX: CGFloat = openLeft ? 0.30 : 0.70
        let closedX: CGFloat = openLeft ? 0.70 : 0.30
        label("你的左",0.25,0.08); label("你的右",0.75,0.08)
        curve((0.43,0.21),(0.19,0.50),(0.41,0.39),(0.14,0.30))
        curve((0.57,0.21),(0.81,0.50),(0.59,0.39),(0.86,0.30))
        curve((0.19,0.50),(0.81,0.50),(0.35,0.61),(0.65,0.61))
        oval(0.23,0.42,0.14,0.09); oval(0.63,0.42,0.14,0.09)
        // A fingertip contacts only the closed nostril. The palm remains below that side.
        curve((closedX - 0.05,0.86),(closedX - 0.04,0.48),(closedX - 0.09,0.71),(closedX - 0.08,0.49), color: accent, width: 3)
        curve((closedX - 0.04,0.48),(closedX + 0.05,0.86),(closedX + 0.08,0.38),(closedX + 0.06,0.72), color: accent, width: 3)
        curve((closedX + 0.05,0.86),(closedX + 0.17,0.88),(closedX + 0.13,0.73),(closedX + 0.19,0.80), color: accent, width: 2)
        label("轻遮",closedX,0.96)
        arrow(openX, from: inhale ? 0.87 : 0.60, to: inhale ? 0.60 : 0.87)
      case .pelvis(let contract):
        // Simplified pelvic bowl and sling: movement belongs to the pelvic floor, not the abdomen.
        curve((0.23,0.17),(0.35,0.72),(0.08,0.43),(0.18,0.64))
        curve((0.77,0.17),(0.65,0.72),(0.92,0.43),(0.82,0.64))
        curve((0.23,0.17),(0.41,0.30),(0.31,0.15),(0.30,0.38))
        curve((0.77,0.17),(0.59,0.30),(0.69,0.15),(0.70,0.38))
        line([(0.41,0.30),(0.46,0.47),(0.54,0.47),(0.59,0.30)])
        curve((0.35,0.66),(0.65,0.66),(0.40,contract ? 0.48 : 0.83),(0.60,contract ? 0.48 : 0.83), color: accent, width: 4)
        arrow(0.50,from: contract ? 0.88 : 0.54,to: contract ? 0.73 : 0.72)
        label("骨盆底部",0.50,0.97)
      }
    }.accessibilityHidden(true)
  }
}
