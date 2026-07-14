import Foundation

/// Loads the daily lectionary calendar from `Resources/Calendar/daily_readings.json` and looks up
/// a given day's readings by day-of-year.
///
/// Covers all 365 days of the fixed (ferial) Kalendar of Lessons — see the README for sourcing
/// and the known Sunday/Collect limitations.
@MainActor
final class CalendarStore: ObservableObject {
    static let shared = CalendarStore()

    private(set) var readingsByDayOfYear: [Int: DailyReadings] = [:]

    init(bundle: Bundle = .main) {
        load(from: bundle)
    }

    func readings(for dayOfYear: Int) -> DailyReadings? {
        readingsByDayOfYear[dayOfYear]
    }

    private func load(from bundle: Bundle) {
        guard let url = bundle.url(forResource: "daily_readings", withExtension: "json") else {
            assertionFailure("daily_readings.json missing from bundle resources")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let entries = try JSONDecoder().decode([DailyReadings].self, from: data)
            readingsByDayOfYear = Dictionary(uniqueKeysWithValues: entries.map { ($0.dayOfYear, $0) })
        } catch {
            assertionFailure("Failed to decode daily_readings.json: \(error)")
        }
    }
}
