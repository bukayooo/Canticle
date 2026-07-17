import SwiftUI

/// A card offering a hymn at the opening or closing of the office, styled like the Litany/
/// Commination `serviceLink` cards in `ContentView`. Links to `HymnPickerView` when the shared
/// library has hymns; otherwise degrades to an inert card, matching `MissingDailyContentView`'s
/// convention for content that isn't available yet.
struct HymnPromptCardView: View {
    let slot: DisplayBlock.HymnSlot
    @ObservedObject private var hymnStore = HymnStore.shared

    private var title: String { "Sing a Hymn" }

    private var subtitle: String {
        switch slot {
        case .opening: return "Before you begin."
        case .closing: return "To close."
        }
    }

    var body: some View {
        if hymnStore.hymns.isEmpty {
            card(showsChevron: false) {
                Text("Add a hymn to your library in Settings to sing one here.")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        } else {
            NavigationLink {
                HymnPickerView()
            } label: {
                card(showsChevron: true) {
                    Text(subtitle)
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func card<Content: View>(showsChevron: Bool, @ViewBuilder subtitleContent: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Typography.reference)
                    .foregroundStyle(Theme.crimson)
                subtitleContent()
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.parchmentPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Theme.gold.opacity(0.5), lineWidth: 1)
        )
    }
}
