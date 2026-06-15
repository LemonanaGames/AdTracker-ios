import SwiftUI

/// In-app preview of widgets / Apple Watch surfaces (port of `DeviceInfo`).
struct DeviceInfoView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    let kind: AppModel.DeviceKind

    private let wallpaper = LinearGradient(colors: [Color(hex: "#2a3340"), Color(hex: "#11151b")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)

    var body: some View {
        let data = WidgetData.make(repo: model.repository, account: model.accountID, goals: model.goals)
        PushScaffold(title: kind == .watch ? "Apple Watch" : "Widgets") {
            VStack(alignment: .leading, spacing: 14) {
                Text(kind == .watch
                     ? "Glance at today's revenue from your wrist, or add a complication to any watch face."
                     : "Add a widget to your Home or Lock Screen to keep revenue in sight all day.")
                    .font(.system(size: 14)).foregroundStyle(t.sec).padding(.horizontal, 4)

                if !model.isPro {
                    proLock
                } else if kind == .watch {
                    VStack(spacing: 14) {
                        HStack(spacing: 18) {
                            WatchAppPreview(theme: t, data: data)
                            WatchFacePreview(theme: t, data: data)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24).background(wallpaper, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                        HStack(spacing: 60) {
                            Text("Watch app").font(.system(size: 12.5, weight: .medium)).foregroundStyle(t.ter)
                            Text("Face complication").font(.system(size: 12.5, weight: .medium)).foregroundStyle(t.ter)
                        }
                    }
                } else {
                    VStack(spacing: 22) {
                        HStack(alignment: .top, spacing: 16) {
                            HomeSmallPreview(theme: t, data: data)
                            HomeMediumPreview(theme: t, data: data)
                        }
                        HomeAppsPreview(theme: t, data: data)
                        VStack(spacing: 8) {
                            Divider().overlay(.white.opacity(0.1))
                            Text("LOCK SCREEN").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.5)).tracking(0.4)
                            LockRectPreview(theme: t, data: data)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 26).padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(wallpaper, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var proLock: some View {
        Card {
            VStack(spacing: 12) {
                Image(systemName: Sym.sparkle).font(.system(size: 30)).foregroundStyle(t.accent)
                Text("A Reporting Pro feature").font(.system(size: 16, weight: .bold)).foregroundStyle(t.text)
                Text("Unlock widgets, Apple Watch and full history.")
                    .font(.system(size: 13.5)).foregroundStyle(t.sec).multilineTextAlignment(.center)
                BigButton(title: "Unlock Reporting Pro") { model.sheet = .paywall }.padding(.top, 4)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
        }
    }
}
