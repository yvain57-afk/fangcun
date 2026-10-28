# Little Exhale 2.0 verification

Base: `560d5790de175f8e5c7b4c9971b7a03f97220557`. Branch: `codex/little-exhale-2`.
Same App ID `6818437987`, bundle `com.yvainair.InnerBalance`; version `2.0.0`, build `2026102801`.

## Release state

The user authorized TestFlight upload **and** App Store review submission. Neither has happened. Xcode has no signed-in developer account and no valid distribution identity; App Store Connect is at an expired/failed login page. The Mac remains locked for native UI operations. The existing production app has not been withdrawn or replaced.

A development-signed Release archive is verified locally. It is **not** an App Store IPA. Export failed with `No Accounts` and `No signing certificate "iOS Distribution" found`. Restore the original Xcode/ASC login; no additional release-scope permission is needed. See `release-state.json`.

## Implementation and preservation

- English-first brand, Breathe/Daily, ten practices, introductions, phase instructions, feedback, drinks, secondary pages, accessibility copy and Watch presentation.
- All duration/variant IDs, phase lengths, guided segment IDs/start/end/focus remain unchanged. Original guidance retained as the source of timing. Health score rules, golden fixtures and permission types unchanged.
- No schema migration, database clear, new account/backend/analytics/subscription. Existing AppStorage keys retained. English feedback is normalized to the original stored values; unknown user-authored text stays unchanged.
- Three generated transparent source atlases; twelve native pixel crops. Cat paws, resting-dog head and seated-dog paws/flag use rigid pivots, not face/body distortion. Breathing, holds, side changes and muscle release use the actual session clock; reduced/static/paused behavior remains.
- 171 English audio files, zero rendering/decode/duration failures. No cue-window change or audio truncation. Original 226 audio files have unchanged hashes. See `AUDIO_PRODUCTION.json` and `compatibility-audit.json`.
- Audio source is **Edge TTS**, `en-US-AvaMultilingualNeural`, not Azure Speech. Commercial distribution rights were not independently verified. No new rights attestation has been made.
- Ten completion clips are bundled; paced practices retain the existing on-screen completion flow without new automatic end playback. Guided meditation/NSDR/PMR endings remain within original timed segments.

## Executed verification

### Core and App

`swift test --package-path InnerBalanceCore` — **173 tests / 36 suites passed**. Log `.build/little-exhale-2/core-tests-final.log`. Includes unchanged golden fixtures, storage/replay, original guided boundaries and English projection.

`xcodebuild test -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -destination "platform=iOS Simulator,id=<private simulator>" -derivedDataPath .build/little-exhale-2/DerivedData -resultBundlePath .build/little-exhale-2/AppTestsR2.xcresult -parallel-testing-enabled NO -collect-test-diagnostics never -only-testing:InnerBalanceTests CODE_SIGNING_ALLOWED=NO` — **235 tests / 39 suites passed**, normal exit/readable result. Repeated in final-motion with the same result after subsequent presentation fixes.

### Native UI

`.build/little-exhale-2/PhoneRegression.xcresult` — **18 passed, 1 failed** initially. Passed journeys include all nine hub methods through start/pause/resume/save, all ten actual character stages, intro skip/natural completion, save retry without duplicate, drink add/undo, exit/continue, large type, reduced motion, real sigh expansion, Kegel/resting-dog cycles, diaphragm natural breathing and PMR timings/sleep ending.

The one failure used obsolete Chinese nostril text. Exact English instructions replaced the obsolete expectations, retaining the four-step order. The same test passed in `final-motion/Motion.xcresult` (86.984 seconds).

Final-motion additionally runs all App unit tests, full drink editing/undo/aggregation, English Daily/dark capture on a Chinese system, real PMR boundary, provider-to-Daily health evidence, and ten native pause/resume video recordings. Final result and any subsequent focused recheck are recorded below. This is **not** a claim that every historical UI test in the repository has passed; unselected legacy suites still need presentation migration.

### Watch and archive

`xcodebuild -project InnerBalance/InnerBalance.xcodeproj -scheme 'InnerBalance Watch App' -configuration Debug -destination 'generic/platform=watchOS Simulator' -derivedDataPath .build/little-exhale-2/WatchDerivedData CODE_SIGNING_ALLOWED=NO build` — **BUILD SUCCEEDED**, log `watch-build-r2.log`. Actual Watch simulator home captured and inspected.

`xcodebuild archive -project InnerBalance/InnerBalance.xcodeproj -scheme InnerBalance -configuration Release -destination 'generic/platform=iOS' -derivedDataPath .build/little-exhale-2/ReleaseDerivedData -archivePath .build/little-exhale-2/LittleExhale-2026102801-release.xcarchive -allowProvisioningUpdates -jobs 2 DEVELOPMENT_TEAM=<existing private team>` — **ARCHIVE SUCCEEDED**, exit 0. Signing logs stay private under `.build`.

`python3 scripts/release/verify_little_exhale.py --app .build/little-exhale-2/LittleExhale-2026102801-release.xcarchive/Products/Applications/InnerBalance.app --out docs/releases/little-exhale-2/archive-verification.json` — passed. Strict/deep code signature, identity/version/Watch match, English catalog, privacy manifest, all 171 audio hashes and 12 character layers verified. Executable hash retained.

`xcodebuild -exportArchive -archivePath .build/little-exhale-2/LittleExhale-2026102801-signed.xcarchive -exportPath .build/little-exhale-2/Distribution -exportOptionsPlist .build/testflight-20261021/ExportOptions.private.plist -allowProvisioningUpdates` — **EXPORT FAILED**, missing account/distribution certificate. No blind repeat; no upload attempted.

## Failures found and fixes

- Initial Core run: old Chinese introduction expectation; changed to approved English while keeping 4/4 and 5/5 timing assertions.
- Intermediate score vocabulary edit caused 22 golden failures: restored model vocabulary exactly, supplied English presentation separately. Golden fixtures never edited.
- Initial App failures: missing 21 legacy English fallback clips and translated feedback parser; supplied exact-window cues and legacy-compatible normalization. Other presentation expectations updated without changing contrast thresholds or dropping behavior assertions.
- First simulator attempt unavailable runtime / iPhone Duo layout: installed ordinary iOS 27.0 runtime and used iPhone 16 Pro Max. Review test preparation/intro-race issues fixed in the harness.
- Dark drink capture showed the old shader removing cream fill; replaced Daily companion usage with the transparent native layers. Long care buttons now stack with 44-point targets.
- Provider-to-Daily tests exposed a new DisclosureGroup identifier leaking into children, hiding their identifiers. Identifier moved onto its label, preserving all child controls. Preformatted dates in the index, history and evidence could still use system Chinese; explicit English presentation locales now cover those strings. Focused regression follows below; scoring and time values unchanged.

## Native evidence and remaining limits

Authoritative delivery: `/Users/yvainair/Downloads/Codex交付/Little-Exhale-2.0-发布更新-20261028/`.
Screenshots/recordings are actual native simulators using synthetic isolated records, not web reconstructions or personal health captures. Hash/provenance manifests accompany the gallery. Video shows visuals; simctl does not verify physical audio or haptics.

Physical iPhone upgrade preservation, interruptions, lock-screen audio, Bluetooth, real HealthKit and Watch synchronization remain **unverified this round**. Simulator passes are not substituted for them. Public name search is not trademark clearance.

Support/privacy pages were updated on the existing dedicated `codex/store-support-site` branch. Live HTTP 200 and exact hashes verified for all three pages (`site-live-check.json`). They retain Chinese support and clearly state the 2.0 update is being prepared. No main merge.

## Final focused follow-up

After moving the disclosure identifier, `EvidenceFinal.xcresult` exposed the harness still searching for the old button identifier. That run was intentionally interrupted (exit 75); it is not a pass. The test now taps the identified visible disclosure label and scrolls to the existing controls, retaining all data/time expectations. The rerun uses `EvidenceFinalR2.xcresult` and `evidence-final-r2.log`.

The final archive also applies English locales to preformatted history/evidence dates and relative dates. This is display-only; native Release compilation/signature/resource checks passed after those edits. No additional model or storage changes were introduced.

`EvidenceFinalR2.xcresult`: **5/5 passed, normal exit 0**, readable xcresult. All four provider-to-Daily data/time tests and English dark Daily/drinks passed. Across the selected current native UI journeys, **25 unique tests have a passing latest result**, zero unresolved failures; initial failed bundles are retained in `test-results.json`.

Ten native recordings finished normally, each 1320×2868, roughly 33 seconds including pause/continue; all ten fully decoded with FFmpeg. Source hashes and viewing limits are in `video-verification.json`. The final offline gallery contains **49 native screenshots and 10 recordings**. Screen captures cover all ten practice stages, light/dark Breathe/Daily, drinks, specific movement teaching, synthetic health evidence, and Watch home. These are selected acceptance screens, not an exhaustive capture of every possible state.

Copy-table note: the TSV exact-literal source/target columns intentionally retain trailing spaces for concatenated labels. `git diff --check` flags those data rows; Swift/source whitespace checks are clean. Do not trim them and change the generated strings.
