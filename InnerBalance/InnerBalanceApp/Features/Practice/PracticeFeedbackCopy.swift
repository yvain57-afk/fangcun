import InnerBalanceCore

/// Existing values are part of the on-device archive. Localize presentation, not storage.
enum PracticeFeedbackCopy {
  static func storedValue(_ value: String?) -> String? {
    switch value {
    case "更舒服", "A little easier": "更舒服"
    case "差不多", "About the same": "差不多"
    case "不舒服", "Less comfortable", "Uncomfortable": "不舒服"
    default: nil
    }
  }
  static func englishTitle(_ value: String) -> String {
    switch storedValue(value) {
    case "更舒服": "A little easier"
    case "差不多": "About the same"
    case "不舒服": "Less comfortable"
    default: value
    }
  }
  static func helpfulness(_ value: String?) -> RecoveryHelpfulness? {
    switch storedValue(value) {
    case "更舒服": .helpful
    case "差不多": .unchanged
    case "不舒服": .uncomfortable
    default: nil
    }
  }
}
