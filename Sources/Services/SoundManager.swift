import Foundation
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private let backgroundMusicFilename = "chicken_loop"
    private var backgroundPlayer: AVAudioPlayer?

    private init() {}

    private func backgroundMusicURL() -> URL? {
        if let url = Bundle.main.url(
            forResource: backgroundMusicFilename,
            withExtension: "wav",
            subdirectory: "Audio"
        ) {
            print("Resolved background music URL: \(url)")
            return url
        }

        print("Warning: Missing background music file \(backgroundMusicFilename).wav in Audio bundle folder")
        return nil
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Warning: Failed to configure audio session: \(error)")
        }
    }

    func startBackgroundMusic() {
        if backgroundPlayer?.isPlaying == true {
            return
        }

        guard let url = backgroundMusicURL() else { return }

        configureAudioSession()

        do {
            backgroundPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundPlayer?.numberOfLoops = -1
            backgroundPlayer?.volume = 0.5
            backgroundPlayer?.prepareToPlay()
            let success = backgroundPlayer?.play() ?? false
            print("Background music play success: \(success)")
        } catch {
            print("Warning: Failed to start background music: \(error)")
        }
    }

    func stopBackgroundMusic() {
        backgroundPlayer?.stop()
        backgroundPlayer = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("Warning: Failed to deactivate audio session: \(error)")
        }
    }
}
