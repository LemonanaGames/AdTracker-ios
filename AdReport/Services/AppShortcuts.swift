import AppIntents

/// "How much did I make today?" — exposes today's revenue to Siri & Spotlight.
struct TodayRevenueIntent: AppIntent {
    static var title: LocalizedStringResource = "Today's Revenue"
    static var description = IntentDescription("How much ad revenue you've earned so far today.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let r = WidgetData.forAccount(nil)
        let amount = Format.money(r.data.today, dp: 0)
        let pct = Int(r.data.goalPct * 100)
        return .result(dialog: "You've made \(amount) so far today — \(pct)% of your daily goal.")
    }
}

struct AdReportShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TodayRevenueIntent(),
            phrases: [
                "How much did I make today in \(.applicationName)",
                "Show today's revenue in \(.applicationName)",
                "\(.applicationName) revenue today",
            ],
            shortTitle: "Today's Revenue",
            systemImageName: "chart.bar.fill")
    }
}
