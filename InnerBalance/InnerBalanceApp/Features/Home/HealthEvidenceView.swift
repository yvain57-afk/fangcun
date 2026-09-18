import InnerBalanceCore
import SwiftUI

struct HealthEvidenceView: View {
  let evidence: HomeHealthEvidence

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: iconName)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(iconColor)
        .frame(width: 28, height: 28)
        .background(iconColor.opacity(0.12), in: Circle())
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .firstTextBaseline) {
          Text(title)
            .font(.subheadline.weight(.medium))
          Spacer(minLength: 12)
          Text(evidence.valueText)
            .font(.subheadline.monospacedDigit().weight(.semibold))
        }

        Text(detailText)
          .font(.caption)
          .foregroundStyle(InnerBalanceTheme.mutedInk)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var title: String {
    switch evidence.kind {
    case .heartRateVariability: "心率变异性"
    case .restingHeartRate: "静息心率"
    case .respiratoryRate: "呼吸频率"
    case .sleep: "主睡眠"
    }
  }

  private var iconName: String {
    switch evidence.kind {
    case .heartRateVariability: "waveform.path.ecg"
    case .restingHeartRate: "heart.fill"
    case .respiratoryRate: "lungs.fill"
    case .sleep: "moon.stars.fill"
    }
  }

  private var iconColor: Color {
    switch evidence.reliability {
    case .needsReview: InnerBalanceTheme.emphasis
    case .stale: InnerBalanceTheme.mutedInk
    case .buildingBaseline, .reliable:
      evidence.deviation == .elevated ? InnerBalanceTheme.emphasis : InnerBalanceTheme.strongFill
    }
  }

  private var detailText: String {
    let reliability =
      switch evidence.reliability {
      case .reliable: evidence.deviation == .elevated ? "偏离近期参考" : "在近期参考内"
      case .buildingBaseline: "原始读数 · 基线尚未完成"
      case .needsReview: "数据需要确认"
      case .stale: "超过 36 小时 · 不参与当前判断"
      }
    let time = evidence.measuredAt.formatted(.relative(presentation: .named))
    let assessment = evidence.assessmentValueText.map { " · \($0)" } ?? ""
    return "\(evidence.sourceName) · 最新测量于 \(time)\(assessment) · \(reliability)"
  }
}
