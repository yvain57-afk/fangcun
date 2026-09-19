import Foundation

public enum CompanionMotionMode: String, Codable, Sendable { case standard, gentle, `static` }
public enum CompanionMotionEvent: String, Codable, Sendable {
  case entered, guidanceChanged, waterCommitted, drinkCommitted, drinkUndone, practicePhaseChanged
  case paused, completed, endedEarly, saveFailed, inactive
}
public struct CompanionPresentation: Sendable {
  public var scene: String
  public var context: String
  public var eventID: String
  public var event: CompanionMotionEvent
  public var intensity: Double
  public var duration: TimeInterval
}
public struct CompanionEvent: Sendable {
  public var id: String
  public var kind: CompanionMotionEvent
  public var origin: String
  public var entityID: String?
  public var revision: Int?
  public var committedAt: Date
  public init(id: String, kind: CompanionMotionEvent, origin: String = "local", entityID: String? = nil,
    revision: Int? = nil, committedAt: Date) {
    self.id = id; self.kind = kind; self.origin = origin; self.entityID = entityID
    self.revision = revision; self.committedAt = committedAt
  }
}
public enum CompanionMotionPolicy {
  public static func resolve(_ event: CompanionEvent, scene: String, context: String,
    now: Date, mode: CompanionMotionMode, reduceMotion: Bool, lowPower: Bool, visible: Bool,
    active: Bool, covered: Bool, seen: Set<String>, breathing: Bool = false) -> CompanionPresentation? {
    guard active, visible, !covered, !lowPower, !reduceMotion, mode != .static,
      event.origin == "local", !seen.contains(event.id), now.timeIntervalSince(event.committedAt) >= 0,
      now.timeIntervalSince(event.committedAt) < 3, ![.saveFailed, .inactive, .paused].contains(event.kind),
      !breathing || event.kind == .practicePhaseChanged else { return nil }
    let duration: Double
    switch event.kind {
    case .waterCommitted: duration = 1.1
    case .drinkCommitted: duration = 0.6
    case .drinkUndone: duration = 0.25
    case .completed: duration = 1.3
    case .endedEarly: duration = 0.8
    default: duration = scene == "duo-calm" ? 1.8 : scene == "dog-drink" ? 0.8 : 1.6
    }
    return .init(scene: scene, context: context, eventID: event.id, event: event.kind,
      intensity: mode == .gentle ? 0.4 : 1, duration: duration)
  }
}

/// One current gesture, no queue. Consumes IDs even when an event is suppressed, so
/// background, retry and covered-view changes cannot replay on the next appearance.
public struct CompanionMotionCoordinator: Sendable {
  public private(set) var seen: Set<String> = []
  public private(set) var current: CompanionPresentation?
  public init() {}
  public mutating func accept(_ event: CompanionEvent, scene: String, context: String, now: Date,
    mode: CompanionMotionMode = .standard, reduceMotion: Bool = false, lowPower: Bool = false,
    visible: Bool = true, active: Bool = true, covered: Bool = false, breathing: Bool = false) -> CompanionPresentation? {
    let next = CompanionMotionPolicy.resolve(event, scene: scene, context: context, now: now, mode: mode,
      reduceMotion: reduceMotion, lowPower: lowPower, visible: visible, active: active, covered: covered,
      seen: seen, breathing: breathing)
    seen.insert(event.id)
    if let next { current = next }
    if !active || !visible || covered { current = nil }
    return next
  }
  public mutating func stop() { current = nil }
}
