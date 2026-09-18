import Foundation
import InnerBalanceCore
import SwiftData

extension DailyEchoState {
  var title: String {
    switch self {
    case .calm: "平静"
    case .clear: "清醒"
    case .moved: "有触动"
    case .tense: "绷着"
    case .tired: "有点累"
    case .uncertain: "说不清"
    }
  }

  var systemImage: String {
    switch self {
    case .calm: "water.waves"
    case .clear: "sun.max"
    case .moved: "heart"
    case .tense: "bolt"
    case .tired: "moon"
    case .uncertain: "ellipsis"
    }
  }
}

struct DailyEchoRecord: Equatable, Identifiable, Sendable {
  let day: Date
  let text: String
  let reflectionID: String
  let reflectionText: String
  let attribution: String?
  let state: DailyEchoState
  let reflectionSource: DailyReflectionSource
  let reflectionWork: String?
  let localDayIdentifier: String
  let updatedAt: Date

  var id: Date { day }

  func displayDay(in calendar: Calendar = .current) -> Date {
    let values = localDayIdentifier.split(separator: "-").compactMap { Int($0) }
    guard values.count == 4 else { return day }
    return calendar.date(
      from: DateComponents(
        calendar: calendar,
        era: values[0],
        year: values[1],
        month: values[2],
        day: values[3]
      )
    ) ?? day
  }
}

@Model
final class StoredDailyEcho {
  @Attribute(.unique) var day: Date
  var text: String
  var reflectionID: String
  var reflectionText: String
  var attribution: String
  var stateRawValue: String = DailyEchoState.uncertain.rawValue
  var localDayIdentifier: String = ""
  var reflectionSourceRawValue: String = DailyReflectionSource.ideaAdaptation.rawValue
  var reflectionWork: String?
  var updatedAt: Date

  init(
    day: Date,
    text: String,
    reflectionID: String,
    reflectionText: String,
    attribution: String,
    state: DailyEchoState,
    localDayIdentifier: String,
    reflectionSource: DailyReflectionSource,
    reflectionWork: String?,
    updatedAt: Date
  ) {
    self.day = day
    self.text = text
    self.reflectionID = reflectionID
    self.reflectionText = reflectionText
    self.attribution = attribution
    stateRawValue = state.rawValue
    self.localDayIdentifier = localDayIdentifier
    reflectionSourceRawValue = reflectionSource.rawValue
    self.reflectionWork = reflectionWork
    self.updatedAt = updatedAt
  }

  var record: DailyEchoRecord {
    let state = DailyEchoState(rawValue: stateRawValue) ?? .uncertain
    return DailyEchoRecord(
      day: day,
      text: text,
      reflectionID: reflectionID,
      reflectionText: reflectionText,
      attribution: attribution.isEmpty ? nil : attribution,
      state: state,
      reflectionSource: DailyReflectionSource(rawValue: reflectionSourceRawValue)
        ?? .ideaAdaptation,
      reflectionWork: reflectionWork,
      localDayIdentifier: localDayIdentifier,
      updatedAt: updatedAt
    )
  }
}

@MainActor
final class DailyEchoStore {
  private let modelContext: ModelContext
  private let calendar: Calendar

  init(modelContext: ModelContext, calendar: Calendar = .current) {
    self.modelContext = modelContext
    self.calendar = calendar
  }

  func save(
    state: DailyEchoState,
    note: String = "",
    reflection: DailyReflection,
    date: Date = .now
  ) throws {
    let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
    let localDayIdentifier = localDayIdentifier(for: date)
    let allRecords = try modelContext.fetch(FetchDescriptor<StoredDailyEcho>())
    let matchingRecords = allRecords.filter {
      $0.localDayIdentifier == localDayIdentifier
        || ($0.localDayIdentifier.isEmpty && calendar.isDate($0.updatedAt, inSameDayAs: date))
    }
    if let existing = matchingRecords.max(by: { $0.updatedAt < $1.updatedAt }) {
      existing.text = trimmed
      existing.reflectionID = reflection.id
      existing.reflectionText = reflection.text
      existing.attribution = reflection.attribution ?? ""
      existing.stateRawValue = state.rawValue
      existing.localDayIdentifier = localDayIdentifier
      existing.reflectionSourceRawValue = reflection.source.rawValue
      existing.reflectionWork = reflection.work
      existing.updatedAt = date
      for duplicate in matchingRecords where duplicate !== existing {
        modelContext.delete(duplicate)
      }
    } else {
      modelContext.insert(
        StoredDailyEcho(
          day: date,
          text: trimmed,
          reflectionID: reflection.id,
          reflectionText: reflection.text,
          attribution: reflection.attribution ?? "",
          state: state,
          localDayIdentifier: localDayIdentifier,
          reflectionSource: reflection.source,
          reflectionWork: reflection.work,
          updatedAt: date
        )
      )
    }
    try modelContext.save()
  }

  func echo(on date: Date = .now) throws -> DailyEchoRecord? {
    let identifier = localDayIdentifier(for: date)
    let records = try modelContext.fetch(FetchDescriptor<StoredDailyEcho>())
    try materializeLegacyRecords(records)

    return
      records
      .filter {
        $0.localDayIdentifier == identifier
          || ($0.localDayIdentifier.isEmpty && calendar.isDate($0.updatedAt, inSameDayAs: date))
      }
      .max(by: { $0.updatedAt < $1.updatedAt })?
      .record
  }

  func history() throws -> [DailyEchoRecord] {
    let descriptor = FetchDescriptor<StoredDailyEcho>(
      sortBy: [SortDescriptor(\.day, order: .reverse)]
    )
    let records = try modelContext.fetch(descriptor)
    try materializeLegacyRecords(records)
    return records.map(\.record)
  }

  private func localDayIdentifier(for date: Date) -> String {
    let components = calendar.dateComponents([.era, .year, .month, .day], from: date)
    return [components.era, components.year, components.month, components.day]
      .map { String($0 ?? 0) }
      .joined(separator: "-")
  }

  private func materializeLegacyRecords(_ records: [StoredDailyEcho]) throws {
    var changed = false
    let currentQuotationIDs = Set(DailyReflectionSelector.library.map(\.id))
    for record in records {
      if record.localDayIdentifier.isEmpty {
        record.localDayIdentifier = localDayIdentifier(for: record.day)
        changed = true
      }
      let isGeneratedReflection = record.reflectionID.hasPrefix("echo-")
      let isRetiredQuotation =
        record.reflectionSourceRawValue == DailyReflectionSource.collectedQuotation.rawValue
        && !currentQuotationIDs.contains(record.reflectionID)
      guard isGeneratedReflection || isRetiredQuotation else { continue }
      let state = DailyEchoState(rawValue: record.stateRawValue) ?? .uncertain
      let reflection = DailyReflectionSelector.reflection(
        on: localDay(for: record.localDayIdentifier) ?? record.day,
        echo: state,
        calendar: calendar
      )
      record.reflectionID = reflection.id
      record.reflectionText = reflection.text
      record.attribution = reflection.attribution ?? ""
      record.reflectionSourceRawValue = reflection.source.rawValue
      record.reflectionWork = reflection.work
      changed = true
    }
    if changed {
      try modelContext.save()
    }
  }

  private func localDay(for identifier: String) -> Date? {
    let values = identifier.split(separator: "-").compactMap { Int($0) }
    guard values.count == 4 else { return nil }
    return calendar.date(
      from: DateComponents(
        calendar: calendar,
        era: values[0],
        year: values[1],
        month: values[2],
        day: values[3]
      )
    )
  }
}
