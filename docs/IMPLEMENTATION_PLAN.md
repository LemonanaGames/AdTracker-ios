# Implementation Plan — Influencer Simulator: Zero to Fame

Source of truth: [`GDD_MASTER_v2.md`](GDD_MASTER_v2.md). This file summarises the architecture
decisions, open owner inputs and milestone status. It is updated after each milestone.

## 1. Architecture decisions (summary)

| Area | Decision | Where |
|---|---|---|
| Stack | Flutter (stable 3.47 / Dart 3.13), iOS-first, Android-compatible | [ADR-001](ADR/001_flutter_ios_first.md) |
| State | Riverpod 3 (`Notifier`) holds *projections only*; no rules in widgets/controllers | `app/lib/app/game_controller.dart` |
| Navigation | go_router `StatefulShellRoute` — 5 labelled tabs, each its own stack; onboarding redirect | `app/lib/app/router.dart` |
| Domain | Pure Dart, no Flutter/SDK imports (enforced by test) | `app/lib/domain/**`, `app/lib/core/**` |
| Simulation | Integer math only; seeded Mulberry32 + FNV-1a (32-bit, platform-identical); post stats are a pure function of elapsed sim time → crediting is idempotent | `domain/engine/post_simulation.dart` |
| Time | Wall clock → sim time via `simSecondsPerRealSecond`; offline capped (free 4h / Pro 24h); clock rollback re-anchors without gain or loss | `domain/engine/game_engine.dart#advanceTo` |
| Content | Versioned JSON in `game_content/`, bundled as Flutter assets, parsed into `GameCatalog`, cross-checked by `CatalogValidator` | `game_content/`, `domain/content/` |
| Gates | One `Requirement` DSL for acts, unlocks, gear, hooks, jobs, goals, story triggers; the same check powers UI checklists ("You need X more") | `domain/content/requirement.dart` |
| Persistence | Drift/SQLite, one row per life + account; payload is a versioned `SaveCodec` envelope with stepwise migrations; revision guard blocks stale writes | `data/`, `domain/save/` |
| Localization | UI chrome via ARB (`gen-l10n`), content strings via `game_content/localization/en.json`; directional insets for future Hebrew RTL | `app/lib/app/l10n/` |
| Telemetry | `Telemetry` interface; M1 ships an in-memory debug sink only — nothing leaves the device | `core/telemetry.dart` |
| Assets | `asset_manifest.json` maps every content `assetKey`; all M1 entries are labelled **placeholders** (vector icons) | `app/assets/asset_manifest.json` |

## 2. Open configuration inputs (owner)

Non-blocking for M0–M3; blocking where noted.

1. **Repository/product name** — repo should be renamed (see README); title legal/ASO clearance pending (K3).
2. **Bundle identifier** — currently `com.lemonanagames.influencerSimulator` (Flutter default from org). Confirm before App Store Connect setup.
3. **Apple Developer team / signing** — needed to run on device and for TestFlight (M7).
4. **Firebase project** (`GoogleService-Info.plist`) — blocking for M4.
5. **Singular SDK key/secret** — blocking for M4 attribution.
6. **RevenueCat project + App Store Connect products** (`pro_lifetime`, `starter_one_time`, `cash_small`, `sp_small`) — blocking for M5. Prices are set in App Store Connect only.
7. **AdMob app ID + rewarded ad unit IDs + SSV endpoint** — blocking for M5.
8. **Art direction** — approve a 1-page style bible + 3 test assets before batch generation (G1).
9. **Fonts** — Inter (or licensed equivalent) files to bundle; M1 uses the platform font.
10. **Minimum iOS version** — Flutter tooling default is iOS 15.0; revisit once Firebase/RevenueCat/AdMob versions are pinned (K3).

## 3. Milestone status

| Milestone | Status |
|---|---|
| M0 — foundation | ✅ done (this change) |
| M1 — playable core | ✅ done (this change) — see report below |
| M1.5 — feel & retention pass (owner request) | ✅ done — see §5 |
| M2 — multi-network + sponsor rules | ⏭ next |
| M3 — narrative / life / endings / archive | not started |
| M4 — Firebase, sync, Remote Config, Crashlytics, Singular | not started (needs credentials) |
| M5 — AdMob rewarded, RevenueCat, offers, paywalls | not started (needs credentials) |
| M6 — UX polish, media import, share cards, a11y audit | not started |
| M7 — TestFlight soft launch | not started |

---

## 4. M0 + M1 report

### 4.1 Implemented (real files and behaviour)

**M0 — foundation**
- Flutter app in `app/` (iOS + Android runners, portrait-only, display name "Influencer Sim").
- Strict analysis options, theme tokens (GDD D3 palette, 8-pt grid), localization pipeline (194 ARB strings).
- go_router shell with 5 labelled tabs; onboarding redirect.
- Pure domain layer + repository interfaces; Drift database; content catalog + validator; asset manifest.
- CI workflow `.github/workflows/ci.yml` (analyze, test, content validation, balance sim, iOS no-codesign build).

**M1 — playable vertical slice**
- Onboarding (GDD I4 beats 1–4): welcome → creator name + editable suggested handle → niche (Comedy/Gaming/Lifestyle) → avatar preset + cosmetic persona (On-camera / Faceless, GDD B5).
- Home: header (avatar, level, energy, cash, skill points), Maya intro, "While you were away" summary, Collect earnings card, story card, **Total followers across networks** + modeled **Estimated unique reach** (A1.3), Next goal with progress, three network mini-cards (locked ones show the requirement), pinned **Create Post** CTA, latest post chart.
- Create: network → topic (own-niche, trending, "Start here" for the first post) → hook (locked hooks show the level needed) → owned gear → live preview (quality breakdown, expected view range, viral chance, energy cost, XP; "estimates, not promises") → Publish → result sheet with rolling counters, sample comment and one-time coachmark.
- First post quality is exactly **38/100** as specified in I4.
- Simulation: seeded quality/trend/viral roll, per-network curves (Loop 50%@2h → 100%@36h; TubeCast 20%@2h …; Vibe 30%@2h …), audience fatigue, follower conversion with trust & niche affinity, integer RPM revenue into a pending wallet, idempotent Collect.
- Jobs (cafe / delivery / freelance), energy & stress with exact regeneration, XP → Creator Level → Skill Points; six skills with Before → After preview (Negotiation disabled until deals exist).
- Gear shop: enabled items with Cost → "Gear quality +8 → +10"; disabled items (editing app, laptop, pro studio) are hidden until their effects exist.
- Acts: Prologue → Act I (Loop 1K **or** Level 3) unlocks TubeCast automatically; Act II rule (10K + engagement, or TubeCast 5K, or trust alt) unlocks Vibe. Posting on TubeCast works once unlocked.
- Social tab: per-network dashboard (followers, 7-day views, engagement with formula tooltip, earned), post list, post detail with chart and "why quality was X".
- Deals tab: honest "coming in the next update" + live Seed-tier checklist and later tiers (read-only preview of the GDD C2 table).
- Story **V01 stub** "Your Phone Is Blowing Up": real trigger (2 posts + a 500-view post), three choices with effect-derived preview chips, a cash-gated choice that shows its requirement, real effects (trust/integrity/relationships/XP/modifiers/flags). **Callbacks (Kai collab, Signature Series content) are not implemented** — they arrive with the story engine in M3.
- Persistence: autosave every 10 s and after every command, on app pause; offline catch-up on launch/resume (capped at 4 h free).
- Balance tooling: `AutoPlayer` + `tool/simulate_lives.dart`.

### 4.2 Tested (commands and actual outcomes, this environment)

```
cd app
flutter analyze                       → No issues found
flutter test                          → 50 tests, all passed
dart run tool/validate_content.dart   → OK (0 errors; 1 warning: V01 callback event not authored yet)
dart run tool/simulate_lives.dart 45 180   → see docs/economy_balance.md
```

M1-required tests (all passing):

| Requirement | Test |
|---|---|
| same seed → same post output | `test/domain/game_engine_test.dart` › determinism |
| no negative views/followers/cash | `test/domain/balance_test.dart` (30 seeded lives × 3 strategies) |
| claim twice → second grants 0 | `game_engine_test.dart` › income |
| insufficient cash → no mutation | `game_engine_test.dart` › gear |
| save migration round-trip | `test/save/save_test.dart` (codec, v0→v1 migration, Drift SQLite in-memory, stale-write guard) |
| platform independence | `game_engine_test.dart` › platform independence (+ cross-promotion adds reach only) |
| onboarding → first post; state after restart | `test/widget/first_session_test.dart` |

Also covered: offline cap, Pro cap, clock rollback, tick-splitting equals one step (no drift), curve monotonicity, V01 effects, RNG stability, content validator, asset manifest resolution, assets bundled via `rootBundle`, domain purity, no float money, formatters.

**Not run here:** an iOS simulator/device build (this Linux container has no Xcode). The CI workflow builds iOS (`--no-codesign`) on a macOS runner. Screens were checked by rendering the real widget tree with real fonts (`tool/screenshots_test.dart`).

### 4.3 Not implemented yet (no pretending)

- Sponsor offers, negotiation, contracts (M2). Deals tab is a read-only preview.
- Production timers / editing app / laptop capacity / queue (gear items exist but are disabled).
- Story engine beyond V01; V02+, callbacks, relationships UI, homes, endings, Life Archive, new life (M3).
- Firebase (Auth, Firestore sync, Remote Config, Crashlytics, Analytics), BigQuery, Singular (M4). No SDK is installed.
- AdMob, RevenueCat, StoreKit, offer engine, paywalls, Pro entitlement (M5). `advanceTo(pro:)` exists but nothing grants Pro.
- Personal media import, share cards, confetti, Rive, formal accessibility/contrast audit, performance profiling on device (M6).
- Final art: **every image is a labelled vector placeholder** (`asset_manifest.json` → `status: placeholder`).
- Bundled Inter font (system font used).
- Old-post compaction (saves grow ~0.6 KB per post; fine for M1, compaction planned for M2).

### 4.4 Credentials / configuration required

None for M0–M3. For M4+: Firebase plist, Singular keys, RevenueCat API key + App Store Connect products, AdMob IDs + SSV, Apple signing team. Secrets go into CI secrets / local untracked files, never into Git.

### 4.5 Risks / open design decisions

- **Pacing** is simulated, not playtested: first gear ≈ 0.1 min (cafe shift), Loop 100 ≈ 2 min, Act I ≈ 12 min, Act II ≈ 2.7 h of active play. Late game (100K–1M) is untuned until sponsors/lifestyle sinks exist.
- **Act I triggers via Level 3 before Loop 1K** for every bot — fine for the "network strategy preview in 10–15 min" beat, but worth playtesting.
- Engagement uses posts *published* in the last 7 game days (not views accrued in the window) — simpler and explained in the tooltip; revisit if sponsor gates feel off.
- `last7dViews` and engagement are recomputed each tick over all posts — O(posts); add compaction before late-game.
- Content is loaded from `../game_content/` via pubspec asset paths outside the package. Verified with `rootBundle` in tests; first real iOS build in CI will confirm on-device bundling.
- iPad is portrait-only with `UIRequiresFullScreen` (no Split View) — revisit if iPad matters.

### 4.6 Next milestone — M2 acceptance criteria

1. Sponsor templates in `game_content/deals/` (≥10, GDD I1 schema) validated by `CatalogValidator`; Seed/Micro/Emerging tiers reachable in the balance sim without paying.
2. Offer eligibility per network exactly as GDD C2 (followers, 7-day views, engagement, trust, niche, exclusivity, cooldown) with a checklist UI showing "You need N more …" for each failed condition.
3. Contracts with game-day deadlines that never fail from real-world absence; fulfillment by publishing qualifying posts; payout idempotent per contract ID (test: double fulfill → single payout).
4. Negotiation with displayed success-probability range and a seeded, reproducible roll; Negotiation skill enabled with Before → After.
5. Story events S01–S03 hooked to sponsor state with real callbacks.
6. Per-network follower growth chart and old-post compaction keeping saves bounded (test: 2,000 posts → save < 300 KB).
7. All of the above covered by unit tests + one widget test (accept → fulfil → collect).

---

## 5. M1.5 report — feel & retention pass (owner request, between M1 and M2)

The owner asked for a less generic, more animated look, sound effects, smart reminders and a
build they could play. This pulls part of M6 (polish) and M6 (local notifications) forward.

### 5.1 Implemented
- **Visual identity:** bundled OFL fonts (Bricolage Grotesque for display, Inter for body),
  procedural flat-illustration characters for avatars and NPCs (`ui/characters.dart`), sticker-style
  icon tiles and labels, tactile "chunky" game buttons (`ui/chunky_button.dart`), a custom nav bar
  with a raised Create button, thumbnail-style topic cards, an animated quality gauge and a followers
  sparkline rebuilt exactly from post curves (`domain/engine/history.dart`).
- **Motion:** staggered card entrances, floating "+N" deltas on followers and cash, drifting
  gradient hero, live pulse dots, an upload ring and confetti on publish, chat messages with a
  typing indicator, full-screen celebrations (level up, network unlock, milestone, new act) with
  rays, queued so they never stack. Everything is static under Reduce Motion, and continuous motion
  can be disabled (`ambientMotionProvider`).
- **Sound and haptics:** 9 original synthesized SFX (`tools/sfx_synth/make_sfx.py`), played with
  low latency through an ambient iOS audio session (respects the silent switch and mixes with
  music). Haptics are mapped per event in one place (`reactToEvent`), with settings toggles for both.
- **Smart reminders:** see [`notifications.md`](notifications.md). A pure planner that projects
  real outcomes, with a contextual opt-in after the first post, quiet hours, at most 3 per
  absence, a learned daily hour and a settings toggle.
- **Web preview build:** `flutter build web` now works (browser-storage saves, no-op notifications),
  for playtesting in a browser.
- Account save schema v2 (sound, haptics, opt-in, session hours) with a v1→v2 migration and tests.

### 5.2 Tested
`flutter analyze`: clean. `flutter test`: 61 passing. The web build ran a scripted playthrough in
headless Chromium (onboarding → Home → Create) with no console errors.
**Not verified:** iOS and Android device builds, notification delivery on a device, and audio
latency on a device.

### 5.3 Risks
- The display font gives the game its personality. Check its licence and fit with the art direction
  when final art arrives.
- Celebrations can appear over the publish result sheet when a post also levels you up. This is
  intentional for now; revisit in playtests.
- The Inter OTFs add about 2.4 MB. Subset them before release.
