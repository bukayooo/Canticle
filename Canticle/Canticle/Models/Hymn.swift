import Foundation

/// A user-uploaded hymn in the shared library: audio plus the words to sing along to.
/// `audioFileName` is resolved against `HymnStore`'s Hymns directory, not stored as a full path,
/// so the library survives the app's container path changing between installs/updates.
struct Hymn: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var lyrics: String
    var audioFileName: String
    var dateAdded: Date
    /// How many stanzas the hymn has. The uploaded audio is typically a recording of just one
    /// stanza's tune, so playback repeats it this many times total (once, then `stanzaCount - 1`
    /// more) so the singer has a pass for each stanza's words.
    var stanzaCount: Int
    /// Freeform theme (e.g. "Advent", "Communion") used to group hymns in the picker. Empty
    /// means uncategorized.
    var category: String

    init(id: UUID, title: String, lyrics: String, audioFileName: String, dateAdded: Date, stanzaCount: Int = 1, category: String = "") {
        self.id = id
        self.title = title
        self.lyrics = lyrics
        self.audioFileName = audioFileName
        self.dateAdded = dateAdded
        self.stanzaCount = stanzaCount
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        lyrics = try container.decode(String.self, forKey: .lyrics)
        audioFileName = try container.decode(String.self, forKey: .audioFileName)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        // Hymns saved before stanza support was added won't have this key.
        stanzaCount = try container.decodeIfPresent(Int.self, forKey: .stanzaCount) ?? 1
        // Hymns saved before category support was added won't have this key.
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
    }
}

/// Where, if at all, a hymn is offered relative to an office — independently configurable for
/// Morning and Evening Prayer in Settings.
enum HymnPosition: String, Codable, CaseIterable {
    case off, beginning, end

    var label: String {
        switch self {
        case .off: return "Off"
        case .beginning: return "Beginning"
        case .end: return "End"
        }
    }
}
