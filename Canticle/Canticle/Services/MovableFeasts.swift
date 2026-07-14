import Foundation

/// Computes Easter Day and the movable feasts whose dates are fixed relative to it, using the
/// Western (Gregorian) computus that the Church of England shares with the Roman Catholic Church
/// and most other Western churches -- the "Anonymous Gregorian algorithm" (also called the
/// Meeus/Jones/Butcher algorithm), a standard mathematical procedure rather than text from any
/// particular source.
enum MovableFeasts {
    /// Easter Day for the given year (Gregorian calendar).
    static func easter(year: Int) -> DateComponents {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return DateComponents(year: year, month: month, day: day)
    }

    static func easter(forYearOf date: Date, calendar: Calendar = .current) -> Date {
        let year = calendar.component(.year, from: date)
        return calendar.date(from: easter(year: year)) ?? date
    }

    private static func offsetting(_ days: Int, from date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// Ash Wednesday, the first day of Lent: 46 days before Easter Day.
    static func ashWednesday(forYearOf date: Date, calendar: Calendar = .current) -> Date {
        offsetting(-46, from: easter(forYearOf: date, calendar: calendar), calendar: calendar)
    }

    /// Ascension Day: the 40th day of Easter, 39 days after Easter Day.
    static func ascensionDay(forYearOf date: Date, calendar: Calendar = .current) -> Date {
        offsetting(39, from: easter(forYearOf: date, calendar: calendar), calendar: calendar)
    }

    /// Whitsunday (Pentecost): the 50th day of Easter, 49 days after Easter Day.
    static func whitsunday(forYearOf date: Date, calendar: Calendar = .current) -> Date {
        offsetting(49, from: easter(forYearOf: date, calendar: calendar), calendar: calendar)
    }

    /// Trinity Sunday: the Sunday after Whitsunday, 56 days after Easter Day.
    static func trinitySunday(forYearOf date: Date, calendar: Calendar = .current) -> Date {
        offsetting(56, from: easter(forYearOf: date, calendar: calendar), calendar: calendar)
    }

    static func isSameDay(_ date: Date, _ other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, inSameDayAs: other)
    }
}
