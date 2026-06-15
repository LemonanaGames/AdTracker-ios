import SwiftUI

/// Headline earnings + full metric list (port of `MetricList`).
struct MetricList: View {
    @Environment(\.theme) private var t
    let totals: MetricValues
    var delta: Double? = nil
    var comparison: String? = nil

    private var rows: [Metric] { Metric.allCases.filter { $0 != .earnings } }

    var body: some View {
        Card(padding: 0) {
            VStack(spacing: 0) {
                // headline
                HStack(spacing: 10) {
                    Text(Format.money(totals.earnings))
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(t.text)
                    if let delta { DeltaChip(value: delta) }
                    if let comparison {
                        Text("vs \(comparison)").font(.system(size: 12.5)).foregroundStyle(t.ter)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

                ForEach(rows) { m in
                    Divider().overlay(t.hair)
                    HStack(spacing: 12) {
                        Image(systemName: m.symbol).font(.system(size: 17)).foregroundStyle(t.sec).frame(width: 22)
                        Text(m.label).font(.system(size: 15.5)).foregroundStyle(t.text)
                        Spacer()
                        Text(m.formatted(m.value(in: totals)))
                            .font(.system(size: 15.5, weight: .bold)).foregroundStyle(t.text)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
            }
        }
    }
}

/// Ranked breakdown section with a metric selector + share bars (port of `Breakdown`).
struct BreakdownSection: View {
    @Environment(\.theme) private var t
    let title: String
    let symbol: String
    let rows: [BreakdownRow]
    let metricOptions: [Metric]
    var onRow: ((BreakdownRow) -> Void)? = nil

    @State private var metric: Metric

    init(title: String, symbol: String, rows: [BreakdownRow],
         metricOptions: [Metric], onRow: ((BreakdownRow) -> Void)? = nil) {
        self.title = title; self.symbol = symbol; self.rows = rows
        self.metricOptions = metricOptions; self.onRow = onRow
        _metric = State(initialValue: metricOptions.first ?? .earnings)
    }

    var body: some View {
        let sorted = rows.sorted { metric.value(in: $0.values) > metric.value(in: $1.values) }
        let maxV = max(sorted.map { metric.value(in: $0.values) }.max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(t.text)
                Text(title).font(.system(size: 20, weight: .bold)).foregroundStyle(t.text)
            }
            .padding(.horizontal, 4)

            PillTabs(options: metricOptions.map { ($0, $0.short) }, selection: $metric, small: true)

            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { i, row in
                        if i > 0 { Divider().overlay(t.hair) }
                        rowView(row, share: metric.value(in: row.values) / maxV)
                    }
                }
            }
        }
        .padding(.bottom, 22)
    }

    @ViewBuilder
    private func rowView(_ row: BreakdownRow, share: Double) -> some View {
        let content = VStack(spacing: 9) {
            HStack(spacing: 12) {
                LeadView(lead: row.lead)
                VStack(alignment: .leading, spacing: 1) {
                    Text(row.name).font(.system(size: 15.5, weight: .semibold)).foregroundStyle(t.text).lineLimit(1)
                    if let sub = row.subtitle {
                        Text(sub).font(.system(size: 12.5)).foregroundStyle(t.ter)
                    }
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(metric.formatted(metric.value(in: row.values)))
                        .font(.system(size: 15.5, weight: .bold)).foregroundStyle(t.text)
                    Text("\(Int((share * 100).rounded()))%").font(.system(size: 11.5)).foregroundStyle(t.ter)
                }
                if onRow != nil {
                    Image(systemName: Sym.chevron).font(.system(size: 13, weight: .semibold)).foregroundStyle(t.ter)
                }
            }
            ShareBar(fraction: share)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)

        if let onRow {
            Button { onRow(row) } label: { content }.buttonStyle(.plain)
        } else {
            content
        }
    }
}

/// Thin gradient share/progress bar.
struct ShareBar: View {
    @Environment(\.theme) private var t
    let fraction: Double
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(t.card2)
                Capsule().fill(t.gradientH)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}
