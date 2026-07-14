import Foundation

/// The two daily offices of the 1662 Book of Common Prayer that this app presents.
enum Office: String, Codable, CaseIterable {
    case morning
    case evening

    var title: String {
        switch self {
        case .morning: return "The Order for Daily Morning Prayer"
        case .evening: return "The Order for Daily Evening Prayer"
        }
    }

    var shortTitle: String {
        switch self {
        case .morning: return "Morning Prayer"
        case .evening: return "Evening Prayer"
        }
    }
}

/// Everything the app derives from "now": which office to show, and where we are in the
/// church/calendar year so the day's proper psalms and lessons can be looked up.
struct DayContext {
    let date: Date
    let office: Office
    /// 1...366, via Calendar ordinality — this is the value the daily calendar data is keyed by.
    let dayOfYear: Int
    /// 1...31, kept for a future Psalter month-cycle if the 30-day ordinary is added later.
    let dayOfMonth: Int
}
