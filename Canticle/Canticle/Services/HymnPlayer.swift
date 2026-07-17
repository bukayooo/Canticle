import AVFoundation
import Foundation

/// Thin `AVAudioPlayer` wrapper scoped to a single hymn-playback screen (not a singleton — only
/// one hymn plays at a time, and its lifetime matches `HymnPlayerView`'s).
@MainActor
final class HymnPlayer: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    /// Which pass through the (single-stanza) recording is currently playing, 1-based.
    @Published private(set) var currentStanza = 1

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var totalStanzas = 1

    /// - Parameter stanzaCount: how many times to repeat the recording end-to-end before
    ///   stopping, for hymns whose uploaded audio is just the tune for one stanza.
    func load(url: URL, stanzaCount: Int = 1) {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)

        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.prepareToPlay()
        duration = player?.duration ?? 0
        currentTime = 0
        totalStanzas = max(stanzaCount, 1)
        currentStanza = 1
    }

    func togglePlayback() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopProgressTimer()
        } else {
            player.play()
            isPlaying = true
            startProgressTimer()
        }
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }

    func stop() {
        player?.stop()
        isPlaying = false
        currentStanza = 1
        stopProgressTimer()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.currentTime = self?.player?.currentTime ?? 0 }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

extension HymnPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Don't capture the delegate callback's `player` argument in the Task below — it's not
        // Sendable, and `self.player` (same underlying instance) is already safe to reach from
        // the main actor.
        Task { @MainActor in
            guard self.currentStanza < self.totalStanzas else {
                self.isPlaying = false
                self.currentTime = 0
                self.currentStanza = 1
                self.stopProgressTimer()
                return
            }
            self.currentStanza += 1
            self.currentTime = 0
            self.player?.currentTime = 0
            self.player?.play()
        }
    }
}
