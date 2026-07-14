import Foundation

/// Resolves any date to its named Sunday in the 1662 Kalendar's church year (e.g. "Advent1",
/// "Trinity5", "Easter2"), the same identifiers used as anchors in the Proper Lessons and Collects
/// tables this data was sourced from. Built on top of `MovableFeasts` for the Easter-anchored
/// portion of the year, plus the fixed anchors (Advent Sunday near 30 November, Christmas Day,
/// the Epiphany) for the Advent/Christmas/Epiphany portion.
enum ChurchYear {
    /// The Sunday nearest to 30 November of the given year -- Advent Sunday, which starts the
    /// church year that continues into the following calendar year.
    static func adventSunday(year: Int, calendar: Calendar = .current) -> Date {
        let stAndrewsEve = calendar.date(from: DateComponents(year: year, month: 11, day: 30))!
        let weekday = calendar.component(.weekday, from: stAndrewsEve) // 1 = Sunday
        // Distance (possibly negative) to the nearest Sunday, choosing the earlier Sunday on a tie.
        let distance = weekday == 1 ? 0 : (weekday <= 4 ? -(weekday - 1) : 7 - (weekday - 1))
        return calendar.date(byAdding: .day, value: distance, to: stAndrewsEve)!
    }

    /// The named Sunday `date` falls on, if any (nil if `date` isn't a Sunday, or is a Sunday this
    /// table doesn't cover).
    static func namedSunday(for date: Date, calendar: Calendar = .current) -> String? {
        guard calendar.component(.weekday, from: date) == 1 else { return nil }
        let year = calendar.component(.year, from: date)
        let adventThisYear = adventSunday(year: year, calendar: calendar)
        let christmasThisYear = calendar.date(from: DateComponents(year: year, month: 12, day: 25))!

        if date >= adventThisYear {
            if date >= christmasThisYear {
                let epiphanyNextYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 6))!
                return sundayAfterChristmas(date: date, christmas: christmasThisYear, epiphany: epiphanyNextYear, calendar: calendar)
            }
            return adventSundayName(date: date, adventSunday: adventThisYear, calendar: calendar)
        }

        let epiphanyThisYear = calendar.date(from: DateComponents(year: year, month: 1, day: 6))!
        if date < epiphanyThisYear {
            let christmasPrevYear = calendar.date(from: DateComponents(year: year - 1, month: 12, day: 25))!
            return sundayAfterChristmas(date: date, christmas: christmasPrevYear, epiphany: epiphanyThisYear, calendar: calendar)
        }

        let easter = MovableFeasts.easter(forYearOf: date, calendar: calendar)
        return sundayFromEpiphanyToTrinity(date: date, easter: easter, epiphany: epiphanyThisYear, adventSunday: adventThisYear, calendar: calendar)
    }

    /// The Sunday whose Collect/Lessons govern the week containing `date` -- `date`'s own named
    /// Sunday if `date` is a Sunday, otherwise the most recent Sunday on or before it (per the 1662
    /// rubric that a Sunday's Collect "shall serve all the week following"). Doesn't account for an
    /// intervening fixed Holy Day's own Collect taking precedence -- a documented simplification.
    static func governingSunday(for date: Date, calendar: Calendar = .current) -> String? {
        let weekday = calendar.component(.weekday, from: date)
        let mostRecentSunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: date) ?? date
        return namedSunday(for: mostRecentSunday, calendar: calendar)
    }

    /// (month, day) of fixed Holy Days with their own distinct Collect, independent of whichever
    /// Sunday governs the week.
    private static let fixedHolyDays: [DateComponents: String] = [
        DateComponents(month: 1, day: 1): "Circumcision",
        DateComponents(month: 1, day: 6): "Epiphany",
        DateComponents(month: 12, day: 25): "Christmas",
        DateComponents(month: 12, day: 26): "Stephen",
        DateComponents(month: 12, day: 27): "JohnEvangelist",
        DateComponents(month: 12, day: 28): "Innocents",
    ]

    /// Movable Holy Days with their own Collect, as a day-offset from Easter.
    private static let movableHolyDays: [Int: String] = [
        -46: "AshWednesday",
        -1: "EasterEven",
        1: "EasterMonday",
        2: "EasterTuesday",
        39: "Ascension",
        50: "WhitsunMonday",
        51: "WhitsunTuesday",
    ]

    /// The fixed or movable Holy Day `date` falls on, if any -- checked ahead of `governingSunday`
    /// since a major Holy Day's own Collect takes precedence over the week's ordinary Sunday.
    static func namedHolyDay(for date: Date, calendar: Calendar = .current) -> String? {
        let components = calendar.dateComponents([.month, .day], from: date)
        if let name = fixedHolyDays[DateComponents(month: components.month, day: components.day)] {
            return name
        }
        let easter = MovableFeasts.easter(forYearOf: date, calendar: calendar)
        for (offset, name) in movableHolyDays {
            let candidate = calendar.date(byAdding: .day, value: offset, to: easter)!
            if calendar.isDate(candidate, inSameDayAs: date) { return name }
        }
        return nil
    }

    // MARK: - Advent / Christmas

    private static func adventSundayName(date: Date, adventSunday: Date, calendar: Calendar) -> String? {
        guard let days = calendar.dateComponents([.day], from: adventSunday, to: date).day else { return nil }
        let week = days / 7
        guard (0...3).contains(week) else { return nil }
        return "Advent\(week + 1)"
    }

    private static func sundayAfterChristmas(date: Date, christmas: Date, epiphany: Date, calendar: Calendar) -> String? {
        var candidate = calendar.date(byAdding: .day, value: 1, to: christmas)!
        var index = 0
        while candidate < epiphany {
            if calendar.component(.weekday, from: candidate) == 1 {
                if calendar.isDate(candidate, inSameDayAs: date) {
                    return index == 0 ? "ChristmasSunday" : "Christmas2"
                }
                index += 1
            }
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate)!
        }
        return nil
    }

    // MARK: - Epiphany through Trinity (all Easter-anchored except Epiphany's start)

    private static func sundayFromEpiphanyToTrinity(date: Date, easter: Date, epiphany: Date, adventSunday: Date, calendar: Calendar) -> String? {
        func offsetting(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: easter)!
        }
        func isDate(_ a: Date, _ b: Date) -> Bool {
            calendar.isDate(a, inSameDayAs: b)
        }

        let septuagesima = offsetting(-63)
        if date < septuagesima {
            var candidate = epiphany
            while calendar.component(.weekday, from: candidate) != 1 {
                candidate = calendar.date(byAdding: .day, value: 1, to: candidate)!
            }
            if isDate(candidate, epiphany) {
                // 6 January is itself a Sunday: Epiphany's fixed feast takes precedence, and
                // "Epiphany1" doesn't begin until the following Sunday.
                candidate = calendar.date(byAdding: .day, value: 7, to: candidate)!
            }
            var week = 0
            while candidate < septuagesima {
                if isDate(candidate, date) {
                    return week < 6 ? "Epiphany\(week + 1)" : nil
                }
                week += 1
                candidate = calendar.date(byAdding: .day, value: 7, to: candidate)!
            }
            return nil
        }

        if isDate(date, septuagesima) { return "Septuagesima" }
        if isDate(date, offsetting(-56)) { return "Sexagesima" }
        if isDate(date, offsetting(-49)) { return "Quinquagesima" }
        for week in 1...5 where isDate(date, offsetting(-49 + 7 * week)) { return "Lent\(week)" }
        if isDate(date, offsetting(-7)) { return "PalmSunday" }
        if isDate(date, easter) { return "Easter" }
        for week in 1...5 where isDate(date, offsetting(7 * week)) { return "Easter\(week)" }
        if isDate(date, offsetting(42)) { return "AscensionSunday" }
        if isDate(date, offsetting(49)) { return "WhitSunday" }
        if isDate(date, offsetting(56)) { return "Trinity" }

        let trinitySunday = offsetting(56)
        for week in 1...27 {
            let candidate = calendar.date(byAdding: .day, value: 7 * week, to: trinitySunday)!
            if candidate >= adventSunday { break }
            if isDate(candidate, date) { return "Trinity\(week)" }
        }
        return nil
    }
}
