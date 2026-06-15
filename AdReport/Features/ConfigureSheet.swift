import SwiftUI

/// Configure networks sheet — connect AdMob (Google) + AppLovin report key
/// (port of `Configure`). Real credential wiring lands in Phase 2/3.
struct ConfigureSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    let adding: Bool

    @State private var admobConnected: Bool
    @State private var reportKey: String

    init(adding: Bool) {
        self.adding = adding
        _admobConnected = State(initialValue: !adding)
        _reportKey = State(initialValue: adding ? "" : "AeuaBOElKtqgxMwLdvDEGN07QTX…")
    }

    var body: some View {
        SheetScaffold(title: adding ? "New account" : "Networks") {
            VStack(alignment: .leading, spacing: 0) {
                Text("Connect your ad networks to pull live revenue. Your keys are stored only on this device.")
                    .font(.system(size: 14)).foregroundStyle(t.sec).padding(.horizontal, 4).padding(.bottom, 18)

                sectionLabel("Google AdMob")
                if AdMobConfig.isConfigured {
                    Card {
                        Button {
                            Task { await model.signInAdMob(); admobConnected = model.auth.isSignedIn }
                        } label: {
                            HStack(spacing: 10) {
                                googleGlyph
                                Text(admobConnected ? "Connected" : "Sign in with Google")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(admobConnected ? t.text : Color(hex: "#202124"))
                                if admobConnected {
                                    Image(systemName: Sym.check).font(.system(size: 16, weight: .bold)).foregroundStyle(t.pos)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(admobConnected ? t.card2 : .white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Sign in with the Google account that owns your AdMob reports. You may be asked twice — to sign in and to grant report access.")
                        .font(.system(size: 12.5)).foregroundStyle(t.ter).padding(.horizontal, 6).padding(.top, 8).padding(.bottom, 20)
                } else {
                    Card {
                        HStack(spacing: 10) {
                            Image(systemName: "wrench.and.screwdriver.fill").foregroundStyle(t.ter)
                            Text("Setup required").font(.system(size: 16, weight: .semibold)).foregroundStyle(t.sec)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                    }
                    Text("AdMob reporting needs a Google OAuth Client ID configured in the app (see SETUP.md). AppLovin works right now with just a Report Key below.")
                        .font(.system(size: 12.5)).foregroundStyle(t.ter).padding(.horizontal, 6).padding(.top, 8).padding(.bottom, 20)
                }

                sectionLabel("AppLovin Max")
                Card {
                    TextField("Report Key", text: $reportKey)
                        .font(.system(size: 16)).foregroundStyle(t.text)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                Text("Find it under Account → Keys → Report Key in your AppLovin dashboard.")
                    .font(.system(size: 12.5)).foregroundStyle(t.ter).padding(.horizontal, 6).padding(.top, 8).padding(.bottom, 28)

                BigButton(title: adding ? "Add account" : "Save") { save() }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private func save() {
        let trimmedKey = reportKey.trimmingCharacters(in: .whitespaces)
        if adding {
            var nets: [String] = []
            if admobConnected { nets.append("admob") }
            if !trimmedKey.isEmpty { nets.append("applovin") }
            if nets.isEmpty { nets = ["admob"] }
            let acc = model.persistence.addAccount(name: "New account", networkIDs: nets, appIDs: [])
            if !trimmedKey.isEmpty { Keychain.set(trimmedKey, for: Keychain.appLovinKey(account: acc.id)) }
            model.reloadAccounts()
            model.selectAccount(acc.id)
        } else {
            let id = model.accountID
            if !trimmedKey.isEmpty { Keychain.set(trimmedKey, for: Keychain.appLovinKey(account: id)) }
            model.persistence.setConnections(accountID: id, admob: admobConnected, appLovin: !trimmedKey.isEmpty)
            model.reloadAccounts()
        }
        Task { await model.syncCurrentAccount() }
        dismiss()
    }

    private func sectionLabel(_ s: String) -> some View {
        Text(s.uppercased()).font(.system(size: 13, weight: .semibold)).foregroundStyle(t.sec)
            .tracking(0.3).padding(.horizontal, 4).padding(.bottom, 8)
    }

    /// Google "G" 4-color conic mark.
    private var googleGlyph: some View {
        Circle()
            .fill(AngularGradient(colors: [Color(hex: "#ea4335"), Color(hex: "#fbbc05"),
                                           Color(hex: "#34a853"), Color(hex: "#4285f4"), Color(hex: "#ea4335")],
                                  center: .center))
            .frame(width: 22, height: 22)
    }
}
