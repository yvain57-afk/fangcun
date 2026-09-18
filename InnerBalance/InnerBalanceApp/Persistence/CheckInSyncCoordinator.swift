import Foundation

@MainActor
final class CheckInSyncCoordinator {
  private let repository: HealthKitRepository
  private let cacheStore: CheckInCacheStore

  init(repository: HealthKitRepository, cacheStore: CheckInCacheStore) {
    self.repository = repository
    self.cacheStore = cacheStore
  }

  func refresh() async -> StateOfMindRecord? {
    do {
      let batch = try await repository.ownStateOfMindChanges()
      for addition in batch.additions {
        try cacheStore.upsert(
          addition.record,
          healthKitObjectUUID: addition.healthKitObjectUUID
        )
      }
      try cacheStore.delete(healthKitObjectUUIDs: batch.deletedObjectUUIDs)
      try repository.commit(batch)
    } catch {
      return try? cacheStore.latestRecord()
    }
    return try? cacheStore.latestRecord()
  }
}
