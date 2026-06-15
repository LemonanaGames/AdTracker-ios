import SwiftUI

/// Insights tab — trends, network split, highlights, weekday pattern, and
/// App/Ad-Unit/Country breakdowns (port of `Analytics`).
struct InsightsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    @State private var bp: Period = .last7

    var body: some View {
        TabScaffold(title: "Insights") {
            if !model.hasAccounts { ConnectEmptyView() }
            else if !model.accountHasData { AccountEmptyView() }
            else { content() }
        }
    }

    /// Sum of `len` days ending `endOffset` days before the latest point (bounds-safe).
    private func windowSum(_ arr: [DayPoint], endOffset: Int, len: Int) -> Double {
        let end = arr.count - endOffset
        let start = max(0, end - len)
        guard end > start, end <= arr.count else { return 0 }
        return arr[start..<end].reduce(0) { $0 + $1.value }
    }

    @ViewBuilder private func content() -> some View {
        let acc = model.account
        let repo = model.repository
        let combined = repo.combinedSeries(account: acc.id)

        let this30 = RevenueMath.sumN(combined, 30)
        let prev30 = windowSum(combined, endOffset: 30, len: 30)
        let d30 = prev30 == 0 ? 0 : (this30 - prev30) / prev30 * 100
        let this7 = RevenueMath.sumN(combined, 7)
        let prev7 = windowSum(combined, endOffset: 7, len: 7)
        let d7 = prev7 == 0 ? 0 : (this7 - prev7) / prev7 * 100

        let full = Array(combined.dropLast())
        let best = full.max { $0.value < $1.value } ?? combined.last
            ?? DayPoint(date: Date(), value: 0, partial: false)
        let avg = this30 / 30
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        let projMonth = avg * Double(daysInMonth)

        let split = acc.networkIDs.map { (net: Catalog.network($0), val: RevenueMath.sumN(repo.series(account: acc.id, network: $0), 30)) }
        let splitTotal = max(split.reduce(0) { $0 + $1.val }, 1)
        let topNet = split.max { $0.val < $1.val }?.net

        VStack(alignment: .leading, spacing: 12) {
            trendRow(this7: this7, d7: d7, this30: this30, d30: d30)
            SmartInsightsView()
            networkSplit(split, total: splitTotal)
            highlights(best: best, avg: avg, topNet: topNet, projMonth: projMonth)
            weekday(full)
            breakdowns(acc: acc)
        }
        .padding(.horizontal, 16)
    }

    private func trendRow(this7: Double, d7: Double, this30: Double, d30: Double) -> some View {
        HStack(spacing: 12) {
            trendCard("LAST 7 DAYS", Format.moneyK(this7), d7)
            trendCard("LAST 30 DAYS", Format.moneyK(this30), d30)
        }
    }
    private func trendCard(_ label: String, _ value: String, _ delta: Double) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text(label).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(t.sec)
                Text(value).font(.system(size: 22, weight: .heavy)).foregroundStyle(t.text)
                DeltaChip(value: delta, sub: "vs prev")
            }
        }
    }

    private func networkSplit(_ split: [(net: AdNetwork, val: Double)], total: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Network split · 30d")
            Card {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            ForEach(Array(split.enumerated()), id: \.offset) { i, s in
                                Rectangle()
                                    .fill(i == 0 ? t.accent : (t.dark ? Color(hex: "#5b6df5") : Color(hex: "#34A853")))
                                    .frame(width: s.val / total * geo.size.width)
                            }
                        }
                    }
                    .frame(height: 14).clipShape(Capsule()).padding(.bottom, 16)

                    ForEach(Array(split.enumerated()), id: \.offset) { i, s in
                        HStack(spacing: 10) {
                            NetBadge(network: s.net, size: 30)
                            Text(s.net.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(t.text)
                            Spacer()
                            Text("\(Int((s.val / total * 100).rounded()))%").font(.system(size: 13)).foregroundStyle(t.sec)
                            Text(Format.moneyK(s.val)).font(.system(size: 15, weight: .bold)).foregroundStyle(t.text)
                        }
                        .padding(.top, i > 0 ? 12 : 0)
                    }
                }
            }
        }
    }

    private func highlights(best: DayPoint, avg: Double, topNet: AdNetwork?, projMonth: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Highlights")
            HStack(spacing: 12) {
                statCard("Best day", Format.moneyK(best.value), Format.dateShort(best.date))
                statCard("Avg / day", Format.moneyK(avg), "last 30 days")
            }
            HStack(spacing: 12) {
                statCard("Top network", topNet?.short ?? "—", "by revenue")
                statCard("Proj. month", Format.moneyK(projMonth), "at current pace")
            }
        }
    }
    private func statCard(_ label: String, _ value: String, _ sub: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(t.sec)
                Text(value).font(.system(size: 21, weight: .heavy)).foregroundStyle(t.text).padding(.top, 4)
                Text(sub).font(.system(size: 12)).foregroundStyle(t.ter)
            }
        }
    }

    private func weekday(_ full: [DayPoint]) -> some View {
        var sums = [Double](repeating: 0, count: 7)
        var counts = [Double](repeating: 0, count: 7)
        for d in full { let k = Format.jsWeekday(d.date); sums[k] += d.value; counts[k] += 1 }
        let avgs = (0..<7).map { sums[$0] / max(counts[$0], 1) }
        let order = [1, 2, 3, 4, 5, 6, 0]
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "By day of week")
            Card {
                VStack(spacing: 12) {
                    BarChart(data: order.map { BarDatum(value: avgs[$0]) },
                             labels: order.map { Format.dow[$0] }, height: 120)
                    Text("Average revenue per weekday · last \(full.count) days")
                        .font(.system(size: 12.5)).foregroundStyle(t.ter)
                }
            }
        }
        .padding(.bottom, 2)
    }

    private func breakdowns(acc: Account) -> some View {
        let appRows = model.repository.appMetrics(account: acc.id, period: bp)
        let tot = RevenueMath.totals(appRows.map(\.values))
        let appItems = appRows.map {
            BreakdownRow(id: $0.app.id, name: $0.app.name,
                         subtitle: "\($0.app.platform) · eCPM \(Format.money($0.values.ecpm))",
                         lead: .app($0.app), values: $0.values)
        }
        let metrics: [Metric] = [.earnings, .clicks, .impressions, .requests, .ecpm]
        return VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Breakdown")
            PillTabs(options: Period.allCases.map { ($0, $0.label) }, selection: $bp)
            BreakdownSection(title: "Apps", symbol: Sym.apps, rows: appItems, metricOptions: metrics) { row in
                model.push(.app(row.id))
            }
            BreakdownSection(title: "Ad Units", symbol: Sym.layers, rows: RevenueMath.splitByAdUnit(tot), metricOptions: metrics)
            BreakdownSection(title: "Countries", symbol: Sym.globe, rows: RevenueMath.splitByCountry(tot), metricOptions: metrics)
        }
        .padding(.top, 8)
    }
}
