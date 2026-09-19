# V2 implementation ledger

Baseline: `99ebe69f30a2a502225e913a9dfd35f54101dabd`, branch `codex/fangcun-v1-m0-m1`.
Workspace was clean at intake. Canonical checkout `/Users/yvainair/Code/fangcun`; legacy checkout untouched.
ZIP SHA256: `c84b79ba0550472cd554b51306504cf96f7fba36f61222125655dfbff1e73be7`.
All eight manifest members match their hashes; standalone Markdown and DOCX match package copies.
Original package files are requirements, not completion receipts.

| Stage | State | Evidence |
|---|---|---|
| V2-00 intake and boundaries | complete | This document; baseline clean; manifest verified |
| V2-01 meaning and first experience | implemented / automated verified | DayGuidanceV2Tests; first and final native evidence; human comprehension pending |
| V2-02 sleep quality and coverage | locally verified | V2-02-VERIFICATION.md; 120 Core tests |
| V2-03 scene motions | implemented / human review pending | six real scene clips; five motion policy tests; physical accessibility/power pending |
| V2-04 beverage data | implemented / automated verified | serving/concentration/ABV, atomic commands, undo revisions, old-peer gate |
| V2-05 care policy | implemented / automated verified | 19 pure care tests; thresholds remain engineering defaults |
| V2-06 local notifications | implemented_unverified on physical system | four injected-client tests pass; physical permission/delivery/cold-start pending |
| V2-07 integration | engineering delivery complete / acceptance partial | REVIEW.md, ACCEPTANCE_RESULTS.md; installed without uninstall; launch blocked by phone lock; human review pending |

Baseline known debt: prior M3 UI run had 15 remaining old-contract failures, while Core 112 and App 185 passed. This is historical evidence, not a current run. V2 intentionally moves diagnostic details out of the default detail screen; affected UI assertions must move to the actual diagnostic route, not disappear.
No M4–M6 expansion, model parameter/golden changes, new HealthKit dietary permissions, backend, or telemetry.
Private device/audit files and raw xcresult bundles stay outside Git. Published assets use synthetic simulator data only.

Phased commits: `3f3dd25` V2-01/02; `a3670d5` V2-03; `c7a8c0d` V2-04; `870ccd3` V2-05; `b2df4a9` V2-06; V2-07 is the commit containing this final ledger and acceptance receipts. No claim that all 45 acceptance cases or the entire legacy UI suite pass.
