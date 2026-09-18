import InnerBalanceCore
import SwiftUI

struct PracticeFeature: View {
  let plan: PracticeProtocol
  let onStart: (PracticeLaunch) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(6)) {
      HStack(alignment: .top, spacing: FangcunLayout.spacing(4)) {
        VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
          Text(plan.kind.outcomeTitle)
            .font(.caption.weight(.bold))
            .foregroundStyle(InnerBalanceTheme.emphasis)
          Text(plan.kind.title)
            .font(.title.weight(.semibold))
            .foregroundStyle(InnerBalanceTheme.ink)
          Text(plan.kind.outcomeDetail)
            .font(.body)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
        PracticeFieldGlyph(kind: plan.kind, size: 92)
      }

      Button {
        onStart(PracticeLaunch(kind: plan.kind, duration: plan.defaultDuration))
      } label: {
        HStack {
          Text("开始")
          Spacer()
          Text(PracticeDurationFormatter.text(plan.defaultDuration))
            .font(.subheadline.monospacedDigit())
          Image(systemName: "arrow.right")
        }
      }
      .buttonStyle(PracticeLaunchButtonStyle())
      .accessibilityLabel("开始\(plan.kind.title)，1 分钟")
      .accessibilityIdentifier("practice.\(plan.kind.rawValue).\(Int(plan.defaultDuration))")
    }
    .padding(FangcunLayout.spacing(6))
    .background(
      InnerBalanceTheme.elevatedSurface,
      in: RoundedRectangle(cornerRadius: 28, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1)
    }
  }
}

struct PracticeLibraryRow: View {
  let plan: PracticeProtocol
  let onStart: (PracticeLaunch) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(4)) {
      HStack(alignment: .center, spacing: FangcunLayout.spacing(4)) {
        PracticeFieldGlyph(kind: plan.kind, size: 64)
        VStack(alignment: .leading, spacing: FangcunLayout.spacing(1)) {
          Text(plan.kind.outcomeTitle)
            .font(.caption.weight(.bold))
            .foregroundStyle(InnerBalanceTheme.emphasis)
          Text(plan.kind.title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(InnerBalanceTheme.ink)
          Text(plan.kind.outcomeDetail)
            .font(.subheadline)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      ViewThatFits(in: .horizontal) {
        HStack(spacing: FangcunLayout.spacing(3)) { durationButtons }
        VStack(spacing: FangcunLayout.spacing(2)) { durationButtons }
      }
    }
    .padding(FangcunLayout.spacing(5))
    .background(
      InnerBalanceTheme.elevatedSurface,
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1)
    }
  }

  @ViewBuilder private var durationButtons: some View {
    ForEach(plan.durationOptions, id: \.self) { duration in
      Button {
        onStart(PracticeLaunch(kind: plan.kind, duration: duration))
      } label: {
        HStack {
          Text(PracticeDurationFormatter.text(duration))
          Spacer(minLength: FangcunLayout.spacing(2))
          Image(systemName: "arrow.up.right")
            .font(.caption.weight(.semibold))
        }
      }
      .buttonStyle(PracticeDurationButtonStyle())
      .accessibilityLabel("开始\(plan.kind.title)，\(PracticeDurationFormatter.text(duration))")
      .accessibilityIdentifier("practice.\(plan.kind.rawValue).\(Int(duration))")
    }
  }
}

struct PracticeFieldGlyph: View {
  let kind: PracticeKind
  let size: CGFloat

  var body: some View {
    ZStack {
      Circle().fill(InnerBalanceTheme.subtleFill)
      Circle().strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1)
      switch PracticeStageKind.for(kind) {
      case .breathing:
        HStack(spacing: FangcunLayout.spacing(2)) {
          Capsule()
            .fill(InnerBalanceTheme.strongFill)
            .frame(width: size * 0.16, height: size * 0.52)
          Capsule()
            .stroke(InnerBalanceTheme.emphasis, lineWidth: 3)
            .frame(width: size * 0.16, height: size * 0.52)
        }
      case .settling:
        ForEach([0.62, 0.42, 0.22], id: \.self) { scale in
          Circle()
            .stroke(InnerBalanceTheme.emphasis.opacity(1.15 - scale), lineWidth: 2)
            .frame(width: size * scale, height: size * scale)
        }
      case .bodyScan:
        VStack(spacing: size * 0.06) {
          ForEach(0..<4) { index in
            Capsule()
              .fill(InnerBalanceTheme.strongFill.opacity(0.34 + Double(index) * 0.18))
              .frame(width: size * (0.28 + CGFloat(index) * 0.09), height: 4)
          }
        }
      case .pelvicFloor:
        ZStack {
          Capsule().stroke(InnerBalanceTheme.emphasis, lineWidth: 2)
            .frame(width: size * 0.42, height: size * 0.60)
          Capsule().fill(InnerBalanceTheme.strongFill.opacity(0.82))
            .frame(width: size * 0.18, height: size * 0.32)
        }
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

private struct PracticeLaunchButtonStyle: ButtonStyle {
  @Environment(\.fangcunReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(InnerBalanceTheme.inverseInk)
      .padding(.horizontal, FangcunLayout.spacing(5))
      .frame(maxWidth: .infinity, minHeight: 56)
      .background(
        InnerBalanceTheme.strongFill.opacity(configuration.isPressed ? 0.78 : 1),
        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
      )
      .scaleEffect(
        FangcunMotion.pressScale(
          isPressed: configuration.isPressed,
          reduceMotion: reduceMotion
        )
      )
      .animation(
        FangcunMotion.pressAnimation(reduceMotion: reduceMotion),
        value: configuration.isPressed
      )
  }
}

private struct PracticeDurationButtonStyle: ButtonStyle {
  @Environment(\.fangcunReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(InnerBalanceTheme.ink)
      .padding(.horizontal, FangcunLayout.spacing(4))
      .frame(maxWidth: .infinity, minHeight: 48)
      .background(
        InnerBalanceTheme.subtleFill.opacity(configuration.isPressed ? 0.58 : 1),
        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1)
      }
      .scaleEffect(
        FangcunMotion.pressScale(
          isPressed: configuration.isPressed,
          reduceMotion: reduceMotion
        )
      )
      .animation(
        FangcunMotion.pressAnimation(reduceMotion: reduceMotion),
        value: configuration.isPressed
      )
  }
}
