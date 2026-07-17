import SwiftUI

/// Manages the shared hymn library from Settings: lists uploaded hymns, lets the user edit or
/// delete them, and presents `AddHymnView` to upload a new one.
struct HymnLibraryView: View {
    @ObservedObject private var hymnStore = HymnStore.shared
    @State private var isAddingHymn = false
    @State private var hymnToEdit: Hymn?

    var body: some View {
        List {
            ForEach(hymnStore.hymns) { hymn in
                Text(hymn.title)
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
                    .listRowBackground(Theme.parchmentPanel)
                    .swipeActions(edge: .trailing) {
                        Button {
                            hymnToEdit = hymn
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Theme.deepGold)

                        Button(role: .destructive) {
                            hymnStore.deleteHymn(hymn)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
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
        .sheet(item: $hymnToEdit) { hymn in
            AddHymnView(hymnToEdit: hymn)
        }
    }
}

#Preview {
    NavigationStack { HymnLibraryView() }
}
