#if canImport(ActivityKit)
import ActivityKit
import Foundation

/// Starts / updates / ends the today's-revenue Live Activity.
/// (Phase: local updates on sync; channel push can be layered on later.)
@MainActor
enum LiveActivityController {

    static var isSupported: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    static func startOrUpdate(accountName: String, data: WidgetData) {
        guard isSupported else { return }
        let state = RevenueActivityAttributes.ContentState(
            today: data.today, goalPct: data.goalPct, paceDelta: data.paceDelta)
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600))

        if let activity = Activity<RevenueActivityAttributes>.activities.first {
            Task { await activity.update(content) }
        } else {
            _ = try? Activity.request(
                attributes: RevenueActivityAttributes(accountName: accountName),
                content: content)
        }
    }

    static func end() {
        for activity in Activity<RevenueActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
#endif
