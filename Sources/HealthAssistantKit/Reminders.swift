import Foundation

public protocol ReminderScheduling {
    func scheduleDailyReminder(identifier: String, hour: Int, minute: Int, message: String) async throws
}

public struct NoopReminderScheduler: ReminderScheduling {
    public init() {}
    public func scheduleDailyReminder(identifier: String, hour: Int, minute: Int, message: String) async throws {}
}

#if canImport(UserNotifications)
import UserNotifications

public final class ReminderScheduler: ReminderScheduling {
    public init() {}
    public func scheduleDailyReminder(identifier: String, hour: Int, minute: Int, message: String) async throws {
        let center = UNUserNotificationCenter.current()
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Health Assistant"
        content.body = message
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }
}
#endif

