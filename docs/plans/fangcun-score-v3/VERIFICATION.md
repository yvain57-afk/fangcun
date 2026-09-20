# V3 verification ledger

## Actual commands

Canonical working directory: `/Users/yvainair/Code/fangcun`.

- `cd docs/plans/fangcun-score-v3 && python3 -m unittest -v test_reference_score_v3.py`: 14 methods / 24 reference cases passed.
- `swift test --package-path InnerBalanceCore`: final 162 tests / 31 suites passed, exit 0 (`s4-core-complete.log`); includes raw 64 points, log-HRV display consistency and HealthKit selection superseding manual sleep without history loss.
- `DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination 'platform=iOS Simulator,id=<local simulator>' -derivedDataPath <local DerivedData> -resultBundlePath <local result.xcresult> -parallel-testing-enabled NO -test-timeouts-enabled YES -maximum-test-execution-time-allowance 90 -collect-test-diagnostics never -only-testing:InnerBalanceTests -only-testing:InnerBalanceUITests CODE_SIGNING_ALLOWED=NO`: `s4-final`, normal exit 65 and readable result: 251 total (197 App passed, 54 UI: 47 passed / 7 failed); final `s4-acceptance` exit0, 212/212 passed (198 App + 14 focused UI), readable result. Across the complete run and focused reruns, all 54 distinct UI cases have passing latest results; zero skipped. Device identifiers remain local.
- `DEVELOPER_DIR=/Applications/Xcode-27-beta.app/Contents/Developer xcodebuild build -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath <local WatchDerivedData> CODE_SIGNING_ALLOWED=NO`: `s4-watch-complete.log`, final shared Core BUILD SUCCEEDED, exit 0.
- Signed Release uses the existing local signing identity, generic iOS destination and final `CURRENT_PROJECT_VERSION=2026092002`. Credentials/team/profiles/logs remain local. Build exit 0. Initial build2001 install exited0. Final build2002 install reported an interrupted connection (CoreDevice3002 / IXRemote6); fresh `devicectl device info apps` exited0 and independently confirmed installed **1.0.0 (2026092002)**. No blind reinstall was needed.

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
| V317 | Old owner selection/generation/CAS tests preserved; additional `simultaneousTargetAndSourceChangeRejectsOldScoreIntent` passed in the full198 App rerun |
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
- `s4-final`: 7 failures comprised four CheckInFlow locator/header/preference cases, Appearance brand locator, actual duplicate resume accessibility elements, and actual post-practice feeling display mismatch. No assertion was removed. `s4-rerun`: normal exit65, readable result, 198 App passed; 25 UI: 21 passed / 4 failed. It exposed an off-screen privacy row and no-breathing test preference left enabled (three tests expecting breathing correctly received rest). Scroll to the privacy row; assert preference reset to 0 and declare default preference preconditions. Keep accessibility hiding on the home content only, outside the modal presenter. `s4-acceptance` exited0 with all 212 tests passed. Original failed cases each have a passing rerun; [filtered machine-readable results](evidence/test-results.json) identify the latest passing run for each of the 54 UI cases.

## Local-only device receipt

Final installed version2002 was confirmed by fresh device readback after the install connection error. All 13 Application Support files and the preference dictionary matched byte-for-byte / value-for-value before vs after this final overwrite, before launch. No uninstall or clear. System rejected launch while phone locked; unlock requested. At that initial check, real score generation/HealthKit refresh remained unverified; the unlocked-phone follow-up below supersedes those two statuses. Watch delivery, notifications and subjective visual/comprehension acceptance remain separate. Final launch returned CoreDevice10002 with explicit locked/denied evidence; this is not counted as a successful runtime verification. No private health files, device identifiers, signing material or physical screenshots are in this repository.

## Original contracts and fixture integrity

`git show 7d2f87e:<golden path>` compared byte-for-byte with the working tree: the original golden file is unchanged. V3 SCORE_V3_FIXTURES.json and SCORE_POLICY_v3.json match the ZIP bytes. Reference runner was accidentally invoked once from repository root (module not found); running from its documented package directory passed all 14 methods / 24 cases.

## Final acceptance (normal exit / readable results)

| Run | Exit | App | UI | Result |
| --- | --- | --- | --- | --- |
| s4-final (complete) | 65 | 197 pass | 47 pass / 7 fail | preserved failure history |
| s4-rerun | 65 | 198 pass | 21 pass / 4 fail | locator scrolling / test preference cleanup resolved next |
| s4-acceptance | 0 | 198 pass | 14 pass / 0 fail | final affected flows; result readable |

Latest result across the complete and focused runs: **54 distinct UI tests passed**, none skipped. This is aggregate coverage, not a claim that the original complete command passed. Final14 = CheckIn no-breathing preference/reset(1), water/coffee/alcohol/undo(1), appearance/privacy/full practice/check-in(1), redesign/motion/preferences/complete journey(4), saved feeling(1), original practice return tests(2), V3 sleep78/manual/night/maximum-type(4).

Focused runs use the same `xcodebuild test` command above and `-only-testing:InnerBalanceTests` plus the class/method IDs in [test-results.json](evidence/test-results.json). Core162, App198, 24 unchanged numeric fixtures, unchanged legacy golden, Watch simulator build and signed iOS Release all passed. Original physical Watch/background remains unverified. Real HealthKit refresh and phone launch were subsequently verified in the unlocked-phone follow-up below. Maximum-type content scrolls; a single automated device size and synthetic data do not prove human three-second comprehension or every narrow-device layout.

## Final media evidence

The final screenshots and three recordings are from `s4-acceptance` synthetic simulator UI. simctl uses variable frame timestamps: cuts were selected by inspecting actual frames, not assuming wall-clock test timestamps equal video timestamps. Playback retains native speed; exported videos contain no device identifiers or private metadata. Home78 is a raw-provider fixture; water/coffee/alcohol/undo shows persisted feedback; breathing shows actual inhale/re-inhale/exhale clock and pause/exit. Files: `evidence/S4-home-action.mp4`, `S4-drinks.mp4`, `S4-breathing.mp4`. Appearance remains subject to human review.

## Unlocked-phone follow-up

After the user confirmed the phone was unlocked, the installed Release2002 app launched successfully (`devicectl device process launch`, exit0). Fresh app-container readback and installed-version readback all exited0. The successful-query timestamp advanced; a fresh, non-manual V3 score snapshot was persisted without a query-failure flag. Replaying its actual inputs with the package's independent reference evaluator matched the integer, raw value and band (Swift enum mapped to the reference's Chinese band labels).

The copied database passed read-only `PRAGMA quick_check`. All pre-launch rows in the practice completion, cached check-in and daily-record tables remained present, old assessment identities were retained, and existing diary/display/scoring preferences matched. Only pass/fail conclusions are public; actual values, records, private copies and device receipts remain local. The initial band comparison in the local verification adapter compared enum text with translated labels; it was corrected to the explicit one-to-one label map. No product code or scoring parameter changed.

This closes the earlier locked-launch and real-query/persisted-score verification gaps. It does not establish a physical visual walkthrough, true nighttime action acceptance, Watch delivery/background behavior, or medical validation. No source change or additional permissions were needed; code tests above remain applicable.
