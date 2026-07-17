import SwiftUI

/// Lets the user choose which hymn from the shared library to sing, reached from
/// `HymnPromptCardView`. Selecting one pushes the dedicated full-screen player. Hymns are grouped
/// under a subheading per their category (set when the hymn was added/edited), sorted
/// alphabetically, with uncategorized hymns collected last under "Other".
struct HymnPickerView: View {
    @ObservedObject private var hymnStore = HymnStore.shared

    private static let otherCategory = "Other"

    private var groupedHymns: [(category: String, hymns: [Hymn])] {
        let grouped = Dictionary(grouping: hymnStore.hymns) { hymn -> String in
            let trimmed = hymn.category.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? Self.otherCategory : trimmed
        }
        let sortedCategories = grouped.keys.sorted { lhs, rhs in
            if lhs == Self.otherCategory { return false }
            if rhs == Self.otherCategory { return true }
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
        return sortedCategories.map { category in
            (category, grouped[category] ?? [])
        }
    }

    var body: some View {
        List {
            ForEach(groupedHymns, id: \.category) { group in
                Section {
                    ForEach(group.hymns) { hymn in
                        NavigationLink {
                            HymnPlayerView(hymn: hymn)
                        } label: {
                            Text(hymn.title)
                                .font(Typography.body)
                                .foregroundStyle(Theme.primaryText)
                        }
                        .listRowBackground(Theme.parchmentPanel)
                    }
                } header: {
                    Text(group.category)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
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
