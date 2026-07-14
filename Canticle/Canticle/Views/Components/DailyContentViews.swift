import SwiftUI

/// A card-style container that sets the day-specific content (Psalms, Lessons, Collect) apart
/// visually from the fixed liturgy around it.
private struct DailyCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
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

struct PsalmsView: View {
    let psalms: [PsalmText]

    private func psalmHeading(for psalm: PsalmText) -> String {
        "Psalm \(psalm.number)  ·  \(psalm.title)"
    }

    var body: some View {
        DailyCard {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(psalms) { psalm in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(psalmHeading(for: psalm))
                            .font(Typography.reference)
                            .foregroundStyle(Theme.crimson)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(psalm.verses.enumerated()), id: \.offset) { _, verse in
                                Text(verse)
                                    .font(Typography.body)
                                    .foregroundStyle(Theme.primaryText)
                                    .lineSpacing(4)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LessonView: View {
    let label: String
    let reading: ResolvedLesson

    var body: some View {
        DailyCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(label)  ·  \(reading.reference)")
                    .font(Typography.reference)
                    .foregroundStyle(Theme.crimson)
                Text(reading.text)
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
                    .lineSpacing(4)
            }
        }
    }
}

struct CollectView: View {
    let collect: Collect

    var body: some View {
        DailyCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(collect.title)
                    .font(Typography.reference)
                    .foregroundStyle(Theme.crimson)
                Text(collect.text)
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
                    .lineSpacing(4)
            }
        }
    }
}

/// Shown wherever the calendar hasn't supplied content yet for today — so the app degrades
/// gracefully in advance of the full 1662 lectionary being imported, rather than showing nothing
/// or fabricated text.
struct MissingDailyContentView: View {
    let kind: DisplayBlock.MissingKind

    private var label: String {
        switch kind {
        case .psalms: return "Today's Psalms couldn't be loaded."
        case .firstLesson: return "Today's First Lesson hasn't been added yet."
        case .secondLesson: return "Today's Second Lesson hasn't been added yet."
        case .collect: return "Today's Collect hasn't been added yet."
        case .sundayLessonNotImplemented: return "Today's Proper Sunday Lesson couldn't be resolved."
        }
    }

    var body: some View {
        DailyCard {
            HStack(alignment: .center, spacing: 10) {
                CrusaderCrossShape()
                    .fill(Theme.secondaryText.opacity(0.5))
                    .frame(width: 16, height: 16)
                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}
