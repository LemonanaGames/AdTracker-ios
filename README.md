# Influencer Simulator: Zero to Fame

An original, iOS-first **Flutter** idle life simulator. You grow from an unknown creator with a cheap
phone to a multi-network celebrity on three fictional networks: **Loop** (short videos),
**TubeCast** (long videos) and **Vibe** (photos/lifestyle). Along the way you make choices that
decide what kind of famous you become.

> Working title; legal/ASO clearance pending. The networks are original inventions, with no real
> platform names, logos or APIs.

- **Product spec (source of truth):** [`docs/GDD_MASTER_v2.md`](docs/GDD_MASTER_v2.md)
- **Plan, status, milestone report:** [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md)
- **Current milestone:** M0 + M1 (playable core) ✅. Next up: M2 (multi-network + sponsors).

## Repository layout

```
app/                 Flutter app (iOS + Android runners)
  lib/core/          clock, deterministic RNG, telemetry interface, feature flags   (pure Dart)
  lib/domain/        models, game engine, post simulation, requirements, save codec  (pure Dart)
  lib/data/          Drift/SQLite repository, asset/catalog loading
  lib/app/           bootstrap, providers, controller, router, theme, l10n
  lib/features/      onboarding, home, create, social, deals, life, stories
  lib/ui/            shared widgets (cards, counters, charts, requirement checklists)
  test/              domain, save, content, architecture and widget tests
  tool/              validate_content, simulate_lives, screenshots
game_content/        versioned JSON content: balance, narrative, deals, localization, schemas
docs/                GDD, implementation plan, ADRs, balance, analytics, privacy, QA
tools/               READMEs for the dev tooling
```

## Run it (Mac)

Requirements: Flutter 3.47.x stable and Xcode with an iOS simulator.

```sh
cd app
flutter pub get
flutter run            # pick an iOS simulator
```

## Checks

```sh
cd app
flutter analyze
flutter test
dart run tool/validate_content.dart          # content cross-reference check
dart run tool/simulate_lives.dart 45 180     # balance report (lives, real minutes)
```

After changing Drift tables or ARB strings, regenerate:
`dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n`.

## Tuning the game

All balance numbers, topics, gear, jobs, goals, acts and story events are JSON files in
`game_content/`, so editing them needs no widget-code changes. Run the validator and the simulator
after each edit, and record the results in `docs/economy_balance.md`.

## Not in this build

There are no ads, purchases, Firebase, analytics upload or cloud sync yet. Everything stays on the
device. See the "Not implemented yet" list in the implementation plan.
