import SwiftUI

@main
struct AdReportWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(\.theme, .midnight)
        }
    }
}
