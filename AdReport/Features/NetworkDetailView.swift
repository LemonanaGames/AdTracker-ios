import SwiftUI

/// Network detail (pushed) — period metrics, 7-day chart, daily list (port of `NetworkDetail`).
struct NetworkDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    let networkID: String
    @State private var period: Period = .today

    var body: some View {
        let acc = model.account
        let net = Catalog.network(networkID)
        let s = model.repository.series(account: acc.id, network: networkID)
        let last7 = RevenueMath.lastN(s, 7)
        let accountWeek = RevenueMath.sumN(model.repository.combinedSeries(account: acc.id), 7)
        let factor = accountWeek == 0 ? 0 : RevenueMath.sumN(s, 7) / accountWeek
        let accTot = model.repository.totals(account: acc.id, period: period)
        let tot = MetricValues(earnings: accTot.earnings * factor, impressions: accTot.impressions * factor,
                               clicks: accTot.clicks * factor, requests: accTot.requests * factor,
                               matched: accTot.matched * factor, ecpm: accTot.ecpm,
                               ctr: accTot.ctr, matchRate: accTot.matchRate)
        let delta = RevenueMath.periodDelta(combined: model.repository.combinedSeries(account: acc.id), period: period)
        let days = Array(s.reversed().prefix(14))

        let shareText = "\(net.name) — \(Format.money(tot.earnings)) (\(period.label))"
        PushScaffold(trailing: {
            ShareLink(item: shareText) {
                Image(systemName: Sym.share).font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(t.accent).frame(width: 38, height: 38).background(t.card, in: Circle())
            }
        }) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    NetBadge(network: net, size: 44)
                    Text(net.name).font(.system(size: 28, weight: .heavy)).foregroundStyle(t.text)
                }

                PillTabs(options: Period.allCases.map { ($0, $0.label) }, selection: $period)

                MetricList(totals: tot, delta: delta, comparison: period.comparison)

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("LAST 7 DAYS").font(.system(size: 12.5, weight: .bold)).foregroundStyle(t.sec).tracking(0.5)
                        BarChart(data: last7.map { BarDatum(value: $0.value, dim: $0.partial) },
                                 labels: last7.map { String(Format.dow[Format.jsWeekday($0.date)].prefix(1)) },
                                 height: 140)
                    }
                }

                SectionTitle(title: "Daily")
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                            if i > 0 { Divider().overlay(t.hair) }
                            HStack(spacing: 8) {
                                Text(Format.date(d.date)).font(.system(size: 15.5, weight: .medium)).foregroundStyle(t.text)
                                if d.partial {
                                    Text("· live").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
                                }
                                Spacer()
                                Text(Format.money(d.value)).font(.system(size: 15.5, weight: .bold)).foregroundStyle(t.text)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
