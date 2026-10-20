import Foundation
import InnerBalanceCore
import SwiftData
import Testing
@testable import InnerBalance

@Suite("PMR additive persistence and permission boundary")
@MainActor struct PracticePMRPersistenceTests {
  private func record(_ id: String, kind: PracticeKind = .progressiveMuscleRelaxation,
    variant: String? = "pmr_day", version: String? = "fangcun-pmr-1.0") -> PracticeCompletionRecord {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    return .init(sessionID: id, practiceKind: kind, plannedDuration: 600, actualDuration: 120,
      startedAt: start, endedAt: start.addingTimeInterval(120), beforeRating: nil, afterRating: nil,
      metadata: version.map { .init(protocolVersion: $0, timelineVariantID: variant,
        sceneID: "dog_gentle_release", completionStatus: "endedEarly", completedCycles: 0,
        activeIntervals: [.init(start: start, end: start.addingTimeInterval(120))]) })
  }

  @Test("PMR day and sleep survive a cold disk reopen alongside untouched V4 and legacy rows")
  func coldReopen() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("pmr-synthetic-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("records.store")
    let records = [record("pmr-day"), record("pmr-sleep", variant: "pmr_sleep"),
      record("v4", kind: .nsdr, variant: nil, version: "fangcun-practice-v4.0"),
      record("legacy", kind: .pacedBreathing, variant: nil, version: nil)]
    do {
      let container = try ModelContainer(for: StoredPracticeCompletion.self, configurations: ModelConfiguration(url: url))
      let store = PracticeCompletionStore(modelContext: container.mainContext)
      for item in records { try store.save(item, mindfulWriteResult: .saved) }
    }
    let reopened = try ModelContainer(for: StoredPracticeCompletion.self, configurations: ModelConfiguration(url: url))
    let store = PracticeCompletionStore(modelContext: reopened.mainContext)
    #expect(try reopened.mainContext.fetchCount(FetchDescriptor<StoredPracticeCompletion>()) == 4)
    for item in records { #expect(try store.completion(sessionID: item.sessionID)?.record == item) }
    let rows = try reopened.mainContext.fetch(FetchDescriptor<StoredPracticeCompletion>())
    #expect(Set(rows.compactMap(\.record).map(\.sessionID)) == Set(records.map(\.sessionID)))
  }

  @Test("PMR completion is idempotent and cannot request any HealthKit writes")
  func localOnlyCompletion() async throws {
    let container = try ModelContainer(for: StoredPracticeCompletion.self, PendingHealthWrite.self, CachedCheckIn.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let writer = PMRRecordingWriter()
    let store = PracticeCompletionStore(modelContext: container.mainContext)
    let coordinator = PracticeCompletionCoordinator(store: store,
      feedbackStore: PracticeFeedbackStore(modelContainer: container),
      healthWriter: HealthWriteCoordinator(writer: writer, modelContext: container.mainContext))
    let item = record("pmr-local-only", variant: "pmr_sleep")
    _ = try await coordinator.saveCompletion(item)
    _ = try await coordinator.saveCompletion(item)
    _ = try await coordinator.saveFeedback(item, postValence: 0, postArousal: 0)
    #expect(try store.completion(sessionID: item.sessionID)?.record == item)
    #expect(try container.mainContext.fetchCount(FetchDescriptor<StoredPracticeCompletion>()) == 1)
    #expect(writer.mindfulWrites == 0 && writer.stateWrites == 0)
    #expect(try container.mainContext.fetchCount(FetchDescriptor<PendingHealthWrite>()) == 0)
    #expect(try container.mainContext.fetchCount(FetchDescriptor<CachedCheckIn>()) == 0)
  }

  @Test("Unknown protocol versions remain unreadable and preserve their original bytes")
  func unknownVersionIsNotLegacy() {
    for kind in [PracticeKind.nsdr, .progressiveMuscleRelaxation] {
      let stored = StoredPracticeCompletion(record: record("unknown", kind: kind, version: "future-999"),
        mindfulWriteResult: .saved, postWriteResult: .saved)
      let original = stored.protocolMetadata
      #expect(stored.record == nil)
      #expect(stored.protocolMetadata == original)
    }
    let wrongKind = StoredPracticeCompletion(record: record("wrong-kind", kind: .nsdr),
      mindfulWriteResult: .saved, postWriteResult: .saved)
    #expect(wrongKind.record == nil)
  }
}

@MainActor private final class PMRRecordingWriter: HealthWriting {
  private(set) var mindfulWrites = 0
  private(set) var stateWrites = 0
  func saveStateOfMind(_ record: StateOfMindRecord) async throws { stateWrites += 1 }
  func saveMindfulSession(_ record: MindfulSessionRecord) async throws { mindfulWrites += 1 }
}
