import Foundation

/// Loads `Resources/Calendar/collects.json` -- the Collects from "The Collects, Epistles, and
/// Gospels", keyed by the same named-Sunday/Holy-Day identifiers `ChurchYear` resolves dates to.
/// Only the Collect itself is stored; the Epistle and Gospel aren't (see the README -- they
/// belong to the Communion service, which Canticle doesn't implement).
@MainActor
final class CollectsStore: ObservableObject {
    static let shared = CollectsStore()

    private struct CollectEntry: Decodable {
        let name: String
        let title: String
        let text: String
    }

    private var collectsByName: [String: Collect] = [:]

    init(bundle: Bundle = .main) {
        load(from: bundle)
    }

    /// The Collect for a named Sunday or Holy Day, if there is one. The source table only defines
    /// distinct Collects through "Trinity25" even though `ChurchYear` can name Sundays up to
    /// "Trinity27" in years with an early Easter -- per the 1662 rubric's general practice of
    /// continuing the last Sunday's Collect, "Trinity26"/"Trinity27" fall back to "Trinity25".
    func collect(for name: String) -> Collect? {
        if let found = collectsByName[name] { return found }
        if name == "Trinity26" || name == "Trinity27" { return collectsByName["Trinity25"] }
        return nil
    }

    private func load(from bundle: Bundle) {
        guard let url = bundle.url(forResource: "collects", withExtension: "json", subdirectory: "Calendar")
            ?? bundle.url(forResource: "collects", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([CollectEntry].self, from: data)
        else {
            assertionFailure("collects.json missing from bundle resources")
            return
        }
        collectsByName = Dictionary(uniqueKeysWithValues: entries.map { ($0.name, Collect(title: $0.title, text: $0.text)) })
    }
}
