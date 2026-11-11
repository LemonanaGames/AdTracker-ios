# Story graphs

Story events live in `game_content/narrative/events.json` (schema:
`game_content/schemas/story_event.schema.json`). The engine applies the choice `effects` exactly
as written, and the UI builds preview chips from the same data, so a preview can never promise
something the engine doesn't do.

## Implemented (M1 stub)

```
[Prologue]
  trigger: postsPublished ≥ 2 AND any post ≥ 500 views (once per life)
  V01 "Your Phone Is Blowing Up"  (Maya, Kai)
   ├─ ride_trend     → integrity −4, Kai +5, next Loop post trend +20% (1 use)   flag v01_rode_trend   → V01_KAI_COLLAB (not authored)
   ├─ make_it_yours  → trust +5, +15 XP, next 3 posts quality +3                 flag signature_series_unlocked
   └─ ask_maya       → requires cash ≥ $100; cash −$100, Maya +8                  flag duet_thumbnail_unlocked
```

Every choice also sets `choice:V01:<id>`, which later callbacks can use.

## Planned (M3)

Arcs 1–5 from GDD B3: V02, S01–S03, R01–R03, L01–L04, F01–F02. Callbacks must land within 3–10
beats, and every ending (Mogul, Icon, People's Creator, Life Off-Camera, Controversial Legend,
fallback Self-Made Creator) needs an automated reachability test. No ending may require a purchase.
