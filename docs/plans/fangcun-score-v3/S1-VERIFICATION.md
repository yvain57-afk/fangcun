# S1 — raw sleep to native score

Synthetic data only. 375 minutes of asleep samples, no HRV/RHR, default goal 480 minutes, no continuity or regularity substitute. Engine computes 78.125, rounds to 78, band fair/尚可; sleep actual normalized weight 100%. Screenshot is the actual SwiftUI app, not an injected display state.

- `cd InnerBalanceCore && swift test`: 148 tests in 29 suites passed, including the 24 unmodified package fixtures, numeric boundaries and raw provider → pipeline → durable store test. Local log `s1-core-fixtures.log`.
- `DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination 'platform=iOS Simulator,id=<local simulator>' -only-testing:InnerBalanceUITests/StatusScoreV3UITests -parallel-testing-enabled NO -test-timeouts-enabled YES -maximum-test-execution-time-allowance 90 CODE_SIGNING_ALLOWED=NO`: 1 UI test passed, exit 0, readable `s1-ui2.xcresult` (local only).
- `testFirstNightRawSleepPublishes78AndRealAction`: visible 78/尚可, actual 100% sleep composition, rest start/finish/feedback skip/done, return to unchanged 78. Screenshots and native recording in `evidence/`.
- Initial `s1-ui` compile failed due to observable initialization ordering; fixed local target initialization, then reran successfully. Not a device or runtime pass.

S1 is the first vertical slice. Full cardio extraction, partial publication, migration/DTO, history/action routing and full regression remain for S2–S4. Physical device and subjective design acceptance are not claimed here.
