import Foundation

/// Loads the fixed 1662 Psalter (all 150 psalms, Coverdale translation) and its 30-day reading
/// cycle from `Resources/Psalter`, and resolves which psalms are appointed for a given
/// day-of-month and office.
///
/// Unlike the lectionary calendar, this data doesn't depend on the calendar date — the Psalter
/// cycle repeats every month — so it ships complete rather than as a sample.
///
/// Also loads a Hebrew psalms_hebrew.json (natural Masoretic verse divisions, not KJV-aligned
/// like `BibleStore`'s copy, since the Psalter always shows a complete psalm rather than a verse
/// range) and returns that instead when `BibleStore.useOriginalLanguages` is on - the Psalms are
/// part of the Hebrew canon, unlike the Apocrypha, so this always has a Hebrew counterpart.
@MainActor
final class PsalterStore: ObservableObject {
    static let shared = PsalterStore()

    private var psalmsByNumber: [Int: PsalmText] = [:]
    private var hebrewPsalmsByNumber: [Int: PsalmText] = [:]
    private var cycleByDayAndOffice: [Int: [Office: [Int]]] = [:]
    private let bibleStore: BibleStore

    init(bundle: Bundle = .main, bibleStore: BibleStore = .shared) {
        self.bibleStore = bibleStore
        load(from: bundle)
    }

    /// The psalms appointed for the given day-of-month (1...31) and office.
    func psalms(dayOfMonth: Int, office: Office) -> [PsalmText] {
        let day = dayOfMonth == 31 ? 30 : dayOfMonth
        let numbers = cycleByDayAndOffice[day]?[office] ?? []
        let byNumber = bibleStore.useOriginalLanguages ? hebrewPsalmsByNumber : psalmsByNumber
        return numbers.compactMap { byNumber[$0] }
    }

    private func load(from bundle: Bundle) {
        guard
            let psalmsURL = bundle.url(forResource: "psalms", withExtension: "json", subdirectory: "Psalter")
                ?? bundle.url(forResource: "psalms", withExtension: "json"),
            let cycleURL = bundle.url(forResource: "psalter_cycle", withExtension: "json", subdirectory: "Psalter")
                ?? bundle.url(forResource: "psalter_cycle", withExtension: "json")
        else {
            assertionFailure("Psalter JSON missing from bundle resources")
            return
        }
        do {
            let psalmsData = try Data(contentsOf: psalmsURL)
            let psalms = try JSONDecoder().decode([PsalmText].self, from: psalmsData)
            psalmsByNumber = Dictionary(uniqueKeysWithValues: psalms.map { ($0.number, $0) })

            let cycleData = try Data(contentsOf: cycleURL)
            let cycle = try JSONDecoder().decode([PsalterCycleEntry].self, from: cycleData)
            for entry in cycle {
                cycleByDayAndOffice[entry.day, default: [:]][entry.office] = entry.psalms
            }
        } catch {
            assertionFailure("Failed to decode Psalter JSON: \(error)")
        }

        guard let hebrewURL = bundle.url(forResource: "psalms_hebrew", withExtension: "json", subdirectory: "Psalter")
            ?? bundle.url(forResource: "psalms_hebrew", withExtension: "json"),
            let hebrewData = try? Data(contentsOf: hebrewURL),
            let hebrewPsalms = try? JSONDecoder().decode([PsalmText].self, from: hebrewData)
        else {
            assertionFailure("Hebrew Psalter JSON missing from bundle resources")
            return
        }
        hebrewPsalmsByNumber = Dictionary(uniqueKeysWithValues: hebrewPsalms.map { ($0.number, $0) })
    }
}
