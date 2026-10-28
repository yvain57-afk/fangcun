import Foundation

public enum StatusPrimaryAction: String, Codable, Sendable {
  case resume, safety, seatedStretch, quietRest, shortBreathing, breathing, unavailable, sync, connect, resumeReading
  public var title: String {
    switch self {
    case .resumeReading: "Resume body context"
    case .resume: "Continue practice"; case .safety: "Get safety help"; case .quietRest: "Take 2 minutes of quiet rest"
    case .seatedStretch: "A 1-minute seated stretch"
    case .shortBreathing: "Unwind for 2 minutes"; case .breathing: "Breathe for 5 minutes"
    case .unavailable: "Stop somewhere safe first"; case .sync: "Sync today's data"; case .connect: "Connect Apple Health"
    }
  }
}
public enum StatusPresentationPolicy {
  public static func action(score: DailyStatusSnapshot?, night: Bool, ongoing: Bool = false,
    severe: Bool = false, driving: Bool = false, avoidBreathing: Bool = false, tense: Bool = false, avoidRest: Bool = false, favoriteBreathing: Bool = true) -> StatusPrimaryAction {
    if ongoing { return .resume }
    if severe { return .safety }
    if driving { return .unavailable }
    if avoidBreathing { return avoidRest ? .seatedStretch : .quietRest }
    if night { return .shortBreathing }
    if tense { return .shortBreathing }
    guard let score else { return .sync }
    return score.band == .good && favoriteBreathing ? .breathing : avoidRest ? .seatedStretch : .quietRest
  }
}
