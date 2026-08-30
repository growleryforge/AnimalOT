import Foundation
import SwiftUI
import UIKit

// MARK: - The mischief ladder (the loop / the "what next")
//
// The hook (mirror + sound) is only the doorway. The GAME is the climb: each bit
// of mischief charges a meter, the world reacts MORE at every rung, and at the top
// it erupts in a big payoff — then resets and invites him to do it again.
//
// Design rules honored:
//  • Escalating GLEE, not difficulty — the meter only ever goes UP and celebrates.
//  • No fail state — there is nothing to lose, no timer, no "too slow."
//  • Bailing is data, never a felt failure — if he stops, the charge gently eases
//    down; it never scolds or resets to punish.

@MainActor
@Observable
final class MischiefMeter {

    /// 0...1 fill toward the next payoff.
    private(set) var charge: Double = 0
    /// 0 = idle, 1/2 = building, 3 = at the top (about to/over the blowout).
    private(set) var tier: Int = 0
    /// Number of big payoffs he's set off this session (a tally, never a target).
    private(set) var blowoutCount: Int = 0
    /// True for the ~1.2s of the eruption so the view can go big.
    private(set) var isBlowingOut: Bool = false
    /// Bumps each blowout so the view can trigger a fresh burst animation.
    private(set) var blowoutTick: Int = 0

    private var lastFire = Date.distantPast
    private var decayTimer: Timer?
    private let haptic = UIImpactFeedbackGenerator(style: .heavy)
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)

    func start() {
        haptic.prepare()
        lightHaptic.prepare()
        decayTimer?.invalidate()
        decayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.decayTick() }
        }
    }

    func stop() {
        decayTimer?.invalidate()
        decayTimer = nil
    }

    /// He did the mischief again (mouth-open). Returns the charge AFTER this bump
    /// so the caller can scale sound + glee to how full the meter is.
    @discardableResult
    func registerFire() -> Double {
        guard !isBlowingOut else { return charge }
        let now = Date()
        let rapid = now.timeIntervalSince(lastFire) < 0.8   // reward keeping it going
        lastFire = now
        charge = min(1.0, charge + (rapid ? 0.22 : 0.15))
        lightHaptic.impactOccurred(intensity: CGFloat(0.4 + 0.6 * charge))
        updateTier()
        if charge >= 1.0 { triggerBlowout() }
        return charge
    }

    private func updateTier() {
        tier = charge >= 0.999 ? 3 : min(2, Int(charge * 3))
    }

    private func triggerBlowout() {
        isBlowingOut = true
        blowoutCount += 1
        blowoutTick += 1
        tier = 3
        haptic.impactOccurred()
        // Hold the eruption, then reset and invite another go.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            self.charge = 0
            self.tier = 0
            self.isBlowingOut = false
            self.haptic.prepare()
        }
    }

    private func decayTick() {
        guard !isBlowingOut, charge > 0 else { return }
        charge = max(0, charge - 0.012)   // gentle ease-down if he pauses
        updateTier()
    }
}

// MARK: - Per-animal theming for the ladder

struct MischiefTheme {
    let powerLabel: String      // the meter's name
    let barColor: Color
    let payoffText: String      // shouted at the top
    let payoffEmoji: String     // the big central pop
    let burstEmojis: [String]   // confetti during the eruption
    let buildEmojis: [String]   // little puffs on each fire while building

    static func theme(for kind: AnimalKind) -> MischiefTheme {
        switch kind {
        case .lion:
            return MischiefTheme(
                powerLabel: "ROAR POWER",
                barColor: .orange,
                payoffText: "MIGHTY ROOOAR!",
                payoffEmoji: "🦁",
                burstEmojis: ["🦁", "💥", "🔊", "⭐️", "😤"],
                buildEmojis: ["🦁", "💢", "😼"]
            )
        case .donkey:
            return MischiefTheme(
                powerLabel: "KICK POWER",
                barColor: .green,
                payoffText: "MEGA KICK! 🫏💥",
                payoffEmoji: "🫏",
                burstEmojis: ["🫏", "💥", "💨", "🌪️", "😆"],
                buildEmojis: ["💥", "🫏", "😝"]
            )
        case .pig:
            return MischiefTheme(
                powerLabel: "MUD POWER",
                barColor: .brown,
                payoffText: "SPLAT-SPLOSION!",
                payoffEmoji: "🟤",
                burstEmojis: ["🟤", "💦", "🐷", "😆", "💥"],
                buildEmojis: ["🟤", "💦", "🐽"]
            )
        case .raccoon:
            return MischiefTheme(
                powerLabel: "SNEAK POWER",
                barColor: .purple,
                payoffText: "POUNCE! 🍪 GOTCHA!",
                payoffEmoji: "🦝",
                burstEmojis: ["✨", "🍪", "🦝", "😼", "💥"],
                buildEmojis: ["✨", "🤫", "👣"]
            )
        }
    }
}
