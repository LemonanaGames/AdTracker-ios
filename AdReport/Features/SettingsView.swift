import SwiftUI

/// Settings tab — Pro upsell, data, notifications & devices, appearance (port of `Settings`).
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.theme) private var t

    var body: some View {
        TabScaffold(title: "Settings") {
            VStack(alignment: .leading, spacing: 0) {
                if !model.isPro { proCard.padding(.bottom, 20) }

                SettingsGroup(header: "Data") {
                    SettingsRow(symbol: Sym.wallet, iconBg: Color(hex: "#5b6df5"),
                                title: "Accounts & Networks", sub: model.account.name, first: true) {
                        model.sheet = .configure(adding: false)
                    }
                    SettingsRow(symbol: Sym.target, iconBg: Color(hex: "#4cc38a"), title: "Goals") {
                        model.switchTo(.goals)
                    }
                    if model.canSyncCurrent {
                        SettingsRow(symbol: "arrow.clockwise", iconBg: t.accent, title: "Sync now",
                                    sub: model.isSyncing ? "Syncing…" : (model.syncError ?? (model.lastSynced != nil ? "Updated" : "Pull live revenue")),
                                    trailing: model.isSyncing ? AnyView(ProgressView()) : nil) {
                            Task { await model.syncCurrentAccount() }
                        }
                    }
                }

                SettingsGroup(header: "Notifications & Devices") {
                    SettingsRow(symbol: Sym.bell, iconBg: Color(hex: "#ff6b6b"), title: "Notifications",
                                sub: model.prefs.daily ? "Daily summary at \(model.prefs.dailyTime)" : "Off", first: true) {
                        model.push(.notifications)
                    }
                    SettingsRow(symbol: Sym.widget, iconBg: Color(hex: "#ff9f43"), title: "Widgets", sub: "Home & Lock Screen") {
                        model.push(.deviceInfo(.widgets))
                    }
                    SettingsRow(symbol: Sym.watch, iconBg: Color(hex: "#111111"), title: "Apple Watch", sub: "Complications & app") {
                        model.push(.deviceInfo(.watch))
                    }
                }

                SettingsGroup(header: "App") {
                    SettingsRow(symbol: Sym.eye, iconBg: Color(hex: "#8b6df7"), title: "Appearance",
                                detail: t.label, first: true) {
                        withAnimation(.easeInOut) { themeStore.cycleDirection() }
                    }
                    SettingsRow(symbol: Sym.dollar, iconBg: Color(hex: "#34A853"), title: "Currency", detail: "USD ($)") {}
                    SettingsRow(symbol: Sym.gear, iconBg: Color(hex: "#8e8e93"), title: "About", detail: "v0.1") {}
                }

                Text("Ad Report · \(model.isPro ? "Pro" : "Free")")
                    .font(.system(size: 12.5)).foregroundStyle(t.ter)
                    .frame(maxWidth: .infinity).padding(.top, 8)
            }
            .padding(.horizontal, 16)
        }
    }

    private var proCard: some View {
        Button { model.sheet = .paywall } label: {
            HStack(spacing: 14) {
                Image(systemName: Sym.sparkle).font(.system(size: 24)).foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Reporting Pro").font(.system(size: 17, weight: .heavy)).foregroundStyle(.white)
                    Text("Widgets, Apple Watch & full history").font(.system(size: 13)).foregroundStyle(.white.opacity(0.9))
                }
                Spacer(minLength: 0)
                Image(systemName: Sym.chevron).font(.system(size: 18, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
            .background(t.gradientH, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
