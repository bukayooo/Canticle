import Foundation

/// One line/paragraph of the fixed liturgy. The Order for Morning and Evening Prayer is almost
/// entirely invariable in 1662 — the parts that change day to day (Psalms, the two Lessons, and
/// the Collect of the Day) are represented as "slots" that `DevotionalViewModel` fills in from
/// the calendar data at runtime.
struct LiturgyItem: Identifiable {
    enum Kind {
        case heading        // section title, e.g. "The Order for Daily Morning Prayer"
        case rubric         // printed instruction, traditionally in red — e.g. "Here all kneel."
        case sentence       // an opening sentence of Scripture
        case text           // a spoken paragraph (exhortation, confession, canticle body, collect)
        case versicle        // said by the Minister
        case response       // answered by the People
        case amen
        case canticleTitle  // e.g. "Venite, exultemus Domino"
        case psalmsSlot
        case firstLessonSlot
        case secondLessonSlot
        case collectSlot
        case creedSlot       // Apostles' Creed, or the Athanasian Creed on its appointed days
    }

    let id = UUID()
    let kind: Kind
    let text: String

    static func heading(_ text: String) -> LiturgyItem { .init(kind: .heading, text: text) }
    static func rubric(_ text: String) -> LiturgyItem { .init(kind: .rubric, text: text) }
    static func sentence(_ text: String) -> LiturgyItem { .init(kind: .sentence, text: text) }
    static func text(_ text: String) -> LiturgyItem { .init(kind: .text, text: text) }
    static func versicle(_ text: String) -> LiturgyItem { .init(kind: .versicle, text: text) }
    static func response(_ text: String) -> LiturgyItem { .init(kind: .response, text: text) }
    static func amen() -> LiturgyItem { .init(kind: .amen, text: "Amen.") }
    static func canticleTitle(_ text: String) -> LiturgyItem { .init(kind: .canticleTitle, text: text) }
    static let psalmsSlot = LiturgyItem(kind: .psalmsSlot, text: "")
    static let firstLessonSlot = LiturgyItem(kind: .firstLessonSlot, text: "")
    static let secondLessonSlot = LiturgyItem(kind: .secondLessonSlot, text: "")
    static let collectSlot = LiturgyItem(kind: .collectSlot, text: "")
    static let creedSlot = LiturgyItem(kind: .creedSlot, text: "")
}
