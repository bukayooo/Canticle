import SwiftUI

struct LitanyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(Litany.title)
                    .font(Typography.officeName)
                    .foregroundStyle(Theme.primaryText)
                    .padding(.top, 12)
                CrusaderDivider()
                    .frame(maxWidth: .infinity, alignment: .center)

                ForEach(Litany.items) { item in
                    LiturgyItemView(item: item)
                }

                CrusaderDivider()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Theme.parchment.ignoresSafeArea())
        .navigationTitle("The Litany")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { LitanyView() }
}
