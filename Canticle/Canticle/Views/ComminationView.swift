import SwiftUI

/// Displays "A Commination" — an occasional penitential service, appointed for Ash Wednesday.
/// Ash Wednesday's date depends on Easter, which Canticle doesn't calculate yet, so this screen is
/// reached from a persistent menu rather than being surfaced automatically on the right day.
struct ComminationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(Commination.title)
                    .font(Typography.officeName)
                    .foregroundStyle(Theme.primaryText)
                    .padding(.top, 12)
                Text(Commination.subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                CrusaderDivider()
                    .frame(maxWidth: .infinity, alignment: .center)

                ForEach(Commination.items) { item in
                    LiturgyItemView(item: item)
                }

                CrusaderDivider()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Theme.parchment.ignoresSafeArea())
        .navigationTitle("A Commination")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { ComminationView() }
}
