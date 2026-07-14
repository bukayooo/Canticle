import Foundation

/// Loads `Resources/Calendar/proper_sundays.json` -- the Lessons Proper for Sundays, keyed by the
/// same named-Sunday identifiers `ChurchYear` resolves a date to (e.g. "Trinity5").
@MainActor
final class ProperSundayStore: ObservableObject {
    static let shared = ProperSundayStore()

    private var entriesByName: [String: ProperSundayEntry] = [:]

    init(bundle: Bundle = .main) {
        load(from: bundle)
    }

    func lessons(for name: String) -> ProperSundayEntry? {
        entriesByName[name]
    }

    private func load(from bundle: Bundle) {
        guard let url = bundle.url(forResource: "proper_sundays", withExtension: "json", subdirectory: "Calendar")
            ?? bundle.url(forResource: "proper_sundays", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([ProperSundayEntry].self, from: data)
        else {
            assertionFailure("proper_sundays.json missing from bundle resources")
            return
        }
        entriesByName = Dictionary(uniqueKeysWithValues: entries.map { ($0.name, $0) })
    }
}
