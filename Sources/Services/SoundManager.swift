import Foundation
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private let backgroundMusicFilename = "pixelated_victory"
    private var backgroundPlayer: AVAudioPlayer?

    private init() {}

    private func backgroundMusicURL() -> URL? {
        if let url = Bundle.main.url(
            forResource: backgroundMusicFilename,
            withExtension: "mp3",
            subdirectory: "Audio"
        ) {
            print("Resolved background music URL: \(url)")
            return url
        }

        print("Warning: Missing background music file \(backgroundMusicFilename).mp3 in Audio bundle folder")
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

    // DIAGNOSTIC: Temporary debug implementation to identify why background audio is not playing.
    // Replace with production implementation once root cause is determined.
    func startBackgroundMusic() {

        print("=== START BACKGROUND MUSIC DEBUG ===")

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            print("Audio session category:", session.category.rawValue)
            print("Audio outputs:", session.currentRoute.outputs.map { "\($0.portType.rawValue): \($0.portName)" })
            print("Secondary audio silenced:", session.secondaryAudioShouldBeSilencedHint)

        } catch {
            print("AUDIO SESSION ERROR:", error)
        }

        let fm = FileManager.default

        print("Bundle resourcePath:", Bundle.main.resourcePath ?? "nil")

        if let root = Bundle.main.resourcePath,
           let rootItems = try? fm.contentsOfDirectory(atPath: root) {
            print("Bundle root contents:", rootItems)
        }

        if let audioPath = Bundle.main.path(
            forResource: "chicken_loop",
            ofType: "wav",
            inDirectory: "Audio"
        ) {

            print("FOUND Audio/chicken_loop.wav at:", audioPath)

            do {

                let attrs = try fm.attributesOfItem(atPath: audioPath)
                print("File attributes:", attrs)

                backgroundPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath))

                backgroundPlayer?.numberOfLoops = -1
                backgroundPlayer?.volume = 1.0

                let prepared = backgroundPlayer?.prepareToPlay() ?? false
                let played = backgroundPlayer?.play() ?? false

                print("prepareToPlay:", prepared)
                print("duration:", backgroundPlayer?.duration ?? -1)
                print("format settings:", backgroundPlayer?.settings ?? [:])
                print("isPlaying:", backgroundPlayer?.isPlaying ?? false)
                print("play() returned:", played)

            } catch {
                print("PLAYER INIT/PLAY ERROR:", error)
            }

        } else {

            print("NOT FOUND: Audio/chicken_loop.wav")

        }

        if let rootPath = Bundle.main.path(
            forResource: "chicken_loop",
            ofType: "wav"
        ) {

            print("FOUND chicken_loop.wav at bundle root:", rootPath)

        } else {

            print("NOT FOUND at bundle root either")

        }

        print("=== END BACKGROUND MUSIC DEBUG ===")
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
