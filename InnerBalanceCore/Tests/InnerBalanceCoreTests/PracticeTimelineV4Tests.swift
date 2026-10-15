import Foundation
import Testing
@testable import InnerBalanceCore

@Suite("V4 nine protocols and shared timeline")
struct PracticeTimelineV4Tests {
  @Test("Nine stable IDs, preserved legacy parameters and explicit default durations")
  func catalog() {
    #expect(Set(PracticeCatalog.v4.map(\.kind)) == Set(PracticeKind.allCases))
    #expect(PracticeCatalog.v4.count == 9)
    #expect(PracticeCatalog.v4.filter { PracticeTimeline.mode(for: $0.kind) == .pacedBreath }.count == 5)
    #expect(PracticeCatalog.v4.first { $0.kind == .physiologicalSigh }?.defaultDuration == 300)
    #expect(PracticeCatalog.v4.first { $0.kind == .pacedBreathing }?.defaultDuration == 300)
    #expect(PracticeCatalog.protocol(for: .physiologicalSigh)?.defaultDuration == 60)
    #expect(PracticeCatalog.protocol(for: .pacedBreathing)?.defaultDuration == 180)
    #expect(PracticeKind.allCases.filter(\.isLegacyWatchExecutable).count == 5)
    #expect(PracticeCatalog.v4.filter { !$0.writesMindfulSession }.map(\.kind) == [.kegel])
  }

  @Test("Every phase boundary uses the configured length, including hold and side")
  func boundaries() {
    let expected: [(PracticeKind, String?, [(PracticeBreathPhase, Double)])] = [
      (.physiologicalSigh, nil, [(.inhale, 3), (.topUp, 2), (.exhale, 7)]),
      (.pacedBreathing, nil, [(.inhale, 4), (.exhale, 6)]),
      (.balancedBreathing, nil, [(.inhale, 5), (.exhale, 5)]),
      (.balancedBreathing, "easy_4_4", [(.inhale, 4), (.exhale, 4)]),
      (.boxBreathing, nil, [(.inhale, 3), (.holdAfterInhale, 3), (.exhale, 3), (.holdAfterExhale, 3)]),
      (.alternateNostrilBreathing, nil, [(.leftInhale, 3), (.rightExhale, 3), (.rightInhale, 3), (.leftExhale, 3)]),
      (.kegel, nil, [(.contract, 4), (.release, 8)])
    ]
    for (kind, variant, steps) in expected {
      var elapsed = 0.0
      for (index, step) in steps.enumerated() {
        let state = PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: 300, variantID: variant)
        #expect(state.phase == step.0)
        #expect(state.phaseDuration == step.1)
        #expect(state.phaseProgress == 0)
        #expect(state.cueID == index)
        #expect(PracticeTimeline.snapshot(kind: kind, elapsed: elapsed + step.1 - 0.001, duration: 300, variantID: variant).phase == step.0)
        elapsed += step.1
      }
      let next = PracticeTimeline.snapshot(kind: kind, elapsed: elapsed, duration: 300, variantID: variant)
      #expect(next.phase == steps[0].0)
      #expect(next.cycleIndex == 1)
    }
    #expect(PracticeTimeline.variantID(for: .balancedBreathing, requested: "unknown") == "equal_5_5")
  }

  @Test("All guided durations have contiguous unique non-looping segments and no fake inhale")
  func naturalAndBodyScan() {
    for kind: PracticeKind in [.diaphragmaticBreathing, .meditation, .nsdr] {
      for duration in PracticeCatalog.protocol(for: kind)!.durationOptions {
        let segments = PracticeTimeline.segments(for: kind, duration: duration)
        #expect(segments.first?.start == 0)
        #expect(segments.last?.end == duration)
        #expect(Set(segments.map(\.id)).count == segments.count)
        for (index, segment) in segments.enumerated() {
          #expect(segment.end > segment.start)
          if index > 0 { #expect(segments[index-1].end == segment.start) }
          let state = PracticeTimeline.snapshot(kind: kind, elapsed: segment.start, duration: duration)
          #expect(state.phase == nil)
          #expect(state.segment == segment)
          #expect(state.cueID == index)
          #expect(state.segmentElapsed == 0)
        }
      }
    }
    #expect(PracticeTimeline.snapshot(kind: .nsdr, elapsed: 570, duration: 600).segment?.focus == "return")
    #expect(PracticeTimeline.snapshot(kind: .nsdr, elapsed: 1170, duration: 1200).segment?.focus == "return")
    #expect(PracticeBreathGuide.state(for: .meditation, elapsed: 0).phase == .natural)
  }

  @Test("Legacy raw values and unknown Watch payload stay lossless")
  func legacyAndUnknown() throws {
    for id in ["physiologicalSigh", "pacedBreathing", "meditation", "nsdr", "kegel"] {
      #expect(try JSONDecoder().decode(PracticeKind.self, from: Data("\"\(id)\"".utf8)).rawValue == id)
    }
    let payload = WatchMindfulPayload(syncIdentifier: "synthetic", sessionID: "test", practiceKind: .balancedBreathing, startDate: .distantPast, endDate: .distantPast)
    var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any])
    json["practiceKindRawValue"] = "future_method"
    let decoded = try JSONDecoder().decode(WatchMindfulPayload.self, from: JSONSerialization.data(withJSONObject: json))
    #expect(decoded.practiceKindRawValue == "future_method")
    #expect(PracticeKind(rawValue: decoded.practiceKindRawValue) == nil)
  }
}
