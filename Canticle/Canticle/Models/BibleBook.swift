import Foundation

/// One book of the Bible, decoded from `Resources/Bible/<slug>.json`. King James Version for the
/// 66 canonical books; the Apocrypha books (needed for some of the autumn Lessons) are from the
/// 1611 Authorized Version and keep that edition's archaic spelling — see the README.
struct BibleBook: Decodable {
    let book: String
    let chapters: [BibleChapter]

    func chapter(_ number: Int) -> BibleChapter? {
        chapters.first { $0.chapter == number }
    }
}

struct BibleChapter: Decodable {
    let chapter: Int
    /// One entry per verse, in order (index 0 is verse 1).
    let verses: [String]
}
