import InnerBalanceCore

// Presentation only: preserve the original model and golden-fixture vocabulary.
extension StatusBand {
  var englishTitle: String {
    switch self {
    case .good: "Good"
    case .fair: "Fair"
    case .low: "Lower"
    case .rest: "Prioritize rest"
    }
  }
}
