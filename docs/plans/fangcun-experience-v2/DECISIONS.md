# Decisions

- V2 requirements apply as a delta to the accepted M3 baseline. No checkout replacement.
- Keep v4 character images and existing v3 breathing assets. Animate local masks, never whole-body stretching or regenerated anatomy.
- DayGuidancePresentation owns user-facing conclusions. The engine's availability, identity, quality flags and timestamps remain intact for diagnostics.
- Diagnostics retain exact measurement/query/calculation meanings. Default views show the one relevant measurement time.
- Sleep quality is dimension-specific. Stage overlap does not destroy a reliable union duration; unresolved awake/asleep conflicts still block whole-sleep conclusions. See V2-02 evidence.
- Drinking remains one authoritative diary, atomic writes and legacy estimates preserved. Coffee is a serving dose unless explicitly entered as concentration. No new HealthKit permissions.
- Local care thresholds are engineering defaults, not validated medical boundaries. External reference material informs wording only; no product network calls.
- A capture demonstrates rendered behavior, not user approval of aesthetics or comprehension. Physical notification delivery is distinct from scheduling.
- V2-01 and V2-02 share the first development commit because the presentation depends directly on the new explicit sleep-quality API. That commit includes real SwiftUI screenshots and three recordings; it is a buildable state. Later motion, dose, policy and notification commits remain separated by responsibility.
- Optional beverage details extend the existing diary envelope. Unknown caffeine is omitted in storage and sent as optional in v2 sync; legacy integer access is a compatibility bridge only. New categories are never downcast. Incoming sync retains the wire payload's origin; a separate local origin mark suppresses replay without an echo revision.
- Care thresholds and notification reservation logic are deterministic pure policies. The system adapter is injected for denial, retry, cancellation and cold-start tests. A mock receipt is never described as physical delivery.
- Explicit severe-symptom safety stays until the user says help has been obtained; no timer silently declares the situation resolved.
- Maximum Dynamic Type uses one scrollable sheet with vertically arranged controls and totals. A screenshot exposed clipping that the initial hittability test missed; the regression now performs record, scroll-to-total and undo. Normal sizes retain the compact sheet.
- Current history groups assessments by recovery cycle and initially displays the latest revision; older revisions remain expandable and stored. Default detail hides technical identities, while the existing diagnostic route retains them.
