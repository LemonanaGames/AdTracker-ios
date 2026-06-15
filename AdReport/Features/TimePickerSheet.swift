import SwiftUI

/// Reminder-time sheet — pick the daily recap time (port of `TimePicker`).
struct TimePickerSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    private let times = ["7:00 AM", "8:00 AM", "9:00 AM", "12:00 PM", "6:00 PM",
                         "8:00 PM", "9:00 PM", "10:00 PM", "11:00 PM"]

    var body: some View {
        SheetScaffold(title: "Reminder time") {
            VStack(alignment: .leading, spacing: 14) {
                Text("When should we send your daily revenue recap?")
                    .font(.system(size: 14)).foregroundStyle(t.sec).padding(.horizontal, 4)
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(times.enumerated()), id: \.offset) { i, tm in
                            if i > 0 { Divider().overlay(t.hair) }
                            Button {
                                model.prefs.dailyTime = tm; dismiss()
                            } label: {
                                HStack {
                                    Text(tm).font(.system(size: 16)).foregroundStyle(t.text)
                                    Spacer()
                                    if model.prefs.dailyTime == tm {
                                        Image(systemName: Sym.check).font(.system(size: 16, weight: .bold)).foregroundStyle(t.accent)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }
}
