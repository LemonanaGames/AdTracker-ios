import SwiftUI

/// Reporting Pro paywall (port of `Paywall`). Uses RevenueCat offerings when configured,
/// otherwise a demo unlock.
struct PaywallSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @State private var plan = ""
    @State private var working = false

    private let features: [(symbol: String, title: String, sub: String)] = [
        (Sym.widget, "Widgets", "Revenue on your Home & Lock Screen"),
        (Sym.watch, "Apple Watch", "Complications and a full watch app"),
        (Sym.bell, "Smart alerts", "Sleep recaps, goals & milestones"),
        (Sym.calendar, "Full history", "Unlimited daily reports & exports"),
    ]
    private var fallbackPlans: [PlanOption] {
        [PlanOption(id: "lifetime", name: "Lifetime", price: "$29.99", sub: "One-time · best value"),
         PlanOption(id: "annual", name: "Annual", price: "$19.99/yr", sub: "$1.67/mo")]
    }
    private var plans: [PlanOption] { store.plans.isEmpty ? fallbackPlans : store.plans }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: Sym.xmark).font(.system(size: 15, weight: .bold)).foregroundStyle(t.sec)
                        .frame(width: 30, height: 30).background(t.card2, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.top, 14)

            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: Sym.sparkle).font(.system(size: 34)).foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(t.gradientH, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.bottom, 14)
                    Text("Reporting Pro").font(.system(size: 30, weight: .heavy)).foregroundStyle(t.text)
                    Text("Unlock everything. Cancel anytime.").font(.system(size: 15.5)).foregroundStyle(t.sec).padding(.top, 4)

                    VStack(spacing: 16) {
                        ForEach(features, id: \.title) { f in
                            HStack(spacing: 14) {
                                Image(systemName: f.symbol).font(.system(size: 22)).foregroundStyle(t.accent)
                                    .frame(width: 40, height: 40)
                                    .background(t.accentSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(f.title).font(.system(size: 16, weight: .bold)).foregroundStyle(t.text)
                                    Text(f.sub).font(.system(size: 13.5)).foregroundStyle(t.sec)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.top, 26).padding(.bottom, 24)

                    VStack(spacing: 10) {
                        ForEach(plans) { o in
                            planRow(o)
                        }
                    }

                    BigButton(title: working ? "…" : "Continue") { Task { await purchase() } }.padding(.top, 16)
                    Button { Task { await restore() } } label: {
                        Text("Restore purchases").font(.system(size: 13)).foregroundStyle(t.ter)
                    }
                    .buttonStyle(.plain).padding(.top, 14)
                }
                .padding(.horizontal, 18).padding(.bottom, 24)
            }
        }
        .background(t.bg)
        .onAppear { if plan.isEmpty { plan = plans.first?.id ?? "" } }
    }

    private func purchase() async {
        working = true
        if store.isConfigured {
            if await store.purchase(planID: plan) { model.isPro = true; dismiss() }
        } else {
            model.isPro = true; dismiss()   // demo
        }
        working = false
    }

    private func restore() async {
        if store.isConfigured {
            if await store.restore() { model.isPro = true; dismiss() }
        }
    }

    private func planRow(_ o: PlanOption) -> some View {
        let sel = plan == o.id
        return Button { plan = o.id } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(sel ? t.accent : t.ter, lineWidth: 2).frame(width: 24, height: 24)
                    if sel { Circle().fill(t.accent).frame(width: 24, height: 24)
                        .overlay(Image(systemName: Sym.check).font(.system(size: 11, weight: .heavy)).foregroundStyle(t.accentText)) }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(o.name).font(.system(size: 16, weight: .bold)).foregroundStyle(t.text)
                    Text(o.sub).font(.system(size: 13)).foregroundStyle(t.sec)
                }
                Spacer()
                Text(o.price).font(.system(size: 17, weight: .heavy)).foregroundStyle(t.text)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(sel ? t.accentSoft : .clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(sel ? t.accent : t.hair, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}
