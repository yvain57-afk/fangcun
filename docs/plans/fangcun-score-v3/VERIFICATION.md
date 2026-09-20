# V3 verification ledger

## Actual commands

Canonical working directory: `/Users/yvainair/Code/fangcun`.

- `cd docs/plans/fangcun-score-v3 && python3 -m unittest -v test_reference_score_v3.py`: 14 methods / 24 reference cases passed.
- `swift test --package-path InnerBalanceCore`: S4 baseline 159 tests / 31 suites passed (`s4-core.log`). The additional raw 64-point regression is pending the final rerun.
- `DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination 'platform=iOS Simulator,id=<local simulator>' -derivedDataPath <local DerivedData> -resultBundlePath <local result.xcresult> -parallel-testing-enabled NO -test-timeouts-enabled YES -maximum-test-execution-time-allowance 90 -collect-test-diagnostics never -only-testing:InnerBalanceTests -only-testing:InnerBalanceUITests CODE_SIGNING_ALLOWED=NO`: `s4-final`, App 197 tests passed; complete UI and targeted reruns in progress. Device identifiers remain local.
- `DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath <local WatchDerivedData> CODE_SIGNING_ALLOWED=NO`: `s4-watch-final.log`, BUILD SUCCEEDED.
- Signed Release uses the existing local signing identity, generic iOS destination and `CURRENT_PROJECT_VERSION=2026092001`. Credentials/team/profiles/logs remain local. Build succeeded; `devicectl device install app` exit 0; installed app version read back as 1.0.0 (2026092001).

## Acceptance mapping

| ID | Evidence / expected behavior |
|---|---|
| V301 | `rawSleepThroughStoreProduces78WithoutCardio`, `rawSleepScoreColdReloadFailureAndTargetRevision`, `testFirstNightRawSleepPublishes78AndRealAction`; native S1 home/composition/action recording |
| V302 | Same raw sleep pipeline and package F01/F02; sleep-only composition, no zero-filled cardio |
| V303 | `perfectSleepWithRegularityRemainsInClosedRange`, scoreSleep480 native/round-trip UI; 100/good and actual composition |
| V304 | Unmodified F04; `rawFourHoursWithMatureCardioMatches64WhenRegularityIsDisabled` plus scoreFull240 UI fixture (regularity explicitly off, matching reference optional-input contract) |
| V305 | `rawShortSleepOverlapsAndNoInventedContinuity`; 45-minute raw confirmed sleep→9; main-sleep selection preserved |
| V306 | Same raw stage overlap test; V2 sleep-quality regressions remain unchanged |
| V307 | Same raw test plus first-night absence of continuity; no invented zero awake |
| V308 | `boundariesCircularClockAndInvalidInput` and package circular cases; shortest circular distance |
| V309 | 24 mathematical fixtures include 1/2/3 samples; raw sparse current HRV via `sparseHRVProgressiveHistory` |
| V310 | Parameterized raw 2/3/7/14-day HRV history and quality weight assertions |
| V311 | `rawRHRHistoryIndependentOfSleepAndDailyFallback`: 20 RHR days, no sleep required |
| V312 | `testEmptyCanSaveActualSleepWithoutConnectingHealth`, insufficient/failed native states; explicit sync/manual path, no fabricated number |
| V313 | HRV-only raw builder returns nil; native scoreHRVOnly case; no population baseline |
| V314 | `sleepPublishesBeforeHRVAndCursorThenFailureRetainsScore`, app cold reload/query failure: same ID/asOf retained |
| V315 | `revisionsIgnoreQueryClockButTrackCompositionConfigurationAndDeletion`, deletion journal/backup legacy tests; same-cycle supersession and redaction |
| V316 | Same fingerprint/clock regression; old M2-R04 tests preserved |
| V317 | Old owner selection/generation/CAS tests preserved; additional `simultaneousTargetAndSourceChangeRejectsOldScoreIntent` pending final targeted run |
| V318 | `nightAndConstraintsChangeOnlyAction`, `testNightKeeps78AndStartsShortBreathingThenForegroundStillClean`; same78, night120-second route |
| V319 | First-night rest UI, breathing round-trip, drink editor tests; no score reward; sessions/feedback actually save |
| V320 | `testMaximumTypeDarkModeScoreAndActionRemainReachable`, current appearance/home scroll/large text and drink tests; screenshots for human review |
| V321 | `StatusScoreV3UITests.assertClean`: all ten forbidden phrases checked against accessible real views; home/detail/foreground |
| V322 | `DailyStatusHistoryView`, new current score identity vs explicit legacy record link; native history/large dark round-trip |
| V323 | Core composition revision assertion, actual component profile and history composition label; no cross-profile delta |
| V324 | Existing BeverageCare/Notification/Motion/DrinkEditor tests unchanged; V2 scene tests updated only numeric home assertions; record/undo/dose behaviors retained |
| V325 | Gated provider proves stored78 before HRV returns and no unfinished HRV cursor; paginated sleep source selection/fault regression |
| V326 | Raw independent RHR→85 without sleep; scoreRHR native fixture; HRV still requires confirmed asleep intervals for its window |
| V327 | Boundary tests 49/50/69/70/84/85; single StatusBand policy; DTO score/band validation |
| V328 | NaN/range errors, bad/unknown DTO protocol, no zero fallback, failed-store cursor preservation |

## Failure classification / reruns

- S1 initial compile: observable initialization ordering; fixed and UI passed.
- S2 actual regression: floating normalization could yield 100.00000000000001 and fail persistence. Closed-range clamp plus exact-100 raw regression; original thresholds and fixture files unchanged.
- S2 old protocol expectation: phone summary test now asserts real score identity plus legacy/new revocation. Session/drink/ACK assertions preserved. Full App rerun passed.
- `s3-ui2`: 25 UI tests, 19 passed / 6 failed over a host-sleep-interrupted overnight run. `pmset` confirmed repeated deep sleep and final 10:28 wake. These six crash/timeout outcomes are not counted as passing; rerun under process-scoped caffeinate.
- `s4-ui-full`: superseded old-contract run stopped, exit75; preserved locally, not counted as final complete result. Its obsolete preset-selector assertions are archived verbatim under legacy-ui-contracts. Updated cases test the approved V3 surface and actual saved records instead.
- `s4-final`: currently running. Initial locator/type/header/preference issues are being fixed; final aggregate and rerun names will be appended before delivery.

## Local-only device receipt

Installation and version readback succeeded. All 13 Application Support files and preference dictionary matched byte-for-byte / value-for-value before vs after overwrite, before launch. No uninstall or clear. System rejected launch while phone locked; unlock requested. Real score generation/HealthKit refresh, Watch delivery, notifications and subjective visual/comprehension acceptance remain unverified until independently checked. No private health files, device identifiers, signing material or physical screenshots are in this repository.
