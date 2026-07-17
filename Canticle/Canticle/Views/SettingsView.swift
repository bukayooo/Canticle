import SwiftUI
import UIKit

struct SettingsView: View {
    @State private var currentIconName: String? = UIApplication.shared.alternateIconName
    @ObservedObject private var bibleStore = BibleStore.shared
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var hymnStore = HymnStore.shared

    var body: some View {
        List {
            Section {
                Toggle(isOn: $notificationService.morningReminderEnabled) {
                    Text("Morning Prayer")
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                }
                .tint(Theme.crimson)
                .listRowBackground(Theme.parchmentPanel)

                if notificationService.morningReminderEnabled {
                    DatePicker(
                        "Time",
                        selection: $notificationService.morningReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
                    .tint(Theme.crimson)
                    .listRowBackground(Theme.parchmentPanel)
                }

                Toggle(isOn: $notificationService.eveningReminderEnabled) {
                    Text("Evening Prayer")
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                }
                .tint(Theme.crimson)
                .listRowBackground(Theme.parchmentPanel)

                if notificationService.eveningReminderEnabled {
                    DatePicker(
                        "Time",
                        selection: $notificationService.eveningReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
                    .tint(Theme.crimson)
                    .listRowBackground(Theme.parchmentPanel)
                }
            } header: {
                Text("Reminders")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            Section {
                Picker(selection: $hymnStore.morningPosition) {
                    ForEach(HymnPosition.allCases, id: \.self) { position in
                        Text(position.label).tag(position)
                    }
                } label: {
                    Text("Morning Prayer")
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                }
                .tint(Theme.crimson)
                .listRowBackground(Theme.parchmentPanel)

                Picker(selection: $hymnStore.eveningPosition) {
                    ForEach(HymnPosition.allCases, id: \.self) { position in
                        Text(position.label).tag(position)
                    }
                } label: {
                    Text("Evening Prayer")
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                }
                .tint(Theme.crimson)
                .listRowBackground(Theme.parchmentPanel)

                NavigationLink {
                    HymnLibraryView()
                } label: {
                    Text("Hymn Library")
                        .font(Typography.reference)
                        .foregroundStyle(Theme.crimson)
                }
                .listRowBackground(Theme.parchmentPanel)
            } header: {
                Text("Hymn")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            Section {
                Toggle(isOn: $bibleStore.useOriginalLanguages) {
                    Text("Original Languages")
                        .font(Typography.body)
                        .foregroundStyle(Theme.primaryText)
                }
                .tint(Theme.crimson)
                .listRowBackground(Theme.parchmentPanel)
            } header: {
                Text("Bible Text")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            Section {
                ForEach(AppIconOption.all) { option in
                    Button {
                        selectIcon(option)
                    } label: {
                        HStack(spacing: 14) {
                            iconSwatch(for: option)
                            Text(option.displayName)
                                .font(Typography.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer(minLength: 0)
                            if option.iconName == currentIconName {
                                Image(systemName: "checkmark")
                                    .font(.system(.body, design: .serif).weight(.semibold))
                                    .foregroundStyle(Theme.crimson)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.parchmentPanel)
                }
            } header: {
                Text("App Icon")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            Section {
                NavigationLink {
                    LitanyView()
                } label: {
                    Text("The Litany")
                        .font(Typography.reference)
                        .foregroundStyle(Theme.crimson)
                }
                .listRowBackground(Theme.parchmentPanel)

                NavigationLink {
                    ComminationView()
                } label: {
                    Text("A Commination")
                        .font(Typography.reference)
                        .foregroundStyle(Theme.crimson)
                }
                .listRowBackground(Theme.parchmentPanel)
            } header: {
                Text("Occasional Services")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.parchment.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func iconSwatch(for option: AppIconOption) -> some View {
        Image(option.previewImageName)
            .resizable()
            .scaledToFill()
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1)
            )
    }

    private func selectIcon(_ option: AppIconOption) {
        guard option.iconName != currentIconName else { return }
        currentIconName = option.iconName
        UIApplication.shared.setAlternateIconName(option.iconName) { error in
            if let error {
                print("Failed to set alternate icon \(option.iconName ?? "primary"): \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
