import Foundation

/// User notification preferences (the Notifications screen).
struct NotificationPrefs: Equatable, Sendable {
    var daily = true
    var dailyTime = "9:00 PM"
    var sleep = true
    var away = true
    var goal = true
    var mover = false
    var milestone: Double = 5000
}
