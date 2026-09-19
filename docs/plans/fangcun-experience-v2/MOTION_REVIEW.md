# Motion implementation

V2-03 reuses the six existing source images. No artwork regeneration or anatomy replacement.

- `CompanionMotionPolicy` defines event eligibility, durations, standard/gentle/static intensity and breathing priority. `CompanionMotionCoordinator` consumes IDs and holds one current gesture; there is no replay queue.
- SwiftUI drives a finite 30 fps timeline only while visible, active, uncovered and allowed by accessibility/power settings. Static/finished/breathing branches contain no decorative TimelineView. Inactive events are dropped.
- Water commit: 1.1 s cup-interior displacement plus head/tail masks; other drinks: 0.6 s neutral head nod, no drinking animation. Undo is 0.25 s inverse cup movement.
- Entry calm 1.8 s; rest/curious 1.6 s; completion 1.3 s only on saved screen. Pre-save comparison art is static. Early end uses rest.
- Breathing uses the existing session's expansion only, and pausing preserves that value. Removed saved-screen whole-character scale animation.
- Existing flattened images cannot support a real new blink or detached paw articulation. Mask-based ear/head follow and the existing paw-touch pose are the supported scope; not claimed as new skeletal animation.

Evidence: [six scene recordings and drink variants](evidence/final-native/README.md), with the first three recordings retained under `evidence/first-native/`. `CompanionMotionPolicyTests` five tests pass in the final 145-test Core run. Simulator evidence includes a real 60-second completion, a five-minute session's live/paused phase, dark appearance and maximum text size. No real health values appear in these captures.

The original recording has simulator startup latency; final clips are aligned to actual video frames rather than using xcresult attachment wall time as frame time. Sampled water, breathing and completion frames were inspected. Completion shows transition to the saved screen, not an injected “finished” state.

Physical Reduce Motion/Low Power/VoiceOver and long-run energy are unverified. Dark-mode blue ink remains the approved original rather than an inverted palette; its subjective visibility and naturalness remain for human review. No physical/user aesthetic acceptance is inferred from shader compilation or test counts.
