# Influencer Simulator: Zero to Fame — project notes for Claude

An original iOS-first Flutter idle life sim. **The source of truth is `docs/GDD_MASTER_v2.md`.** Status
and next steps are in `docs/IMPLEMENTATION_PLAN.md`; update it after every milestone using the
report format from GDD Part J (Implemented / Tested / Not implemented / Credentials / Risks / Next).

This repo used to hold a SwiftUI ad-revenue tracker ("AdReport"). It was removed when the project
restarted. Don't resurrect it.

## Rules

- Deliver milestones **in order (M0→M7), one at a time**. M0+M1 are done; M2 is next.
- **Never claim an SDK is installed or configured unless it's verified in the project.** There's no
  Firebase, Singular, AdMob or RevenueCat yet. Don't invent keys or product IDs; ask for them.
- No real platform names or logos (TikTok/YouTube/Instagram) in the UI or assets. Networks are
  Loop / TubeCast / Vibe.
- Placeholders must stay labelled as placeholders (`app/assets/asset_manifest.json`).

## Architecture

- `app/lib/domain` + `app/lib/core` are **pure Dart** (a test enforces this). All game rules live in
  `GameEngine` (commands return `CommandResult`, and on error the state is the unchanged input).
  The Riverpod `GameController` only forwards commands, persists, logs telemetry and ticks the clock.
- Integers only: money in cents (`*Minor`), rates in ‰ / bps, energy and stress in milli-points.
  Use `Format.*` for display and never hand-roll strings.
- Determinism: `Seed.of([...])` + `Rng` (32-bit). Post stats are a pure function of elapsed sim
  time, so crediting is idempotent. Keep it that way.
- One `Requirement` DSL drives every gate and every "how to unlock" UI.
- Content lives in `game_content/*.json` (bundled via `../game_content/` asset paths) and is
  checked by `CatalogValidator`. New content files go into `GameCatalog.files` **and** `pubspec.yaml`.
- UI strings go in ARB (`app/lib/app/l10n/app_en.arb`), content strings in
  `game_content/localization/en.json`. Use directional insets (RTL-ready).
- Persistence: Drift + `SaveCodec` versioned envelope. Schema change means bumping the version and
  adding a migration plus a test.

## Commands (run in `app/`)

```
flutter analyze && flutter test
dart run tool/validate_content.dart
dart run tool/simulate_lives.dart 45 180
dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n   # after DB/ARB changes
SHOT_DIR=/tmp/shots flutter test tool/screenshots_test.dart                    # render screens to PNG
flutter build web --release --no-web-resources-cdn                             # browser preview build
python3 ../tools/sfx_synth/make_sfx.py assets/sfx                              # regenerate sound effects
```

## Feel layer

- Sounds and haptics go through `GameController.feedback(...)`, which honours settings. Map events to
  juice in one place: `reactToEvent` (`features/celebrations/celebration_overlay.dart`).
- Every animation must have a static Reduce Motion path. Continuous loops must also check
  `ambientMotion(...)`, and widget tests override `ambientMotionProvider` to false so that
  `pumpAndSettle` settles.
- Reminders: change rules in `NotificationPlanner` (pure, tested), not in the UI. See `docs/notifications.md`.

Formatting uses a 120-column page width (generated files are excluded).
