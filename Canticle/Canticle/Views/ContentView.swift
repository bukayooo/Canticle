import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DevotionalViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    CrusaderDivider()
                        .frame(maxWidth: .infinity, alignment: .center)

                    ForEach(viewModel.blocks) { block in
                        blockView(for: block)
                    }

                    if viewModel.context.office == .morning && Litany.isAppointed(on: viewModel.context.date) {
                        serviceLink(
                            title: "The Litany is appointed today",
                            subtitle: "To be said or sung after Morning Prayer."
                        ) { LitanyView() }
                    }

                    if viewModel.context.office == .morning && Commination.isAppointed(on: viewModel.context.date) {
                        serviceLink(
                            title: "A Commination is appointed today",
                            subtitle: "Ash Wednesday — to be read after Morning Prayer, the Litany ended."
                        ) { ComminationView() }
                    }

                    CrusaderDivider()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Theme.parchment.ignoresSafeArea())
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.refresh()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink("The Litany") { LitanyView() }
                        NavigationLink("A Commination") { ComminationView() }
                    } label: {
                        Image(systemName: "book.closed")
                    }
                }
            }
            #if DEBUG
            .safeAreaInset(edge: .bottom) { debugOfficeSwitcher }
            #endif
        }
    }

    /// A card linking to an occasional service (Litany, Commination) appointed for today — those
    /// are separate screens since they're long standalone rites, not part of the fixed daily
    /// scrollview.
    @ViewBuilder
    private func serviceLink<Destination: View>(
        title: String,
        subtitle: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(Typography.reference)
                        .foregroundStyle(Theme.crimson)
                    Text(subtitle)
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.gold)
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
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CANTICLE")
                .font(.system(.caption, design: .serif).weight(.bold))
                .kerning(3)
                .foregroundStyle(Theme.gold)
            Text(viewModel.context.office.shortTitle)
                .font(Typography.officeName)
                .foregroundStyle(Theme.primaryText)
            Text(dateLine)
                .font(Typography.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.top, 24)
    }

    private var dateLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        let date = formatter.string(from: viewModel.context.date)
        return "\(date)  ·  Day \(viewModel.context.dayOfYear) of the year"
    }

    @ViewBuilder
    private func blockView(for block: DisplayBlock) -> some View {
        switch block {
        case .liturgy(let item):
            LiturgyItemView(item: item)
        case .psalms(let psalms):
            PsalmsView(psalms: psalms)
        case .lesson(let reading):
            LessonView(label: lessonLabel(for: reading), reading: reading)
        case .collect(let collect):
            CollectView(collect: collect)
        case .missingDailyContent(let kind):
            MissingDailyContentView(kind: kind)
        }
    }

    /// The fixed liturgy already prints a "Then shall be read the First/Second Lesson" rubric
    /// immediately before each lesson slot, so the card itself just needs a short label.
    private func lessonLabel(for reading: ResolvedLesson) -> String {
        "Lesson"
    }

    #if DEBUG
    /// Debug-only preview control (never shown in Release builds) for switching offices without
    /// waiting for the clock — styled to match the rest of the app rather than the default system
    /// segmented control.
    private var debugOfficeSwitcher: some View {
        HStack(spacing: 0) {
            debugOfficeButton(.morning, label: "Morning")
            debugOfficeButton(.evening, label: "Evening")
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.parchmentPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.gold.opacity(0.5), lineWidth: 1)
        )
        .padding(12)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func debugOfficeButton(_ office: Office, label: String) -> some View {
        let isSelected = viewModel.context.office == office
        Button {
            viewModel.debugSetOffice(office)
        } label: {
            Text(label)
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? Theme.parchment : Theme.secondaryText)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isSelected ? Theme.crimson : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
    #endif
}

#Preview {
    ContentView()
}
