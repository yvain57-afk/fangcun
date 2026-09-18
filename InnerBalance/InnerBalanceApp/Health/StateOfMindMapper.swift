import HealthKit
import InnerBalanceCore

enum CheckInAssociation: String, CaseIterable, Codable, Sendable {
  case work
  case tasks
  case health
  case family
  case relationship
  case money
  case training
  case sleep
}

extension CheckInAssociation {
  var stressSource: CurrentStressSource {
    switch self {
    case .work: .work
    case .tasks: .tasks
    case .health: .health
    case .family: .family
    case .relationship: .relationship
    case .money: .money
    case .training: .training
    case .sleep: .sleep
    }
  }
}

struct StateOfMindRecord: Equatable, Codable, Sendable {
  let syncIdentifier: String
  let syncVersion: Int
  let date: Date
  let valence: Double
  let arousal: Double
  let labels: [EmotionLabel]
  let associations: [CheckInAssociation]
  let bodySensationCodes: [String]
  let unclassified: Bool
  let origin: HealthRecordOrigin
  let sessionID: String?
  let phase: HealthRecordPhase
}

enum StateOfMindMappingError: Error, Equatable {
  case invalidValence
  case invalidArousal
}

enum StateOfMindMapper {
  static func sample(from record: StateOfMindRecord) throws -> HKStateOfMind {
    guard (-1...1).contains(record.valence) else {
      throw StateOfMindMappingError.invalidValence
    }
    guard (-1...1).contains(record.arousal) else {
      throw StateOfMindMappingError.invalidArousal
    }

    let associations = Array(record.associations.prefix(2))
    return HKStateOfMind(
      date: record.date,
      kind: .momentaryEmotion,
      valence: record.valence,
      labels: record.labels.map(healthKitLabel),
      associations: associations.compactMap(healthKitAssociation),
      metadata: HealthMetadataKeys.stateOfMind(
        syncIdentifier: record.syncIdentifier,
        syncVersion: record.syncVersion,
        arousal: record.arousal,
        bodySensationCodes: record.bodySensationCodes,
        associationCodes: associations.map(\.rawValue),
        unclassified: record.unclassified,
        origin: record.origin,
        sessionID: record.sessionID,
        phase: record.phase
      )
    )
  }

  static func record(from sample: HKStateOfMind) -> StateOfMindRecord? {
    guard
      let metadata = sample.metadata,
      let syncIdentifier = metadata[HKMetadataKeySyncIdentifier] as? String,
      syncIdentifier.isEmpty == false,
      let syncVersion = (metadata[HKMetadataKeySyncVersion] as? NSNumber)?.intValue,
      let arousal = (metadata[HealthMetadataKeys.arousal] as? NSNumber)?.doubleValue,
      (-1...1).contains(arousal),
      let originValue = metadata[HealthMetadataKeys.origin] as? String,
      let origin = HealthRecordOrigin(rawValue: originValue),
      let phaseValue = metadata[HealthMetadataKeys.phase] as? String,
      let phase = HealthRecordPhase(rawValue: phaseValue)
    else { return nil }

    let bodySensationCodes = commaSeparatedValues(
      metadata[HealthMetadataKeys.bodySensationCodes] as? String
    )
    let customAssociations = commaSeparatedValues(
      metadata[HealthMetadataKeys.associationCodes] as? String
    ).compactMap(CheckInAssociation.init(rawValue:))
    let associations =
      customAssociations.isEmpty
      ? sample.associations.compactMap(checkInAssociation)
      : customAssociations
    let labels = sample.labels.compactMap(emotionLabel)
    let markedUnclassified =
      (metadata[HealthMetadataKeys.unclassified] as? NSNumber)?.boolValue ?? false

    return StateOfMindRecord(
      syncIdentifier: syncIdentifier,
      syncVersion: syncVersion,
      date: sample.startDate,
      valence: sample.valence,
      arousal: arousal,
      labels: labels,
      associations: associations,
      bodySensationCodes: bodySensationCodes,
      unclassified: markedUnclassified || labels.count != sample.labels.count,
      origin: origin,
      sessionID: metadata[HealthMetadataKeys.sessionID] as? String,
      phase: phase
    )
  }

  private static func healthKitLabel(_ label: EmotionLabel) -> HKStateOfMind.Label {
    switch label {
    case .amazed: .amazed
    case .amused: .amused
    case .angry: .angry
    case .anxious: .anxious
    case .ashamed: .ashamed
    case .brave: .brave
    case .calm: .calm
    case .content: .content
    case .disappointed: .disappointed
    case .discouraged: .discouraged
    case .disgusted: .disgusted
    case .embarrassed: .embarrassed
    case .excited: .excited
    case .frustrated: .frustrated
    case .grateful: .grateful
    case .guilty: .guilty
    case .happy: .happy
    case .hopeless: .hopeless
    case .irritated: .irritated
    case .jealous: .jealous
    case .joyful: .joyful
    case .lonely: .lonely
    case .passionate: .passionate
    case .peaceful: .peaceful
    case .proud: .proud
    case .relieved: .relieved
    case .sad: .sad
    case .scared: .scared
    case .stressed: .stressed
    case .surprised: .surprised
    case .worried: .worried
    case .annoyed: .annoyed
    case .confident: .confident
    case .drained: .drained
    case .hopeful: .hopeful
    case .indifferent: .indifferent
    case .overwhelmed: .overwhelmed
    case .satisfied: .satisfied
    }
  }

  private static func emotionLabel(_ label: HKStateOfMind.Label) -> EmotionLabel? {
    switch label {
    case .amazed: .amazed
    case .amused: .amused
    case .angry: .angry
    case .anxious: .anxious
    case .ashamed: .ashamed
    case .brave: .brave
    case .calm: .calm
    case .content: .content
    case .disappointed: .disappointed
    case .discouraged: .discouraged
    case .disgusted: .disgusted
    case .embarrassed: .embarrassed
    case .excited: .excited
    case .frustrated: .frustrated
    case .grateful: .grateful
    case .guilty: .guilty
    case .happy: .happy
    case .hopeless: .hopeless
    case .irritated: .irritated
    case .jealous: .jealous
    case .joyful: .joyful
    case .lonely: .lonely
    case .passionate: .passionate
    case .peaceful: .peaceful
    case .proud: .proud
    case .relieved: .relieved
    case .sad: .sad
    case .scared: .scared
    case .stressed: .stressed
    case .surprised: .surprised
    case .worried: .worried
    case .annoyed: .annoyed
    case .confident: .confident
    case .drained: .drained
    case .hopeful: .hopeful
    case .indifferent: .indifferent
    case .overwhelmed: .overwhelmed
    case .satisfied: .satisfied
    @unknown default: nil
    }
  }

  private static func healthKitAssociation(
    _ association: CheckInAssociation
  ) -> HKStateOfMind.Association? {
    switch association {
    case .work: .work
    case .tasks: .tasks
    case .health: .health
    case .family: .family
    case .relationship: .partner
    case .money: .money
    case .training: .fitness
    case .sleep: nil
    }
  }

  private static func checkInAssociation(
    _ association: HKStateOfMind.Association
  ) -> CheckInAssociation? {
    switch association {
    case .work: .work
    case .tasks: .tasks
    case .health: .health
    case .family: .family
    case .partner: .relationship
    case .money: .money
    case .fitness: .training
    default: nil
    }
  }

  private static func commaSeparatedValues(_ value: String?) -> [String] {
    guard let value, value.isEmpty == false else { return [] }
    return value.split(separator: ",").map(String.init)
  }
}
