import SwiftUI

/// App detail (pushed) — full per-period metrics + ad-unit breakdown (port of `AppDetail`).
struct AppDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    let appID: String
    @State private var period: Period = .today

    var body: some View {
        let app = Catalog.app(appID)
        let rows = model.repository.appMetrics(account: model.accountID, period: period)
        let row = rows.first { $0.app.id == appID } ?? rows[0]
        let tot = row.values
        let baseDelta = RevenueMath.periodDelta(combined: model.repository.combinedSeries(account: model.accountID), period: period)
        let delta = baseDelta * (0.6 + Double(Int(app.hue) % 50) / 100)
        let units = RevenueMath.splitByAdUnit(tot, subtitle: app.name)

        PushScaffold(trailing: { IconPill(symbol: Sym.share) {} }) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 13) {
                    AppIconTile(app: app, size: 52)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(app.name).font(.system(size: 26, weight: .heavy)).foregroundStyle(t.text)
                        Text("\(app.platform) · com.demo.\(app.id)").font(.system(size: 13.5)).foregroundStyle(t.sec)
                    }
                }

                PillTabs(options: Period.allCases.map { ($0, $0.label) }, selection: $period)

                MetricList(totals: tot, delta: delta, comparison: period.comparison)

                BreakdownSection(title: "Ad Units", symbol: Sym.layers, rows: units,
                                 metricOptions: [.earnings, .impressions, .clicks, .ecpm])
            }
            .padding(.horizontal, 16)
        }
    }
}
