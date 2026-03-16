import Foundation
import AVFoundation
import SpriteKit

final class SoundManager {
    static let shared = SoundManager()

    private var backgroundPlayer: AVAudioPlayer?

    private init() {}

    // MARK: - Background Music

    func startBackgroundMusic() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Warning: Failed to configure audio session: \(error)")
            return
        }

        guard let path = audioPath(name: "chicken_loop", ext: "wav") else {
            print("Warning: Missing background music file chicken_loop.wav")
            return
        }

        do {
            backgroundPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            backgroundPlayer?.numberOfLoops = -1
            backgroundPlayer?.volume = 0.25
            backgroundPlayer?.prepareToPlay()
            backgroundPlayer?.play()
        } catch {
            print("Warning: Failed to create background music player: \(error)")
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

    // MARK: - Effect Helpers

    private func audioPath(name: String, ext: String) -> String? {
        if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "Audio") {
            return path
        }
        return Bundle.main.path(forResource: name, ofType: ext)
    }

    func soundAction(name: String, ext: String = "mp3") -> SKAction? {
        guard audioPath(name: name, ext: ext) != nil else {
            print("Warning: Missing sound file \(name).\(ext)")
            return nil
        }
        return SKAction.playSoundFileNamed("Audio/\(name).\(ext)", waitForCompletion: false)
    }
}
