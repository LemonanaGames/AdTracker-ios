#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

/// Today's-revenue Live Activity — Lock Screen + Dynamic Island.
struct RevenueLiveActivity: Widget {
    private let t = Theme.midnight

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RevenueActivityAttributes.self) { context in
            // Lock Screen / banner
            HStack(spacing: 14) {
                Gauge(value: min(1, context.state.goalPct)) { } currentValueLabel: {
                    Text("\(Int(context.state.goalPct * 100))")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(t.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY · \(context.attributes.accountName)")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(t.sec).lineLimit(1)
                    Text(Format.money(context.state.today, dp: 0))
                        .font(.system(size: 24, weight: .heavy)).foregroundStyle(t.text)
                }
                Spacer()
                Text("▲\(Int(abs(context.state.paceDelta)))%")
                    .font(.system(size: 14, weight: .bold)).foregroundStyle(t.pos)
            }
            .padding(16)
            .activityBackgroundTint(t.bg)
            .activitySystemActionForegroundColor(t.accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Today", systemImage: "chart.bar.fill").font(.system(size: 13, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("▲\(Int(abs(context.state.paceDelta)))%").foregroundStyle(.green).font(.system(size: 13, weight: .bold))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(Format.money(context.state.today, dp: 0)).font(.system(size: 22, weight: .heavy))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Gauge(value: min(1, context.state.goalPct)) {
                        Text("\(Int(context.state.goalPct * 100))% of daily goal")
                    }
                    .tint(t.accent)
                }
            } compactLeading: {
                Image(systemName: "chart.bar.fill").foregroundStyle(t.accent)
            } compactTrailing: {
                Text(Format.moneyK(context.state.today))
            } minimal: {
                Image(systemName: "chart.bar.fill").foregroundStyle(t.accent)
            }
        }
    }
}
#endif
