import SwiftUI

/// Lets the user choose which hymn from the shared library to sing, reached from
/// `HymnPromptCardView`. Selecting one pushes the dedicated full-screen player.
struct HymnPickerView: View {
    @ObservedObject private var hymnStore = HymnStore.shared

    var body: some View {
        List(hymnStore.hymns) { hymn in
            NavigationLink {
                HymnPlayerView(hymn: hymn)
            } label: {
                Text(hymn.title)
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
            }
            .listRowBackground(Theme.parchmentPanel)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.parchment.ignoresSafeArea())
        .navigationTitle("Choose a Hymn")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { HymnPickerView() }
}
