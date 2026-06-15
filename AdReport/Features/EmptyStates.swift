import SwiftUI

/// Shown when the user has no accounts yet (connect-first first run).
struct ConnectEmptyView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(t.accent)
                .frame(width: 96, height: 96)
                .background(t.accentSoft, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            Text("Track your ad revenue")
                .font(.system(size: 22, weight: .heavy)).foregroundStyle(t.text)
            Text("Connect AppLovin MAX or Google AdMob to see your earnings — daily, by app, country and network.")
                .font(.system(size: 15)).foregroundStyle(t.sec)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            BigButton(title: "Connect a network", leadingSymbol: Sym.plus) {
                model.sheet = .configure(adding: true)
            }
            .padding(.horizontal, 24).padding(.top, 8)

            Button { model.loadSampleData() } label: {
                Text("Load sample data").font(.system(size: 15, weight: .semibold)).foregroundStyle(t.accent)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

/// Shown when an account exists but has no revenue yet (syncing / not connected).
struct AccountEmptyView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t

    var body: some View {
        VStack(spacing: 14) {
            if model.isSyncing {
                ProgressView().controlSize(.large)
                Text("Fetching your revenue…").font(.system(size: 15)).foregroundStyle(t.sec)
            } else {
                Image(systemName: "tray")
                    .font(.system(size: 40)).foregroundStyle(t.ter)
                    .frame(width: 90, height: 90)
                    .background(t.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                Text("No data yet").font(.system(size: 20, weight: .bold)).foregroundStyle(t.text)
                if let err = model.syncError {
                    Text(err).font(.system(size: 13.5)).foregroundStyle(t.neg)
                        .multilineTextAlignment(.center).padding(.horizontal, 24)
                } else {
                    Text(model.canSyncCurrent
                         ? "Pull your latest report from the connected network."
                         : "Connect a network for this account to load revenue.")
                        .font(.system(size: 15)).foregroundStyle(t.sec)
                        .multilineTextAlignment(.center).padding(.horizontal, 24)
                }
                if model.canSyncCurrent {
                    BigButton(title: "Sync now") { Task { await model.syncCurrentAccount() } }
                        .padding(.horizontal, 24).padding(.top, 4)
                } else {
                    BigButton(title: "Connect a network") { model.sheet = .configure(adding: false) }
                        .padding(.horizontal, 24).padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
