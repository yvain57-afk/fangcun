# Little Exhale 2.0 implementation and release

## Authorization and starting point

2026-10-28: The user approved Little Exhale's brand/UI proposal and the ten-practice character/English-voice review. They explicitly requested uploading to TestFlight **and submitting the update to App Store review**. Keep the existing published app available, retain App ID 6818437987 and existing bundle identifiers. Do not delete or reset data.

Start: `560d5790de175f8e5c7b4c9971b7a03f97220557`, branch `codex/fangcun-v4-breathing-hub`. Work branch: `codex/little-exhale-2`. Three pre-existing untracked files remain untouched (Azure setup notes/script and overseas research plan).

Approved references:
- `/Users/yvainair/Downloads/Codex交付/方寸-海外品牌与界面提案-20261028/`
- `/Users/yvainair/Downloads/Codex交付/Little-Exhale-动作与英文试听-20261028/`

## Invariants

- Preserve all practice IDs, duration/phase parameters, variant IDs, golden fixtures, health permissions, stored records and preferences. Never translate user-authored entries in storage.
- English-first authored product content, naturally rewritten; retain original source resources for compatibility. Breathe / Daily remain the two tabs.
- A five-minute sigh remains the main start, with a one-minute option. Keep introduction skipping, voice/tone/ambience/haptic controls, reduced/static motion, and resumable drafts.
- Preserve the approved cat/dog identity. No face stretching, disconnected limbs or whole-image breathing scale. Character motion, visual guide, sound and haptics use the real training timeline and freeze together.
- No new account, backend, analytics, purchase or subscription.
- Public name search found no complete match within stated scope, but does not establish trademark clearance. Do not register a domain or claim legal clearance.
- Audition audio used Edge TTS; do not describe it as a licensed Azure pack. Record the actual production source and any remaining release constraints accurately.

## Work and verification

- [x] Inspect current branch, HEAD and workspace; preserve subsequent changes.
- [x] Integrate English brand, navigation, practice and Daily interfaces; cover secondary pages, accessibility, notifications and Watch.
- [x] Integrate context-specific character actions and original-timeline visual guidance; inspect light/dark, paused, reduced/static and large text.
- [x] Produce and validate English introductions, phase cues, guided segments and endings against existing cue windows; retain skip/mute preferences. (171 decoded assets; native playback acceptance pending.)
- [x] Test local data compatibility, Core (173), App (235), selected UI flows (25 latest passes) and Watch compilation. Physical upgrade/Watch acceptance remains unverified.
- [x] Capture native screenshots and motion evidence; archive and validate the development-signed release archive.
- [ ] Export an App Store distribution IPA (blocked: Xcode has no developer account / distribution identity).
- [ ] Upload once, reconcile processing and TestFlight availability; prepare English store assets and submit the same app's new version for review.

Remote upload, TestFlight processing, review submission and public release are separate states. Record their actual receipts rather than infer success from a local build.

2026-10-29 continuation: User asked the agent to handle all technical preparation independently. Required 6.3-inch store screenshots are now captured and reviewed; use the normal native Safari file picker without changing extension security. Only Apple’s offered owner Touch ID verification is pending human input. No new monitoring authorization.
