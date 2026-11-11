# ADR-001 — Flutter, iOS first

- **Status:** accepted (2026-11-11)
- **Context:** Influencer Simulator is a UI-, data- and 2D-asset-heavy idle/narrative life sim. It needs
  an iOS launch first and a cheap Android port later. There are no 3D scenes or physics.

## Decision

Build the client in **Flutter (stable) / Dart**, iOS first, with an Android-compatible
architecture.

- One codebase for UI, simulation and persistence. The Android port becomes a store and integration
  task, not a rewrite.
- Impeller renders on iOS. 60 fps is the target, to be measured on real hardware (M6).
- Native bridges (Swift) are allowed for edge cases: PHPicker, share sheet, StoreKit specifics.
- The **domain layer is pure Dart** (no Flutter or SDK imports, enforced by `test/architecture_test.dart`).
  It stays portable and fast to test, and could back a different renderer later.

## Alternatives considered

- **SwiftUI first:** an excellent native UI, but its UI code can't be reused for Android, and it would
  mean writing the UI twice.
- **Kotlin:** Android-native, so it doesn't fit an iOS-first launch.
- **Flame / Unity:** only worth it if interactive 2D scenes or physics come to dominate. That would
  need a new ADR before switching.

## Consequences

- State: Riverpod; navigation: go_router; local DB: Drift/SQLite (all chosen in GDD A1.8).
- Store, ads and analytics SDKs are integrated through Flutter plugins behind interfaces. They are
  added only in M4/M5, once credentials exist.
- This repository previously held a SwiftUI app (AdReport / ad-revenue tracker). It was removed on
  this branch when the project restarted, and its history stays in Git.
