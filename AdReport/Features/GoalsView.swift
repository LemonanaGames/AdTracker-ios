import SwiftUI

/// One cadence's progress snapshot.
struct GoalStat {
    let mode: ReportMode
    let current: Double
    let goal: Double
    let frac: Double          // fraction of the period elapsed
    let label: String
    var pct: Double { goal == 0 ? 0 : current / goal }
    var projected: Double { frac == 0 ? current : current / frac }
    var onPace: Bool { projected >= goal }
}

/// Goals tab — hero daily ring, streak, and weekly/monthly/yearly cards (port of `Goals`).
struct GoalsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t

    var body: some View {
        TabScaffold(title: "Goals") {
            if !model.hasAccounts { ConnectEmptyView() }
            else if !model.accountHasData { AccountEmptyView() }
            else { content() }
        }
    }

    @ViewBuilder private func content() -> some View {
        let combined = model.repository.combinedSeries(account: model.accountID)
        let stats = Self.periodStats(combined: combined, goals: model.goals)
        let daily = stats[.daily] ?? GoalStat(mode: .daily, current: 0, goal: model.goals.daily,
                                              frac: Catalog.nowFraction, label: "Today")

        VStack(alignment: .leading, spacing: 18) {
            heroCard(daily)
            streakCard
            SectionTitle(title: "All goals", action: "Edit") { model.sheet = .editGoal(.daily) }
            VStack(spacing: 12) {
                periodCard(stats[.weekly] ?? daily)
                periodCard(stats[.monthly] ?? daily)
                periodCard(stats[.yearly] ?? daily)
            }
        }
        .padding(.horizontal, 16)
    }

    private func heroCard(_ d: GoalStat) -> some View {
        Card {
            VStack(spacing: 18) {
                RingView(value: d.current, goal: d.goal, size: 196, lineWidth: 18,
                         color: d.onPace ? t.pos : t.accent) {
                    VStack(spacing: 2) {
                        Text("TODAY").font(.system(size: 12, weight: .bold)).foregroundStyle(t.ter).tracking(0.5)
                        Text(Format.money(d.current, dp: 0)).font(.system(size: 34, weight: .heavy)).foregroundStyle(t.text)
                        Text("of \(Format.moneyK(d.goal)) goal").font(.system(size: 13)).foregroundStyle(t.sec)
                    }
                }
                VStack(spacing: 3) {
                    Text("\(Int((d.pct * 100).rounded()))% complete")
                        .font(.system(size: 20, weight: .heavy)).foregroundStyle(d.onPace ? t.pos : t.text)
                    Text(d.onPace
                         ? "On track — pacing to \(Format.moneyK(d.projected)) today"
                         : "\(Format.money(d.goal - d.current, dp: 0)) to go · pacing \(Format.moneyK(d.projected))")
                        .font(.system(size: 14)).foregroundStyle(t.sec).multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var streakCard: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: Sym.flame).font(.system(size: 24)).foregroundStyle(Color(hex: "#ff9f43"))
                    .frame(width: 46, height: 46)
                    .background(Color(hex: "#ff9f43").opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text("12-day goal streak 🔥").font(.system(size: 16, weight: .bold)).foregroundStyle(t.text)
                    Text("You've hit your daily goal 12 days running").font(.system(size: 13.5)).foregroundStyle(t.sec)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func periodCard(_ s: GoalStat) -> some View {
        Card {
            HStack(spacing: 16) {
                RingView(value: s.current, goal: s.goal, size: 62, lineWidth: 7,
                         color: s.onPace ? t.pos : t.accent) {
                    Text("\(Int((min(1, s.pct) * 100).rounded()))%").font(.system(size: 13, weight: .heavy)).foregroundStyle(t.text)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(s.mode.label).font(.system(size: 15.5, weight: .bold)).foregroundStyle(t.text)
                        Spacer()
                        Text(s.label).font(.system(size: 13)).foregroundStyle(t.sec)
                    }
                    Text("\(Format.moneyK(s.current)) of \(Format.moneyK(s.goal))").font(.system(size: 14)).foregroundStyle(t.sec)
                    Text(s.onPace ? "✓ On pace" : "Projected \(Format.moneyK(s.projected))")
                        .font(.system(size: 12.5, weight: .semibold)).foregroundStyle(s.onPace ? t.pos : t.ter)
                }
                Button { model.sheet = .editGoal(s.mode) } label: {
                    Image(systemName: Sym.chevron).font(.system(size: 13, weight: .semibold)).foregroundStyle(t.sec)
                        .frame(width: 32, height: 32).background(t.card2, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: period stats (port of `periodStats`)
    static func periodStats(combined: [DayPoint], goals: Goals,
                            nowFraction: Double = Catalog.nowFraction) -> [ReportMode: GoalStat] {
        let cal = Calendar.utc
        guard let today = combined.last else { return [:] }
        let dt = today.date
        let n = combined.count

        // weekly (Mon start)
        let dowMon = (Format.jsWeekday(dt) + 6) % 7
        var wk = 0.0
        for i in 0...dowMon where n - 1 - i >= 0 { wk += combined[n - 1 - i].value }
        let wkFrac = (Double(dowMon) + nowFraction) / 7

        // monthly
        let dom = cal.component(.day, from: dt)
        var mo = 0.0
        for i in 0..<dom where n - 1 - i >= 0 { mo += combined[n - 1 - i].value }
        let daysInMonth = cal.range(of: .day, in: .month, for: dt)?.count ?? 30
        let moFrac = (Double(dom - 1) + nowFraction) / Double(daysInMonth)

        // yearly
        let year = cal.component(.year, from: dt)
        let doy = cal.ordinality(of: .day, in: .year, for: dt) ?? 1
        let yr = combined.filter { cal.component(.year, from: $0.date) == year }.reduce(0) { $0 + $1.value }
        let yrFrac = (Double(doy - 1) + nowFraction) / 365

        return [
            .daily:   GoalStat(mode: .daily,   current: today.value, goal: goals.daily,   frac: nowFraction, label: "Today"),
            .weekly:  GoalStat(mode: .weekly,  current: wk,          goal: goals.weekly,  frac: wkFrac,      label: "This week"),
            .monthly: GoalStat(mode: .monthly, current: mo,          goal: goals.monthly, frac: moFrac,      label: Format.monthName(cal.component(.month, from: dt) - 1)),
            .yearly:  GoalStat(mode: .yearly,  current: yr,          goal: goals.yearly,  frac: yrFrac,      label: "\(year)"),
        ]
    }
}
