import SwiftUI

/// Snapshot of the values a widget / watch surface needs (port of `dataFor`).
struct WidgetData: Sendable {
    var today: Double
    var yesterday: Double
    var d7: Double
    var goalPct: Double
    var ecpm: Double
    var last7: [Double]
    var topApps: [AppMetric]

    /// Pace-delta vs yesterday.
    var paceDelta: Double {
        yesterday == 0 ? 0 : (today / Catalog.nowFraction - yesterday) / yesterday * 100
    }

    /// Build a snapshot for an account straight from the App-Group store
    /// (live cache if present, else mock). Used by widgets and the watch app.
    @MainActor
    static func forAccount(_ id: String?, persistence: Persistence = .shared)
        -> (data: WidgetData, accountName: String, goals: Goals, accent: String) {
        let goals = persistence.goals()
        let accounts = persistence.accounts().isEmpty ? Catalog.accounts : persistence.accounts()
        let acc = accounts.first { $0.id == id } ?? accounts.first ?? Catalog.accounts[0]
        let mock = MockRevenueRepository(accounts: accounts)
        let repo: any RevenueRepository = persistence.hasCache(acc.id)
            ? LiveRevenueRepository(accounts: accounts, mock: mock, cache: [acc.id: persistence.cachedRows(accountID: acc.id)])
            : mock
        return (make(repo: repo, account: acc.id, goals: goals), acc.name, goals, "#5cb7c9")
    }

    static func make(repo: any RevenueRepository, account: String, goals: Goals) -> WidgetData {
        let cmb = repo.combinedSeries(account: account)
        let tot = repo.totals(account: account, period: .today)
        return WidgetData(
            today: RevenueMath.valueToday(cmb),
            yesterday: cmb.count >= 2 ? cmb[cmb.count - 2].value : 0,
            d7: RevenueMath.sumN(cmb, 7),
            goalPct: goals.daily == 0 ? 0 : RevenueMath.valueToday(cmb) / goals.daily,
            ecpm: tot.ecpm,
            last7: RevenueMath.lastN(cmb, 7).map(\.value),
            topApps: Array(repo.appMetrics(account: account, period: .today).prefix(3))
        )
    }
}

/// Lightweight bar chart for widget surfaces (no environment dependency).
struct MiniBars: View {
    let values: [Double]
    var color: Color
    var dimLast: Bool = false
    var body: some View {
        let maxV = max(values.max() ?? 1, 1)
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: geo.size.width * 0.03) {
                ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(dimLast && i == values.count - 1 ? color.opacity(0.3) : color)
                        .frame(height: max(3, v / maxV * geo.size.height))
                        .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: geo.size.height, alignment: .bottom)
        }
    }
}

private func surface(_ theme: Theme) -> (bg: Color, text: Color, sec: Color) {
    theme.dark ? (Color(hex: "#1c1c1e"), .white, .rgba(235, 235, 245, 0.6))
               : (.white, Color(hex: "#16161a"), .rgba(60, 60, 67, 0.6))
}

// MARK: - Home widgets

struct HomeSmallPreview: View {
    let theme: Theme; let data: WidgetData
    var body: some View {
        let s = surface(theme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 5).fill(theme.accent).frame(width: 16, height: 16)
                Text("TODAY").font(.system(size: 11, weight: .bold)).foregroundStyle(s.sec).tracking(0.3)
            }
            Text(Format.money(data.today, dp: 0)).font(.system(size: 27, weight: .heavy)).foregroundStyle(s.text)
                .minimumScaleFactor(0.6).lineLimit(1).padding(.top, 10)
            Text("▲ \(Int(abs(data.paceDelta)))% pace").font(.system(size: 12, weight: .bold)).foregroundStyle(theme.pos)
            Spacer(minLength: 6)
            MiniBars(values: data.last7, color: theme.accent, dimLast: true).frame(height: 36)
        }
        .padding(16).frame(width: 158, height: 158, alignment: .topLeading)
        .background(s.bg, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

struct HomeMediumPreview: View {
    let theme: Theme; let data: WidgetData
    var body: some View {
        let s = surface(theme)
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 5).fill(theme.accent).frame(width: 16, height: 16)
                    Text("TODAY").font(.system(size: 11, weight: .bold)).foregroundStyle(s.sec)
                }
                Text(Format.money(data.today, dp: 0)).font(.system(size: 30, weight: .heavy)).foregroundStyle(s.text)
                    .minimumScaleFactor(0.6).lineLimit(1).padding(.top, 8)
                Text("▲ \(Int(abs(data.paceDelta)))% vs avg").font(.system(size: 12.5, weight: .bold)).foregroundStyle(theme.pos)
                Spacer(minLength: 4)
                Text("\(Int(data.goalPct * 100))% of daily goal").font(.system(size: 11.5)).foregroundStyle(s.sec)
                ProgressView(value: min(1, data.goalPct)).tint(theme.accent).frame(height: 5)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("LAST 7 DAYS").font(.system(size: 11, weight: .bold)).foregroundStyle(s.sec)
                    Spacer()
                    Text(Format.moneyK(data.d7)).font(.system(size: 11, weight: .bold)).foregroundStyle(s.text)
                }
                MiniBars(values: data.last7, color: theme.accent, dimLast: true)
            }
        }
        .padding(18).frame(width: 338, height: 158)
        .background(s.bg, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

struct HomeAppsPreview: View {
    let theme: Theme; let data: WidgetData
    var body: some View {
        let s = surface(theme)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(theme.accent).frame(width: 14, height: 14)
                    Text("TOP APPS · TODAY").font(.system(size: 11, weight: .bold)).foregroundStyle(s.sec)
                }
                Spacer()
                Text(Format.money(data.today, dp: 0)).font(.system(size: 11, weight: .bold)).foregroundStyle(s.text)
            }
            .padding(.bottom, 10)
            VStack(spacing: 0) {
                ForEach(data.topApps) { r in
                    HStack(spacing: 10) {
                        AppIconTile(app: r.app, size: 26, radius: 7)
                        Text(r.app.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(s.text).lineLimit(1)
                        Spacer(minLength: 4)
                        Text(Format.money(r.values.ecpm)).font(.system(size: 13.5)).foregroundStyle(s.sec)
                        Text(Format.money(r.values.earnings, dp: 0)).font(.system(size: 14, weight: .bold)).foregroundStyle(s.text)
                            .frame(minWidth: 56, alignment: .trailing)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16).frame(width: 338, height: 158)
        .background(s.bg, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

/// Lock-screen rectangular widget (rendered over a wallpaper).
struct LockRectPreview: View {
    let theme: Theme; let data: WidgetData
    var body: some View {
        HStack(spacing: 12) {
            RingView(value: data.today, goal: max(1, data.today / max(data.goalPct, 0.0001)),
                     size: 44, lineWidth: 5, color: .white, track: .white.opacity(0.25)) {
                Text("\(Int(data.goalPct * 100))").font(.system(size: 11, weight: .heavy)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("TODAY · AD REPORT").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
                Text(Format.money(data.today, dp: 0)).font(.system(size: 22, weight: .heavy)).foregroundStyle(.white)
            }
            Spacer(minLength: 0)
            Text("▲\(Int(abs(data.paceDelta)))%").font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: "#7be0a3"))
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(width: 320, height: 72)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Apple Watch

private struct WatchBezel<Content: View>: View {
    var width: CGFloat = 184; var height: CGFloat = 224
    @ViewBuilder var content: Content
    var body: some View {
        content
            .frame(width: width, height: height)
            .background(.black, in: RoundedRectangle(cornerRadius: 44, style: .continuous))
            .padding(8)
            .background(Color(hex: "#0a0a0a"), in: RoundedRectangle(cornerRadius: 52, style: .continuous))
            .shadow(color: .black.opacity(0.45), radius: 20, y: 18)
    }
}

struct WatchAppPreview: View {
    let theme: Theme; let data: WidgetData
    var body: some View {
        WatchBezel {
            VStack(spacing: 0) {
                HStack {
                    Text("Ad Report").font(.system(size: 12, weight: .semibold)).foregroundStyle(theme.accent)
                    Spacer()
                    Text("9:41").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                }
                Spacer()
                RingView(value: data.goalPct, goal: 1, size: 120, lineWidth: 11,
                         color: theme.accent, track: Color(hex: "#1c1c1e")) {
                    VStack(spacing: 0) {
                        Text("TODAY").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.6))
                        Text(Format.money(data.today, dp: 0)).font(.system(size: 23, weight: .heavy)).foregroundStyle(.white)
                            .minimumScaleFactor(0.6).lineLimit(1)
                        Text("▲\(Int(abs(data.paceDelta)))%").font(.system(size: 11, weight: .bold)).foregroundStyle(theme.pos)
                    }
                }
                Spacer()
                HStack(spacing: 7) {
                    watchStat("7D", Format.moneyK(data.d7), theme.text)
                    watchStat("eCPM", Format.money(data.ecpm), .white)
                    watchStat("GOAL", "\(Int(data.goalPct * 100))%", theme.accent)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
    }
    private func watchStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
            Text(value).font(.system(size: 12.5, weight: .bold)).foregroundStyle(color).minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 7)
        .background(Color(hex: "#1c1c1e"), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct WatchFacePreview: View {
    let theme: Theme; let data: WidgetData
    var body: some View {
        WatchBezel {
            VStack(spacing: 0) {
                HStack {
                    Text("◷ \(Format.money(data.today, dp: 0))").font(.system(size: 11, weight: .bold)).foregroundStyle(theme.accent)
                    Spacer()
                    Text("84%").font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                HStack { Spacer(); Text("9:41").font(.system(size: 50, weight: .light)).foregroundStyle(theme.accent) }
                Spacer()
                HStack(spacing: 8) {
                    RingView(value: data.goalPct, goal: 1, size: 28, lineWidth: 4,
                             color: theme.accent, track: .white.opacity(0.2))
                    VStack(alignment: .leading, spacing: 0) {
                        Text("TODAY · \(Int(data.goalPct * 100))% OF GOAL").font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.55))
                        Text(Format.money(data.today, dp: 0)).font(.system(size: 14, weight: .heavy)).foregroundStyle(.white)
                    }
                    Spacer(minLength: 0)
                }
                .padding(8).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(14)
            .background(RadialGradient(colors: [Color(hex: "#14202b"), .black], center: .top, startRadius: 0, endRadius: 220))
        }
    }
}
