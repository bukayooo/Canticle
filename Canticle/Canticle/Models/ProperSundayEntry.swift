import Foundation

/// The Proper Lessons appointed for a named Sunday (e.g. "Trinity5"), overriding the ordinary
/// fixed Kalendar's First Lesson at both offices. Most Sundays only override the First Lesson --
/// `secondLessonMorning`/`secondLessonEvening` are nil except on the handful of major Sundays
/// (Septuagesima, Palm Sunday, Easter Day, Easter1, Whitsunday, Trinity Sunday) that also have a
/// Proper Second Lesson; elsewhere the Second Lesson still follows the ordinary Kalendar course.
struct ProperSundayEntry: Decodable {
    let name: String
    let firstLessonMorning: ScriptureReading
    let firstLessonEvening: ScriptureReading
    let secondLessonMorning: ScriptureReading?
    let secondLessonEvening: ScriptureReading?

    func firstLesson(for office: Office) -> ScriptureReading {
        office == .morning ? firstLessonMorning : firstLessonEvening
    }

    /// Nil means "not proper here -- use the ordinary Kalendar's Second Lesson for today".
    func secondLesson(for office: Office) -> ScriptureReading? {
        office == .morning ? secondLessonMorning : secondLessonEvening
    }
}
