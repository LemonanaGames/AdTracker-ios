import SwiftUI

/// Home tab — today's revenue, daily-goal ring, 7-day chart, overview tiles,
/// per-network cards and top apps (port of `Dashboard`).
struct DashboardView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t

    var body: some View {
        let repo = model.repository
        let acc = model.account
        let combined = repo.combinedSeries(account: acc.id)
        let today = RevenueMath.valueToday(combined)
        let yesterday = combined[combined.count - 2].value
        let projToday = today / Catalog.nowFraction
        let deltaVsYest = yesterday == 0 ? 0 : (projToday - yesterday) / yesterday * 100
        let last7 = RevenueMath.lastN(combined, 7)
        let goalPct = today / model.goals.daily

        TabScaffold {
            VStack(alignment: .leading, spacing: 18) {
                header(acc: acc)
                hero(today: today, delta: deltaVsYest, projToday: projToday)
                goalCard(today: today, goalPct: goalPct)
                chartCard(combined: combined, last7: last7)
                overview(combined: combined)
                networks(acc: acc, today: today)
                topApps(acc: acc)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: account switcher + greeting
    private func header(acc: Account) -> some View {
        HStack {
            Text("Good morning").font(.system(size: 15, weight: .medium)).foregroundStyle(t.sec)
            Spacer()
            Button { model.sheet = .accounts } label: {
                HStack(spacing: 5) {
                    Text(acc.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(t.text)
                    Image(systemName: Sym.chevronD).font(.system(size: 12, weight: .semibold)).foregroundStyle(t.sec)
                }
                .padding(.leading, 12).padding(.trailing, 8).padding(.vertical, 6)
                .glassEffect(.regular.interactive(), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: hero total
    private func hero(today: Double, delta: Double, projToday: Double) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY SO FAR").font(.system(size: 13, weight: .bold)).foregroundStyle(t.ter).tracking(0.5)
            Text(Format.money(today))
                .font(.system(size: 52, weight: .heavy)).foregroundStyle(t.text)
                .minimumScaleFactor(0.6).lineLimit(1)
            HStack(spacing: 10) {
                DeltaChip(value: delta)
                Text("vs yesterday · pace \(Format.moneyK(projToday))")
                    .font(.system(size: 13.5)).foregroundStyle(t.ter)
            }
            .padding(.top, 8)
        }
    }

    // MARK: daily goal
    private func goalCard(today: Double, goalPct: Double) -> some View {
        Card {
            HStack(spacing: 16) {
                RingView(value: today, goal: model.goals.daily, size: 64, lineWidth: 7) {
                    Text("\(Int((goalPct * 100).rounded()))%").font(.system(size: 14, weight: .heavy)).foregroundStyle(t.text)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily goal").font(.system(size: 15, weight: .bold)).foregroundStyle(t.text)
                    Text("\(Format.money(max(0, model.goals.daily - today), dp: 0)) to go · target \(Format.moneyK(model.goals.daily))")
                        .font(.system(size: 13.5)).foregroundStyle(t.sec)
                }
                Spacer(minLength: 0)
                Image(systemName: Sym.chevron).font(.system(size: 16, weight: .semibold)).foregroundStyle(t.ter)
            }
        }
        .cardTap { model.switchTo(.goals) }
    }

    // MARK: 7-day chart
    private func chartCard(combined: [DayPoint], last7: [DayPoint]) -> some View {
        Card {
            VStack(spacing: 14) {
                HStack {
                    Text("LAST 7 DAYS").font(.system(size: 12.5, weight: .bold)).foregroundStyle(t.sec).tracking(0.5)
                    Spacer()
                    Text(Format.money(RevenueMath.sumN(combined, 7), dp: 0))
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(t.text)
                }
                BarChart(data: last7.map { BarDatum(value: $0.value, dim: $0.partial) },
                         labels: last7.map { String(Format.dow[Format.jsWeekday($0.date)].prefix(1)) },
                         height: 130)
            }
        }
    }

    // MARK: overview tiles
    private func overview(combined: [DayPoint]) -> some View {
        let cells = [("TODAY", RevenueMath.valueToday(combined)),
                     ("7 DAYS", RevenueMath.sumN(combined, 7)),
                     ("30 DAYS", RevenueMath.sumN(combined, 30))]
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Overview")
            Card(padding: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { i, cell in
                        if i > 0 { Rectangle().fill(t.hair).frame(width: 1) }
                        VStack(spacing: 6) {
                            Text(cell.0).font(.system(size: 11.5, weight: .bold)).foregroundStyle(t.accent).tracking(0.4)
                            Text(Format.money(cell.1)).font(.system(size: 19, weight: .bold)).foregroundStyle(t.text)
                                .minimumScaleFactor(0.6).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 8)
                    }
                }
            }
        }
    }

    // MARK: networks
    private func networks(acc: Account, today: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Networks")
            VStack(spacing: 12) {
                ForEach(acc.networkIDs, id: \.self) { nid in
                    let net = Catalog.network(nid)
                    let s = model.repository.series(account: acc.id, network: nid)
                    let nToday = RevenueMath.valueToday(s)
                    let share = today == 0 ? 0 : nToday / today * 100
                    Card {
                        HStack(spacing: 12) {
                            NetBadge(network: net, size: 40)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(net.name).font(.system(size: 16, weight: .bold)).foregroundStyle(t.text)
                                Text("\(Int(share.rounded()))% of today").font(.system(size: 13)).foregroundStyle(t.sec)
                            }
                            Spacer(minLength: 4)
                            Sparkline(data: RevenueMath.lastN(s, 14).map(\.value), height: 30).frame(width: 78)
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(Format.money(nToday, dp: 0)).font(.system(size: 16, weight: .bold)).foregroundStyle(t.text)
                                Text("today").font(.system(size: 12)).foregroundStyle(t.ter)
                            }
                            Image(systemName: Sym.chevron).font(.system(size: 14, weight: .semibold)).foregroundStyle(t.ter)
                        }
                    }
                    .cardTap { model.push(.network(nid)) }
                }
            }
        }
    }

    // MARK: top apps
    private func topApps(acc: Account) -> some View {
        let rows = Array(model.repository.appMetrics(account: acc.id, period: .today).prefix(4))
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Top apps · today", action: "All apps") { model.switchTo(.analytics) }
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
                        if i > 0 { Divider().overlay(t.hair) }
                        Button { model.push(.app(r.app.id)) } label: {
                            HStack(spacing: 12) {
                                AppIconTile(app: r.app, size: 38)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(r.app.name).font(.system(size: 15.5, weight: .semibold)).foregroundStyle(t.text)
                                    Text("\(r.app.platform) · eCPM \(Format.money(r.values.ecpm))")
                                        .font(.system(size: 12.5)).foregroundStyle(t.ter)
                                }
                                Spacer(minLength: 4)
                                Text(Format.money(r.values.earnings, dp: 0)).font(.system(size: 15.5, weight: .bold)).foregroundStyle(t.text)
                                Image(systemName: Sym.chevron).font(.system(size: 13, weight: .semibold)).foregroundStyle(t.ter)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
