import SwiftUI
import UniformTypeIdentifiers

/// Sheet for uploading a new hymn into the shared library (or editing an existing one): an audio
/// file, a title, a category, and the words to sing along to.
struct AddHymnView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var hymnStore = HymnStore.shared

    /// Non-nil when editing an existing hymn rather than adding a new one; every field is
    /// pre-populated from it and Save updates it in place instead of creating a new entry.
    private let editingHymn: Hymn?

    @State private var title: String
    @State private var lyrics: String
    @State private var category: String
    @State private var stanzaCount: Int
    /// Only set when the user picks a (replacement) audio file in this session. When editing,
    /// leaving this nil keeps the hymn's existing audio.
    @State private var newAudioURL: URL?
    @State private var isImportingAudio = false
    @State private var errorMessage: String?

    init(hymnToEdit: Hymn? = nil) {
        self.editingHymn = hymnToEdit
        _title = State(initialValue: hymnToEdit?.title ?? "")
        _lyrics = State(initialValue: hymnToEdit?.lyrics ?? "")
        _category = State(initialValue: hymnToEdit?.category ?? "")
        _stanzaCount = State(initialValue: hymnToEdit?.stanzaCount ?? 1)
    }

    private var audioDisplayName: String {
        if let newAudioURL { return newAudioURL.lastPathComponent }
        if let editingHymn { return editingHymn.audioFileName }
        return "Choose…"
    }

    private var canSave: Bool {
        let hasAudio = newAudioURL != nil || editingHymn != nil
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasAudio
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Title", text: $title)
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                        .listRowBackground(Theme.parchmentPanel)

                    Button {
                        isImportingAudio = true
                    } label: {
                        HStack {
                            Text("Audio File")
                                .font(Typography.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            Text(audioDisplayName)
                                .font(Typography.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .listRowBackground(Theme.parchmentPanel)

                    TextField("Category", text: $category)
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                        .listRowBackground(Theme.parchmentPanel)

                    Stepper(value: $stanzaCount, in: 1...20) {
                        Text("Stanzas: \(stanzaCount)")
                            .font(Typography.body)
                            .foregroundStyle(Theme.primaryText)
                    }
                    .tint(Theme.crimson)
                    .listRowBackground(Theme.parchmentPanel)
                } header: {
                    Text("Hymn")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                } footer: {
                    Text("Leave this at 1 if the recording already plays through every stanza. If it's only the tune for one stanza, set the number of stanzas the hymn has and playback will repeat the recording that many times so you can sing all the words.")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                }

                Section {
                    TextEditor(text: $lyrics)
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                        .frame(minHeight: 200)
                        .listRowBackground(Theme.parchmentPanel)
                } header: {
                    Text("Words")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.crimson)
                        .listRowBackground(Theme.parchmentPanel)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.parchment.ignoresSafeArea())
            .navigationTitle(editingHymn == nil ? "Add Hymn" : "Edit Hymn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .fileImporter(isPresented: $isImportingAudio, allowedContentTypes: [.audio]) { result in
                switch result {
                case .success(let url):
                    newAudioURL = url
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func save() {
        do {
            if let editingHymn {
                try hymnStore.updateHymn(
                    editingHymn,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    lyrics: lyrics,
                    category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                    stanzaCount: stanzaCount,
                    newAudioSourceURL: newAudioURL
                )
            } else {
                guard let newAudioURL else { return }
                _ = try hymnStore.addHymn(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    lyrics: lyrics,
                    sourceURL: newAudioURL,
                    stanzaCount: stanzaCount,
                    category: category.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddHymnView()
}
