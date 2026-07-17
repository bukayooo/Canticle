import SwiftUI

/// Dedicated full-screen playback for a single hymn: transport controls plus the lyrics, sized
/// for singing along rather than silent reading.
struct HymnPlayerView: View {
    let hymn: Hymn
    @StateObject private var player = HymnPlayer()

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                Text(hymn.title)
                    .font(Typography.officeName)
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                transportControls

                CrusaderDivider()
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(hymn.lyrics)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(Theme.primaryText)
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Theme.parchment.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { player.load(url: HymnStore.shared.audioURL(for: hymn), stanzaCount: hymn.stanzaCount) }
        .onDisappear { player.stop() }
    }

    private var transportControls: some View {
        VStack(spacing: 8) {
            if hymn.stanzaCount > 1 {
                Text("Stanza \(player.currentStanza) of \(hymn.stanzaCount)")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0...max(player.duration, 1)
            )
            .tint(Theme.crimson)

            HStack {
                Text(timeString(player.currentTime))
                Spacer()
                Text(timeString(player.duration))
            }
            .font(Typography.caption)
            .foregroundStyle(Theme.secondaryText)

            Button {
                player.togglePlayback()
            } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.crimson)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private func timeString(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
