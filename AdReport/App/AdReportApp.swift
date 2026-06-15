import SwiftUI

@main
struct AdReportApp: App {
    @State private var model = AppModel()
    @State private var themeStore = ThemeStore()
    @State private var store = SubscriptionStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(themeStore)
                .environment(store)
                .environment(\.theme, themeStore.theme)
                .tint(themeStore.theme.accent)
                .preferredColorScheme(themeStore.theme.dark ? .dark : .light)
                .task {
                    store.configure()
                    await store.refresh()
                    if store.isConfigured { model.isPro = store.isPro }
                    NotificationScheduler.scheduleDaily(model.prefs)
                    await model.syncCurrentAccount()           // refresh + ambient surfaces on launch
                }
                .onChange(of: store.isPro) { _, pro in
                    if store.isConfigured { model.isPro = pro }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { SyncService.scheduleAppRefresh() }
        }
        .backgroundTask(.appRefresh(SyncService.backgroundTaskID)) {
            await SyncService.runBackground()
        }
    }
}

/// App entry point — shows onboarding on first run, then the main app.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("didOnboard") private var didOnboard = false

    var body: some View {
        if didOnboard {
            MainTabView()
        } else {
            OnboardingView(
                onConnect: { didOnboard = true; model.sheet = .configure(adding: true) },
                onSkip: { didOnboard = true })
            .transition(.opacity)
        }
    }
}
