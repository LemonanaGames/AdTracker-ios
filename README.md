# Ad Report — ad-revenue tracker

iOS app (iPhone + Apple Watch + Widgets + Live Activities) showing app/game developers their
**ad revenue** from **AppLovin MAX** and **Google AdMob** — daily/weekly/monthly/yearly reports,
analytics, multi-account, goals.

Implemented from the Claude Design handoff in [`Design/`](Design/) (read `Design/README.md` and the
`Design/project/app/*.jsx` prototypes — they are the pixel-perfect reference).

## Stack
SwiftUI · iOS 26 / watchOS 26 · Swift 6.3 · MV pattern (`@Observable`) · XcodeGen.

## Build (Mac + Xcode 26)
```sh
brew install xcodegen
cd AdReport
xcodegen generate
open AdReport.xcodeproj
```
Run the **AdReport** scheme on an iOS 26 simulator.

## Structure
- `Shared/` — domain models, data layer, theme, UI components (shared with future widget/watch targets)
  - `Models/` — `Domain.swift`, `NotificationPrefs.swift`
  - `Data/` — `Catalog`, `Formatting`, `RevenueMath`, `RevenueRepository` (+ `MockRevenueRepository`)
  - `Theme/` — `Theme` (3 directions), `ThemeStore`, `Color+Hex`, `Symbols`
  - `UI/` — `Card`, `Charts`, `RingView`, `Controls`, `Badges`, `MetricViews`, `SettingsRows`, `DevicePreviews`
- `AdReport/App/` — `AdReportApp`, `MainTabView`, `AppModel`, `Scaffold`
- `AdReport/Features/` — every screen (Dashboard, Reports, Goals, Insights, Settings, Network/App detail, sheets…)
- `AdReportTests/` — Swift Testing suite for the data/derivation layer

## Status — all phases implemented
1. ✅ Scaffold + design system + all screens (mock data, 3 themes, Liquid Glass)
2. ✅ SwiftData persistence (App Group) + Keychain credentials
3. ✅ Live AdMob (OAuth) + AppLovin clients, cache-backed `LiveRevenueRepository`, background sync
4. ✅ Home/Lock widgets (Gauge) + Control Center control
5. ✅ Apple Watch app + complications (own scheme)
6. ✅ Local notifications + ActivityKit Live Activity
7. ✅ On-device AI insights (Foundation Models, gated, rule-based fallback) + Siri/Spotlight App Intents
8. ✅ RevenueCat paywall + Pro gating (demo unlock until configured)
9. ✅ Data-layer tests + docs
- ✅ First-run onboarding (welcome → connect) + connect-first empty states
- ✅ GitHub Actions CI — build + Swift Testing on a macOS runner (`.github/workflows/ios.yml`, needs an Xcode 26 image)

**Connect-first:** first launch is empty with a "Connect a network" prompt (plus a "Load sample data"
button for a quick tour). Real data comes from the **AppLovin MAX** Reporting API (paste a Report Key —
works immediately) and **Google AdMob** API (Sign in with Google — needs a one-time OAuth Client ID, see
[`SETUP.md`](SETUP.md)). Sample accounts use deterministic mock data; real accounts show live data or an
empty/loading state until synced.

Data is source-agnostic behind `RevenueRepository`; `LiveRevenueRepository` serves sample→mock,
connected→live cache, otherwise empty — no UI changes needed.
