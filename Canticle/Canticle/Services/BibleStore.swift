import Foundation

/// Loads Bible text on demand from the per-book JSON files in `Resources/Bible` and resolves
/// references (including the abbreviated book names used in the 1662 Kalendar's Table of
/// Lessons, e.g. "Gen.", "1 Cor.", "Ecclus.") to their text.
///
/// King James Version for the 66 canonical books; the Apocrypha books are from the 1611
/// Authorized Version and keep that edition's archaic spelling (see the README) — a handful of
/// autumn Lessons in the 1662 Kalendar are appointed from the Apocrypha.
@MainActor
final class BibleStore: ObservableObject {
    static let shared = BibleStore()

    private struct ManifestEntry: Decodable {
        let book: String
        let slug: String
        let chapterCount: Int
        let isApocrypha: Bool
    }

    private var canonicalNameByNormalizedKey: [String: String] = [:]
    private var slugByCanonicalName: [String: String] = [:]
    private var loadedBooks: [String: BibleBook] = [:]
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        loadManifest()
    }

    /// Resolves a book name or common abbreviation (e.g. "Gen", "1 Cor", "Ecclus") to the
    /// canonical name used by the bundled data (e.g. "Genesis", "1 Corinthians", "Ecclesiasticus").
    func canonicalBookName(for input: String) -> String? {
        canonicalNameByNormalizedKey[Self.normalize(input)]
    }

    /// Full text for a parsed reference, verses joined into continuous prose (as Lessons are
    /// read), or nil if the book/chapter/verses aren't found. Spans multiple chapters when the
    /// reference does (e.g. "Genesis 45:25-46:8").
    func text(for ref: ScriptureRef) -> String? {
        guard let canonicalName = canonicalBookName(for: ref.book),
              let slug = slugByCanonicalName[canonicalName],
              let book = loadBook(slug: slug, canonicalName: canonicalName)
        else { return nil }

        var verses: [String] = []
        for chapterNumber in ref.startChapter...ref.endChapter {
            guard let chapter = book.chapter(chapterNumber) else { return nil }
            let startVerse = chapterNumber == ref.startChapter ? (ref.startVerse ?? 1) : 1
            let endVerse = chapterNumber == ref.endChapter ? (ref.endVerse ?? chapter.verses.count) : chapter.verses.count
            guard startVerse <= endVerse else { continue }
            verses.append(contentsOf: chapter.verses.indices
                .filter { $0 + 1 >= startVerse && $0 + 1 <= endVerse }
                .map { chapter.verses[$0] })
        }
        guard !verses.isEmpty else { return nil }
        return verses.joined(separator: " ")
    }

    private func loadBook(slug: String, canonicalName: String) -> BibleBook? {
        if let cached = loadedBooks[canonicalName] { return cached }
        guard let url = bundle.url(forResource: slug, withExtension: "json", subdirectory: "Bible")
            ?? bundle.url(forResource: slug, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let book = try? JSONDecoder().decode(BibleBook.self, from: data)
        else { return nil }
        loadedBooks[canonicalName] = book
        return book
    }

    private func loadManifest() {
        guard let url = bundle.url(forResource: "manifest", withExtension: "json", subdirectory: "Bible")
            ?? bundle.url(forResource: "manifest", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([ManifestEntry].self, from: data)
        else {
            assertionFailure("Bible manifest.json missing from bundle resources")
            return
        }
        for entry in entries {
            slugByCanonicalName[entry.book] = entry.slug
            canonicalNameByNormalizedKey[Self.normalize(entry.book)] = entry.book
        }
        for (alias, canonical) in Self.bookAliases where slugByCanonicalName[canonical] != nil {
            canonicalNameByNormalizedKey[Self.normalize(alias)] = canonical
        }
    }

    private static func normalize(_ raw: String) -> String {
        raw.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Common abbreviations for the canonical (KJV) and Apocrypha book names, matching the forms
    /// used in the 1662 Kalendar's Table of Lessons and other common lectionary shorthand.
    private static let bookAliases: [String: String] = [
        "Gen": "Genesis", "Exod": "Exodus", "Exo": "Exodus", "Lev": "Leviticus",
        "Num": "Numbers", "Numb": "Numbers", "Deut": "Deuteronomy", "Josh": "Joshua",
        "Judg": "Judges", "1 Sam": "1 Samuel", "2 Sam": "2 Samuel",
        "1 Kings": "1 Kings", "2 Kings": "2 Kings", "1 Kgs": "1 Kings", "2 Kgs": "2 Kings",
        "1 Chron": "1 Chronicles", "2 Chron": "2 Chronicles", "1 Chr": "1 Chronicles", "2 Chr": "2 Chronicles",
        "Neh": "Nehemiah", "Esth": "Esther", "Ester": "Esther", "Ps": "Psalms", "Psalm": "Psalms",
        "Psal": "Psalms", "Prov": "Proverbs", "Eccles": "Ecclesiastes", "Eccle": "Ecclesiastes",
        "Cant": "Song of Solomon", "Song of Songs": "Song of Solomon", "Canticles": "Song of Solomon",
        "Isai": "Isaiah", "Isa": "Isaiah", "Jerem": "Jeremiah", "Jer": "Jeremiah", "Lam": "Lamentations",
        "Ezek": "Ezekiel", "Dan": "Daniel", "Hos": "Hosea", "Obad": "Obadiah", "Mic": "Micah", "Micha": "Micah",
        "Habak": "Habakkuk", "Habb": "Habakkuk", "Zeph": "Zephaniah", "Hagg": "Haggai", "Zech": "Zechariah",
        "Mal": "Malachi", "Matth": "Matthew", "Matt": "Matthew", "Mark": "Mark", "Luke": "Luke", "Joh": "John",
        "Rom": "Romans", "1 Cor": "1 Corinthians", "2 Cor": "2 Corinthians", "Gal": "Galatians",
        "Galateans": "Galatians", // typo on the source Kalendar site itself (Whitsunday's 2nd Lesson)
        "Ephes": "Ephesians", "Eph": "Ephesians", "Philip": "Philippians", "Phil": "Philippians",
        "Coloss": "Colossians", "Col": "Colossians", "1 Thes": "1 Thessalonians", "2 Thes": "2 Thessalonians",
        "1 Thess": "1 Thessalonians", "2 Thess": "2 Thessalonians", "1 Tim": "1 Timothy", "2 Tim": "2 Timothy",
        "Tit": "Titus", "Philem": "Philemon", "Hebr": "Hebrews", "Heb": "Hebrews", "Jam": "James", "Jas": "James",
        "1 Pet": "1 Peter", "2 Pet": "2 Peter", "1 Joh": "1 John", "2 Joh": "2 John", "3 Joh": "3 John",
        "Rev": "Revelation", "Apoc": "Revelation",
        // Apocrypha
        "Ecclus": "Ecclesiasticus", "Sirach": "Ecclesiasticus", "Wisd": "Wisdom of Solomon",
        "Wisdom": "Wisdom of Solomon", "Bar": "Baruch", "Tob": "Tobit", "Judeth": "Judith",
        "Bel and y Drag": "Bel and the Dragon", "Bel & y Drag": "Bel and the Dragon",
        "Hist of Susan": "Susanna", "Song of Three": "Prayer of Azariah",
        "Pr of Manasses": "Prayer of Manasseh", "Ecclesus": "Ecclesiasticus",
    ]
}
