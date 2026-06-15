import Foundation
import UserNotifications

/// Local notifications: daily recap reminder + on-demand alerts (goal / milestone / mover).
@MainActor
enum NotificationScheduler {

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Schedule (or clear) the repeating daily recap at the user's chosen time.
    static func scheduleDaily(_ prefs: NotificationPrefs) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily.recap"])
        guard prefs.daily, let (hour, minute) = parseTime(prefs.dailyTime) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily recap"
        content.body = "See how much you've earned today."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour; comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "daily.recap", content: content, trigger: trigger))
    }

    /// Fire an immediate local alert (used by sync when a goal/milestone is crossed).
    static func notify(title: String, body: String, id: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: nil))
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f
    }()

    static func parseTime(_ s: String) -> (hour: Int, minute: Int)? {
        guard let date = timeFormatter.date(from: s) else { return nil }
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let h = c.hour, let m = c.minute else { return nil }
        return (h, m)
    }
}
