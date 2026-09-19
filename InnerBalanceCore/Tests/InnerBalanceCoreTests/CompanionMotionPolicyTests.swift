import Foundation
import Testing
@testable import InnerBalanceCore

@Suite struct CompanionMotionPolicyTests {
  @Test func commitsDeduplicateAndBackgroundDoesNotQueue() {
    let now = Date(); var c = CompanionMotionCoordinator()
    let e = CompanionEvent(id: "water-1", kind: .waterCommitted, entityID: "cup", revision: 1, committedAt: now)
    #expect(c.accept(e, scene: "dog-drink", context: "sheet", now: now)?.duration == 1.1)
    #expect(c.accept(e, scene: "dog-drink", context: "sheet", now: now) == nil)
    let hidden = CompanionEvent(id: "water-2", kind: .waterCommitted, committedAt: now)
    #expect(c.accept(hidden, scene: "dog-drink", context: "sheet", now: now, active: false) == nil)
    #expect(c.accept(hidden, scene: "dog-drink", context: "sheet", now: now) == nil)
  }
  @Test func accessibilityFailureAndRemoteNeverCelebrate() {
    for kind in [CompanionMotionEvent.saveFailed, .drinkCommitted] {
      let e = CompanionEvent(id: "remote", kind: kind, origin: "remote", committedAt: .now)
      #expect(CompanionMotionPolicy.resolve(e, scene: "dog-drink", context: "sheet", now: .now,
        mode: .standard, reduceMotion: false, lowPower: false, visible: true, active: true, covered: false, seen: []) == nil)
    }
    for mode in [CompanionMotionMode.standard, .gentle, .static] {
      let e = CompanionEvent(id: "reduce", kind: .waterCommitted, committedAt: .now)
      #expect(CompanionMotionPolicy.resolve(e, scene: "dog-drink", context: "sheet", now: .now,
        mode: mode, reduceMotion: true, lowPower: false, visible: true, active: true, covered: false, seen: []) == nil)
    }
  }
  @Test func distinctDrinkGesturesAndBreathPriority() {
    let now = Date(); var c = CompanionMotionCoordinator()
    #expect(c.accept(.init(id: "coffee", kind: .drinkCommitted, committedAt: now), scene: "dog-drink", context: "sheet", now: now)?.duration == 0.6)
    #expect(c.accept(.init(id: "undo", kind: .drinkUndone, committedAt: now), scene: "dog-drink", context: "sheet", now: now)?.duration == 0.25)
    #expect(c.accept(.init(id: "entry", kind: .entered, committedAt: now), scene: "breathing", context: "session", now: now, breathing: true) == nil)
  }
  @Test func tenRefreshesDoNotQueueAndRapidCommitsReplace() {
    let now = Date(); var c = CompanionMotionCoordinator(); var starts = 0
    for _ in 0..<10 {
      if c.accept(.init(id: "same-guidance", kind: .entered, committedAt: now), scene: "duo-calm", context: "home", now: now) != nil { starts += 1 }
    }
    #expect(starts == 1)
    for i in 0..<10 { _ = c.accept(.init(id: "cup-\(i)", kind: .waterCommitted, committedAt: now), scene: "dog-drink", context: "sheet", now: now) }
    #expect(c.current?.eventID == "cup-9")
    c.stop(); #expect(c.current == nil)
  }
  @Test func staticLowPowerCoveredOffscreenAndGentleAreExplicit() {
    let now = Date(); let e = CompanionEvent(id: "scene", kind: .entered, committedAt: now)
    for mode in [CompanionMotionMode.standard, .gentle, .static] {
      #expect(CompanionMotionPolicy.resolve(e, scene: "duo-calm", context: "home", now: now,
        mode: mode, reduceMotion: false, lowPower: true, visible: true, active: true, covered: false, seen: []) == nil)
    }
    var c = CompanionMotionCoordinator()
    #expect(c.accept(e, scene: "duo-calm", context: "home", now: now, covered: true) == nil)
    var other = CompanionMotionCoordinator()
    #expect(other.accept(e, scene: "duo-calm", context: "home", now: now, visible: false) == nil)
    var gentle = CompanionMotionCoordinator()
    #expect(gentle.accept(e, scene: "duo-calm", context: "home", now: now, mode: .gentle)?.intensity == 0.4)
  }
}
