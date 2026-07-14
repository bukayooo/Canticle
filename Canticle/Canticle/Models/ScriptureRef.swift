import Foundation

/// A parsed Bible reference, e.g. "Genesis 1:1-19", "1 Corinthians 13", or a cross-chapter span
/// like "Genesis 45:25-46:8". `startVerse`/`endVerse` of nil mean "start/end of chapter".
struct ScriptureRef {
    let book: String
    let startChapter: Int
    let startVerse: Int?
    let endChapter: Int
    let endVerse: Int?

    /// Parses references in the common Kalendar/lectionary forms: "Book" (a single-chapter book
    /// referenced with no chapter number, e.g. "Jude"), "Book C", "Book C:V", "Book C:V-V", and
    /// cross-chapter spans "Book C:V-C:V". The book name may be a full name or a recognized
    /// abbreviation — see `BibleStore.canonicalBookName(for:)`.
    init?(_ reference: String) {
        let trimmed = reference.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard !trimmed.isEmpty else { return nil }

        guard let lastSpace = trimmed.range(of: " ", options: .backwards) else {
            // No space at all: a single-chapter book referenced by name alone (e.g. "Philemon").
            self.book = trimmed
            self.startChapter = 1
            self.startVerse = nil
            self.endChapter = 1
            self.endVerse = nil
            return
        }

        let bookPart = String(trimmed[trimmed.startIndex..<lastSpace.lowerBound])
        let numberPart = String(trimmed[lastSpace.upperBound...])

        let sides = numberPart.split(separator: "-", maxSplits: 1)
        guard let start = Self.parseChapterVerse(String(sides[0])) else {
            // The token after the last space isn't a chapter/verse (e.g. "2 John", "3 John") --
            // the whole string is the book name, referenced without a chapter number.
            self.book = trimmed
            self.startChapter = 1
            self.startVerse = nil
            self.endChapter = 1
            self.endVerse = nil
            return
        }

        var endChapter = start.chapter
        var endVerse = start.verse
        if sides.count == 2 {
            let endRaw = String(sides[1])
            if endRaw.contains(":") {
                guard let end = Self.parseChapterVerse(endRaw) else { return nil }
                endChapter = end.chapter
                endVerse = end.verse
            } else if let bareNumber = Int(endRaw) {
                if let startVerse = start.verse, bareNumber < startVerse {
                    // Can't be a verse in the same chapter (it would run backwards) -- it's the
                    // ending chapter number instead, read through to the end of that chapter.
                    endChapter = bareNumber
                    endVerse = nil
                } else {
                    endVerse = bareNumber
                }
            } else {
                return nil
            }
        }

        // Reject nonsensical ranges (occasionally a genuine typo in the source Kalendar, e.g.
        // "Ezekiel 27:26-21") rather than guess at what was meant.
        guard endChapter > start.chapter
            || (endChapter == start.chapter && (endVerse == nil || endVerse! >= (start.verse ?? 1)))
        else { return nil }

        self.book = bookPart
        self.startChapter = start.chapter
        self.startVerse = start.verse
        self.endChapter = endChapter
        self.endVerse = endVerse
    }

    private static func parseChapterVerse(_ s: String) -> (chapter: Int, verse: Int?)? {
        let parts = s.split(separator: ":", maxSplits: 1)
        guard let chapter = Int(parts[0]) else { return nil }
        let verse = parts.count == 2 ? Int(parts[1]) : nil
        return (chapter, verse)
    }
}
