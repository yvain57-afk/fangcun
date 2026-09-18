import Foundation
import Testing

@Suite("隐私合规")
struct PrivacyManifestTests {
  @Test("TestFlight 候选构建使用正式 1.0 版本号")
  func releaseCandidateUsesVersionOne() {
    let version =
      Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
      ) as? String
    #expect(version == "1.0.0")
  }

  @Test("TestFlight 候选构建不声明非豁免加密")
  func releaseCandidateDoesNotUseNonExemptEncryption() {
    let usesNonExemptEncryption =
      Bundle.main.object(
        forInfoDictionaryKey: "ITSAppUsesNonExemptEncryption"
      ) as? Bool
    #expect(usesNonExemptEncryption == false)
  }

  @Test("成品 App 携带隐私清单并仅声明 App 内 UserDefaults")
  func appBundlesAnAppLocalUserDefaultsReason() throws {
    let manifestURL = try #require(
      Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
    )
    let data = try Data(contentsOf: manifestURL)
    let manifest = try #require(
      PropertyListSerialization.propertyList(from: data, format: nil)
        as? [String: Any]
    )

    #expect(manifest["NSPrivacyTracking"] as? Bool == false)
    #expect((manifest["NSPrivacyTrackingDomains"] as? [String])?.isEmpty == true)
    #expect((manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]])?.isEmpty == true)

    let accessedAPIs = try #require(
      manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]]
    )
    let userDefaultsDeclaration = try #require(
      accessedAPIs.first {
        $0["NSPrivacyAccessedAPIType"] as? String
          == "NSPrivacyAccessedAPICategoryUserDefaults"
      }
    )

    #expect(
      userDefaultsDeclaration["NSPrivacyAccessedAPITypeReasons"] as? [String]
        == ["CA92.1"]
    )
  }
}
