import Foundation
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private var backgroundPlayer: AVAudioPlayer?
    private(set) var debugStatus: String = "Audio debug not started"

    private let audioFilename = "chicken_loop"

    private init() {}

    // DIAGNOSTIC: Temporary debug implementation to identify why background audio is not playing.
    // Replace with production implementation once root cause is determined.
    func startBackgroundMusic() {
        var lines: [String] = []
        lines.append("Audio debug start")

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            let outputs = session.currentRoute.outputs.map { "\($0.portType.rawValue):\($0.portName)" }.joined(separator: ", ")
            lines.append("session=ok")
            lines.append("route=\(outputs.isEmpty ? "none" : outputs)")
        } catch {
            lines.append("session error=\(error.localizedDescription)")
            debugStatus = lines.joined(separator: "\n")
            return
        }

        let audioPath = Bundle.main.path(forResource: audioFilename, ofType: "wav", inDirectory: "Audio")
        let rootPath = Bundle.main.path(forResource: audioFilename, ofType: "wav")

        lines.append("audioPath=\(audioPath != nil ? "found" : "missing")")
        lines.append("rootPath=\(rootPath != nil ? "found" : "missing")")

        let chosenPath = audioPath ?? rootPath

        guard let chosenPath else {
            lines.append("result=no file in bundle")
            debugStatus = lines.joined(separator: "\n")
            return
        }

        do {
            backgroundPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: chosenPath))
            backgroundPlayer?.numberOfLoops = -1
            backgroundPlayer?.volume = 1.0

            let prepared = backgroundPlayer?.prepareToPlay() ?? false
            let played = backgroundPlayer?.play() ?? false
            let isPlaying = backgroundPlayer?.isPlaying ?? false
            let duration = backgroundPlayer?.duration ?? -1

            lines.append("player init=ok")
            lines.append("prepare=\(prepared)")
            lines.append("play=\(played)")
            lines.append("isPlaying=\(isPlaying)")
            lines.append("duration=\(duration)")
        } catch {
            lines.append("player error=\(error.localizedDescription)")
        }

        debugStatus = lines.joined(separator: "\n")
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
