import SwiftUI

/// Accounts sheet — switch between studios / ad accounts (port of `Accounts`).
struct AccountsSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @State private var addingAccount = false

    var body: some View {
        SheetScaffold(title: "Accounts") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Track revenue across multiple studios and ad accounts. Each account powers its own widgets.")
                    .font(.system(size: 14)).foregroundStyle(t.sec).padding(.horizontal, 4)

                VStack(spacing: 12) {
                    ForEach(model.accounts) { a in
                        accountCard(a)
                    }
                }

                BigButton(title: "Add account", style: .tinted, leadingSymbol: Sym.plus) {
                    addingAccount = true
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
        .sheet(isPresented: $addingAccount) {
            ConfigureSheet(adding: true).environment(\.theme, t).tint(t.accent)
        }
    }

    private func accountCard(_ a: Account) -> some View {
        let today = RevenueMath.valueToday(model.repository.combinedSeries(account: a.id))
        let selected = a.id == model.accountID
        return Button {
            model.selectAccount(a.id); dismiss()
        } label: {
            HStack(spacing: 14) {
                HStack(spacing: -10) {
                    ForEach(Array(a.networkIDs.enumerated()), id: \.offset) { _, nid in
                        NetBadge(network: Catalog.network(nid), size: 36, radius: 10)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(t.card, lineWidth: 2))
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(a.name).font(.system(size: 16, weight: .bold)).foregroundStyle(t.text)
                    Text("\(a.networkIDs.count) network\(a.networkIDs.count > 1 ? "s" : "") · \(Format.money(today, dp: 0)) today")
                        .font(.system(size: 13)).foregroundStyle(t.sec)
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: Sym.check).font(.system(size: 14, weight: .heavy)).foregroundStyle(t.accentText)
                        .frame(width: 26, height: 26).background(t.accent, in: Circle())
                } else {
                    Circle().stroke(t.hair, lineWidth: 2).frame(width: 26, height: 26)
                }
            }
            .padding(16)
            .background(t.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(selected ? t.accent : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
