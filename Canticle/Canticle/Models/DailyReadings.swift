import Foundation

/// The day-specific content of the office that isn't already covered by the fixed 1662 Psalter
/// cycle: the two Lessons for morning and evening, and the Collect of the Day. This is exactly the
/// shape of data you'll supply when the full 1662 lectionary calendar is ready — see
/// `Resources/Calendar/daily_readings.json` and the README for the schema. Everything here is
/// `Decodable` from that JSON file.
///
/// Note that Psalms are *not* part of this type: the 1662 Psalter is read on a fixed 30-day
/// monthly cycle independent of the calendar date, so they're sourced from `PsalterStore` by
/// day-of-month instead — see `Resources/Psalter`.
struct DailyReadings: Decodable, Identifiable {
    var id: Int { dayOfYear }

    /// 1...366, matching `DayContext.dayOfYear` (Calendar's day-of-year ordinality).
    let dayOfYear: Int
    /// Human-readable label, e.g. "13 July". Purely for display.
    let dateLabel: String
    /// Name of the Holy Day or commemoration falling on this date, if any (e.g. "Epiphany",
    /// "Lucian, P. & M."). Nil on ordinary days.
    let feastName: String?
    /// Whether this is a Kalendar "red-letter" Holy Day (a fixed feast, as opposed to an ordinary
    /// black-letter commemoration or ferial day).
    let isRedLetterDay: Bool

    let firstLessonMorning: ScriptureReading
    let secondLessonMorning: ScriptureReading
    let firstLessonEvening: ScriptureReading
    let secondLessonEvening: ScriptureReading

    /// Nil until the movable-feast-dependent Collects/Epistles/Gospels table is wired in — see
    /// the README. Days without one fall back to the same "not yet added" empty state as any
    /// other missing calendar content.
    let collectOfTheDay: Collect?

    func firstLesson(for office: Office) -> ScriptureReading {
        office == .morning ? firstLessonMorning : firstLessonEvening
    }

    func secondLesson(for office: Office) -> ScriptureReading {
        office == .morning ? secondLessonMorning : secondLessonEvening
    }
}

/// Full text of one psalm, as printed in the 1662 Psalter (Coverdale translation).
struct PsalmText: Decodable, Identifiable {
    var id: Int { number }
    /// Psalm number, e.g. 23.
    let number: Int
    /// Latin incipit, e.g. "Dominus regit me".
    let title: String
    /// Each entry is one verse, in order; the Psalter prints every verse as its own line.
    let verses: [String]
}

/// A Lesson as it comes from the calendar data — just a reference (e.g. "Genesis 1:1-19"). The
/// actual verse text is resolved at render time from `BibleStore`, not stored here, so calendar
/// entries never need to embed scripture text themselves.
struct ScriptureReading: Decodable {
    let reference: String
}

/// A Lesson reference resolved against `BibleStore` for display. Only ever constructed once the
/// text has actually been found — if a reference can't be parsed or resolved, callers fall back
/// to the same "not yet added" empty state used for missing calendar data, rather than
/// constructing one of these with nothing to show.
struct ResolvedLesson: Identifiable {
    var id: String { reference }
    let reference: String
    let text: String
}

struct Collect: Decodable {
    let title: String
    let text: String
}
