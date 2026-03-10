import Foundation
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private let backgroundMusicFilename = "563603__badoink__chicken-loop"
    private var backgroundPlayer: AVAudioPlayer?

    private init() {}

    private func backgroundMusicURL() -> URL? {
        if let url = Bundle.main.url(
            forResource: backgroundMusicFilename,
            withExtension: "wav",
            subdirectory: "Audio"
        ) {
            return url
        }

        if let url = Bundle.main.url(
            forResource: backgroundMusicFilename,
            withExtension: "wav",
            subdirectory: "Sounds"
        ) {
            return url
        }

        if let url = Bundle.main.url(
            forResource: backgroundMusicFilename,
            withExtension: "wav"
        ) {
            return url
        }

        print("Warning: Missing background music file \(backgroundMusicFilename).wav")
        return nil
    }

    func startBackgroundMusic() {
        guard let url = backgroundMusicURL() else { return }

        do {
            backgroundPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundPlayer?.numberOfLoops = -1
            backgroundPlayer?.volume = 0.5
            backgroundPlayer?.prepareToPlay()
            backgroundPlayer?.play()
        } catch {
            print("Warning: Failed to start background music: \(error)")
        }
    }

    func stopBackgroundMusic() {
        backgroundPlayer?.stop()
        backgroundPlayer = nil
    }
}
