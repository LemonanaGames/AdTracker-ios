import Foundation

/// Pure revenue derivations ported 1:1 from the design's `data.jsx`.
///
/// All functions operate on plain `[DayPoint]` series (oldest-first, today last),
/// so they are identical for mock and live data sources.
enum RevenueMath {

    static func addDays(_ d: Date, _ n: Int) -> Date {
        Calendar.utc.date(byAdding: .day, value: n, to: d)!
    }

    // MARK: Series slices

    /// Most recent `n` points (today included/last).
    static func lastN(_ arr: [DayPoint], _ n: Int) -> [DayPoint] {
        Array(arr.suffix(n))
    }
    static func sumN(_ arr: [DayPoint], _ n: Int) -> Double {
        lastN(arr, n).reduce(0) { $0 + $1.value }
    }
    static func valueToday(_ arr: [DayPoint]) -> Double { arr.last?.value ?? 0 }

    // MARK: Aggregation (Reports)

    struct AggregateRow: Identifiable, Hashable, Sendable {
        let id: String
        let label: String
        let value: Double
        let sort: Double
        let partial: Bool
    }

    static func aggregate(_ arr: [DayPoint], _ mode: ReportMode) -> [AggregateRow] {
        var groups: [String: (label: String, value: Double, sort: Double, partial: Bool)] = [:]
        let cal = Calendar.utc
        for d in arr {
            let comps = cal.dateComponents([.year, .month, .day], from: d.date)
            let year = comps.year!, month = comps.month!
            let key: String, label: String, sort: Double
            switch mode {
            case .weekly:
                let day = (Format.jsWeekday(d.date) + 6) % 7   // Mon = 0
                let monday = addDays(d.date, -day)
                key = ymd(monday)
                label = "Week of " + Format.dateShort(monday)
                sort = monday.timeIntervalSince1970
            case .monthly:
                key = "\(year)-\(month)"
                label = "\(Format.monthName(month - 1)) \(year)"
                sort = Double(year * 12 + month)
            case .yearly:
                key = "\(year)"
                label = "\(year)"
                sort = Double(year)
            case .daily:
                key = ymd(d.date); label = Format.date(d.date); sort = d.date.timeIntervalSince1970
            }
            var g = groups[key] ?? (label, 0, sort, false)
            g.value += d.value
            if d.partial { g.partial = true }
            groups[key] = g
        }
        return groups
            .map { AggregateRow(id: $0.key, label: $0.value.label, value: $0.value.value, sort: $0.value.sort, partial: $0.value.partial) }
            .sorted { $0.sort > $1.sort }
    }

    private static func ymd(_ d: Date) -> String {
        let c = Calendar.utc.dateComponents([.year, .month, .day], from: d)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }

    // MARK: Period revenue & deltas

    private static func monthSum(_ cmb: [DayPoint], offset: Int, today: Date) -> Double {
        let cal = Calendar.utc
        let tc = cal.dateComponents([.year, .month], from: today)
        let base = cal.date(from: DateComponents(year: tc.year, month: tc.month! + offset, day: 1))!
        let bc = cal.dateComponents([.year, .month], from: base)
        return cmb.reduce(0) { acc, d in
            let dc = cal.dateComponents([.year, .month], from: d.date)
            return (dc.year == bc.year && dc.month == bc.month) ? acc + d.value : acc
        }
    }

    static func periodRevenue(combined cmb: [DayPoint], period: Period,
                              today: Date = Catalog.mockToday) -> Double {
        let L = cmb.count - 1
        switch period {
        case .today: return cmb[L].value
        case .yesterday: return cmb[L - 1].value
        case .last7: return sumN(cmb, 7)
        case .thisMonth: return monthSum(cmb, offset: 0, today: today)
        case .lastMonth: return monthSum(cmb, offset: -1, today: today)
        }
    }

    static func periodDelta(combined cmb: [DayPoint], period: Period,
                            today: Date = Catalog.mockToday,
                            nowFraction: Double = Catalog.nowFraction) -> Double {
        let L = cmb.count - 1
        var cur: Double, prev: Double
        switch period {
        case .today:
            cur = cmb[L].value / nowFraction; prev = cmb[L - 7].value
        case .yesterday:
            cur = cmb[L - 1].value; prev = cmb[L - 8].value
        case .last7:
            cur = sumN(cmb, 7)
            prev = cmb[(L - 13)...(L - 7)].reduce(0) { $0 + $1.value }
        case .thisMonth:
            cur = monthSum(cmb, offset: 0, today: today)
            let dayOfMonth = Double(Calendar.utc.component(.day, from: today))
            prev = monthSum(cmb, offset: -1, today: today) * (dayOfMonth / 30)
        case .lastMonth:
            cur = monthSum(cmb, offset: -1, today: today)
            let p2 = monthSum(cmb, offset: -2, today: today)
            prev = p2 != 0 ? p2 : cur * 0.9
        }
        guard prev != 0 else { return 0 }
        return (cur - prev) / prev * 100
    }

    // MARK: Totals & splits

    static func totals(_ rows: [MetricValues]) -> MetricValues {
        var t = MetricValues()
        for r in rows {
            t.earnings += r.earnings; t.impressions += r.impressions
            t.clicks += r.clicks; t.requests += r.requests; t.matched += r.matched
        }
        t.ecpm = t.impressions != 0 ? t.earnings / t.impressions * 1000 : 0
        t.ctr = t.impressions != 0 ? t.clicks / t.impressions * 100 : 0
        t.matchRate = t.requests != 0 ? t.matched / t.requests * 100 : 0
        return t
    }

    /// Split a totals object across the country catalog (varying eCPM by `em`).
    static func splitByCountry(_ tot: MetricValues) -> [BreakdownRow] {
        splitBy(tot, Catalog.countries.map { ($0.id, $0.name, $0.weight, $0.em, BreakdownRow.Lead.flag($0.flag)) })
    }
    /// Split a totals object across the ad-unit catalog.
    static func splitByAdUnit(_ tot: MetricValues, subtitle: String? = nil) -> [BreakdownRow] {
        splitBy(tot, Catalog.adUnits.map { ($0.id, $0.name, $0.weight, $0.em, BreakdownRow.Lead.unit) }, subtitle: subtitle)
    }

    private static func splitBy(_ tot: MetricValues,
                                _ catalog: [(id: String, name: String, weight: Double, em: Double, lead: BreakdownRow.Lead)],
                                subtitle: String? = nil) -> [BreakdownRow] {
        let tw = catalog.reduce(0) { $0 + $1.weight }
        return catalog.map { c in
            let earnings = tot.earnings * c.weight / tw
            let ecpm = tot.ecpm * c.em
            let impressions = ecpm != 0 ? earnings / ecpm * 1000 : 0
            let clicks = impressions * (tot.ctr / 100)
            let denom = (tot.matchRate / 100) != 0 ? (tot.matchRate / 100) : 0.8
            let requests = impressions / denom
            let values = MetricValues(earnings: earnings, impressions: impressions, clicks: clicks,
                                      requests: requests, matched: impressions, ecpm: ecpm,
                                      ctr: tot.ctr, matchRate: tot.matchRate)
            return BreakdownRow(id: c.id, name: c.name, subtitle: subtitle, lead: c.lead, values: values)
        }
        .sorted { $0.values.earnings > $1.values.earnings }
    }
}
