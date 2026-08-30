import Foundation
import UIKit

// MARK: - Animal mask configuration
//
// A light face overlay (ears, snout, whiskers, eyes, and — for the lion — a full
// mane) attached to the ARKit face anchor. NOT a full-body avatar (deferred 2.0).
// Colors here drive the richer procedural geometry in AnimalFeatureNode. Keep them
// swappable so families could add their own.

enum AnimalKind: String {
    case lion     // his animal: ROAR (gross-loud lane)
    case donkey   // gross-LOUD
    case raccoon  // sneaky
    case pig      // gross-MESSY

    /// Map a seed game to its mask. Falls back to the lion (his animal).
    static func forGame(_ game: Game) -> AnimalKind {
        switch game.id {
        case SeedData.lionID:       return .lion
        case SeedData.grossLoudID:  return .donkey
        case SeedData.sneakyID:     return .raccoon
        case SeedData.grossMessyID: return .pig
        default:
            let t = game.animalTheme.lowercased()
            if t.contains("lion") { return .lion }
            if t.contains("raccoon") || t.contains("cat") || t.contains("fox") { return .raccoon }
            if t.contains("pig") || t.contains("dog") { return .pig }
            return .donkey
        }
    }
}

/// How the child triggers the mischief for this animal.
enum TriggerStyle {
    case mouth   // open mouth wide (roar / toot / oink / pounce)
    case buck    // throw head back, chin up (the donkey's kick)
}

struct AnimalMaskConfig {
    let kind: AnimalKind
    let furColor: UIColor       // ears / cheek tufts
    let snoutColor: UIColor     // muzzle
    let earColor: UIColor       // outer ear
    let innerColor: UIColor     // inner ear / accents
    let noseColor: UIColor      // nose tip
    let maneColor: UIColor?     // lion mane (nil = none)
    let hasWhiskers: Bool
    /// The sound bank this animal pulls from (file names, sans extension).
    let soundNames: [String]
    /// Whether opening the mouth should fire a sound (the gross-loud lever).
    let mouthFiresSound: Bool
    /// How this animal is triggered.
    let triggerStyle: TriggerStyle

    static func config(for kind: AnimalKind) -> AnimalMaskConfig {
        switch kind {
        case .lion:
            return AnimalMaskConfig(
                kind: .lion,
                furColor: UIColor(red: 0.97, green: 0.82, blue: 0.55, alpha: 1),
                snoutColor: UIColor(red: 0.99, green: 0.90, blue: 0.70, alpha: 1),
                earColor: UIColor(red: 0.93, green: 0.74, blue: 0.44, alpha: 1),
                innerColor: UIColor(red: 0.45, green: 0.27, blue: 0.14, alpha: 1),
                noseColor: UIColor(red: 0.42, green: 0.24, blue: 0.16, alpha: 1),
                maneColor: UIColor(red: 0.85, green: 0.52, blue: 0.18, alpha: 1),
                hasWhiskers: true,
                soundNames: ["roar", "growl", "rawr"],
                mouthFiresSound: true,
                triggerStyle: .mouth
            )
        case .donkey:
            return AnimalMaskConfig(
                kind: .donkey,
                furColor: UIColor(red: 0.66, green: 0.62, blue: 0.59, alpha: 1),
                snoutColor: UIColor(red: 0.52, green: 0.48, blue: 0.46, alpha: 1),
                earColor: UIColor(red: 0.58, green: 0.54, blue: 0.51, alpha: 1),
                innerColor: UIColor(red: 0.85, green: 0.72, blue: 0.72, alpha: 1),
                noseColor: UIColor(red: 0.26, green: 0.23, blue: 0.22, alpha: 1),
                maneColor: nil,
                hasWhiskers: false,
                soundNames: ["bray", "fart", "burp"],
                mouthFiresSound: false,        // donkey is triggered by a head-back BUCK
                triggerStyle: .buck
            )
        case .raccoon:
            return AnimalMaskConfig(
                kind: .raccoon,
                furColor: UIColor(red: 0.55, green: 0.56, blue: 0.60, alpha: 1),
                snoutColor: UIColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1),
                earColor: UIColor(red: 0.40, green: 0.41, blue: 0.45, alpha: 1),
                innerColor: UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1),
                noseColor: UIColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1),
                maneColor: nil,
                hasWhiskers: true,
                soundNames: ["pounce", "chitter"],
                mouthFiresSound: true,   // mouth-open = the pounce; charges the sneak ladder
                triggerStyle: .mouth
            )
        case .pig:
            return AnimalMaskConfig(
                kind: .pig,
                furColor: UIColor(red: 0.97, green: 0.76, blue: 0.78, alpha: 1),
                snoutColor: UIColor(red: 0.94, green: 0.62, blue: 0.66, alpha: 1),
                earColor: UIColor(red: 0.95, green: 0.70, blue: 0.73, alpha: 1),
                innerColor: UIColor(red: 0.86, green: 0.48, blue: 0.54, alpha: 1),
                noseColor: UIColor(red: 0.80, green: 0.45, blue: 0.50, alpha: 1),
                maneColor: nil,
                hasWhiskers: false,
                soundNames: ["oink", "splat", "shake"],
                mouthFiresSound: true,
                triggerStyle: .mouth
            )
        }
    }
}
