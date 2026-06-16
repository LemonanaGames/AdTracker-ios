import WidgetKit
import SwiftUI
import AppIntents

/// Opens the app from the Control / Lock Screen control.
struct OpenAdReportIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Ad Report"
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult { .result() }
}

/// Control Center / Lock-Screen control that launches straight into today's revenue.
struct RevenueControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.millionappz.adreport.control") {
            ControlWidgetButton(action: OpenAdReportIntent()) {
                Label("Ad Report", systemImage: "chart.bar.fill")
            }
        }
        .displayName("Ad Report")
        .description("Open today's revenue.")
    }
}
