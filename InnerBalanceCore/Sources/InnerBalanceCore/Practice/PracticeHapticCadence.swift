import Foundation

public enum PracticeHapticCadence {
  public static func consumeCue(
    for kind: PracticeKind,
    elapsed: TimeInterval,
    isActive: Bool,
    isEnabled: Bool,
    lastCueID: inout Int?
  ) -> Bool {
    guard isActive, isEnabled else { return false }
    let currentCueID = cueID(for: kind, elapsed: elapsed)
    guard currentCueID != lastCueID else { return false }
    lastCueID = currentCueID
    return true
  }

  public static func cueID(for kind: PracticeKind, elapsed: TimeInterval) -> Int {
    let elapsed = max(0, elapsed)
    switch kind {
    case .physiologicalSigh:
      let cycle = Int(elapsed / 12)
      let position = elapsed.truncatingRemainder(dividingBy: 12)
      let phase = position < 3 ? 0 : position < 5 ? 1 : 2
      return cycle * 3 + phase
    case .pacedBreathing:
      let cycle = Int(elapsed / 10)
      let phase = elapsed.truncatingRemainder(dividingBy: 10) < 4 ? 0 : 1
      return cycle * 2 + phase
    case .meditation:
      return Int(elapsed / 10)
    case .nsdr:
      return Int(elapsed / 20)
    case .kegel:
      let cycle = Int(elapsed / 12)
      let phase = elapsed.truncatingRemainder(dividingBy: 12) < 4 ? 0 : 1
      return cycle * 2 + phase
    }
  }
}
