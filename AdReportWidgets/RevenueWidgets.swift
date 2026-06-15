import WidgetKit
import SwiftUI

// MARK: - Timeline

struct RevenueEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
    let accountName: String
    let goals: Goals
}

struct RevenueProvider: TimelineProvider {
    private let theme = Theme.midnight

    func placeholder(in context: Context) -> RevenueEntry {
        let repo = MockRevenueRepository()
        return RevenueEntry(date: Date(),
                            data: WidgetData.make(repo: repo, account: "main", goals: Catalog.defaultGoals),
                            accountName: "Main Studio", goals: Catalog.defaultGoals)
    }

    func getSnapshot(in context: Context, completion: @escaping (RevenueEntry) -> Void) {
        Task { @MainActor in completion(makeEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RevenueEntry>) -> Void) {
        Task { @MainActor in
            let entry = makeEntry()
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
        }
    }

    @MainActor private func makeEntry() -> RevenueEntry {
        let r = WidgetData.forAccount(nil)
        return RevenueEntry(date: Date(), data: r.data, accountName: r.accountName, goals: r.goals)
    }
}

// MARK: - Views

private let widgetTheme = Theme.midnight

struct RevenueWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RevenueEntry

    var body: some View {
        switch family {
        case .systemSmall: SmallRevenue(entry: entry)
        case .systemMedium: MediumRevenue(entry: entry)
        case .accessoryRectangular: LockRectangular(entry: entry)
        case .accessoryCircular: LockCircular(entry: entry)
        case .accessoryInline: Text("Today \(Format.money(entry.data.today, dp: 0))")
        default: SmallRevenue(entry: entry)
        }
    }
}

private struct SmallRevenue: View {
    let entry: RevenueEntry
    var body: some View {
        let t = widgetTheme
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 5).fill(t.accent).frame(width: 14, height: 14)
                Text("TODAY").font(.system(size: 11, weight: .bold)).foregroundStyle(t.sec)
            }
            Text(Format.money(entry.data.today, dp: 0))
                .font(.system(size: 26, weight: .heavy)).foregroundStyle(t.text)
                .minimumScaleFactor(0.6).lineLimit(1).padding(.top, 8)
            Text("▲ \(Int(abs(entry.data.paceDelta)))% pace").font(.system(size: 12, weight: .bold)).foregroundStyle(t.pos)
            Spacer(minLength: 6)
            MiniBars(values: entry.data.last7, color: t.accent, dimLast: true).frame(height: 34)
        }
        .containerBackground(t.bg, for: .widget)
    }
}

private struct MediumRevenue: View {
    let entry: RevenueEntry
    var body: some View {
        let t = widgetTheme
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("TODAY · \(entry.accountName)").font(.system(size: 10, weight: .bold)).foregroundStyle(t.sec).lineLimit(1)
                Text(Format.money(entry.data.today, dp: 0)).font(.system(size: 28, weight: .heavy)).foregroundStyle(t.text)
                    .minimumScaleFactor(0.6).lineLimit(1).padding(.top, 6)
                Text("▲ \(Int(abs(entry.data.paceDelta)))% pace").font(.system(size: 12, weight: .bold)).foregroundStyle(t.pos)
                Spacer(minLength: 4)
                Text("\(Int(entry.data.goalPct * 100))% of daily goal").font(.system(size: 11)).foregroundStyle(t.sec)
                ProgressView(value: min(1, entry.data.goalPct)).tint(t.accent)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("7 DAYS").font(.system(size: 10, weight: .bold)).foregroundStyle(t.sec)
                    Spacer()
                    Text(Format.moneyK(entry.data.d7)).font(.system(size: 11, weight: .bold)).foregroundStyle(t.text)
                }
                MiniBars(values: entry.data.last7, color: t.accent, dimLast: true)
            }
        }
        .containerBackground(t.bg, for: .widget)
    }
}

private struct LockRectangular: View {
    let entry: RevenueEntry
    var body: some View {
        HStack(spacing: 8) {
            Gauge(value: min(1, entry.data.goalPct)) { } currentValueLabel: {
                Text("\(Int(entry.data.goalPct * 100))")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            VStack(alignment: .leading, spacing: 1) {
                Text("TODAY").font(.system(size: 11, weight: .semibold))
                Text(Format.money(entry.data.today, dp: 0)).font(.system(size: 18, weight: .heavy))
            }
            Spacer(minLength: 0)
        }
        .containerBackground(.clear, for: .widget)
    }
}

private struct LockCircular: View {
    let entry: RevenueEntry
    var body: some View {
        Gauge(value: min(1, entry.data.goalPct)) { } currentValueLabel: {
            Text(Format.moneyK(entry.data.today))
                .font(.system(size: 11, weight: .bold)).minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Top apps widget

struct TopAppsWidgetView: View {
    let entry: RevenueEntry
    var body: some View {
        let t = widgetTheme
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TOP APPS · TODAY").font(.system(size: 10, weight: .bold)).foregroundStyle(t.sec)
                Spacer()
                Text(Format.money(entry.data.today, dp: 0)).font(.system(size: 11, weight: .bold)).foregroundStyle(t.text)
            }
            ForEach(entry.data.topApps) { r in
                HStack(spacing: 10) {
                    AppIconTile(app: r.app, size: 24, radius: 6)
                    Text(r.app.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(t.text).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(Format.money(r.values.earnings, dp: 0)).font(.system(size: 13, weight: .bold)).foregroundStyle(t.text)
                }
            }
            Spacer(minLength: 0)
        }
        .containerBackground(t.bg, for: .widget)
    }
}

// MARK: - Widgets

struct RevenueWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RevenueWidget", provider: RevenueProvider()) { entry in
            RevenueWidgetView(entry: entry)
        }
        .configurationDisplayName("Revenue")
        .description("Today's ad revenue at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct TopAppsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TopAppsWidget", provider: RevenueProvider()) { entry in
            TopAppsWidgetView(entry: entry)
        }
        .configurationDisplayName("Top Apps")
        .description("Your highest-earning apps today.")
        .supportedFamilies([.systemMedium])
    }
}
