import SwiftUI
import InnerBalanceCore

/// Authored cutout layers move as rigid pieces. Faces and silhouettes are never warped.
/// Every pose is a pure function of the same elapsed time as audio and phase guidance.
struct PracticeCompanionV4: View {
  let kind: PracticeKind
  let elapsed: Double
  let duration: Double
  var variantID: String? = nil
  var isActive = true
  var entryProgress = 1.0
  var completionProgress = 0.0
  var reduceMotionOverride = false
  @Environment(\.accessibilityReduceMotion) private var systemReduced
  @AppStorage("fangcun.reduceMotion") private var reduceMotion = false
  @AppStorage("fangcun.motionMode") private var motionMode = "standard"

  private var snapshot: PracticeTimelineSnapshot {
    PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: duration, variantID: variantID)
  }
  private var strength: Double {
    (systemReduced || reduceMotion || reduceMotionOverride || motionMode == "static" || ProcessInfo.processInfo.isLowPowerModeEnabled) ? 0 : (motionMode == "gentle" ? 0.55 : 1)
  }
  private var pose: LittleExhalePose {
    LittleExhalePose.make(kind: kind, snapshot: snapshot, strength: strength)
  }
  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let height = geometry.size.height
      Group {
        switch kind {
        case .physiologicalSigh:
          LittleExhaleCat(opening: pose.pawOpening)
        case .balancedBreathing:
          HStack(alignment: .bottom, spacing: 0) {
            LittleExhaleCat(opening: pose.pawOpening).frame(width: width * 0.48)
            LittleExhaleRestingDog(lift: pose.headLift).frame(width: width * 0.52)
          }.frame(height: height * 0.86)
        case .pacedBreathing:
          LittleExhaleRestingDog(lift: pose.headLift)
        case .boxBreathing:
          LittleExhaleCat(opening: pose.pawOpening, pointing: true)
        case .diaphragmaticBreathing:
          LittleExhaleSeatedDog(leftLift: pose.leftLift, rightLift: pose.rightLift)
        case .alternateNostrilBreathing:
          LittleExhaleSeatedDog(leftLift: pose.leftLift, rightLift: pose.rightLift)
        case .meditation:
          LittleExhaleCat(opening: 0, resting: true, settling: pose.settling)
        case .nsdr:
          LittleExhaleRestingDog(lift: pose.headLift)
        case .kegel:
          LittleExhaleSeatedDog(leftLift: 0, rightLift: pose.rightLift, flag: true)
        case .progressiveMuscleRelaxation:
          LittleExhaleCat(opening: pose.pawOpening, resting: true)
        }
      }.frame(width: width, height: height)
    }
    .accessibilityElement(children: .ignore).accessibilityLabel(stageLabel)
    .accessibilityIdentifier("practice.companion")
  }

  private var stageLabel: String {
    switch kind {
    case .physiologicalSigh: "Cat opens its paws with the two-part inhale, then lowers them as you exhale"
    case .pacedBreathing: "Dog gently lifts its chin, then settles onto its paws with the longer exhale"
    case .balancedBreathing: "Cat and dog follow the same even breathing rhythm"
    case .boxBreathing: "Cat opens its paws to breathe in, stays still during holds, and settles to breathe out"
    case .diaphragmaticBreathing: "Dog rests its paws by its lower ribs. Follow your own breathing rhythm"
    case .alternateNostrilBreathing: "Dog gestures toward your left or right side, following the current cue"
    case .meditation: "Cat sits with closed eyes, quietly keeping you company"
    case .nsdr: "Dog settles into rest. There is no breathing pace to follow"
    case .kegel: "Dog raises its flag for a gentle lift, then lowers it for a full release. Breathe normally"
    case .progressiveMuscleRelaxation: "Cat gently opens its paws after the hand exercise, then rests while you follow the remaining muscle groups"
    }
  }
}

/// Separate from View composition so pause/reduced-motion and phase behavior can be replayed.
struct LittleExhalePose: Equatable {
  var pawOpening = 0.0
  var headLift = 0.0
  var leftLift = 0.0
  var rightLift = 0.0
  var settling = 0.0

  static func make(kind: PracticeKind, snapshot: PracticeTimelineSnapshot, strength: Double) -> Self {
    let s = min(1, max(0, strength))
    let motion = PracticeVisualMotion(kind: kind, snapshot: snapshot)
    var pose = Self()
    switch kind {
    case .physiologicalSigh, .balancedBreathing, .boxBreathing:
      pose.pawOpening = motion.expansion * s
      pose.headLift = motion.expansion * s
    case .pacedBreathing:
      pose.headLift = motion.expansion * s
    case .alternateNostrilBreathing:
      // Small arrival gesture, then hold the correct side. Never mirror user directions.
      let arrive = PracticeVisualMotion.eased(snapshot.elapsedInPhase / 0.5)
      pose.leftLift = motion.side == -1 ? arrive * s : 0
      pose.rightLift = motion.side == 1 ? arrive * s : 0
    case .diaphragmaticBreathing:
      // One settling gesture at each spoken cue, not an invented recurring breath pace.
      let settle = 1 - PracticeVisualMotion.eased(snapshot.segmentElapsed / 2.4)
      pose.leftLift = 0.18 * settle * s
      pose.rightLift = 0.18 * settle * s
    case .meditation:
      pose.settling = PracticeVisualMotion.eased(snapshot.segmentElapsed / 2.4) * s
    case .nsdr:
      pose.headLift = 0.18 * (1 - PracticeVisualMotion.eased(snapshot.segmentElapsed / 2.4)) * s
    case .kegel:
      pose.rightLift = motion.contraction * s
    case .progressiveMuscleRelaxation:
      // Hands close for hand tension and open for release. Other muscle groups stay still.
      pose.pawOpening = 0.35 * s
      if snapshot.segment?.focus == "pmr_m01_gentle_tension" {
        pose.pawOpening = 0.35 * (1 - PracticeVisualMotion.eased(snapshot.segmentElapsed / 0.6)) * s
      } else if snapshot.segment?.focus == "pmr_m01_release" {
        pose.pawOpening = 0.35 * PracticeVisualMotion.eased(snapshot.segmentElapsed / 1.6) * s
      }
    }
    return pose
  }
}

struct LittleExhaleCat: View {
  var opening: Double
  var resting = false
  var pointing = false
  var settling = 0.0
  var body: some View {
    GeometryReader { geometry in
      let w = min(geometry.size.width * 0.93, geometry.size.height * 0.91)
      let h = w * 571 / 545
      ZStack {
        Image(resting ? "LE2-cat-rest-base" : "LE2-cat-base")
          .resizable().scaledToFit().frame(width: w, height: h)
        paw("left", width: w * 0.23, angle: 48 * opening,
          anchor: UnitPoint(x: 0.24, y: 0.20))
          .position(x: w * 0.49, y: h * (0.71 - 0.055 * opening + 0.01 * settling))
        paw("right", width: w * 0.23, angle: -(pointing ? 62 : 48) * opening,
          anchor: UnitPoint(x: 0.76, y: 0.20))
          .position(x: w * 0.76, y: h * (0.71 - 0.055 * opening + 0.01 * settling))
      }.frame(width: w, height: h)
        .position(x: geometry.size.width * 0.46, y: geometry.size.height * 0.50)
    }.accessibilityHidden(true)
  }
  private func paw(_ side: String, width: CGFloat, angle: Double, anchor: UnitPoint) -> some View {
    Image("LE2-cat-" + side + "-paw").resizable().scaledToFit()
      .frame(width: width, height: width * 1.09)
      .rotationEffect(.degrees(angle), anchor: anchor)
  }
}

struct LittleExhaleRestingDog: View {
  let lift: Double
  var body: some View {
    GeometryReader { geometry in
      let w = min(geometry.size.width, geometry.size.height / 0.75)
      let h = w * 0.75
      ZStack {
        Image("LE2-dog-rest-body").resizable().scaledToFit()
          .frame(width: w, height: w * 302 / 586)
          .position(x: w * 0.5, y: h * 0.64)
        Image("LE2-dog-rest-head").resizable().scaledToFit()
          .frame(width: w * 0.64, height: w * 0.64 * 301 / 489)
          .rotationEffect(.degrees(-2.2 * lift), anchor: .bottom)
          .position(x: w * 0.35, y: h * 0.39 - w * 0.035 * lift)
        Image("LE2-dog-rest-paws").resizable().scaledToFit()
          .frame(width: w * 235 / 586, height: w * 85 / 586)
          .position(x: w * (42 + 117.5) / 586, y: h * 0.64 + w * (154 + 42.5 - 151) / 586)
      }.frame(width: w, height: h)
        .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.54)
    }.accessibilityHidden(true)
  }
}

struct LittleExhaleSeatedDog: View {
  let leftLift: Double
  let rightLift: Double
  var flag = false
  var body: some View {
    GeometryReader { geometry in
      let w = min(geometry.size.width * 0.90, geometry.size.height * 0.93)
      let h = w * 544 / 539
      ZStack {
        Image("LE2-dog-base").resizable().scaledToFit().frame(width: w, height: h)
        Image("LE2-dog-left-paw").resizable().scaledToFit().frame(width: w * 0.22)
          .rotationEffect(.degrees(38 * leftLift), anchor: UnitPoint(x: 0.25, y: 0.15))
          .position(x: w * 0.29, y: h * (0.73 - 0.04 * leftLift))
        ZStack {
          if flag {
            Image("LE2-flag").resizable().scaledToFit().frame(width: w * 0.29)
              .offset(x: w * 0.07, y: -w * 0.13)
          }
          Image("LE2-dog-right-paw").resizable().scaledToFit().frame(width: w * 0.22)
        }.frame(width: w * 0.22, height: w * 0.23)
          .rotationEffect(.degrees(-42 * rightLift), anchor: UnitPoint(x: 0.75, y: 0.15))
          .position(x: w * 0.53, y: h * (0.73 - 0.04 * rightLift))
      }.frame(width: w, height: h)
        .position(x: geometry.size.width * 0.54, y: geometry.size.height * 0.50)
    }.accessibilityHidden(true)
  }
}
