import Foundation
import SwiftData

/// App Group shared between the app, widgets and watch.
enum AppGroup {
    static let id = "group.com.millionappz.adreport"
}

// MARK: - SwiftData models

@Model final class AccountRecord {
    @Attribute(.unique) var id: String
    var name: String
    var networkIDs: [String]
    var appIDs: [String]
    var mult: Double
    var admobConnected: Bool
    var appLovinConnected: Bool
    var order: Int
    var isSample: Bool = false

    init(id: String, name: String, networkIDs: [String], appIDs: [String], mult: Double,
         admobConnected: Bool, appLovinConnected: Bool, order: Int, isSample: Bool = false) {
        self.id = id; self.name = name; self.networkIDs = networkIDs; self.appIDs = appIDs
        self.mult = mult; self.admobConnected = admobConnected
        self.appLovinConnected = appLovinConnected; self.order = order; self.isSample = isSample
    }

    var domain: Account {
        Account(id: id, name: name, networkIDs: networkIDs, mult: mult, appIDs: appIDs, isSample: isSample)
    }
}

@Model final class GoalRecord {
    var daily: Double; var weekly: Double; var monthly: Double; var yearly: Double
    init(_ g: Goals) { daily = g.daily; weekly = g.weekly; monthly = g.monthly; yearly = g.yearly }
    var domain: Goals { Goals(daily: daily, weekly: weekly, monthly: monthly, yearly: yearly) }
    func apply(_ g: Goals) { daily = g.daily; weekly = g.weekly; monthly = g.monthly; yearly = g.yearly }
}

@Model final class PrefsRecord {
    var daily: Bool; var dailyTime: String
    var sleep: Bool; var away: Bool; var goal: Bool; var mover: Bool
    var milestone: Double
    init(_ p: NotificationPrefs) {
        daily = p.daily; dailyTime = p.dailyTime; sleep = p.sleep; away = p.away
        goal = p.goal; mover = p.mover; milestone = p.milestone
    }
    var domain: NotificationPrefs {
        NotificationPrefs(daily: daily, dailyTime: dailyTime, sleep: sleep, away: away,
                          goal: goal, mover: mover, milestone: milestone)
    }
    func apply(_ p: NotificationPrefs) {
        daily = p.daily; dailyTime = p.dailyTime; sleep = p.sleep; away = p.away
        goal = p.goal; mover = p.mover; milestone = p.milestone
    }
}

/// A cached normalized report row (App-Group store; read by widgets/watch).
@Model final class CachedRow {
    var accountID: String
    var date: Date
    var networkID: String
    var appID: String
    var appName: String
    var platform: String
    var country: String
    var adFormat: String
    var earnings: Double
    var impressions: Double
    var clicks: Double
    var requests: Double
    var matched: Double

    init(accountID: String, row: LiveReportRow) {
        self.accountID = accountID
        date = row.date; networkID = row.networkID; appID = row.appID; appName = row.appName
        platform = row.platform; country = row.country; adFormat = row.adFormat
        earnings = row.earnings; impressions = row.impressions; clicks = row.clicks
        requests = row.requests; matched = row.matched
    }

    var row: LiveReportRow {
        LiveReportRow(date: date, networkID: networkID, appID: appID, appName: appName,
                      platform: platform, country: country, adFormat: adFormat,
                      earnings: earnings, impressions: impressions, clicks: clicks,
                      requests: requests, matched: matched)
    }
}

// MARK: - Persistence facade

@MainActor
final class Persistence {
    let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    static let shared = Persistence()

    init() {
        let schema = Schema([AccountRecord.self, GoalRecord.self, PrefsRecord.self, CachedRow.self])
        // Use the App Group container (shared with widgets/watch) only when it's actually
        // provisioned — otherwise SwiftData fatal-errors. Falls back to a local, then an
        // in-memory store (e.g. unsigned CI simulator).
        let groupAvailable = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id) != nil
        let config = groupAvailable
            ? ModelConfiguration(schema: schema, groupContainer: .identifier(AppGroup.id))
            : ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            container = c
        } else {
            container = try! ModelContainer(for: schema,
                                            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        }
        seedIfNeeded()
    }

    private func seedIfNeeded() {
        // Connect-first: no demo accounts are seeded. Only defaults for goals/prefs.
        if ((try? context.fetch(FetchDescriptor<GoalRecord>()))?.isEmpty ?? true) {
            context.insert(GoalRecord(Catalog.defaultGoals))
        }
        if ((try? context.fetch(FetchDescriptor<PrefsRecord>()))?.isEmpty ?? true) {
            context.insert(PrefsRecord(NotificationPrefs()))
        }
        try? context.save()
    }

    // MARK: Accounts
    func accountRecords() -> [AccountRecord] {
        let d = FetchDescriptor<AccountRecord>(sortBy: [SortDescriptor(\.order)])
        return (try? context.fetch(d)) ?? []
    }
    func accounts() -> [Account] { accountRecords().map(\.domain) }
    func hasAnyAccounts() -> Bool { !accountRecords().isEmpty }

    /// Insert the demo studios (mock data) for trying out the app.
    func loadSampleData() {
        let existing = Set(accountRecords().map(\.id))
        for (i, a) in Catalog.accounts.enumerated() where !existing.contains(a.id) {
            context.insert(AccountRecord(id: a.id, name: a.name, networkIDs: a.networkIDs,
                                         appIDs: a.appIDs, mult: a.mult,
                                         admobConnected: false, appLovinConnected: false,
                                         order: 100 + i, isSample: true))
        }
        try? context.save()
    }

    func addAccount(name: String, networkIDs: [String], appIDs: [String]) -> Account {
        let order = (accountRecords().map(\.order).max() ?? -1) + 1
        let id = "acc-\(order)-\(abs(name.hashValue % 100000))"
        let rec = AccountRecord(id: id, name: name, networkIDs: networkIDs, appIDs: appIDs,
                                mult: 1.0, admobConnected: networkIDs.contains("admob"),
                                appLovinConnected: networkIDs.contains("applovin"), order: order)
        context.insert(rec)
        try? context.save()
        return rec.domain
    }

    func setConnections(accountID: String, admob: Bool? = nil, appLovin: Bool? = nil) {
        guard let rec = accountRecords().first(where: { $0.id == accountID }) else { return }
        if let admob { rec.admobConnected = admob }
        if let appLovin { rec.appLovinConnected = appLovin }
        try? context.save()
    }

    // MARK: Goals
    func goals() -> Goals { goalRecord().domain }
    func setGoals(_ g: Goals) { goalRecord().apply(g); try? context.save() }
    private func goalRecord() -> GoalRecord {
        if let r = try? context.fetch(FetchDescriptor<GoalRecord>()).first { return r }
        let r = GoalRecord(Catalog.defaultGoals); context.insert(r); return r
    }

    // MARK: Prefs
    func prefs() -> NotificationPrefs { prefsRecord().domain }
    func setPrefs(_ p: NotificationPrefs) { prefsRecord().apply(p); try? context.save() }
    private func prefsRecord() -> PrefsRecord {
        if let r = try? context.fetch(FetchDescriptor<PrefsRecord>()).first { return r }
        let r = PrefsRecord(NotificationPrefs()); context.insert(r); return r
    }

    // MARK: Cache (live report rows)
    func hasCache(_ accountID: String) -> Bool {
        var d = FetchDescriptor<CachedRow>(predicate: #Predicate { $0.accountID == accountID })
        d.fetchLimit = 1
        return ((try? context.fetchCount(d)) ?? 0) > 0
    }

    func cachedRows(accountID: String) -> [LiveReportRow] {
        let d = FetchDescriptor<CachedRow>(predicate: #Predicate { $0.accountID == accountID })
        return ((try? context.fetch(d)) ?? []).map(\.row)
    }

    /// Replace all cached rows for an account with a fresh sync result.
    func replaceCache(accountID: String, rows: [LiveReportRow]) {
        let d = FetchDescriptor<CachedRow>(predicate: #Predicate { $0.accountID == accountID })
        for old in (try? context.fetch(d)) ?? [] { context.delete(old) }
        for r in rows { context.insert(CachedRow(accountID: accountID, row: r)) }
        try? context.save()
    }
}
