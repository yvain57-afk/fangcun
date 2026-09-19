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
}
