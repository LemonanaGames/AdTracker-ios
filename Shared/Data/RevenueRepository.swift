import Foundation

/// Per-app metrics for an account & period.
struct AppMetric: Identifiable, Hashable, Sendable {
    let app: MonetizedApp
    var values: MetricValues
    var id: String { app.id }
}

/// Source-agnostic revenue access. Implemented by `MockRevenueRepository` (Phase 1)
/// and `LiveRevenueRepository` (Phase 3, reading the AdMob/AppLovin cache).
///
/// Reads are synchronous: a live repository serves from its local cache, while a
/// separate sync step performs the network fetch and refreshes that cache.
protocol RevenueRepository: Sendable {
    var accounts: [Account] { get }
    func combinedSeries(account: String) -> [DayPoint]
    func series(account: String, network: String) -> [DayPoint]
    func appMetrics(account: String, period: Period) -> [AppMetric]
}

extension RevenueRepository {
    func account(_ id: String) -> Account {
        accounts.first { $0.id == id } ?? accounts.first
            ?? Account(id: id, name: "", networkIDs: [], mult: 0, appIDs: [])
    }

    /// Totals over all of an account's apps for a period.
    func totals(account: String, period: Period) -> MetricValues {
        RevenueMath.totals(appMetrics(account: account, period: period).map(\.values))
    }
}
