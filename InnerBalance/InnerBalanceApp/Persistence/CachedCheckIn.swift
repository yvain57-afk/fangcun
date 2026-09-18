import Foundation
import SwiftData

@Model
final class CachedCheckIn {
  @Attribute(.unique) var syncIdentifier: String
  var syncVersion: Int
  var date: Date
  var payload: Data
  var healthKitObjectUUID: UUID?

  init(
    syncIdentifier: String,
    syncVersion: Int,
    date: Date,
    payload: Data,
    healthKitObjectUUID: UUID? = nil
  ) {
    self.syncIdentifier = syncIdentifier
    self.syncVersion = syncVersion
    self.date = date
    self.payload = payload
    self.healthKitObjectUUID = healthKitObjectUUID
  }
}

@MainActor
final class CheckInCacheStore {
  private let modelContext: ModelContext
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func upsert(
    _ record: StateOfMindRecord,
    healthKitObjectUUID: UUID? = nil
  ) throws {
    let syncIdentifier = record.syncIdentifier
    let descriptor = FetchDescriptor<CachedCheckIn>(
      predicate: #Predicate { $0.syncIdentifier == syncIdentifier }
    )
    let payload = try encoder.encode(record)
    if let existing = try modelContext.fetch(descriptor).first {
      if record.syncVersion > existing.syncVersion {
        existing.syncVersion = record.syncVersion
        existing.date = record.date
        existing.payload = payload
      }
      if let healthKitObjectUUID {
        existing.healthKitObjectUUID = healthKitObjectUUID
      }
    } else {
      modelContext.insert(
        CachedCheckIn(
          syncIdentifier: record.syncIdentifier,
          syncVersion: record.syncVersion,
          date: record.date,
          payload: payload,
          healthKitObjectUUID: healthKitObjectUUID
        )
      )
    }
    try modelContext.save()
  }

  func delete(healthKitObjectUUIDs: [UUID]) throws {
    guard !healthKitObjectUUIDs.isEmpty else { return }
    let deleted = Set(healthKitObjectUUIDs)
    let cached = try modelContext.fetch(FetchDescriptor<CachedCheckIn>())
    for item in cached where item.healthKitObjectUUID.map(deleted.contains) == true {
      modelContext.delete(item)
    }
    try modelContext.save()
  }

  func record(syncIdentifier: String) throws -> StateOfMindRecord? {
    let descriptor = FetchDescriptor<CachedCheckIn>(
      predicate: #Predicate { $0.syncIdentifier == syncIdentifier }
    )
    guard let cached = try modelContext.fetch(descriptor).first else { return nil }
    return try decoder.decode(StateOfMindRecord.self, from: cached.payload)
  }

  func latestRecord() throws -> StateOfMindRecord? {
    var descriptor = FetchDescriptor<CachedCheckIn>(
      sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    descriptor.fetchLimit = 1
    guard let cached = try modelContext.fetch(descriptor).first else { return nil }
    return try decoder.decode(StateOfMindRecord.self, from: cached.payload)
  }

  func latestContextRecord(
    on date: Date = .now,
    calendar: Calendar = .current
  ) throws -> StateOfMindRecord? {
    let descriptor = FetchDescriptor<CachedCheckIn>(
      sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    for cached in try modelContext.fetch(descriptor) {
      let record = try decoder.decode(StateOfMindRecord.self, from: cached.payload)
      guard calendar.isDate(record.date, inSameDayAs: date) else { continue }
      if !record.associations.isEmpty || !record.bodySensationCodes.isEmpty {
        return record
      }
    }
    return nil
  }
}
