import SwiftUI

/// On-device AI "Smart insights" card with a deterministic rule-based fallback.
struct SmartInsightsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t

    @State private var ai: (headline: String, points: [String], recommendation: String)?
    @State private var loading = false
    @State private var asking = false

    var body: some View {
        let facts = buildFacts()
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: Sym.sparkle).font(.system(size: 18)).foregroundStyle(t.accent)
                Text("Smart insights").font(.system(size: 20, weight: .bold)).foregroundStyle(t.text)
                Spacer()
                if InsightEngine.isAvailable {
                    Text("On-device AI").font(.system(size: 11, weight: .semibold)).foregroundStyle(t.accent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(t.accentSoft, in: Capsule())
                }
            }
            .padding(.horizontal, 4)

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    if loading {
                        HStack(spacing: 8) { ProgressView(); Text("Analyzing…").foregroundStyle(t.sec).font(.system(size: 14)) }
                    } else {
                        let shown = ai ?? (facts.headline, facts.bullets, facts.recommendation)
                        Text(shown.0).font(.system(size: 16, weight: .bold)).foregroundStyle(t.text)
                        ForEach(Array(shown.1.enumerated()), id: \.offset) { _, p in
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(t.accent).frame(width: 5, height: 5).padding(.top, 7)
                                Text(p).font(.system(size: 14)).foregroundStyle(t.sec)
                            }
                        }
                        if !shown.2.isEmpty {
                            Text(shown.2).font(.system(size: 13.5, weight: .medium)).foregroundStyle(t.accent)
                                .padding(.top, 2)
                        }
                    }
                    if InsightEngine.isAvailable && model.isPro {
                        Button { asking = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.left.and.text.bubble.right")
                                Text("Ask about your revenue")
                            }
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(t.accent)
                        }
                        .buttonStyle(.plain).padding(.top, 4)
                    }
                }
            }
        }
        .task(id: model.accountID) { await load(facts: facts.text) }
        .sheet(isPresented: $asking) {
            AskRevenueSheet(facts: facts.text).environment(\.theme, t).tint(t.accent)
        }
    }

    private func load(facts: String) async {
        ai = nil
        #if canImport(FoundationModels)
        guard model.isPro, InsightEngine.isAvailable else { return }
        loading = true
        ai = await InsightEngine().generate(facts: facts)
        loading = false
        #endif
    }

    // MARK: facts + rule-based fallback
    private func buildFacts() -> (text: String, headline: String, bullets: [String], recommendation: String) {
        let repo = model.repository
        let acc = model.account
        let cmb = repo.combinedSeries(account: acc.id)
        let n = cmb.count
        let this7 = RevenueMath.sumN(cmb, 7)
        let prev7 = n >= 14 ? cmb[(n - 14)..<(n - 7)].reduce(0) { $0 + $1.value } : 0
        let d7 = prev7 == 0 ? 0 : (this7 - prev7) / prev7 * 100
        let this30 = RevenueMath.sumN(cmb, 30)
        let avg = this30 / 30
        let full = cmb.dropLast()
        let best = full.max { $0.value < $1.value }
        let topApp = repo.appMetrics(account: acc.id, period: .last7).first
        let split = acc.networkIDs.map { (Catalog.network($0).short, RevenueMath.sumN(repo.series(account: acc.id, network: $0), 30)) }
        let topNet = split.max { $0.1 < $1.1 }?.0 ?? "—"

        let text = """
        Account: \(acc.name)
        Last 7 days: \(Format.money(this7, dp: 0)) (\(Format.pct(d7)) vs previous 7)
        Last 30 days: \(Format.money(this30, dp: 0)), avg/day \(Format.money(avg, dp: 0))
        Best day: \(best.map { Format.money($0.value, dp: 0) } ?? "—")
        Top app (7d): \(topApp?.app.name ?? "—") at \(Format.money(topApp?.values.earnings ?? 0, dp: 0))
        Top network (30d): \(topNet)
        Daily goal: \(Format.money(model.goals.daily, dp: 0))
        """

        let headline = d7 >= 0
            ? "Revenue is up \(Format.pct(d7).replacingOccurrences(of: "+", with: "")) over last week"
            : "Revenue dipped \(Format.pct(abs(d7))) over last week"
        var bullets = [
            "7-day total \(Format.money(this7, dp: 0)), averaging \(Format.money(avg, dp: 0))/day.",
            "\(topApp?.app.name ?? "Your top app") leads, \(topNet) is your strongest network.",
        ]
        if let best { bullets.append("Best day so far: \(Format.money(best.value, dp: 0)).") }
        let rec = d7 >= 0
            ? "Keep momentum — consider scaling UA on \(topNet)."
            : "Investigate the dip: check fill rate and top-country eCPM."
        return (text, headline, bullets, rec)
    }
}

/// One-shot natural-language Q&A over the revenue summary (Foundation Models).
struct AskRevenueSheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    let facts: String

    @State private var question = ""
    @State private var answer: String?
    @State private var thinking = false

    var body: some View {
        SheetScaffold(title: "Ask about your revenue") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Ask anything about your numbers — answered privately on-device.")
                    .font(.system(size: 14)).foregroundStyle(t.sec).padding(.horizontal, 4)
                Card {
                    TextField("e.g. Which country pays best?", text: $question, axis: .vertical)
                        .font(.system(size: 16)).foregroundStyle(t.text).lineLimit(1...4)
                }
                BigButton(title: thinking ? "Thinking…" : "Ask") { Task { await ask() } }
                if let answer {
                    Card { Text(answer).font(.system(size: 15)).foregroundStyle(t.text) }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private func ask() async {
        guard !question.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        #if canImport(FoundationModels)
        thinking = true
        answer = await InsightEngine().answer(question: question, facts: facts) ?? "Couldn't generate an answer right now."
        thinking = false
        #else
        answer = "On-device AI isn't available on this device."
        #endif
    }
}
