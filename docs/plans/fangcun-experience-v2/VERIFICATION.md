# V2 verification

## V2-01 first native delivery

`python3 <local-scratch>/run.py v201-first InnerBalanceUITests/ExperienceV2UITests`

Expanded command: `DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination 'platform=iOS Simulator,id=<local simulator>' -derivedDataPath <local-derived-data> -resultBundlePath <local-scratch>/v201-first.xcresult -parallel-testing-enabled NO -test-timeouts-enabled YES -maximum-test-execution-time-allowance 90 -collect-test-diagnostics never -only-testing:InnerBalanceUITests/ExperienceV2UITests CODE_SIGNING_ALLOWED=NO`

Normal exit **0**, 1 UI test passed, result bundle readable by `xcresulttool export attachments`. Four synthetic screenshots exported, three short clips cut directly from `simctl io recordVideo` of that same run. No health/device/signing data in repository evidence.

- [Home](evidence/first-native/v2-home.png), [explanation](evidence/first-native/v2-detail.png), [drink sheet](evidence/first-native/v2-drinks.png), [breathing](evidence/first-native/v2-breathing.png).
- [Home clip](evidence/first-native/home.mp4), [water clip](evidence/first-native/water.mp4), [breathing clip](evidence/first-native/breathing.mp4).
- Assertions: no character-viewing button; explanation has conclusion and hides diagnostic identity/range by default; water commit reaches sheet; actual five-minute flow opens and pauses.
- These are first-stage captures, not final V2-04 dose/V2-05 care behavior. Human aesthetic/comprehension review pending.

## V2-02

See [quality evidence](V2-02-VERIFICATION.md) and [deidentified coverage findings](BASELINE_COVERAGE_FINDINGS.md). Core 120 tests pass. Full physical audit remains local only.

## Remaining integration

App full suite, revised UI contracts, final six-scene motion captures, care scheduling tests, Watch simulator and physical overwrite/update verification are not yet claimed passed.
