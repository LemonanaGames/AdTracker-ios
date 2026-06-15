import SwiftUI

/// Reports tab — daily / weekly / monthly / yearly breakdown with proportional bars
/// (port of `Reports`).
struct ReportsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    @State private var mode: ReportMode = .daily

    var body: some View {
        let combined = model.repository.combinedSeries(account: model.accountID)
        let (rows, total, label) = data(combined)
        let maxVal = max(rows.map(\.value).max() ?? 1, 1)
        let sparkData = (mode == .daily
                         ? RevenueMath.lastN(combined, 30).map(\.value)
                         : rows.reversed().map(\.value))

        TabScaffold(title: "Reports") {
            VStack(alignment: .leading, spacing: 18) {
                Segmented(options: ReportMode.allCases.map { ($0, $0.label) }, selection: $mode)

                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(t.sec)
                            Text(Format.money(total, dp: 0)).font(.system(size: 28, weight: .heavy)).foregroundStyle(t.text)
                        }
                        Spacer()
                        Sparkline(data: sparkData, height: 40).frame(width: 100)
                    }
                }

                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
                            if i > 0 { Divider().overlay(t.hair) }
                            VStack(spacing: 8) {
                                HStack {
                                    HStack(spacing: 8) {
                                        Text(r.label).font(.system(size: 15, weight: .medium)).foregroundStyle(t.text)
                                        if r.partial { liveTag }
                                    }
                                    Spacer()
                                    Text(Format.money(r.value, dp: 0)).font(.system(size: 15, weight: .bold)).foregroundStyle(t.text)
                                }
                                ShareBar(fraction: r.value / maxVal, height: 6)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 13)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var liveTag: some View {
        Text("· live").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
    }

    private func data(_ combined: [DayPoint]) -> (rows: [RevenueMath.AggregateRow], total: Double, label: String) {
        if mode == .daily {
            let rows = combined.reversed().prefix(30).map {
                RevenueMath.AggregateRow(id: "\($0.date.timeIntervalSince1970)", label: Format.date($0.date),
                                         value: $0.value, sort: $0.date.timeIntervalSince1970, partial: $0.partial)
            }
            return (Array(rows), RevenueMath.sumN(combined, 30), "Last 30 days")
        }
        let agg = RevenueMath.aggregate(combined, mode)
        let count = mode == .weekly ? 16 : mode == .monthly ? 12 : 4
        let rows = Array(agg.prefix(count))
        let label = mode == .weekly ? "Last 16 weeks" : mode == .monthly ? "Last 12 months" : "All time"
        return (rows, rows.reduce(0) { $0 + $1.value }, label)
    }
}
