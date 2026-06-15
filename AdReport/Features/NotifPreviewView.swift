import SwiftUI

/// Full-screen lock-screen mock previewing the notification styles (port of `NotifPreview`).
struct NotifPreviewView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let today = RevenueMath.valueToday(model.repository.combinedSeries(account: model.accountID))
        let goalPct = Int((today / model.goals.daily * 100).rounded())
        let banners: [(symbol: String, tint: Color, time: String, title: String, body: String)] = [
            (Sym.sparkle, t.accent, "now", "Daily recap",
             "You've made \(Format.money(today, dp: 0)) so far today — \(goalPct)% of your goal."),
            (Sym.moon, Color(hex: "#5b6df5"), "7:02 AM", "While you slept 😴",
             "You earned \(Format.money(today * 0.4, dp: 0)) overnight across 2 networks."),
            (Sym.trophy, t.pos, "Yesterday", "Goal reached 🎉",
             "You hit your daily goal of \(Format.moneyK(model.goals.daily)). 12-day streak!"),
        ]

        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("Sunday, June 15").font(.system(size: 17, weight: .medium)).foregroundStyle(.white.opacity(0.85))
                Text("9:41").font(.system(size: 76, weight: .light)).foregroundStyle(.white.opacity(0.9))
            }
            .padding(.top, 70).padding(.bottom, 30)

            VStack(spacing: 10) {
                ForEach(Array(banners.enumerated()), id: \.offset) { _, b in
                    HStack(spacing: 11) {
                        Image(systemName: b.symbol).font(.system(size: 20)).foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(b.tint, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("AD REPORT").font(.system(size: 11.5, weight: .semibold)).foregroundStyle(.white.opacity(0.6)).tracking(0.3)
                                Spacer()
                                Text(b.time).font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
                            }
                            Text(b.title).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                            Text(b.body).font(.system(size: 14)).foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
            .padding(.horizontal, 14)

            Spacer()
            Button { dismiss() } label: {
                Text("Done").font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14).padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [Color(hex: "#1a2535"), Color(hex: "#0c1118")], startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
    }
}
