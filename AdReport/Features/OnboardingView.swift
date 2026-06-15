import SwiftUI

/// Lightweight first-run welcome → connect flow. Swipeable highlights with persistent CTAs.
struct OnboardingView: View {
    @Environment(\.theme) private var t
    let onConnect: () -> Void
    let onSkip: () -> Void
    @State private var page = 0

    private struct Page: Identifiable { let id = UUID(); let symbol: String; let title: String; let subtitle: String }
    private let pages = [
        Page(symbol: "chart.bar.xaxis", title: "See every dollar",
             subtitle: "Track your ad revenue in real time — today, this week, this month, by app, country and network."),
        Page(symbol: "antenna.radiowaves.left.and.right", title: "AppLovin MAX & AdMob",
             subtitle: "Connect your networks and pull live earnings straight from their Reporting APIs."),
        Page(symbol: "target", title: "Goals, widgets & watch",
             subtitle: "Set revenue goals, glance at your Home Screen, Lock Screen and Apple Watch, and get smart alerts."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { i, p in
                    pageView(p).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 10) {
                BigButton(title: "Connect a network", leadingSymbol: Sym.plus, action: onConnect)
                Button(action: onSkip) {
                    Text("Maybe later").font(.system(size: 15, weight: .semibold)).foregroundStyle(t.sec)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(t.bg.ignoresSafeArea())
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: p.symbol)
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(t.accent)
                .frame(width: 130, height: 130)
                .background(t.accentSoft, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
            Text(p.title)
                .font(.system(size: 28, weight: .heavy)).foregroundStyle(t.text)
                .multilineTextAlignment(.center)
            Text(p.subtitle)
                .font(.system(size: 16)).foregroundStyle(t.sec)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
