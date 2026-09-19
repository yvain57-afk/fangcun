import Foundation

public enum SleepScoreEngine {
  public static func evaluate(_ input: StatusScoreInput, configuration c: StatusScoreConfiguration = .init()) -> (Double?, [String: Double]) {
    guard input.sleepUsable, let minutes = input.sleepMinutes else { return (nil, [:]) }
    var subs = ["duration": 100 * min(minutes / c.sleepGoalMinutes, 1)]
    var numerator = subs["duration"]! * c.durationWeight, denominator = c.durationWeight
    if input.awakeCoverageComplete, let awake = input.awakeMinutes, minutes + awake > 0 {
      subs["continuity"] = 100 * minutes / (minutes + awake)
      numerator += subs["continuity"]! * c.continuityWeight; denominator += c.continuityWeight
    }
    if c.regularityEnabled, input.regularityHistoryDays >= 3, let delta = input.regularityDeltaMinutes {
      subs["regularity"] = 100 * max(0, 1 - delta / c.regularityZeroMinutes)
      numerator += subs["regularity"]! * c.regularityWeight; denominator += c.regularityWeight
    }
    return (numerator / denominator, subs)
  }
  public static func circularDistance(_ a: Double, _ b: Double) -> Double {
    let x = (a.truncatingRemainder(dividingBy: 1440) + 1440).truncatingRemainder(dividingBy: 1440)
    let y = (b.truncatingRemainder(dividingBy: 1440) + 1440).truncatingRemainder(dividingBy: 1440)
    return min(abs(x-y), 1440-abs(x-y))
  }
  public static func circularMedian(_ values: [Double]) -> Double? {
    guard !values.isEmpty, values.allSatisfy(\.isFinite) else { return nil }
    let normalized = values.map { ($0.truncatingRemainder(dividingBy: 1440) + 1440).truncatingRemainder(dividingBy: 1440) }
    return Set(normalized).sorted().min { a, b in
      let da = normalized.reduce(0) { $0 + circularDistance(a, $1) }, db = normalized.reduce(0) { $0 + circularDistance(b, $1) }
      return da == db ? a < b : da < db
    }
  }
}
public enum DailyStatusScoreEngine {
  public static func evaluate(_ i: StatusScoreInput, configuration c: StatusScoreConfiguration = .init()) throws -> StatusScoreResult {
    guard c.isValid else { throw StatusScoreError.invalidConfiguration }
    guard [i.sleepMinutes,i.awakeMinutes,i.regularityDeltaMinutes].compactMap({ $0 }).allSatisfy({ $0.isFinite && (0...1440).contains($0) }),
      [i.hrvDeviation,i.rhrDeviation].compactMap({ $0 }).allSatisfy(\.isFinite),
      [i.regularityHistoryDays,i.hrvDays,i.hrvSamples,i.hrvHours,i.rhrDays].allSatisfy({ $0 >= 0 }) else { throw StatusScoreError.invalidInput }
    let (sleep, subs) = SleepScoreEngine.evaluate(i, configuration: c)
    var parts: [StatusScoreComponent] = []
    if let sleep { parts.append(.init(name: "sleep", score: sleep, effectiveWeight: c.sleepWeight, normalizedWeight: 0)) }
    func cardio(_ z: Double) -> Double { min(c.maxCardioScore, max(0, c.nominalCardioScore - c.adverseMultiplier * max(z,0) + c.benefitMultiplier * min(max(-z,0),c.maxBenefitZ))) }
    if i.hrvUsable, let z = i.hrvDeviation, z >= c.highHRVExclusionZ, i.hrvDays >= c.minimumHistoryDays, i.hrvSamples > 0, i.hrvHours > 0 {
      let q = min(1,Double(i.hrvDays)/Double(c.fullHistoryDays)) * min(1,Double(i.hrvSamples)/Double(c.hrvFullSamples)) * min(1,Double(i.hrvHours)/Double(c.hrvFullHours))
      parts.append(.init(name: "hrv", score: cardio(z), effectiveWeight: c.hrvWeight*q, normalizedWeight: 0))
    }
    if i.rhrUsable, let z = i.rhrDeviation, i.rhrDays >= c.minimumHistoryDays {
      parts.append(.init(name: "rhr", score: cardio(z), effectiveWeight: c.rhrWeight * min(1,Double(i.rhrDays)/Double(c.fullHistoryDays)), normalizedWeight: 0))
    }
    let denominator = parts.reduce(0) { $0 + $1.effectiveWeight }
    guard denominator > 0 else { return .init(rawScore: nil, displayScore: nil, band: nil, components: [], sleepSubscores: subs) }
    for index in parts.indices { parts[index].normalizedWeight = parts[index].effectiveWeight / denominator }
    let raw = parts.reduce(0) { $0 + $1.score*$1.effectiveWeight } / denominator
    let score = Int(floor(min(100,max(0,raw))+0.5+1e-10))
    return .init(rawScore: raw, displayScore: score, band: StatusBand.resolve(score), components: parts, sleepSubscores: subs)
  }
}
