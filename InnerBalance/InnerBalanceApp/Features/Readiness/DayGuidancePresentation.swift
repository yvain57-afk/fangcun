import Foundation
import InnerBalanceCore

/// User-facing meaning is composed once. Diagnostic flags never become a list of warnings.
struct DayGuidancePresentation {
  enum Kind: String { case recoveryAssessment, scopedAdvice, onboarding, serviceIssue }
  struct Copy: Equatable {
    let key: String
    var number: Double? = nil
    var text: String { number.map { FangcunCopy.text(key, $0) } ?? FangcunCopy.text(key) }
  }
  let kind: Kind
  let titleKey: String
  let reasons: [Copy]
  let actionKey: String
  let noteKey: String?
  let basisIDs: [String]
  let asOf: Date?
  let scene: FangcunCompanionScene
  var title: String { FangcunCopy.text(titleKey) }
  var summary: String { reasons.map(\.text).joined(separator: "\n") }

  static func resolve(_ a: ReadinessAssessment?, reading: Bool = true, serviceError: Bool = false) -> Self {
    let current = a?.freshness == .current
    let ids = a.map { [$0.assessmentID] } ?? []
    func result(_ kind: Kind, _ title: String, _ reasons: [Copy], _ action: String = "pause", _ note: String? = nil,
      _ scene: FangcunCompanionScene = .curious) -> Self {
      .init(kind: kind, titleKey: "guidance." + title, reasons: Array(reasons.prefix(2)),
        actionKey: "guidance.action." + action, noteKey: note.map { "guidance." + $0 }, basisIDs: ids,
        asOf: current ? a?.latestMeasuredAt : nil, scene: scene)
    }
    guard reading else { return result(.onboarding, "paused", [.init(key: "guidance.reason.paused")]) }
    if let a, current, let level = a.level, a.availability == .assessable || a.availability == .provisional {
      var reasons: [Copy] = []
      if let seconds = a.actualSleepSeconds, a.sleepDurationUsable {
        reasons.append(.init(key: "guidance.reason.sleep", number: seconds / 3600))
      }
      reasons.append(.init(key: "guidance.reason." + ((a.autonomicSeverity ?? 0) > 0 ? "bodyLower" : (a.sleepSeverity ?? 0) > 0 ? "sleepShort" : "bodyUsual")))
      return result(.recoveryAssessment, level.rawValue, reasons, level == .usual ? "rhythm" : "ease",
        a.refreshFailure != nil || serviceError ? "cached" : a.availability == .provisional ? "provisional" : nil,
        level == .usual ? .calm : .rest)
    }
    if serviceError || a?.availability == .failed {
      return result(.serviceIssue, "service", [.init(key: "guidance.reason.service")], "retry")
    }
    if let a, current, a.sleepDurationUsable, let seconds = a.actualSleepSeconds {
      let short = seconds < a.configuration.sleepTargetHours
        * 3600 // User's selected target; does not change the assessment model.
      return result(.scopedAdvice, "sleepAdvice", [.init(key: "guidance.reason.sleep", number: seconds / 3600),
        .init(key: short ? "guidance.reason.sleepShort" : "guidance.reason.sleepOnly")], short ? "ease" : "pause", "scoped", short ? .rest : .curious)
    }
    if let a, current, a.evidence.contains(where: { $0.feature.reliable && $0.feature.displayValue != nil }) {
      return result(.scopedAdvice, "facts", [.init(key: "guidance.reason.facts")], "pause", "scoped")
    }
    return result(.onboarding, "notYet", [.init(key: "guidance.reason.notYet")], "pause")
  }
}
