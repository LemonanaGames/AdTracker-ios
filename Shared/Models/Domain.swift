import Foundation

// MARK: - Core reference entities

/// An ad-mediation network the user can connect (AppLovin MAX / Google AdMob).
struct AdNetwork: Identifiable, Hashable, Sendable {
    let id: String          // "applovin" | "admob"
    let name: String        // "AppLovin Max"
    let short: String       // "AppLovin"
    /// Deterministic-mock parameters (ignored by live data).
    let base: Double
    let vol: Double
    let colorHex: String
}

/// A monetized app belonging to an account.
struct MonetizedApp: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let platform: String    // "iOS" | "Android"
    let weight: Double       // revenue share weight (mock)
    let ecpm: Double
    let ctr: Double          // 0...1
    let matchRate: Double    // 0...1
    let hue: Double          // for the generated app-icon color
}

/// A country/region breakdown bucket.
struct Country: Identifiable, Hashable, Sendable {
    let id: String          // ISO-ish code, "XX" = Other
    let name: String
    let flag: String        // emoji
    let weight: Double
    let em: Double          // eCPM multiplier (mock)
}

/// An ad-unit / format breakdown bucket.
struct AdUnit: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let weight: Double
    let em: Double
}

/// A user account = a studio with one or more connected networks and apps.
struct Account: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let networkIDs: [String]
    let mult: Double         // mock revenue multiplier
    let appIDs: [String]
}

// MARK: - Series & metrics

/// A single day's revenue value for a series. `partial` marks today (still accruing).
struct DayPoint: Hashable, Sendable {
    let date: Date
    let value: Double
    let partial: Bool
}

/// The full set of derived monetization metrics for some slice (app/country/ad-unit/total).
struct MetricValues: Hashable, Sendable {
    var earnings: Double = 0
    var impressions: Double = 0
    var clicks: Double = 0
    var requests: Double = 0
    var matched: Double = 0
    var ecpm: Double = 0
    var ctr: Double = 0        // percent (0...100)
    var matchRate: Double = 0  // percent (0...100)
}

/// A ranked breakdown row (Apps / Ad Units / Countries) used by the `Breakdown` view.
struct BreakdownRow: Identifiable, Hashable, Sendable {
    enum Lead: Hashable, Sendable {
        case app(MonetizedApp)
        case network(AdNetwork)
        case flag(String)
        case unit
    }
    let id: String
    let name: String
    var subtitle: String?
    let lead: Lead
    var values: MetricValues
}

// MARK: - Periods, report modes & metrics

/// Pill-selector periods used on detail/insights screens.
enum Period: String, CaseIterable, Identifiable, Sendable {
    case today, yesterday, last7, thisMonth, lastMonth
    var id: String { rawValue }
    var label: String {
        switch self {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .last7: "Last 7 days"
        case .thisMonth: "This month"
        case .lastMonth: "Last month"
        }
    }
    /// What the delta compares against.
    var comparison: String {
        switch self {
        case .today: "same day last week"
        case .yesterday: "prev day"
        case .last7: "prev 7 days"
        case .thisMonth: "last month"
        case .lastMonth: "prior month"
        }
    }
}

/// Reports tab aggregation mode.
enum ReportMode: String, CaseIterable, Identifiable, Sendable {
    case daily, weekly, monthly, yearly
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

/// A single monetization metric — selectable in metric lists and breakdowns.
enum Metric: String, CaseIterable, Identifiable, Sendable {
    case earnings, clicks, impressions, matchRate, matched, ctr, requests, ecpm
    var id: String { rawValue }

    var label: String {
        switch self {
        case .earnings: "Earnings"
        case .clicks: "Clicks"
        case .impressions: "Impressions"
        case .matchRate: "Match Rate"
        case .matched: "Matched Requests"
        case .ctr: "Impression CTR"
        case .requests: "Ad Requests"
        case .ecpm: "Observed eCPM"
        }
    }
    var short: String {
        switch self {
        case .earnings: "Earnings"
        case .clicks: "Clicks"
        case .impressions: "Impr."
        case .matchRate: "Match"
        case .matched: "Matched"
        case .ctr: "CTR"
        case .requests: "Requests"
        case .ecpm: "eCPM"
        }
    }
    /// SF Symbol mapped from the design's custom stroke icons.
    var symbol: String {
        switch self {
        case .earnings: "dollarsign.circle"
        case .clicks: "cursorarrow"
        case .impressions: "eye"
        case .matchRate: "waveform.path.ecg"
        case .matched: "chart.bar"
        case .ctr: "chart.pie"
        case .requests: "megaphone"
        case .ecpm: "centsign.circle"
        }
    }

    func value(in m: MetricValues) -> Double {
        switch self {
        case .earnings: m.earnings
        case .clicks: m.clicks
        case .impressions: m.impressions
        case .matchRate: m.matchRate
        case .matched: m.matched
        case .ctr: m.ctr
        case .requests: m.requests
        case .ecpm: m.ecpm
        }
    }

    func formatted(_ v: Double) -> String {
        switch self {
        case .earnings, .ecpm: Format.money(v)
        case .ctr: String(format: "%.2f%%", v)
        case .matchRate: String(format: "%.0f%%", v)
        default: Format.compact(v)
        }
    }
}

/// Revenue goals per cadence.
struct Goals: Hashable, Sendable {
    var daily: Double
    var weekly: Double
    var monthly: Double
    var yearly: Double

    subscript(_ mode: ReportMode) -> Double {
        get {
            switch mode {
            case .daily: daily
            case .weekly: weekly
            case .monthly: monthly
            case .yearly: yearly
            }
        }
        set {
            switch mode {
            case .daily: daily = newValue
            case .weekly: weekly = newValue
            case .monthly: monthly = newValue
            case .yearly: yearly = newValue
            }
        }
    }
}
