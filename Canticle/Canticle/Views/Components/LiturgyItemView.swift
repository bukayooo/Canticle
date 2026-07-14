import SwiftUI

/// Renders one fixed line of the liturgy according to its kind, mirroring the conventions of a
/// printed Prayer Book (rubrics traditionally set off in red italic, versicle/response pairs
/// bold, canticle titles in small italic caps).
struct LiturgyItemView: View {
    let item: LiturgyItem

    var body: some View {
        switch item.kind {
        case .heading:
            Text(item.text)
                .font(Typography.heading)
                .foregroundStyle(Theme.primaryText)
                .padding(.top, 12)

        case .rubric:
            Text(item.text)
                .font(Typography.rubric)
                .foregroundStyle(Theme.crimson)

        case .sentence:
            Text(item.text)
                .font(Typography.body.italic())
                .foregroundStyle(Theme.primaryText)

        case .canticleTitle:
            Text(item.text)
                .font(Typography.canticleTitle)
                .foregroundStyle(Theme.crimson)
                .padding(.top, 6)

        case .versicle:
            Text(item.text)
                .font(Typography.versicle)
                .foregroundStyle(Theme.primaryText)

        case .response:
            Text(item.text)
                .font(Typography.body)
                .foregroundStyle(Theme.secondaryText)
                .padding(.leading, 12)

        case .amen:
            Text(item.text)
                .font(Typography.versicle)
                .foregroundStyle(Theme.crimson)

        case .text:
            Text(item.text)
                .font(Typography.body)
                .foregroundStyle(Theme.primaryText)
                .lineSpacing(4)

        case .psalmsSlot, .firstLessonSlot, .secondLessonSlot, .collectSlot, .creedSlot:
            EmptyView() // resolved into other DisplayBlock cases before rendering
        }
    }
}
