import Foundation
import AVFoundation
import AudioToolbox

// MARK: - Sound engine
//
// Hard requirement #3: tight feedback — the fart/sound fires INSTANTLY with the
// action. Gross humor dies on lag. So we preload players up front and keep them
// warm; triggering just resets currentTime and plays (sub-frame latency).
//
// Drop your own generic, reusable .wav/.m4a assets named to match
// AnimalMaskConfig.soundNames into the app bundle. If an asset is missing we fall
// back to a system sound so the loop never feels broken during bring-up.

@MainActor
final class SoundEngine {

    private var players: [String: AVAudioPlayer] = [:]

    init() {
        configureSession()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // Ambient + mixWithOthers so ARKit / capture audio coexist; low latency.
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    /// Preload a bank so the first trigger has zero load cost.
    func preload(_ names: [String]) {
        for name in names where players[name] == nil {
            guard let url = Self.url(for: name) else { continue }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[name] = player
            }
        }
    }

    /// Fire instantly. `escalation` 0...1 raises volume + pitch for the
    /// escalating-GLEE ladder (bigger is better), never difficulty.
    func fire(_ name: String, escalation: Double = 0) {
        if let player = players[name] {
            player.currentTime = 0
            player.volume = Float(min(1.0, 0.6 + 0.4 * escalation))
            player.enableRate = true
            player.rate = Float(1.0 + 0.15 * escalation)
            player.play()
        } else {
            // Fallback keeps the loop alive before real assets are added.
            AudioServicesPlaySystemSound(SystemSoundID(1057))
        }
    }

    private static func url(for name: String) -> URL? {
        for ext in ["wav", "m4a", "caf", "aiff", "mp3"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}
