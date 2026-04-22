import Foundation
import AVFoundation
import Observation

// MARK: - AudioPlaybackManager
//
// Manages audio playback during runs using AVAudioPlayer.
// Configures AVAudioSession for background playback and handles interruptions.
//
// TODO: To enable background audio, add "Audio, AirPlay, and Picture in Picture"
//       to your Xcode target's Background Modes capability.

@Observable
final class AudioPlaybackManager: NSObject {

    // MARK: - State

    var currentTrack: AudioTrack?
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var volume: Float = 0.8 {
        didSet { player?.volume = volume }
    }

    private(set) var playlist: Playlist = .builtIn
    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var currentIndex: Int = 0

    // MARK: - Setup

    override init() {
        super.init()
        configureAudioSession()
        setupInterruptionObserver()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("[AudioPlaybackManager] Session setup failed: \(error)")
        }
    }

    // MARK: - Playback controls

    func play(track: AudioTrack) {
        guard let url = Bundle.main.url(forResource: track.filename.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") else {
            print("[AudioPlaybackManager] Track not found: \(track.filename)")
            // Still update state so UI shows "playing" in previews/simulators without actual file
            currentTrack = track
            isPlaying = true
            return
        }
        do {
            player?.stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
            currentTrack = track
            isPlaying = true
            startProgressTimer()
        } catch {
            print("[AudioPlaybackManager] Playback error: \(error)")
        }
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if let track = currentTrack {
            resumeOrPlay(track: track)
        } else {
            playCurrentIndex()
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    func next() {
        currentIndex = (currentIndex + 1) % playlist.tracks.count
        playCurrentIndex()
    }

    func previous() {
        if currentTime > 3 {
            player?.currentTime = 0
            currentTime = 0
        } else {
            currentIndex = (currentIndex - 1 + playlist.tracks.count) % playlist.tracks.count
            playCurrentIndex()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTrack = nil
        currentTime = 0
        stopProgressTimer()
    }

    func setVolume(_ value: Float) {
        volume = max(0, min(1, value))
    }

    // MARK: - Private helpers

    private func resumeOrPlay(track: AudioTrack) {
        if player != nil {
            player?.play()
            isPlaying = true
            startProgressTimer()
        } else {
            play(track: track)
        }
    }

    private func playCurrentIndex() {
        guard currentIndex < playlist.tracks.count else { return }
        play(track: playlist.tracks[currentIndex])
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.currentTime = self?.player?.currentTime ?? 0
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Interruption handling

    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAudioInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            pause()
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume), let track = currentTrack {
                resumeOrPlay(track: track)
            }
        @unknown default:
            break
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag { next() }
    }
}
