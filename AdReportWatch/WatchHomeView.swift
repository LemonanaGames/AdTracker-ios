import SwiftUI

/// watchOS glance — today's revenue ring + 7d / eCPM / goal tiles.
/// Reads the App-Group cache written by the phone's sync.
struct WatchHomeView: View {
    @Environment(\.theme) private var t
    @State private var data: WidgetData?
    @State private var accountName: String = ""

    var body: some View {
        ScrollView {
            if let d = data {
                VStack(spacing: 12) {
                    Text(accountName.isEmpty ? "Ad Report" : accountName)
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(t.accent)

                    Gauge(value: min(1, d.goalPct)) {
                    } currentValueLabel: {
                        VStack(spacing: 0) {
                            Text(Format.money(d.today, dp: 0)).font(.system(size: 22, weight: .heavy))
                                .minimumScaleFactor(0.5).lineLimit(1)
                            Text("▲\(Int(abs(d.paceDelta)))%").font(.system(size: 11, weight: .bold)).foregroundStyle(t.pos)
                        }
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(t.accent)
                    .frame(width: 120, height: 120)

                    HStack(spacing: 6) {
                        tile("7D", Format.moneyK(d.d7))
                        tile("eCPM", Format.money(d.ecpm))
                        tile("GOAL", "\(Int(d.goalPct * 100))%")
                    }
                }
                .padding(.horizontal, 4)
            } else {
                ProgressView()
            }
        }
        .task {
            let r = WidgetData.forAccount(nil)
            data = r.data
            accountName = r.accountName
        }
    }

    private func tile(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 12.5, weight: .bold)).minimumScaleFactor(0.5).lineLimit(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 7)
        .background(t.card, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}
