import SwiftUI

/// Manages the shared hymn library from Settings: lists uploaded hymns, lets the user delete
/// them, and presents `AddHymnView` to upload a new one.
struct HymnLibraryView: View {
    @ObservedObject private var hymnStore = HymnStore.shared
    @State private var isAddingHymn = false

    var body: some View {
        List {
            ForEach(hymnStore.hymns) { hymn in
                Text(hymn.title)
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
                    .listRowBackground(Theme.parchmentPanel)
            }
            .onDelete { offsets in
                // Snapshot the target hymns before deleting any of them — deleting by index
                // one-at-a-time would shift later indices in the same offset set out from
                // under us once the array shrinks.
                offsets.map { hymnStore.hymns[$0] }.forEach(hymnStore.deleteHymn)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.parchment.ignoresSafeArea())
        .navigationTitle("Hymn Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingHymn = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.crimson)
                }
            }
        }
        .sheet(isPresented: $isAddingHymn) {
            AddHymnView()
        }
    }
}

#Preview {
    NavigationStack { HymnLibraryView() }
}
