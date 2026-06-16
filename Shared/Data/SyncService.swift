import Foundation
import WidgetKit
import BackgroundTasks

/// Orchestrates live fetches from AdMob + AppLovin, writes the App-Group cache,
/// and reloads widget/watch timelines.
@MainActor
final class SyncService {
    let persistence: Persistence
    let auth: AdMobAuth
    var appLovin = AppLovinClient()
    var adMob = AdMobClient()

    init(persistence: Persistence, auth: AdMobAuth) {
        self.persistence = persistence
        self.auth = auth
    }

    /// Whether an account has any connected, fetchable network.
    func canSync(_ account: Account) -> Bool {
        let hasAppLovin = account.networkIDs.contains("applovin")
            && Keychain.get(Keychain.appLovinKey(account: account.id)) != nil
        let hasAdMob = account.networkIDs.contains("admob") && AdMobConfig.isConfigured && auth.isSignedIn
        return hasAppLovin || hasAdMob
    }

    @discardableResult
    func sync(account: Account, days: Int = 90) async throws -> Bool {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        var rows: [LiveReportRow] = []

        if account.networkIDs.contains("applovin"),
           let key = Keychain.get(Keychain.appLovinKey(account: account.id)) {
            rows += try await appLovin.fetch(reportKey: key, start: start, end: end)
        }
        if account.networkIDs.contains("admob"), AdMobConfig.isConfigured, auth.isSignedIn {
            let token = try await auth.accessToken()
            let publisher = try await adMob.publisherID(accessToken: token)
            rows += try await adMob.fetch(accessToken: token, publisherID: publisher, start: start, end: end)
        }

        guard !rows.isEmpty else { return false }
        persistence.replaceCache(accountID: account.id, rows: rows)
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }

    nonisolated static let backgroundTaskID = "com.millionappz.adreport.refresh"

    /// Background-refresh entry point: sync every syncable account, then reschedule.
    static func runBackground() async {
        let persistence = Persistence.shared
        let svc = SyncService(persistence: persistence, auth: AdMobAuth())
        for account in persistence.accounts() where svc.canSync(account) {
            _ = try? await svc.sync(account: account)
        }
        scheduleAppRefresh()
    }

    nonisolated static func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)   // ~hourly
        try? BGTaskScheduler.shared.submit(request)
    }
}
