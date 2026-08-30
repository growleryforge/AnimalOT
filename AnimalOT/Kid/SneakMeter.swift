import Foundation
import SwiftUI
import UIKit

// MARK: - The sneak game (the raccoon's loop — real movement grading)
//
// The mischief is STILLNESS: he creeps up on a cookie by holding still, and the
// raccoon sneaks closer on its own. Catch enough cookies and the raccoon gets a
// FULL BELLY — a big celebration. Two ways to win, so progress always happens:
//   • Hold still until the meter fills → the raccoon creeps all the way and GRABS
//     it automatically (clear cause/effect, no timing skill needed).
//   • Once "ready", open wide to POUNCE and snatch it early for extra flair.
//
// Tuned to be forgiving — a 7-year-old holding an iPad can't be perfectly still —
// while still surfacing movement grading & timing. No fail: an early pounce just
// lets the cookie skitter with a giggle ("so close — sneak again").

@MainActor
@Observable
final class SneakMeter {

    enum Phase { case sneaking, caught, skittered }

    /// 0...1 — how close he's crept (fills while still).
    private(set) var charge = 0.0
    private(set) var phase: Phase = .sneaking
    /// Total cookies this session.
    private(set) var caught = 0
    /// Cookies in the current stash (resets each FULL BELLY).
    private(set) var stash = 0
    /// Cookies needed for the next belly. Starts EASY (2) and grows by one each
    /// time he fills it, so the first win is quick and it lasts a little longer
    /// every round — earned, never harder to trigger.
    var stashGoal: Int { min(6, 2 + feasts) }
    /// Full bellies this session.
    private(set) var feasts = 0
    /// Bumps so the view can fire a catch / feast animation.
    private(set) var catchTick = 0
    private(set) var feastTick = 0
    private(set) var missTick = 0
    private(set) var isStill = false
    /// True for the duration of a FULL BELLY celebration.
    private(set) var isFeasting = false

    /// Forgiving: normal small wobble still counts as "holding still".
    let stillThreshold = 0.22
    /// Once this close, a pounce lands (and the glow says "now!").
    let readyThreshold = 0.5

    private var cooldown = false
    private let success = UINotificationFeedbackGenerator()
    private let thud = UIImpactFeedbackGenerator(style: .rigid)

    var isReady: Bool { charge >= readyThreshold }
    var justFeasted: Bool { isFeasting }

    func start() {
        success.prepare()
        thud.prepare()
    }

    /// Per-frame head motion. Still → creep closer; full → auto-grab.
    func registerMotion(_ motion: Double) {
        guard phase == .sneaking, !cooldown else { return }
        isStill = motion < stillThreshold
        if isStill {
            charge = min(1.0, charge + 0.024)       // ~0.7s of reasonable stillness
            if charge >= 1.0 { succeed() }          // crept all the way → auto-catch
        } else {
            charge = max(0.0, charge - 0.008 * motion)  // gentle, never punishing
        }
    }

    /// He pounced (mouth-open). Lands if he's crept close enough; else skitters.
    @discardableResult
    func pounce() -> Bool {
        guard phase == .sneaking, !cooldown else { return false }
        if isReady { succeed(); return true }
        miss()
        return false
    }

    // MARK: Outcomes

    private func succeed() {
        guard !cooldown else { return }
        cooldown = true
        phase = .caught
        caught += 1
        stash += 1
        catchTick += 1
        success.notificationOccurred(.success)

        if stash >= stashGoal {
            isFeasting = true       // tray stays full + celebration shows
            feastTick += 1
            // Big party, then grow the goal and clear the stash for the next belly.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
                guard let self else { return }
                self.feasts += 1     // next belly needs one more (lasts longer)
                self.stash = 0
                self.isFeasting = false
                self.resetToSneaking()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
                self?.resetToSneaking()
            }
        }
    }

    private func miss() {
        cooldown = true
        phase = .skittered
        missTick += 1
        thud.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.resetToSneaking()
        }
    }

    private func resetToSneaking() {
        charge = 0
        phase = .sneaking
        cooldown = false
        success.prepare()
        thud.prepare()
    }
}
