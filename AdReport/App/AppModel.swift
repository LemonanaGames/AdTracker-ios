import SwiftUI

/// Top-level navigation & app state (MV pattern). Drives the tab bar, per-tab push
/// stacks, sheets, the selected account, goals and notification prefs.
@MainActor @Observable
final class AppModel {

    // MARK: Tabs
    enum Tab: String, CaseIterable, Identifiable, Hashable {
        case home, reports, goals, analytics, settings
        var id: String { rawValue }
        var title: String? {
            switch self {
            case .home: nil               // Dashboard renders its own greeting header
            case .reports: "Reports"
            case .goals: "Goals"
            case .analytics: "Insights"
            case .settings: "Settings"
            }
        }
        var label: String { self == .analytics ? "Insights" : rawValue.capitalized }
        var symbol: String {
            switch self {
            case .home: Sym.homeOutline
            case .reports: Sym.chart
            case .goals: Sym.target
            case .analytics: Sym.pulse
            case .settings: Sym.gear
            }
        }
    }

    // MARK: Push routes (within a tab's NavigationStack)
    enum Route: Hashable {
        case network(String)            // network id
        case app(String)                // app id
        case notifications
        case deviceInfo(DeviceKind)
    }
    enum DeviceKind: Hashable { case widgets, watch }

    // MARK: Modal routes
    enum SheetRoute: Identifiable, Hashable {
        case accounts
        case editGoal(ReportMode)
        case timePicker
        case configure(adding: Bool)
        case paywall
        var id: String {
            switch self {
            case .accounts: "accounts"
            case .editGoal(let m): "editGoal-\(m.rawValue)"
            case .timePicker: "timePicker"
            case .configure(let a): "configure-\(a)"
            case .paywall: "paywall"
            }
        }
    }
    enum FullRoute: Identifiable, Hashable {
        case notifPreview
        var id: String { "notifPreview" }
    }

    // MARK: State
    var selectedTab: Tab = .home
    var accountID: String
    var accounts: [Account]
    var goals: Goals { didSet { persistence.setGoals(goals) } }
    var prefs: NotificationPrefs {
        didSet { persistence.setPrefs(prefs); NotificationScheduler.scheduleDaily(prefs) }
    }
    var isPro = true

    var sheet: SheetRoute?
    var fullScreen: FullRoute?

    // per-tab navigation paths
    var homePath: [Route] = []
    var reportsPath: [Route] = []
    var goalsPath: [Route] = []
    var analyticsPath: [Route] = []
    var settingsPath: [Route] = []

    // MARK: Dependencies
    private(set) var repository: any RevenueRepository = MockRevenueRepository()
    let persistence: Persistence
    let auth: AdMobAuth
    let syncService: SyncService

    // Sync state
    var isSyncing = false
    var syncError: String?
    var lastSynced: Date?

    init(persistence: Persistence = .shared) {
        self.persistence = persistence
        let adMobAuth = AdMobAuth()
        self.auth = adMobAuth
        self.syncService = SyncService(persistence: persistence, auth: adMobAuth)
        let accs = persistence.accounts()
        self.accounts = accs.isEmpty ? Catalog.accounts : accs
        self.accountID = accs.first?.id ?? Catalog.accounts[0].id
        self.goals = persistence.goals()
        self.prefs = persistence.prefs()
        self.repository = makeRepository()
    }

    var account: Account { accounts.first { $0.id == accountID } ?? accounts.first ?? Catalog.accounts[0] }

    func reloadAccounts() {
        accounts = persistence.accounts()
        rebuildRepository()
    }

    // MARK: Live data
    private func makeRepository() -> any RevenueRepository {
        let mock = MockRevenueRepository(accounts: accounts)
        var cache: [String: [LiveReportRow]] = [:]
        for a in accounts where persistence.hasCache(a.id) {
            cache[a.id] = persistence.cachedRows(accountID: a.id)
        }
        return cache.isEmpty ? mock : LiveRevenueRepository(accounts: accounts, mock: mock, cache: cache)
    }

    func rebuildRepository() { repository = makeRepository() }

    /// Whether the current account can pull live data.
    var canSyncCurrent: Bool { syncService.canSync(account) }

    func syncCurrentAccount() async {
        guard syncService.canSync(account) else { updateAmbient(); return }
        isSyncing = true; syncError = nil
        do {
            _ = try await syncService.sync(account: account)
            rebuildRepository()
            lastSynced = Date()
        } catch {
            syncError = error.localizedDescription
        }
        isSyncing = false
        updateAmbient()
    }

    /// Refresh ambient surfaces (Live Activity) and fire threshold alerts for the current account.
    func updateAmbient() {
        let r = WidgetData.forAccount(accountID, persistence: persistence)
        #if canImport(ActivityKit)
        if isPro { LiveActivityController.startOrUpdate(accountName: r.accountName, data: r.data) }
        #endif
        fireThresholdAlerts(data: r.data)
    }

    private func fireThresholdAlerts(data: WidgetData) {
        let defaults = UserDefaults.standard
        let dayKey = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        if prefs.goal, data.goalPct >= 1 {
            let key = "alert.goal.\(accountID).\(dayKey)"
            if !defaults.bool(forKey: key) {
                defaults.set(true, forKey: key)
                NotificationScheduler.notify(title: "Goal reached 🎉",
                                             body: "You hit your daily goal of \(Format.moneyK(goals.daily)).")
            }
        }
        if data.today >= prefs.milestone {
            let key = "alert.milestone.\(accountID).\(dayKey).\(Int(prefs.milestone))"
            if !defaults.bool(forKey: key) {
                defaults.set(true, forKey: key)
                NotificationScheduler.notify(title: "Milestone",
                                             body: "You've crossed \(Format.moneyK(prefs.milestone)) today.")
            }
        }
    }

    func signInAdMob() async {
        do { try await auth.signIn(); await syncCurrentAccount() }
        catch { syncError = "Google sign-in failed" }
    }

    // MARK: Navigation helpers
    func push(_ route: Route) {
        switch selectedTab {
        case .home: homePath.append(route)
        case .reports: reportsPath.append(route)
        case .goals: goalsPath.append(route)
        case .analytics: analyticsPath.append(route)
        case .settings: settingsPath.append(route)
        }
    }

    func switchTo(_ tab: Tab) { selectedTab = tab }

    func selectAccount(_ id: String) { accountID = id }
}
