#if canImport(ActivityKit)
import ActivityKit
import Foundation

/// Live Activity attributes for today's revenue (shared between the app, which starts/updates
/// the activity, and the widget extension, which renders it).
struct RevenueActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var today: Double
        var goalPct: Double
        var paceDelta: Double
    }
    var accountName: String
}
#endif
