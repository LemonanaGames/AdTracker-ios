import Foundation

/// Static reference data ported from the design's `data.jsx`.
///
/// For mock data this *is* the catalog. For live data, accounts/apps come from the
/// connected networks; countries/ad-units/metric definitions remain shared here.
enum Catalog {

    // MARK: Networks
    static let networks: [AdNetwork] = [
        AdNetwork(id: "applovin", name: "AppLovin Max", short: "AppLovin",
                  base: 4400, vol: 0.22, colorHex: "#7B5BF5"),
        AdNetwork(id: "admob", name: "Google AdMob", short: "AdMob",
                  base: 1850, vol: 0.18, colorHex: "#34A853"),
    ]
    static func network(_ id: String) -> AdNetwork { networks.first { $0.id == id }! }

    // MARK: Apps
    static let apps: [MonetizedApp] = [
        MonetizedApp(id: "tod",   name: "Truth or Dare", platform: "iOS",     weight: 34, ecpm: 16.5, ctr: 0.018, matchRate: 0.82, hue: 330),
        MonetizedApp(id: "taino", name: "Taino VPN",     platform: "Android", weight: 26, ecpm: 9.2,  ctr: 0.011, matchRate: 0.74, hue: 212),
        MonetizedApp(id: "sera",  name: "Sera",          platform: "iOS",     weight: 18, ecpm: 21.0, ctr: 0.022, matchRate: 0.88, hue: 265),
        MonetizedApp(id: "pulse", name: "Pulse Tracker", platform: "iOS",     weight: 13, ecpm: 13.0, ctr: 0.014, matchRate: 0.80, hue: 150),
        MonetizedApp(id: "lumio", name: "Lumio",         platform: "Android", weight: 9,  ecpm: 7.5,  ctr: 0.009, matchRate: 0.70, hue: 35),
    ]
    static func app(_ id: String) -> MonetizedApp { apps.first { $0.id == id }! }

    // MARK: Countries
    static let countries: [Country] = [
        Country(id: "US", name: "United States",  flag: "🇺🇸", weight: 38, em: 1.6),
        Country(id: "PH", name: "Philippines",    flag: "🇵🇭", weight: 14, em: 0.55),
        Country(id: "IN", name: "India",          flag: "🇮🇳", weight: 12, em: 0.42),
        Country(id: "BR", name: "Brazil",         flag: "🇧🇷", weight: 10, em: 0.6),
        Country(id: "GB", name: "United Kingdom", flag: "🇬🇧", weight: 9,  em: 1.5),
        Country(id: "DE", name: "Germany",        flag: "🇩🇪", weight: 7,  em: 1.4),
        Country(id: "XX", name: "Other",          flag: "🌐", weight: 10, em: 0.7),
    ]

    // MARK: Ad units
    static let adUnits: [AdUnit] = [
        AdUnit(id: "inter",    name: "Interstitial", weight: 34, em: 1.2),
        AdUnit(id: "rewarded", name: "Rewarded",     weight: 30, em: 1.55),
        AdUnit(id: "banner",   name: "Banner",       weight: 21, em: 0.35),
        AdUnit(id: "native",   name: "Native",       weight: 10, em: 0.9),
        AdUnit(id: "appopen",  name: "App Open",     weight: 5,  em: 1.05),
    ]

    // MARK: Accounts (seed/demo)
    static let accounts: [Account] = [
        Account(id: "main",   name: "Main Studio", networkIDs: ["applovin", "admob"], mult: 1.0,  appIDs: ["tod", "taino", "sera", "pulse", "lumio"]),
        Account(id: "hyper",  name: "Hyper Games", networkIDs: ["applovin"],          mult: 0.42, appIDs: ["pulse", "lumio"]),
        Account(id: "casual", name: "Casual Labs", networkIDs: ["admob"],             mult: 0.65, appIDs: ["taino", "sera"]),
    ]
    static func account(_ id: String) -> Account { accounts.first { $0.id == id }! }

    // MARK: Goals (defaults)
    static let defaultGoals = Goals(daily: 7000, weekly: 42000, monthly: 175000, yearly: 2_000_000)

    /// Frozen "now" for deterministic mock data — June 15 2026 (a Sunday), ~27% through the day.
    static let mockToday: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 6; c.day = 15
        return Calendar.utc.date(from: c)!
    }()
    static let nowFraction = 0.27
    static let historyDays = 120
}

extension Calendar {
    /// A fixed UTC Gregorian calendar so mock dates/weekdays are device-independent.
    static let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
}
