import Foundation

/// Shared presentation copy; stable keys live in Localizable.xcstrings and COPY_REVIEW.csv.
enum FangcunCopy {
  static func text(_ key: String, _ arguments: CVarArg...) -> String {
    let format = String(localized: String.LocalizationValue(key))
    return arguments.isEmpty ? format : String(format: format, locale: Locale.current, arguments: arguments)
  }

  static func timestamp(_ date: Date) -> String {
    date.formatted(.dateTime.month().day().hour().minute())
  }
}
