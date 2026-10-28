import Foundation

/// Shared presentation copy; stable keys live in Localizable.xcstrings and COPY_REVIEW.csv.
enum FangcunCopy {
  private static let englishBundle: Bundle = {
    guard let path = Bundle.main.path(forResource: "en", ofType: "lproj"), let bundle = Bundle(path: path) else { return .main }
    return bundle
  }()
  static func text(_ key: String, _ arguments: CVarArg...) -> String {
    let format = englishBundle.localizedString(forKey: key, value: nil, table: nil)
    return arguments.isEmpty ? format : String(format: format, locale: Locale(identifier: "en"), arguments: arguments)
  }

  static func timestamp(_ date: Date?) -> String {
    date.map { timestamp($0) } ?? text("readiness.unknown")
  }
  static func timestamp(_ date: Date) -> String {
    date.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "en")))
  }
}
