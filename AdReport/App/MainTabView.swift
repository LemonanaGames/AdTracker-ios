import SwiftUI

/// The 5-tab shell with per-tab navigation stacks, sheets and the full-screen
/// notification preview. The tab bar adopts Liquid Glass automatically on iOS 26.
struct MainTabView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t

    var body: some View {
        @Bindable var model = model

        TabView(selection: $model.selectedTab) {
            Tab(value: AppModel.Tab.home) {
                stack($model.homePath) { DashboardView() }
            } label: { tabLabel(.home) }
            Tab(value: AppModel.Tab.reports) {
                stack($model.reportsPath) { ReportsView() }
            } label: { tabLabel(.reports) }
            Tab(value: AppModel.Tab.goals) {
                stack($model.goalsPath) { GoalsView() }
            } label: { tabLabel(.goals) }
            Tab(value: AppModel.Tab.analytics) {
                stack($model.analyticsPath) { InsightsView() }
            } label: { tabLabel(.analytics) }
            Tab(value: AppModel.Tab.settings) {
                stack($model.settingsPath) { SettingsView() }
            } label: { tabLabel(.settings) }
        }
        .tint(t.tabActive)
        .sheet(item: $model.sheet) { route in
            sheetView(route)
                .environment(\.theme, t)
                .tint(t.accent)
                .preferredColorScheme(t.dark ? .dark : .light)
        }
        .fullScreenCover(item: $model.fullScreen) { route in
            switch route {
            case .notifPreview: NotifPreviewView().environment(\.theme, t)
            }
        }
    }

    private func tabLabel(_ tab: AppModel.Tab) -> some View {
        Label(tab.label, systemImage: tab.symbol)
    }

    // MARK: per-tab stack + push destinations
    @ViewBuilder
    private func stack(_ path: Binding<[AppModel.Route]>, @ViewBuilder root: () -> some View) -> some View {
        NavigationStack(path: path) {
            root()
                .navigationDestination(for: AppModel.Route.self) { route in
                    destination(route)
                }
        }
    }

    @ViewBuilder
    private func destination(_ route: AppModel.Route) -> some View {
        switch route {
        case .network(let id): NetworkDetailView(networkID: id)
        case .app(let id): AppDetailView(appID: id)
        case .notifications: NotificationsView()
        case .deviceInfo(let kind): DeviceInfoView(kind: kind)
        }
    }

    // MARK: sheets
    @ViewBuilder
    private func sheetView(_ route: AppModel.SheetRoute) -> some View {
        switch route {
        case .accounts: AccountsSheet()
        case .editGoal(let mode): EditGoalSheet(mode: mode)
        case .timePicker: TimePickerSheet()
        case .configure(let adding): ConfigureSheet(adding: adding)
        case .paywall: PaywallSheet()
        }
    }
}
