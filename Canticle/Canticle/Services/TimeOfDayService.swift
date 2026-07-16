import Foundation

/// Determines which office to show and where "today" sits in the calendar year.
enum TimeOfDayService {
    /// The hour (24h clock) at which the app switches from Morning to Evening Prayer.
    static let noonCutoffHour = 15

    static func currentContext(now: Date = Date(), calendar: Calendar = .current) -> DayContext {
        let hour = calendar.component(.hour, from: now)
        let office: Office = hour < noonCutoffHour ? .morning : .evening
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let dayOfMonth = calendar.component(.day, from: now)
        return DayContext(date: now, office: office, dayOfYear: dayOfYear, dayOfMonth: dayOfMonth)
    }
}
