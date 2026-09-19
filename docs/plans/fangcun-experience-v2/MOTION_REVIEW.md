# Motion implementation

V2-03 reuses the six existing source images. No artwork regeneration or anatomy replacement.

- `CompanionMotionPolicy` defines event eligibility, durations, standard/gentle/static intensity and breathing priority. `CompanionMotionCoordinator` consumes IDs and holds one current gesture; there is no replay queue.
- SwiftUI drives a finite 30 fps timeline only while visible, active, uncovered and allowed by accessibility/power settings. Static/finished/breathing branches contain no decorative TimelineView. Inactive events are dropped.
- Water commit: 1.1 s cup-interior displacement plus head/tail masks; other drinks: 0.6 s neutral head nod, no drinking animation. Undo is 0.25 s inverse cup movement.
- Entry calm 1.8 s; rest/curious 1.6 s; completion 1.3 s only on saved screen. Pre-save comparison art is static. Early end uses rest.
- Breathing uses the existing session's expansion only, and pausing preserves that value. Removed saved-screen whole-character scale animation.
- Existing flattened images cannot support a real new blink or detached paw articulation. Mask-based ear/head follow and the existing paw-touch pose are the supported scope; not claimed as new skeletal animation.

Evidence so far: first native clips under `evidence/first-native/`; `CompanionMotionPolicyTests` three tests pass in Core 139 test run. Final scene/large-type/dark captures and physical power/performance validation are tracked separately in VERIFICATION.md. Human cuteness review remains pending.
