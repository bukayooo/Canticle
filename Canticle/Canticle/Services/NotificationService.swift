import Foundation
import UserNotifications

/// Manages the optional daily local-notification reminders for Morning and Evening Prayer.
///
/// Each office has its own enabled flag and time-of-day, persisted independently so a user can,
/// for example, be reminded for Evening Prayer only. Scheduling uses a repeating
/// `UNCalendarNotificationTrigger` keyed to hour/minute, so once scheduled it keeps firing daily
/// without the app needing to run — `didSet` on the published properties is the only place
/// (re)scheduling happens, mirroring how `BibleStore.useOriginalLanguages` colocates persistence
/// with its side effect.
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var morningReminderEnabled: Bool {
        didSet {
            guard morningReminderEnabled != oldValue else { return }
            UserDefaults.standard.set(morningReminderEnabled, forKey: Self.morningEnabledKey)
            updateReminder(for: .morning)
        }
    }

    @Published var morningReminderTime: Date {
        didSet {
            UserDefaults.standard.set(morningReminderTime, forKey: Self.morningTimeKey)
            if morningReminderEnabled { updateReminder(for: .morning) }
        }
    }

    @Published var eveningReminderEnabled: Bool {
        didSet {
            guard eveningReminderEnabled != oldValue else { return }
            UserDefaults.standard.set(eveningReminderEnabled, forKey: Self.eveningEnabledKey)
            updateReminder(for: .evening)
        }
    }

    @Published var eveningReminderTime: Date {
        didSet {
            UserDefaults.standard.set(eveningReminderTime, forKey: Self.eveningTimeKey)
            if eveningReminderEnabled { updateReminder(for: .evening) }
        }
    }

    private static let morningEnabledKey = "morningReminderEnabled"
    private static let morningTimeKey = "morningReminderTime"
    private static let eveningEnabledKey = "eveningReminderEnabled"
    private static let eveningTimeKey = "eveningReminderTime"

    private static let morningIdentifier = "morningPrayerReminder"
    private static let eveningIdentifier = "eveningPrayerReminder"

    private static let defaultMorningTime = time(hour: 7, minute: 0)
    private static let defaultEveningTime = time(hour: 18, minute: 0)

    private static func time(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private init() {
        let defaults = UserDefaults.standard
        morningReminderEnabled = defaults.bool(forKey: Self.morningEnabledKey)
        morningReminderTime = defaults.object(forKey: Self.morningTimeKey) as? Date ?? Self.defaultMorningTime
        eveningReminderEnabled = defaults.bool(forKey: Self.eveningEnabledKey)
        eveningReminderTime = defaults.object(forKey: Self.eveningTimeKey) as? Date ?? Self.defaultEveningTime
    }

    private func updateReminder(for office: Office) {
        let identifier = office == .morning ? Self.morningIdentifier : Self.eveningIdentifier
        let enabled = office == .morning ? morningReminderEnabled : eveningReminderEnabled
        let time = office == .morning ? morningReminderTime : eveningReminderTime

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard enabled else { return }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            guard granted else { return }
            Task { @MainActor in
                self?.schedule(identifier: identifier, office: office, time: time)
            }
        }
    }

    private func schedule(identifier: String, office: Office, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Canticle"
        content.body = "It's time for \(office.shortTitle.lowercased())."
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
