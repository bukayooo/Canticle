import Foundation
import Combine

/// One rendered row of the scrollview: either a fixed liturgy line, or one of the day-specific
/// inserts (psalms / lessons / collect) resolved against whatever calendar data is available.
enum DisplayBlock: Identifiable {
    case liturgy(LiturgyItem)
    case psalms([PsalmText])
    case lesson(ResolvedLesson)
    case collect(Collect)
    case missingDailyContent(kind: MissingKind)

    enum MissingKind {
        case psalms, firstLesson, secondLesson, collect
        /// The 1662 Kalendar appoints separate Proper Lessons for Sundays (which depend on the
        /// date of Easter each year) instead of the fixed weekday Lessons — Canticle doesn't
        /// calculate those yet, so Sundays intentionally show this instead of the ferial Lesson.
        case sundayLessonNotImplemented
    }

    var id: String {
        switch self {
        case .liturgy(let item): return "liturgy-\(item.id)"
        case .psalms(let psalms): return "psalms-\(psalms.map(\.number))"
        case .lesson(let reading): return "lesson-\(reading.reference)"
        case .collect(let collect): return "collect-\(collect.title)"
        case .missingDailyContent(let kind): return "missing-\(kind)"
        }
    }
}

@MainActor
final class DevotionalViewModel: ObservableObject {
    @Published private(set) var context: DayContext
    @Published private(set) var blocks: [DisplayBlock] = []

    private let calendarStore: CalendarStore
    private let psalterStore: PsalterStore
    private let bibleStore: BibleStore
    private let properSundayStore: ProperSundayStore
    private let collectsStore: CollectsStore

    init(
        calendarStore: CalendarStore = .shared,
        psalterStore: PsalterStore = .shared,
        bibleStore: BibleStore = .shared,
        properSundayStore: ProperSundayStore = .shared,
        collectsStore: CollectsStore = .shared,
        now: Date = Date()
    ) {
        self.calendarStore = calendarStore
        self.psalterStore = psalterStore
        self.bibleStore = bibleStore
        self.properSundayStore = properSundayStore
        self.collectsStore = collectsStore
        self.context = TimeOfDayService.currentContext(now: now)
        rebuild()
    }

    /// Re-checks the clock and rebuilds the displayed office. Call when the app returns to the
    /// foreground so the office flips from Morning to Evening (or into a new day) without
    /// requiring a relaunch.
    func refresh(now: Date = Date()) {
        context = TimeOfDayService.currentContext(now: now)
        rebuild()
    }

    #if DEBUG
    /// Lets the UI preview the other office without waiting for the clock — debug builds only.
    func debugSetOffice(_ office: Office) {
        context = DayContext(date: context.date, office: office, dayOfYear: context.dayOfYear, dayOfMonth: context.dayOfMonth)
        rebuild()
    }
    #endif

    private func rebuild() {
        let fixedLiturgy = context.office == .morning ? MorningPrayer.items : EveningPrayer.items
        let readings = calendarStore.readings(for: context.dayOfYear)
        let isSunday = Calendar.current.component(.weekday, from: context.date) == 1

        let psalms = psalterStore.psalms(dayOfMonth: context.dayOfMonth, office: context.office)

        blocks = fixedLiturgy.flatMap { item -> [DisplayBlock] in
            switch item.kind {
            case .psalmsSlot:
                guard !psalms.isEmpty else { return [.missingDailyContent(kind: .psalms)] }
                return [.psalms(psalms)]
            case .firstLessonSlot:
                if isSunday {
                    guard let properReading = properLesson(readings: readings, isFirst: true) else {
                        return [.missingDailyContent(kind: .sundayLessonNotImplemented)]
                    }
                    guard let resolved = resolveLesson(properReading) else {
                        return [.missingDailyContent(kind: .firstLesson)]
                    }
                    return [.lesson(resolved)]
                }
                guard let readings, let resolved = resolveLesson(readings.firstLesson(for: context.office)) else {
                    return [.missingDailyContent(kind: .firstLesson)]
                }
                return [.lesson(resolved)]
            case .secondLessonSlot:
                if isSunday {
                    guard let properReading = properLesson(readings: readings, isFirst: false) else {
                        return [.missingDailyContent(kind: .sundayLessonNotImplemented)]
                    }
                    guard let resolved = resolveLesson(properReading) else {
                        return [.missingDailyContent(kind: .secondLesson)]
                    }
                    return [.lesson(resolved)]
                }
                guard let readings, let resolved = resolveLesson(readings.secondLesson(for: context.office)) else {
                    return [.missingDailyContent(kind: .secondLesson)]
                }
                return [.lesson(resolved)]
            case .collectSlot:
                if let holyDayName = ChurchYear.namedHolyDay(for: context.date), let collect = collectsStore.collect(for: holyDayName) {
                    return [.collect(collect)]
                }
                if let sundayName = ChurchYear.governingSunday(for: context.date), let collect = collectsStore.collect(for: sundayName) {
                    return [.collect(collect)]
                }
                guard let readings, let collect = readings.collectOfTheDay else {
                    return [.missingDailyContent(kind: .collect)]
                }
                return [.collect(collect)]
            case .creedSlot:
                if AthanasianCreed.isAppointed(on: context.date) {
                    return [.liturgy(.heading(AthanasianCreed.title)), .liturgy(.text(AthanasianCreed.text))]
                } else {
                    return [.liturgy(.heading("Then the Apostles' Creed")), .liturgy(.text(ApostlesCreed.text))]
                }
            default:
                return [.liturgy(item)]
            }
        }
    }

    /// For Sundays: resolves the appropriate Lesson from the Proper Sunday table. Falls back to
    /// the ordinary Kalendar's Second Lesson when the Proper table doesn't override it, which is
    /// true for all but a handful of major Sundays -- see `ProperSundayEntry`. Returns nil if
    /// today isn't a named Sunday at all (a rare edge case) or, for the Second Lesson, if there's
    /// also no ordinary Kalendar data to fall back to.
    private func properLesson(readings: DailyReadings?, isFirst: Bool) -> ScriptureReading? {
        guard let name = ChurchYear.namedSunday(for: context.date),
              let proper = properSundayStore.lessons(for: name)
        else { return nil }
        if isFirst {
            return proper.firstLesson(for: context.office)
        }
        return proper.secondLesson(for: context.office) ?? readings?.secondLesson(for: context.office)
    }

    /// Resolves a calendar-supplied reference (e.g. "Genesis 1:1-19") against `BibleStore`.
    /// Returns nil if the reference doesn't parse or the passage isn't bundled, so the caller can
    /// fall back to the same "not yet added" empty state used for missing calendar data.
    private func resolveLesson(_ reading: ScriptureReading) -> ResolvedLesson? {
        guard let ref = ScriptureRef(reading.reference),
              let text = bibleStore.text(for: ref)
        else { return nil }
        return ResolvedLesson(reference: reading.reference, text: text)
    }
}
