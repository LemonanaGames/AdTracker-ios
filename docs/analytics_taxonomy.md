# Analytics taxonomy

**M1 status:** events are emitted by the pure engine as `GameEvent`s. The app logs them through the
`Telemetry` interface into an **in-memory debug sink only**, so nothing leaves the device. Firebase
Analytics and Singular adapters arrive in M4 and must be checked with their debug tools before
anyone relies on the data (GDD Part J rule 8).

## Emitted today

| Event | Source | Params |
|---|---|---|
| `tutorial_start` | onboarding open | — |
| `tutorial_step` | onboarding step advance | `step` |
| `tutorial_complete` | life created | `step` |
| `new_life_started` | life created | `niche_id`, `persona` |
| `content_composer_open` | Create opened | — |
| `post_published` | engine | `network_id`, `content_format`, `topic_id`, `quality`, `viral_tier` |
| `followers_milestone` | engine | `network_id`, `milestone` |
| `network_unlocked` | engine | `network_id` |
| `story_act_complete` | engine | `act` |
| `level_up` | engine | `player_level` |
| `gear_purchased` | engine | `gear_id`, `cost_minor` |
| `skill_spent` | engine | `skill_id`, `rank` |
| `job_shift_completed` | engine | `job_id`, `pay_minor` |
| `offline_claimed` | engine (Collect) | `amount_minor` |
| `story_choice_made` | engine | `event_id`, `choice_id`, `act` |
| `relationship_changed` | engine | `npc_id`, `delta` |
| `clock_rollback_detected` | engine | `delta_ms` |
| `save_failed` | controller | `error` (type name only) |

## Rules

- Params are stable enum-like strings or integers. They never contain PII, file names, paths, free text, or the player's name or handle.
- Media import (M6) may only log `custom_media_used=true`.
- Use one verified revenue feed per revenue type (IAP via RevenueCat or the backend; ad revenue via impression-level paid events → Singular) to avoid double counting.
- When the Firebase adapter lands, add a contract test that every emitted name is listed in this file, and add `app_version` / `content_version` / hashed `life_id`.

Remaining GDD F6 events (sponsor, offer, purchase, rewarded, share, media, sync) get added together with their features.
