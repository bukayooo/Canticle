import SwiftUI
import UniformTypeIdentifiers

/// Sheet for uploading a new hymn into the shared library: an audio file, a title, and the
/// words to sing along to.
struct AddHymnView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var hymnStore = HymnStore.shared

    @State private var title = ""
    @State private var lyrics = ""
    @State private var audioURL: URL?
    @State private var stanzaCount = 1
    @State private var isImportingAudio = false
    @State private var errorMessage: String?

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && audioURL != nil
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
                            Text(audioURL?.lastPathComponent ?? "Choose…")
                                .font(Typography.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
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
            .navigationTitle("Add Hymn")
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
                    audioURL = url
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func save() {
        guard let audioURL else { return }
        do {
            _ = try hymnStore.addHymn(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                lyrics: lyrics,
                sourceURL: audioURL,
                stanzaCount: stanzaCount
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddHymnView()
}
