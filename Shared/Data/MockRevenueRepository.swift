import Foundation

/// Deterministic mock revenue, ported from the design's `data.jsx` (seeded mulberry32).
/// Used for previews, demo accounts, and any not-yet-connected account.
struct MockRevenueRepository: RevenueRepository {

    let accounts: [Account]
    private let seriesByKey: [String: [DayPoint]]   // "accountID:networkID"

    init(accounts: [Account] = Catalog.accounts) {
        self.accounts = accounts
        var map: [String: [DayPoint]] = [:]
        for acc in accounts {
            for nid in acc.networkIDs {
                map["\(acc.id):\(nid)"] = Self.buildSeries(accountID: acc.id, networkID: nid, mult: acc.mult)
            }
        }
        self.seriesByKey = map
    }

    func series(account: String, network: String) -> [DayPoint] {
        seriesByKey["\(account):\(network)"] ?? []
    }

    func combinedSeries(account: String) -> [DayPoint] {
        let acc = self.account(account)
        let nets = acc.networkIDs
        guard let first = nets.first, let count = seriesByKey["\(account):\(first)"]?.count else { return [] }
        return (0..<count).map { i in
            var v = 0.0; var date = Catalog.mockToday; var partial = false
            for nid in nets {
                if let s = seriesByKey["\(account):\(nid)"]?[i] {
                    v += s.value; date = s.date; partial = s.partial
                }
            }
            return DayPoint(date: date, value: v, partial: partial)
        }
    }

    func appMetrics(account: String, period: Period) -> [AppMetric] {
        let acc = self.account(account)
        let apps = acc.appIDs.map { Catalog.app($0) }
        let rev = RevenueMath.periodRevenue(combined: combinedSeries(account: account), period: period)
        let tw = apps.reduce(0) { $0 + $1.weight }
        return apps.map { a in
            let earnings = rev * a.weight / tw
            let impressions = earnings / a.ecpm * 1000
            let clicks = impressions * a.ctr
            let requests = impressions / a.matchRate
            let values = MetricValues(earnings: earnings, impressions: impressions, clicks: clicks,
                                      requests: requests, matched: impressions, ecpm: a.ecpm,
                                      ctr: a.ctr * 100, matchRate: a.matchRate * 100)
            return AppMetric(app: a, values: values)
        }
        .sorted { $0.values.earnings > $1.values.earnings }
    }

    // MARK: - Deterministic series generation

    private static func buildSeries(accountID: String, networkID: String, mult: Double) -> [DayPoint] {
        let net = Catalog.network(networkID)
        var rng = SeededRNG(seed: hashStr("\(accountID):\(networkID)"))
        let H = Catalog.historyDays
        var out: [DayPoint] = []
        out.reserveCapacity(H)
        for i in stride(from: H - 1, through: 0, by: -1) {
            let date = RevenueMath.addDays(Catalog.mockToday, -i)
            let dow = Format.jsWeekday(date)
            let wk = (dow == 0 || dow == 6) ? 0.88 : 1.0 + (dow == 3 ? 0.06 : 0)
            let trend = 1 + Double(H - i) / Double(H) * 0.35
            let wave = 1 + sin(Double(H - i) / 9) * 0.07
            let noise = 1 + (rng.next() - 0.5) * net.vol * 2
            var value = net.base * mult * wk * trend * wave * noise
            let partial = (i == 0)
            if partial { value *= Catalog.nowFraction }
            out.append(DayPoint(date: date, value: max(0, value), partial: partial))
        }
        return out
    }

    /// Stable hue (0–359) for a string — used to color live app icons deterministically.
    static func stableHue(_ s: String) -> Int { Int(hashStr(s) % 360) }

    /// xmur3-style string hash → 32-bit seed (matches `hashStr` in data.jsx).
    static func hashStr(_ s: String) -> UInt32 {
        var h: UInt32 = 1779033703 ^ UInt32(truncatingIfNeeded: s.utf16.count)
        for ch in s.utf16 {
            h = (h ^ UInt32(ch)) &* 3432918353
            h = (h << 13) | (h >> 19)
        }
        return h
    }
}

/// mulberry32 PRNG (matches `mulberry32` in data.jsx) — identical sequence given the same seed.
struct SeededRNG {
    private var a: UInt32
    init(seed: UInt32) { self.a = seed }
    mutating func next() -> Double {
        a = a &+ 0x6D2B_79F5
        var t = (a ^ (a >> 15)) &* (a | 1)
        t = (t &+ ((t ^ (t >> 7)) &* (t | 61))) ^ t
        return Double(t ^ (t >> 14)) / 4_294_967_296
    }
}
