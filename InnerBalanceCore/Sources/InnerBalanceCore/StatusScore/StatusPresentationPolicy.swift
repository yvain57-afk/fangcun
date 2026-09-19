import Foundation

public enum StatusPrimaryAction: String, Codable, Sendable {
  case resume, safety, quietRest, shortBreathing, breathing, unavailable, sync, connect
  public var title: String {
    switch self {
    case .resume: "继续练习"; case .safety: "查看安全帮助"; case .quietRest: "开始 2 分钟安静休息"
    case .shortBreathing: "开始 2 分钟放松"; case .breathing: "开始 5 分钟呼吸"
    case .unavailable: "先停靠到安全位置"; case .sync: "同步今日数据"; case .connect: "连接 Apple 健康"
    }
  }
}
public enum StatusPresentationPolicy {
  public static func action(score: DailyStatusSnapshot?, night: Bool, ongoing: Bool = false,
    severe: Bool = false, driving: Bool = false, avoidBreathing: Bool = false, tense: Bool = false) -> StatusPrimaryAction {
    if ongoing { return .resume }
    if severe { return .safety }
    if driving { return .unavailable }
    if avoidBreathing { return .quietRest }
    if night { return .shortBreathing }
    if tense { return .shortBreathing }
    guard let score else { return .sync }
    return score.band == .good ? .breathing : .quietRest
  }
}
