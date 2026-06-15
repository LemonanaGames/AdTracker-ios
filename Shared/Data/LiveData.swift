import Foundation

/// A normalized row returned by the network clients, before aggregation.
/// Both AdMob and AppLovin responses map into this shape.
struct LiveReportRow: Sendable, Hashable, Codable {
    var date: Date
    var networkID: String      // "admob" | "applovin"
    var appID: String
    var appName: String
    var platform: String       // "iOS" | "Android" | ""
    var country: String        // ISO code, "" if unknown
    var adFormat: String       // ad-unit format label
    var earnings: Double
    var impressions: Double
    var clicks: Double
    var requests: Double
    var matched: Double
}

extension Period {
    /// Inclusive day interval for the period relative to `now` (live data uses the real clock).
    func interval(now: Date = Date(), calendar: Calendar = .current) -> (start: Date, end: Date) {
        let startOfToday = calendar.startOfDay(for: now)
        switch self {
        case .today:
            return (startOfToday, now)
        case .yesterday:
            let y = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            return (y, startOfToday)
        case .last7:
            return (calendar.date(byAdding: .day, value: -6, to: startOfToday)!, now)
        case .thisMonth:
            let comps = calendar.dateComponents([.year, .month], from: now)
            return (calendar.date(from: comps)!, now)
        case .lastMonth:
            let comps = calendar.dateComponents([.year, .month], from: now)
            let firstThis = calendar.date(from: comps)!
            let firstLast = calendar.date(byAdding: .month, value: -1, to: firstThis)!
            return (firstLast, firstThis)
        }
    }
}

/// The app's runtime repository. Sample accounts are served by the deterministic mock;
/// real accounts are served from the synced live cache, or empty until they sync.
/// Pure value type (Sendable): `AppModel` rebuilds it from the App-Group cache after each sync.
struct LiveRevenueRepository: RevenueRepository {
    let accounts: [Account]
    let mock: MockRevenueRepository
    let cache: [String: [LiveReportRow]]      // accountID → rows

    private func isSample(_ id: String) -> Bool { accounts.first { $0.id == id }?.isSample == true }

    func series(account: String, network: String) -> [DayPoint] {
        if isSample(account) { return mock.series(account: account, network: network) }
        guard let rows = cache[account] else { return [] }
        return Self.dailySeries(rows.filter { $0.networkID == network })
    }

    func combinedSeries(account: String) -> [DayPoint] {
        if isSample(account) { return mock.combinedSeries(account: account) }
        guard let rows = cache[account] else { return [] }
        return Self.dailySeries(rows)
    }

    func appMetrics(account: String, period: Period) -> [AppMetric] {
        if isSample(account) { return mock.appMetrics(account: account, period: period) }
        guard let rows = cache[account] else { return [] }
        let range = period.interval()
        let cal = Calendar.current
        let inRange = rows.filter { $0.date >= range.start && $0.date <= range.end }
        let grouped = Dictionary(grouping: inRange, by: { $0.appID })
        return grouped.map { (appID, rows) -> AppMetric in
            var v = MetricValues()
            for r in rows {
                v.earnings += r.earnings; v.impressions += r.impressions
                v.clicks += r.clicks; v.requests += r.requests; v.matched += r.matched
            }
            v.ecpm = v.impressions != 0 ? v.earnings / v.impressions * 1000 : 0
            v.ctr = v.impressions != 0 ? v.clicks / v.impressions * 100 : 0
            v.matchRate = v.requests != 0 ? v.matched / v.requests * 100 : 0
            let name = rows.first?.appName ?? appID
            let platform = rows.first?.platform ?? ""
            let hue = Double(MockRevenueRepository.stableHue(name))
            let app = MonetizedApp(id: appID, name: name, platform: platform, weight: v.earnings,
                                   ecpm: v.ecpm, ctr: v.ctr / 100, matchRate: v.matchRate / 100, hue: hue)
            _ = cal
            return AppMetric(app: app, values: v)
        }
        .sorted { $0.values.earnings > $1.values.earnings }
    }

    /// Collapse rows into one ascending daily series (today flagged partial).
    private static func dailySeries(_ rows: [LiveReportRow]) -> [DayPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let byDay = Dictionary(grouping: rows) { cal.startOfDay(for: $0.date) }
        return byDay.keys.sorted().map { day in
            DayPoint(date: day, value: byDay[day]!.reduce(0) { $0 + $1.earnings }, partial: day == today)
        }
    }
}
