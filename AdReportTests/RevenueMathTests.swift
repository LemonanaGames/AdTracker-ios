import Testing
import Foundation
@testable import AdReport

@Suite("Revenue data & math")
struct RevenueMathTests {

    let repo = MockRevenueRepository()

    @Test("Mock series are deterministic across instances")
    func determinism() {
        let a = MockRevenueRepository().combinedSeries(account: "main")
        let b = MockRevenueRepository().combinedSeries(account: "main")
        #expect(a.count == b.count)
        for (x, y) in zip(a, b) { #expect(x.value == y.value) }
    }

    @Test("Series length and partial flag")
    func seriesShape() {
        let s = repo.series(account: "main", network: "admob")
        #expect(s.count == Catalog.historyDays)
        #expect(s.last?.partial == true)
        #expect(s.dropLast().allSatisfy { !$0.partial })
    }

    @Test("Combined series sums each network per day")
    func combinedSumsNetworks() {
        let main = repo.account("main")
        let combined = repo.combinedSeries(account: "main")
        let perNet = main.networkIDs.map { repo.series(account: "main", network: $0) }
        let lastIdx = combined.count - 1
        let expected = perNet.reduce(0) { $0 + $1[lastIdx].value }
        #expect(abs(combined[lastIdx].value - expected) < 0.0001)
    }

    @Test("periodRevenue(today) equals today's combined value")
    func periodToday() {
        let combined = repo.combinedSeries(account: "main")
        let today = RevenueMath.periodRevenue(combined: combined, period: .today)
        #expect(abs(today - RevenueMath.valueToday(combined)) < 0.0001)
    }

    @Test("Totals derive eCPM / CTR / match-rate consistently")
    func totalsDerivation() {
        let rows = repo.appMetrics(account: "main", period: .last7).map(\.values)
        let t = RevenueMath.totals(rows)
        #expect(t.earnings > 0)
        #expect(abs(t.ecpm - t.earnings / t.impressions * 1000) < 0.0001)
        #expect(abs(t.ctr - t.clicks / t.impressions * 100) < 0.0001)
    }

    @Test("Country split conserves total earnings")
    func splitConservesEarnings() {
        let tot = repo.totals(account: "main", period: .thisMonth)
        let split = RevenueMath.splitByCountry(tot)
        let sum = split.reduce(0) { $0 + $1.values.earnings }
        #expect(abs(sum - tot.earnings) < 0.01)
    }

    @Test("App metrics are sorted by earnings descending")
    func appMetricsSorted() {
        let rows = repo.appMetrics(account: "main", period: .today)
        let earnings = rows.map(\.values.earnings)
        #expect(earnings == earnings.sorted(by: >))
    }

    @Test("Formatting matches the design helpers")
    func formatting() {
        #expect(Format.money(1234.5) == "$1,234.50")
        #expect(Format.money(1234, dp: 0) == "$1,234")
        #expect(Format.moneyK(1_500_000) == "$1.50M")
        #expect(Format.moneyK(12_300) == "$12.3K")
        #expect(Format.pct(12.34) == "+12.3%")
        #expect(Format.pct(-5) == "-5.0%")
    }

    @Test("Aggregation buckets are ordered newest-first")
    func aggregateOrder() {
        let combined = repo.combinedSeries(account: "main")
        let monthly = RevenueMath.aggregate(combined, .monthly)
        #expect(monthly.count >= 2)
        #expect(monthly[0].sort > monthly[1].sort)
    }
}
