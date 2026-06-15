import Testing
import Foundation
@testable import AdReport

@Suite("Live data aggregation")
struct LiveDataTests {

    private func sampleRepo() -> LiveRevenueRepository {
        let acc = Account(id: "x", name: "X", networkIDs: ["admob", "applovin"], mult: 1, appIDs: [])
        let now = Date()
        let yesterday = now.addingTimeInterval(-86_400)
        let rows: [LiveReportRow] = [
            row("a", "App A", "admob", now, earnings: 100, impr: 10_000),
            row("a", "App A", "applovin", now, earnings: 50, impr: 4_000),
            row("b", "App B", "admob", yesterday, earnings: 30, impr: 3_000),
        ]
        return LiveRevenueRepository(accounts: [acc], mock: MockRevenueRepository(accounts: [acc]), cache: ["x": rows])
    }

    private func row(_ id: String, _ name: String, _ net: String, _ date: Date, earnings: Double, impr: Double) -> LiveReportRow {
        LiveReportRow(date: date, networkID: net, appID: id, appName: name, platform: "iOS",
                      country: "US", adFormat: "Interstitial", earnings: earnings, impressions: impr,
                      clicks: impr * 0.01, requests: impr * 1.2, matched: impr)
    }

    @Test("Combined series sums all networks per day")
    func combined() {
        let repo = sampleRepo()
        let series = repo.combinedSeries(account: "x")
        #expect(series.count == 2)              // today + yesterday
        #expect(abs((series.last?.value ?? 0) - 150) < 0.001)  // 100 + 50 today
        #expect(series.last?.partial == true)
    }

    @Test("Per-network series filters correctly")
    func perNetwork() {
        let repo = sampleRepo()
        let admob = repo.series(account: "x", network: "admob")
        let total = admob.reduce(0) { $0 + $1.value }
        #expect(abs(total - 130) < 0.001)       // 100 today + 30 yesterday
    }

    @Test("App metrics group by app and derive eCPM")
    func appGrouping() {
        let repo = sampleRepo()
        let metrics = repo.appMetrics(account: "x", period: .last7)
        #expect(metrics.count == 2)
        #expect(metrics.first?.app.id == "a")   // sorted by earnings desc
        let a = metrics.first!
        #expect(abs(a.values.earnings - 150) < 0.001)
        #expect(abs(a.values.ecpm - a.values.earnings / a.values.impressions * 1000) < 0.001)
    }

    @Test("Falls back to mock when an account has no cache")
    func fallback() {
        let repo = LiveRevenueRepository(accounts: Catalog.accounts, mock: MockRevenueRepository(), cache: [:])
        #expect(repo.combinedSeries(account: "main").count == Catalog.historyDays)
    }

    @Test("Period intervals are anchored to the day")
    func periodInterval() {
        let cal = Calendar.current
        let now = Date()
        let today = Period.today.interval(now: now, calendar: cal)
        #expect(today.start == cal.startOfDay(for: now))
        let last7 = Period.last7.interval(now: now, calendar: cal)
        #expect(last7.start < today.start)
    }
}
