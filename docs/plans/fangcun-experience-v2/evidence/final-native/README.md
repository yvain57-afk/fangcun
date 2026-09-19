# Native synthetic visual review

All images are XCTest screenshots of the current SwiftUI app. Videos are cuts from an actual `simctl io recordVideo` run, not generated animation or HTML mockups. Inputs are synthetic provider fixtures. No raw attachment manifest (which contains simulator identifiers) is published.

| Scene | Screenshot | Actual recording |
|---|---|---|
| Usual / calm duo | [Home](scene-assessable.png) | [Calm](calm.mp4) |
| Reduced / resting dog | [Reduced](scene-reduced.png), [low](scene-low.png) | [Rest](rest.mp4) |
| Insufficient / curious cat | [Limited data](scene-insufficient.png) | [Curious](curious.mp4) |
| Committed water | [Water](scene-drink-water.png) | [Record and undo sequence](drinks.mp4) |
| Neutral coffee/alcohol, undo | [Coffee](scene-drink-coffee.png), [alcohol](scene-drink-alcohol.png), [undo](scene-drink-undo.png) | [Continuous water / coffee / alcohol / undo](drinks.mp4) |
| Five-minute breathing entry | [Breathing](v2-breathing.png) | [Live breathing](breathing.mp4) |
| Saved actual one-minute completion | [Saved](scene-completed.png) | [Completion](complete.mp4) |
| Maximum Dynamic Type / dark | [Home](scene-dark-large-home.png), [detail](scene-dark-large-detail.png), [sheet](scene-dark-large-drinks.png), [full totals](scene-dark-large-drink-summary.png) | Static mode intentionally used |

`v2-ui-final` produced the scene recordings and initial screenshots. The final `v2-ui-accessible` rerun replaced drink/dark screenshots after fixing maximum-type layout; normal row wrapping therefore differs slightly from the earlier video. Business events, source art and motion behavior are unchanged. Initial failing-layout screenshots remain only in the private result bundle for diagnosis.

Human checks still pending: first-glance comprehension, distinguish scoped advice from full assessment, naturalness/cuteness, and the original blue ink's dark-mode visibility. These are review materials, not a user approval receipt.
