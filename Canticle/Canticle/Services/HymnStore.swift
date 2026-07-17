import Foundation

/// Manages the user's shared hymn library (uploaded audio + title + lyrics) and the independent
/// per-office setting for whether/where a hymn is offered.
///
/// Unlike every other store in `Services/`, this one *writes* user data rather than only reading
/// bundled JSON: uploaded audio files and a small JSON index live in the app's Application Support
/// directory (created on first use), following the same `JSONDecoder`/`Codable` idiom the
/// bundle-backed stores use, just read/write instead of read-only.
@MainActor
final class HymnStore: ObservableObject {
    static let shared = HymnStore()

    @Published private(set) var hymns: [Hymn] = []

    @Published var morningPosition: HymnPosition {
        didSet {
            guard morningPosition != oldValue else { return }
            UserDefaults.standard.set(morningPosition.rawValue, forKey: Self.morningPositionKey)
        }
    }

    @Published var eveningPosition: HymnPosition {
        didSet {
            guard eveningPosition != oldValue else { return }
            UserDefaults.standard.set(eveningPosition.rawValue, forKey: Self.eveningPositionKey)
        }
    }

    private static let morningPositionKey = "hymnMorningPosition"
    private static let eveningPositionKey = "hymnEveningPosition"

    private let fileManager: FileManager

    private init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let defaults = UserDefaults.standard
        morningPosition = defaults.string(forKey: Self.morningPositionKey).flatMap(HymnPosition.init) ?? .off
        eveningPosition = defaults.string(forKey: Self.eveningPositionKey).flatMap(HymnPosition.init) ?? .off

        try? fileManager.createDirectory(at: Self.hymnsDirectory, withIntermediateDirectories: true)
        hymns = Self.loadIndex(fileManager: fileManager)
    }

    func position(for office: Office) -> HymnPosition {
        office == .morning ? morningPosition : eveningPosition
    }

    func audioURL(for hymn: Hymn) -> URL {
        Self.hymnsDirectory.appendingPathComponent(hymn.audioFileName)
    }

    /// Copies `sourceURL` (typically a security-scoped URL handed back by `.fileImporter`) into
    /// the Hymns directory and adds it to the library.
    func addHymn(title: String, lyrics: String, sourceURL: URL, stanzaCount: Int = 1, category: String = "") throws -> Hymn {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer { if didAccess { sourceURL.stopAccessingSecurityScopedResource() } }

        let id = UUID()
        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let fileName = "\(id.uuidString).\(ext)"
        let destination = Self.hymnsDirectory.appendingPathComponent(fileName)
        try fileManager.copyItem(at: sourceURL, to: destination)

        let hymn = Hymn(
            id: id,
            title: title,
            lyrics: lyrics,
            audioFileName: fileName,
            dateAdded: Date(),
            stanzaCount: max(stanzaCount, 1),
            category: category
        )
        hymns.append(hymn)
        saveIndex()
        return hymn
    }

    /// Updates an existing hymn's title/lyrics/category/stanza count in place, optionally
    /// replacing its audio (copying in the new file and removing the old one) if the user chose
    /// a replacement while editing.
    func updateHymn(_ hymn: Hymn, title: String, lyrics: String, category: String, stanzaCount: Int, newAudioSourceURL: URL?) throws {
        guard let index = hymns.firstIndex(where: { $0.id == hymn.id }) else { return }

        var updated = hymns[index]
        updated.title = title
        updated.lyrics = lyrics
        updated.category = category
        updated.stanzaCount = max(stanzaCount, 1)

        if let newAudioSourceURL {
            let didAccess = newAudioSourceURL.startAccessingSecurityScopedResource()
            defer { if didAccess { newAudioSourceURL.stopAccessingSecurityScopedResource() } }

            let ext = newAudioSourceURL.pathExtension.isEmpty ? "m4a" : newAudioSourceURL.pathExtension
            let fileName = "\(UUID().uuidString).\(ext)"
            let destination = Self.hymnsDirectory.appendingPathComponent(fileName)
            try fileManager.copyItem(at: newAudioSourceURL, to: destination)
            try? fileManager.removeItem(at: audioURL(for: hymn))
            updated.audioFileName = fileName
        }

        hymns[index] = updated
        saveIndex()
    }

    func deleteHymn(_ hymn: Hymn) {
        try? fileManager.removeItem(at: audioURL(for: hymn))
        hymns.removeAll { $0.id == hymn.id }
        saveIndex()
    }

    private static var hymnsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Hymns", isDirectory: true)
    }

    private static var indexURL: URL {
        hymnsDirectory.appendingPathComponent("index.json")
    }

    private static func loadIndex(fileManager: FileManager) -> [Hymn] {
        guard let data = fileManager.contents(atPath: indexURL.path) else { return [] }
        return (try? JSONDecoder().decode([Hymn].self, from: data)) ?? []
    }

    private func saveIndex() {
        guard let data = try? JSONEncoder().encode(hymns) else { return }
        try? data.write(to: Self.indexURL, options: .atomic)
    }
}
