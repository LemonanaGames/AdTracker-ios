import SwiftUI

/// Notifications settings (pushed) — daily summary, away recaps, alerts (port of `Notifications`).
struct NotificationsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t

    var body: some View {
        @Bindable var model = model
        PushScaffold(title: "Notifications") {
            VStack(alignment: .leading, spacing: 0) {
                Text("Stay on top of revenue without opening the app.")
                    .font(.system(size: 14)).foregroundStyle(t.sec).padding(.horizontal, 4).padding(.bottom, 16)

                SettingsGroup(header: "Daily summary") {
                    SettingsRow(title: "Daily reminder", sub: "A recap of how much you've made", first: true,
                                trailing: AnyView(toggle($model.prefs.daily)))
                    if model.prefs.daily {
                        SettingsRow(title: "Time", detail: model.prefs.dailyTime) { model.sheet = .timePicker }
                    }
                }

                SettingsGroup(header: "While you were away") {
                    SettingsRow(symbol: Sym.moon, iconBg: Color(hex: "#5b6df5"), title: "Sleep recap",
                                sub: "When your phone is in Sleep Focus, get a recap on wake", first: true,
                                trailing: AnyView(toggle($model.prefs.sleep)))
                    SettingsRow(symbol: Sym.flame, iconBg: Color(hex: "#ff9f43"), title: "Away recap (Focus modes)",
                                sub: "Earnings while in Gym, Work or DND",
                                trailing: AnyView(toggle($model.prefs.away)))
                }

                SettingsGroup(header: "Alerts") {
                    SettingsRow(title: "Goal reached", sub: "When you hit a daily / weekly goal", first: true,
                                trailing: AnyView(toggle($model.prefs.goal)))
                    SettingsRow(title: "Milestone", sub: "Crossing a revenue threshold today",
                                detail: Format.moneyK(model.prefs.milestone)) {
                        model.prefs.milestone = model.prefs.milestone >= 10000 ? 1000 : model.prefs.milestone + 1000
                    }
                    SettingsRow(title: "Big mover", sub: "A day up or down 25%+ vs usual",
                                trailing: AnyView(toggle($model.prefs.mover)))
                }

                BigButton(title: "Preview notifications", style: .tinted) { model.fullScreen = .notifPreview }
            }
            .padding(.horizontal, 16)
        }
        .task { await NotificationScheduler.requestAuthorization() }
    }

    private func toggle(_ binding: Binding<Bool>) -> some View {
        Toggle("", isOn: binding).labelsHidden().tint(t.pos)
    }
}
