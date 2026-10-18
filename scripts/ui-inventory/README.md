# Native UI review evidence

Capture journeys are deliberately kept **outside the UITests target**, so normal regressions do not include slow screenshot/video collection. The Python runners temporarily copy only their own Swift file into the existing UI test target, refuse to overwrite an existing file, and remove that copy only when its bytes still match. They reuse the real app's navigation, synthetic UI-testing store and training clock; no production health data or phone is accessed.

## Current UI overhaul (2026-10-18–19)

Run from the repository root, after other UI tests have finished. Supply an isolated simulator UUID and a fresh output directory beneath `.build/ui-overhaul-20261018/`.

```sh
python3 scripts/ui-inventory/capture-ui.py --simulator SIMULATOR_UUID --output .build/ui-overhaul-20261018/capture
python3 scripts/ui-inventory/record-motion.py --simulator SIMULATOR_UUID --output .build/ui-overhaul-20261018/motion
python3 scripts/ui-inventory/package-review.py --work .build/ui-overhaul-20261018 --output DELIVERY_DIRECTORY
```

`capture-ui.py --only test09MenusDemonstrationAndNaturalCompletion` can replay one journey in a fresh output directory. Keep failed results/logs; don't replace them with successful results at the same path. `-parallel-testing-enabled NO` prevents simultaneous UI workers; `-collect-test-diagnostics never` skips the simulator sysdiagnose collection that stalled on this host, while retaining normal test results, screenshots, logs and assertion failures.

The capture suite covers all nine methods, entry/active/pause/finish/feedback/history, daily score and missing data, trends, drinks and composite editing, feelings, light actions, settings and subpages, drafts, failures, dark mode and maximum Dynamic Type. Repeated numbered screenshots are scroll positions, not additional independent screens.

`MotionReviewUITests` emits markers only after a real native session starts. `record-motion.py` records that simulator display with `simctl recordVideo`, capturing 24 seconds of training plus pause and resume. These are visual recordings, not evidence of real-device audio/haptics, lock-screen behavior, HealthKit or Watch connectivity.

`package-review.py` copies original PNG/MP4 files and creates a searchable HTML index and SHA-256 manifests. It does not redraw, retouch or simulate the UI. App signing/export and verification receipts are handled separately. See `docs/plans/ui-overhaul-20261018/` for the corrected specification and final evidence.

## Previous inventory

The prior read-only baseline was `b882c02b23091776488b6518089cbd6d91832a5c`, captured on 2026-10-18. Its raw Capture/Supplement/Final/AppearanceFinal results remain under `.build/ui-audit-20261018/`; they are historical evidence and are not substituted for current screenshots.
