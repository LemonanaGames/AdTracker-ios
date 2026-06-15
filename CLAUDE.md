# Ad Report — iOS App (project notes for Claude)

Ad-revenue tracker for AppLovin MAX + AdMob. SwiftUI, iOS 26 / watchOS 26, Swift 6.3, MV pattern
(`@Observable`), XcodeGen. **This is a different product from the `Boker` alarm app** in the sibling folder.

## Source of truth for design
`Design/project/app/*.jsx` — the Claude Design handoff prototypes. Recreate them pixel-perfectly in SwiftUI;
match the visual output, not the prototype's internal structure.

## Architecture
- **Source-agnostic data**: all screens read `any RevenueRepository` from `AppModel`. `MockRevenueRepository`
  (deterministic, ported from `data.jsx`) drives everything today; `LiveRevenueRepository` (AdMob + AppLovin)
  plugs in later with no UI changes.
- **Math lives in `RevenueMath`** (pure, ported 1:1 from `data.jsx`) — keep mock & live identical.
- **Theme**: `Theme` token sets (Midnight/Graphite/Mist) + `ThemeStore` (`@Observable`), injected via
  `@Environment(\.theme)`. Components read the theme from the environment.
- **Navigation**: `AppModel` holds the selected tab, per-tab push paths, sheet/full-screen routes, account,
  goals, prefs. `MainTabView` wires 5 `Tab`s, each its own `NavigationStack`.

## Conventions
- iOS 26 APIs used directly (Liquid Glass `glassEffect`, `Tab(value:)`, `@Entry`) — no pre-26 fallbacks.
- Money/format via `Format.*`; never hand-roll currency strings.
- Mock "today" is frozen to **2026-06-15** (`Catalog.mockToday`) to match the design's numbers.

## Build / verify (Mac)
`brew install xcodegen && xcodegen generate && open AdReport.xcodeproj` → run **AdReport** on iOS 26 sim;
run `AdReportTests` for the data layer.

## Phases (see plan)
1 ✅ scaffold + design system + all screens on mock data · 2 persistence/credentials · 3 live AdMob+AppLovin ·
4 widgets+Control · 5 Apple Watch · 6 notifications+Live Activity · 7 AI insights+App Intents · 8 paywall · 9 polish/tests.
