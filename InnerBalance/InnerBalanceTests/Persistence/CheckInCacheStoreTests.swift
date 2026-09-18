import Foundation
import InnerBalanceCore
import SwiftData
import Testing

@testable import InnerBalance

@Suite("Local check-in cache")
struct CheckInCacheStoreTests {
  @Test("A newer sync version replaces the same check-in without duplication")
  @MainActor
  func newerVersionReplacesExistingRecord() throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: CachedCheckIn.self,
      configurations: configuration
    )
    let store = CheckInCacheStore(modelContext: container.mainContext)
    let version1 = makeRecord(version: 1, labels: [.anxious])
    let version2 = makeRecord(version: 2, labels: [.stressed])

    try store.upsert(version1)
    try store.upsert(version2)
    try store.upsert(version1)

    let cached = try container.mainContext.fetch(FetchDescriptor<CachedCheckIn>())
    #expect(cached.count == 1)
    #expect(cached.first?.syncVersion == 2)
    #expect(try store.latestRecord()?.labels == [.stressed])
  }

  @Test("A HealthKit deletion removes the matching cached check-in")
  @MainActor
  func healthKitDeletionRemovesCachedRecord() throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: CachedCheckIn.self,
      configurations: configuration
    )
    let store = CheckInCacheStore(modelContext: container.mainContext)
    let objectUUID = UUID()

    try store.upsert(
      makeRecord(version: 1, labels: [.anxious]),
      healthKitObjectUUID: objectUUID
    )
    try store.delete(healthKitObjectUUIDs: [objectUUID])

    #expect(try store.latestRecord() == nil)
  }

  @Test("最后一条 HealthKit 情绪被删除后首页状态会完整清空")
  @MainActor
  func emptyLatestRecordClearsHomeState() {
    let state = LatestCheckInViewState(record: nil)

    #expect(state.record == nil)
    #expect(state.date == nil)
    #expect(state.title == nil)
  }

  @Test("练习后的空上下文不会清掉当天已选压力来源")
  @MainActor
  func latestContextSurvivesANewerPostPracticeRecord() throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: CachedCheckIn.self,
      configurations: configuration
    )
    let store = CheckInCacheStore(modelContext: container.mainContext)
    let day = Date(timeIntervalSince1970: 1_786_320_000)
    let standalone = makeRecord(version: 1, labels: [.anxious])
    let post = StateOfMindRecord(
      syncIdentifier: "post-practice",
      syncVersion: 1,
      date: day.addingTimeInterval(600),
      valence: 0.3,
      arousal: -0.4,
      labels: [.relieved],
      associations: [],
      bodySensationCodes: [],
      unclassified: false,
      origin: .iPhone,
      sessionID: "practice-1",
      phase: .post
    )

    try store.upsert(standalone)
    try store.upsert(post)

    #expect(try store.latestRecord()?.syncIdentifier == "post-practice")
    #expect(try store.latestContextRecord(on: day)?.associations == [.work])
  }

  private func makeRecord(version: Int, labels: [EmotionLabel]) -> StateOfMindRecord {
    StateOfMindRecord(
      syncIdentifier: "check-in-cache",
      syncVersion: version,
      date: Date(timeIntervalSince1970: 1_786_320_000),
      valence: -0.6,
      arousal: 0.7,
      labels: labels,
      associations: [.work],
      bodySensationCodes: ["shoulders_tight"],
      unclassified: false,
      origin: .iPhone,
      sessionID: nil,
      phase: .standalone
    )
  }
}
