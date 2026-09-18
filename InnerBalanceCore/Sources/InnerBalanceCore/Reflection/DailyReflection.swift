import Foundation

public enum DailyReflectionTheme: String, Sendable {
  case universal
  case steady
  case attention
  case recovery

  public static func forBodyLoad(_ level: BodyLoadLevel) -> DailyReflectionTheme {
    switch level {
    case .buildingBaseline: .universal
    case .steady: .steady
    case .watch: .attention
    case .elevated: .recovery
    }
  }
}

public enum DailyReflectionSource: String, Sendable {
  case collectedQuotation
  case ideaAdaptation
}

public struct DailyReflectionProvenance: Equatable, Sendable {
  public let authorDeathYear: Int
  public let sourcePublicationYear: Int
  public let sourceURL: String
  public let translationCredit: String

  public init(
    authorDeathYear: Int,
    sourcePublicationYear: Int,
    sourceURL: String,
    translationCredit: String
  ) {
    self.authorDeathYear = authorDeathYear
    self.sourcePublicationYear = sourcePublicationYear
    self.sourceURL = sourceURL
    self.translationCredit = translationCredit
  }
}

public struct DailyReflection: Equatable, Identifiable, Sendable {
  public let id: String
  public let text: String
  public let attribution: String?
  public let work: String?
  public let source: DailyReflectionSource
  public let provenance: DailyReflectionProvenance?

  public init(
    id: String,
    text: String,
    attribution: String? = nil,
    work: String? = nil,
    source: DailyReflectionSource = .ideaAdaptation,
    provenance: DailyReflectionProvenance? = nil
  ) {
    self.id = id
    self.text = text
    self.attribution = attribution
    self.work = work
    self.source = source
    self.provenance = provenance
  }
}

public enum DailyReflectionSelector {
  public static let library = PublicDomainQuotationLibrary.reflections
  private static let blockedCareContextIDs: Set<String> = [
    "montaigne-death", "nietzsche-monster", "nietzsche-abyss", "pascal-room",
  ]
  private static let echoSchedules = makeEchoSchedules()
  private static let stressReflectionPools:
    [StressReflectionGroup: [CurrentStressLevel: [String]]] = [
      .workAndTasks: [
        .low: ["james-effort", "aurelius-last-act", "seneca-begin", "montaigne-use"],
        .moderate: ["james-wise", "james-attention", "epictetus-use", "seneca-postponing"],
        .high: ["epictetus-control", "seneca-imagination", "aurelius-no-opinion", "seneca-delay"],
      ],
      .relationships: [
        .low: ["seneca-company", "james-appreciation", "montaigne-belong", "nietzsche-love"],
        .moderate: ["pascal-heart", "spinoza-hatred", "aurelius-revenge", "epictetus-insult"],
        .high: ["seneca-delay", "epictetus-control", "aurelius-within", "spinoza-opposite"],
      ],
      .money: [
        .low: ["schopenhauer-possession", "seneca-poor", "montaigne-use", "spinoza-good"],
        .moderate: ["schopenhauer-cards", "nietzsche-desire", "spinoza-desire", "james-wise"],
        .high: [
          "epictetus-control", "seneca-imagination", "aurelius-no-opinion", "epictetus-wish",
        ],
      ],
      .healthAndBody: [
        .low: ["montaigne-live", "spinoza-life", "aurelius-within", "montaigne-cheerful"],
        .moderate: ["spinoza-clear", "epictetus-use", "pascal-reed", "aurelius-judgment"],
        .high: [
          "seneca-imagination", "epictetus-control", "aurelius-no-opinion", "spinoza-opposite",
        ],
      ],
      .training: [
        .low: ["james-effort", "aurelius-last-act", "epictetus-progress", "montaigne-use"],
        .moderate: ["schopenhauer-cards", "epictetus-use", "seneca-brave", "aurelius-be-one"],
        .high: [
          "epictetus-control", "aurelius-no-opinion", "seneca-imagination", "aurelius-within",
        ],
      ],
      .sleepAndEnergy: [
        .low: ["montaigne-cheerful", "spinoza-life", "james-worth-living", "montaigne-live"],
        .moderate: ["schopenhauer-alone", "pascal-present", "james-wise", "montaigne-belong"],
        .high: ["aurelius-within", "epictetus-wish", "seneca-imagination", "spinoza-clear"],
      ],
      .mentalLoad: [
        .low: ["james-attention", "james-wise", "aurelius-thoughts", "montaigne-belong"],
        .moderate: ["james-wandering", "epictetus-views", "spinoza-clear", "aurelius-judgment"],
        .high: ["seneca-imagination", "epictetus-control", "aurelius-no-opinion", "seneca-delay"],
      ],
      .unspecified: [
        .low: ["montaigne-live", "james-worth-living", "spinoza-life", "aurelius-color"],
        .moderate: ["james-attention", "epictetus-use", "spinoza-clear", "aurelius-within"],
        .high: [
          "epictetus-control", "seneca-imagination", "aurelius-no-opinion", "spinoza-opposite",
        ],
      ],
    ]

  public static func reflection(
    on date: Date,
    theme: DailyReflectionTheme,
    calendar: Calendar = .current
  ) -> DailyReflection {
    _ = theme
    return select(from: selectableLibrary, on: date, salt: 0, calendar: calendar)
  }

  public static func reflection(
    on date: Date,
    echo: DailyEchoState?,
    calendar: Calendar = .current
  ) -> DailyReflection {
    guard let echo else {
      return select(from: selectableLibrary, on: date, salt: 0, calendar: calendar)
    }
    let schedule = echoSchedules[echo] ?? selectableLibrary
    return select(from: schedule, on: date, salt: 0, calendar: calendar)
  }

  public static func reflection(
    on date: Date,
    stressProfile: CurrentStressProfile,
    calendar: Calendar = .current
  ) -> DailyReflection {
    let group = stressReflectionGroup(for: stressProfile.source)
    guard let ids = stressReflectionPools[group]?[stressProfile.level], !ids.isEmpty else {
      preconditionFailure("Every stress profile must have a targeted reflection pool")
    }

    let reflectionsByID = Dictionary(uniqueKeysWithValues: library.map { ($0.id, $0) })
    let reflections = ids.compactMap { reflectionsByID[$0] }
    precondition(
      reflections.count == ids.count
        && reflections.allSatisfy { !blockedCareContextIDs.contains($0.id) },
      "Stress reflection pools must use approved public-domain quotations"
    )
    return select(
      from: reflections,
      on: date,
      salt: stressSelectionSalt(for: stressProfile),
      calendar: calendar
    )
  }

  private static var selectableLibrary: [DailyReflection] {
    library.filter { !blockedCareContextIDs.contains($0.id) }
  }

  private static func makeEchoSchedules() -> [DailyEchoState: [DailyReflection]] {
    let openingSchedule = selectableLibrary
    var usedIDsByDay = openingSchedule.map { Set([$0.id]) }
    var schedules: [DailyEchoState: [DailyReflection]] = [:]

    for state in DailyEchoState.allCases {
      let preferred = rotated(
        reflectionPool(for: state),
        by: echoSelectionSalt(for: state)
      )
      let preferredIDs = Set(preferred.map(\.id))
      let fallback = rotated(
        selectableLibrary.filter { !preferredIDs.contains($0.id) },
        by: echoSelectionSalt(for: state)
      )
      var schedule = preferred + fallback
      precondition(schedule.count == openingSchedule.count)

      for dayIndex in schedule.indices
      where usedIDsByDay[dayIndex].contains(schedule[dayIndex].id) {
        let conflictingReflection = schedule[dayIndex]
        guard
          let swapIndex = schedule.indices.first(where: { candidateIndex in
            candidateIndex != dayIndex
              && !usedIDsByDay[dayIndex].contains(schedule[candidateIndex].id)
              && !usedIDsByDay[candidateIndex].contains(conflictingReflection.id)
          })
        else {
          preconditionFailure("Daily reflection schedules must be collision free")
        }
        schedule.swapAt(dayIndex, swapIndex)
      }

      precondition(
        schedule.indices.allSatisfy {
          !usedIDsByDay[$0].contains(schedule[$0].id)
        }
      )
      for dayIndex in schedule.indices {
        usedIDsByDay[dayIndex].insert(schedule[dayIndex].id)
      }
      schedules[state] = schedule
    }

    return schedules
  }

  private static func rotated(
    _ reflections: [DailyReflection],
    by offset: Int
  ) -> [DailyReflection] {
    guard !reflections.isEmpty else { return [] }
    let normalizedOffset = offset % reflections.count
    return Array(reflections[normalizedOffset...] + reflections[..<normalizedOffset])
  }

  private static func reflectionPool(for echo: DailyEchoState) -> [DailyReflection] {
    let ids =
      switch echo {
      case .calm:
        [
          "aurelius-no-opinion", "aurelius-thoughts", "aurelius-be-one",
          "aurelius-color", "aurelius-within", "aurelius-last-act",
          "epictetus-control", "epictetus-wish", "epictetus-use", "epictetus-actor",
          "seneca-begin", "seneca-company", "seneca-brave",
          "montaigne-belong", "montaigne-profession", "montaigne-use",
          "montaigne-cheerful", "montaigne-quote", "montaigne-live",
          "spinoza-clear", "spinoza-hatred", "spinoza-life", "spinoza-blessedness",
          "schopenhauer-alone", "schopenhauer-freedom", "schopenhauer-possession",
          "nietzsche-love", "nietzsche-maturity", "james-attention", "james-wise",
          "james-worth-living", "james-effort", "james-fate", "pascal-heart",
          "pascal-present", "pascal-reed", "pascal-dignity",
        ]
      case .clear:
        [
          "aurelius-no-opinion", "aurelius-judgment", "aurelius-be-one",
          "aurelius-last-act", "epictetus-control", "epictetus-views", "epictetus-use",
          "epictetus-progress", "seneca-poor", "seneca-postponing", "seneca-begin",
          "seneca-company", "montaigne-quote", "montaigne-belief", "montaigne-live",
          "spinoza-desire", "spinoza-clear", "spinoza-opposite", "spinoza-good",
          "schopenhauer-horizon", "schopenhauer-time", "schopenhauer-cards",
          "schopenhauer-possession", "nietzsche-desire", "nietzsche-maturity",
          "nietzsche-interpretation", "james-attention", "james-wandering", "james-habit",
          "james-wise", "james-effort", "james-fate", "pascal-present", "pascal-habit",
          "pascal-dignity", "pascal-justice", "pascal-truth",
        ]
      case .moved:
        [
          "aurelius-color", "aurelius-within", "aurelius-revenge", "epictetus-wish",
          "epictetus-actor", "epictetus-returned", "seneca-imagination", "seneca-company",
          "seneca-adversity", "montaigne-belong", "montaigne-profession", "montaigne-use",
          "montaigne-cheerful", "montaigne-death", "spinoza-clear", "spinoza-hope",
          "spinoza-hatred", "spinoza-life", "spinoza-blessedness", "schopenhauer-alone",
          "schopenhauer-loss", "schopenhauer-possession", "nietzsche-love",
          "nietzsche-desire", "nietzsche-maturity", "james-appreciation",
          "james-worth-living", "james-effort", "james-fate", "pascal-heart",
          "pascal-reed", "pascal-dignity", "pascal-truth",
        ]
      case .tense:
        [
          "aurelius-no-opinion", "aurelius-judgment", "aurelius-within",
          "epictetus-control", "epictetus-views", "epictetus-wish", "epictetus-use",
          "epictetus-insult", "epictetus-returned", "seneca-imagination",
          "seneca-postponing", "seneca-delay", "seneca-brave", "montaigne-cheerful",
          "montaigne-death", "montaigne-live", "spinoza-clear", "spinoza-hope",
          "spinoza-opposite", "spinoza-life", "schopenhauer-alone", "schopenhauer-freedom",
          "schopenhauer-horizon", "schopenhauer-loss", "nietzsche-monster",
          "nietzsche-abyss", "nietzsche-desire", "james-attention", "james-wandering",
          "james-wise", "james-effort", "pascal-room", "pascal-heart", "pascal-present",
          "pascal-habit",
        ]
      case .tired:
        [
          "aurelius-no-opinion", "aurelius-thoughts", "aurelius-color", "aurelius-within",
          "aurelius-last-act", "epictetus-control", "epictetus-wish", "epictetus-use",
          "epictetus-progress", "epictetus-returned", "seneca-imagination", "seneca-begin",
          "seneca-company", "seneca-adversity", "montaigne-belong", "montaigne-use",
          "montaigne-cheerful", "montaigne-live", "spinoza-clear", "spinoza-hope",
          "spinoza-life", "spinoza-blessedness", "schopenhauer-alone",
          "schopenhauer-freedom", "schopenhauer-loss", "schopenhauer-possession",
          "nietzsche-love", "nietzsche-maturity", "james-attention", "james-wandering",
          "james-wise", "james-worth-living", "james-effort", "pascal-room", "pascal-heart",
          "pascal-present", "pascal-reed",
        ]
      case .uncertain:
        [
          "aurelius-judgment", "aurelius-thoughts", "aurelius-be-one", "aurelius-color",
          "aurelius-within", "epictetus-control", "epictetus-views", "epictetus-wish",
          "epictetus-use", "epictetus-actor", "seneca-imagination", "seneca-poor",
          "seneca-begin", "seneca-company", "montaigne-belong", "montaigne-profession",
          "montaigne-quote", "montaigne-belief", "montaigne-live", "spinoza-desire",
          "spinoza-clear", "spinoza-hope", "spinoza-good", "schopenhauer-horizon",
          "schopenhauer-loss", "schopenhauer-cards", "schopenhauer-possession",
          "nietzsche-abyss", "nietzsche-desire", "nietzsche-maturity",
          "nietzsche-interpretation", "james-attention", "james-wandering", "james-wise",
          "james-effort", "james-fate", "pascal-heart", "pascal-present", "pascal-reed",
          "pascal-dignity", "pascal-truth",
        ]
      }

    let reflectionsByID = Dictionary(uniqueKeysWithValues: library.map { ($0.id, $0) })
    return ids.compactMap { reflectionsByID[$0] }
      .filter { !blockedCareContextIDs.contains($0.id) }
  }

  private static func echoSelectionSalt(for echo: DailyEchoState) -> Int {
    switch echo {
    case .calm: 5
    case .clear: 11
    case .moved: 17
    case .tense: 23
    case .tired: 29
    case .uncertain: 35
    }
  }

  private static func stressReflectionGroup(
    for source: CurrentStressSource
  ) -> StressReflectionGroup {
    switch source {
    case .work, .tasks:
      .workAndTasks
    case .family, .relationship:
      .relationships
    case .money:
      .money
    case .health, .physicalTension, .bodySignals:
      .healthAndBody
    case .training:
      .training
    case .sleep, .lowEnergy:
      .sleepAndEnergy
    case .mentalLoad:
      .mentalLoad
    case .none:
      .unspecified
    }
  }

  private static func stressSelectionSalt(for profile: CurrentStressProfile) -> Int {
    let sourceSalt =
      switch profile.source {
      case .none: 0
      case .work: 1
      case .tasks: 2
      case .health: 3
      case .family: 4
      case .relationship: 5
      case .money: 6
      case .training: 7
      case .sleep: 8
      case .physicalTension: 9
      case .mentalLoad: 10
      case .lowEnergy: 11
      case .bodySignals: 12
      }
    let levelSalt =
      switch profile.level {
      case .low: 0
      case .moderate: 17
      case .high: 31
      }
    return sourceSalt + levelSalt
  }

  private static func select(
    from reflections: [DailyReflection],
    on date: Date,
    salt: Int,
    calendar: Calendar
  ) -> DailyReflection {
    precondition(!reflections.isEmpty)
    let localDay = calendar.startOfDay(for: date)
    let localDaySeed = calendar.ordinality(of: .day, in: .era, for: localDay) ?? 0
    return reflections[(localDaySeed + salt) % reflections.count]
  }

  private enum StressReflectionGroup: Hashable {
    case workAndTasks
    case relationships
    case money
    case healthAndBody
    case training
    case sleepAndEnergy
    case mentalLoad
    case unspecified
  }

}
