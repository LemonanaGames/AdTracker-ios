import WidgetKit
import SwiftUI

struct WatchEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct WatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchEntry {
        WatchEntry(date: Date(), data: WidgetData.make(repo: MockRevenueRepository(), account: "main", goals: Catalog.defaultGoals))
    }
    func getSnapshot(in context: Context, completion: @escaping (WatchEntry) -> Void) {
        Task { @MainActor in completion(WatchEntry(date: Date(), data: WidgetData.forAccount(nil).data)) }
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
        Task { @MainActor in
            let entry = WatchEntry(date: Date(), data: WidgetData.forAccount(nil).data)
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
        }
    }
}

struct WatchComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: min(1, entry.data.goalPct)) { } currentValueLabel: {
                Text(Format.moneyK(entry.data.today)).font(.system(size: 11, weight: .bold)).minimumScaleFactor(0.5)
            }
            .gaugeStyle(.accessoryCircular)
            .containerBackground(.clear, for: .widget)
        case .accessoryInline:
            Text("Today \(Format.money(entry.data.today, dp: 0))")
                .containerBackground(.clear, for: .widget)
        case .accessoryCorner:
            Text(Format.moneyK(entry.data.today))
                .widgetCurvesContent()
                .widgetLabel { Text("\(Int(entry.data.goalPct * 100))% of goal") }
                .containerBackground(.clear, for: .widget)
        default: // accessoryRectangular
            HStack(spacing: 8) {
                Gauge(value: min(1, entry.data.goalPct)) { } currentValueLabel: {
                    Text("\(Int(entry.data.goalPct * 100))")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                VStack(alignment: .leading, spacing: 1) {
                    Text("TODAY").font(.system(size: 11, weight: .semibold))
                    Text(Format.money(entry.data.today, dp: 0)).font(.system(size: 16, weight: .heavy))
                }
                Spacer(minLength: 0)
            }
            .containerBackground(.clear, for: .widget)
        }
    }
}

struct WatchComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AdReportWatchComplication", provider: WatchProvider()) { entry in
            WatchComplicationView(entry: entry)
        }
        .configurationDisplayName("Revenue")
        .description("Today's revenue & goal.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

@main
struct AdReportWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WatchComplication()
    }
}
