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

## Integration status

The final results below supersede earlier stage counts. Human comprehension/cuteness and physical notification behavior remain separate, unverified acceptance items.

## V2-04 dose and persistence

- `run.py v204-red3 InnerBalanceTests/BeverageV2Tests`: 2 tests, 2 failures reproducing per-serving dilution and old fixed 10 g estimate for a new beer. Earlier red/red2 failed to compile because XCTest inherited the App target's default actor isolation; converted the new regression to the project's Swift Testing style before assessing behavior.
- `run.py v204-commands InnerBalanceTests/BeverageV2Tests InnerBalanceTests/FangcunDiaryMigrationTests InnerBalanceTests/BeverageCareCoordinatorTests`: normal exit 0, 10 tests passed; result bundle readable.
- `run.py v2-app-first InnerBalanceTests`: normal exit 0, 187 tests passed. A later full rerun includes subsequent additions.
- Existing migration assertions were explicitly updated for V2 behavior: fixed per-serving caffeine/sugar no longer scales with dilution; undo restores values but advances revision; legacy unknown estimate remains unknown. Original golden/model tests unchanged. The previous first integration run failed six old assumptions in this one migration test; all corrected expectations subsequently passed.
- Data storage remains the checksummed, atomic `diary-v2.json` authority. Optional details, command receipts and local revision tombstones decode with defaults from older archives. Existing IDs, old beer 10 g estimates and backups retained. No clear/reimport.
- New beverage DTOs remain unacknowledged in the outbox until peer advertises `beverage-v2`; no fallback to water/zero. Legacy payloads without new details remain supported.

## V2-05 pure policy

`DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer swift test --package-path InnerBalanceCore` (`core-v2-final2.log`): normal exit 0, **141 tests / 28 suites passed**. Includes 17 beverage/care policy tests, 3 motion tests, new old-peer gating regression, original golden and M2-R suites.

Coverage includes no-record wording keys, coffee fluid contribution, unknown doses, accepted reference and no catch-up debt, fluid restrictions across care types, consumption vs recording time, late/midnight/shift caffeine, manual cutoff, combined candidates, partial known totals, alcohol unknown/excess/safety, next-cycle passive care, priority/dismissal, non-material name edits, persistent timezone-safe mute, 3-day one-shot reservation, both budgets/cooldown, new-fluid/target cancellations, and no late alcohol request deferral into quiet hours.

## V2-06 local notification adapter and integration

- `run.py v2-app-final InnerBalanceTests`: normal exit 0, **195 tests / 31 suites passed**. Includes `CareNotificationTests` (startup/denial/explicit request, own-only cancellation/privacy cleanup, foreground silence, scheduled vs delivered receipts, cold-start action persistence/retry dedup), `BeverageCareCoordinatorTests`, `BeverageV2Tests` and raw-provider `DayGuidanceV2Tests` (six scenarios).
- `swift test --package-path InnerBalanceCore` using the same DEVELOPER_DIR (`core-v2-final.log`): normal exit 0, **143 tests / 28 suites passed**. Added ten-refresh/no-queue and static/low-power/covered/gentle regressions.
- `xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' -destination 'generic/platform=watchOS Simulator' -derivedDataPath <local>/WatchDerivedData CODE_SIGNING_ALLOWED=NO`: exit 0, BUILD SUCCEEDED.
- Notification tests use an injected client and deterministic planning. They do not prove physical lock-screen/background delivery, permission dialogs, or a user reading a notification. Real system delivery remains explicitly unverified.
- No HealthKit water/caffeine requests, push server, entitlement expansion, badge, sound, critical alerts, or time-sensitive level. Default lock-screen text contains no dose or health assessment. One app-owned delegate and merged category registration preserve other feature identifiers.
- Superseded planning is cancelled through a generation guard. Cold-start actions persist the receipt and user action before returning; “record” navigates only. Target completion, latest fluid, undo/edit/sync, preference/privacy changes replan only this feature's requests.

## V2-07 final actual runs

All paths below are relative to the canonical repository. Local runner location: `/Users/yvainair/Code/Codex/2026-09-19/fangcun-experience-v2/`. Raw xcresult and physical diagnostics remain there and are not committed. Public receipts contain synthetic test names/status only.

| Command/run | Exit / result | Public receipt |
|---|---|---|
| `DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer swift test --package-path InnerBalanceCore` (`core-v2-acceptance.log`) | 0; 145 tests / 28 suites | [Core](evidence/tests/core-v2-acceptance.txt) |
| `python3 <runner>/run.py v2-app-final InnerBalanceTests` | 0; 195 tests / 31 suites; xcresult readable | [App](evidence/tests/v2-app-final-summary.json) |
| `python3 <runner>/run.py v2-ui-full InnerBalanceUITests` | 65; 28 passed / 18 failed / 46 total; xcresult readable | [Full UI](evidence/tests/v2-ui-full-summary.json) |
| `python3 <runner>/record-tests.py` → `v2-ui-final` | 0; 10 passed / 0 failed; xcresult readable | [Final selected UI](evidence/tests/v2-ui-final-summary.json) |
| `python3 <runner>/run.py v2-ui-accessible InnerBalanceUITests/ExperienceV2SceneUITests/testOneDayDarkMaximumTypeHasScopedFactsAndNoPersonalRange InnerBalanceUITests/ExperienceV2SceneUITests/testWaterCoffeeAlcoholAndUndoShowCommittedFeedback InnerBalanceUITests/DrinkEditorUITests` | 0; 3 passed / 0 failed; xcresult readable | [Accessible sheet rerun](evidence/tests/v2-ui-accessible-summary.json) |
| Watch simulator command above | 0; BUILD SUCCEEDED | [Watch](evidence/tests/watch-build.txt) |
| `python3 <runner>/device-build.py` | 0; signed Release build; 1.0.0 / 2026091904 | [Physical receipt](evidence/phone-upgrade.json) |

`run.py` expands to the xcodebuild command shown in the first section, with each named selector passed as `-only-testing:`. All UI runs are serial, use `-collect-test-diagnostics never`, and exited normally. The full App run predates the final layout-only sheet adjustment; the affected sheet/editor/maximum-type UI tests were rerun after that adjustment. Final Core adds two acceptance edge tests without production changes.

`v2-ui-final` selectors: `DrinkEditorUITests`; `ExperienceV2SceneUITests` (4 methods); `ExperienceV2UITests`; `FangcunRedesignUITests` (2 methods); `HomeEvidencePipelineUITests/testQualifiedEvidenceAndWorkoutProtection`; `ReadinessHomeUITests/testAssessable`.

### Failure classification

- **Baseline debt, still failing:** the same 15 methods documented in [M3-LEGACY-UI](../fangcun-v1/M3-LEGACY-UI.md), excluding its four already-fixed check-in methods. Current full-run names are in [full log](evidence/tests/v2-ui-full.txt). Their old echo/state selectors, old navigation/brand AX expectations and legacy practice-copy contracts were not restored, deleted or silently skipped. Full UI is **not green**.
- **Three new integration failures, fixed:** `DrinkEditorUITests.testCapacityEditingUndoAndQuickLogShareTheSameRecords` now scrolls to the editor form after selecting a record; `HomeEvidencePipelineUITests.testQualifiedEvidenceAndWorkoutProtection` again shows the exclusion explanation in the legacy protection path; `ReadinessHomeUITests.testAssessable` uses an explicit accessible method disclosure. All three passed in the final 10-test run; the drink editor passed again after the layout fix.
- **Visual defect discovered despite a passing UI test, fixed:** maximum Dynamic Type squeezed the sheet header/rows and truncated totals. The entire accessibility layout now scrolls, rows/summary stack vertically and text wraps. Its test now actually records a cup, reaches the full totals, and undoes it; current screenshots are from the passing 3-test rerun.
- **Red-before-fix beverage behavior:** two failures for serving dilution and new-beer dosage are retained in [red receipt](evidence/tests/v204-red3.txt). Old fixture decoding/legacy estimates and original readiness golden fixtures remain unchanged.
- **Not physically verified:** notification permission prompt/denial, foreground and locked/background delivery, notification action cold-start, system Reduce Motion/Low Power/VoiceOver and physical save-failure injection. Injected-client/Core/Simulator results do not prove these.

### Physical overwrite and preservation

Signed Release was installed via `xcrun devicectl device install app` without uninstall. Version readback is `1.0.0 (2026091904)`. The launcher returned CoreDeviceError 10002 with underlying `Locked`: the phone was locked; this is not an observed App crash. A request to unlock was sent to the user.

App preferences and Application Support were copied before and after installation into a private local directory. Existing support files (diary, original migration backups, SwiftData files, Insights, Recovery, Sync) and preferences compared equal. This proves install preservation; it does **not** prove post-launch migration or current foreground HealthKit refresh. Prior M3 HealthKit readback and the local V2 audit are separately described in BASELINE_COVERAGE_FINDINGS.md. No health data, device IDs, certificates or raw physical logs are published.

### Visual evidence and human acceptance

See [final synthetic captures](evidence/final-native/README.md), [motion review](MOTION_REVIEW.md), and [all 45 case statuses](ACCEPTANCE_RESULTS.md). Tests verify observable contracts; user comprehension, naturalness and cuteness are still pending. Maximum-size controls are reachable through scrolling; ordinary text size retains the half-height sheet.
