import Foundation
import SwiftData
import SwiftUI

// MARK: - MoveCard (the OT "animal move" exercises)
//
// Whole-body animal movement cards (Crocodile Crawl, Bear Walk, Lion Pose…) the
// family authored. These are DATA, loaded from the bundled AnimalMoves.json so the
// deck can be edited without code changes. The child sees the emoji + name +
// simple instruction; the clinical `targets` ride along for the parent side.

@Model
final class MoveCard {
    var id: UUID = UUID()
    var slug: String = ""           // stable id from JSON, e.g. "bear_walk"
    var deck: String = ""           // deck title
    var name: String = ""
    var emoji: String = ""
    var kidInstruction: String = ""
    var targets: [String] = []      // clinical, parent-side only
    var difficulty: Int = 1         // 1...5
    var themeColorHex: String = "#888888"
    var displayOrder: Int = 0

    init(id: UUID = UUID(),
         slug: String = "",
         deck: String = "",
         name: String = "",
         emoji: String = "",
         kidInstruction: String = "",
         targets: [String] = [],
         difficulty: Int = 1,
         themeColorHex: String = "#888888",
         displayOrder: Int = 0) {
        self.id = id
        self.slug = slug
        self.deck = deck
        self.name = name
        self.emoji = emoji
        self.kidInstruction = kidInstruction
        self.targets = targets
        self.difficulty = difficulty
        self.themeColorHex = themeColorHex
        self.displayOrder = displayOrder
    }

    var color: Color { Color(hex: themeColorHex) ?? .gray }

    /// Map the move's targets to a sensory system for parent insights.
    var system: SensorySystem {
        let t = targets.joined(separator: " ").lowercased()
        if t.contains("vestibular") || t.contains("balance") { return .vestibular }
        if t.contains("proprioceptive") || t.contains("heavy") { return .proprioceptive }
        if t.contains("tactile") { return .tactile }
        return .praxis   // strength / coordination / motor planning
    }
}

// MARK: - JSON shapes (decoding AnimalMoves.json)

struct MoveDeckFile: Decodable {
    let decks: [MoveDeck]
}
struct MoveDeck: Decodable {
    let id: String
    let title: String
    let cards: [MoveCardDTO]
}
struct MoveCardDTO: Decodable {
    let id: String
    let name: String
    let emoji: String
    let kidInstruction: String
    let targets: [String]
    let difficulty: Int
    let themeColor: String
}

// MARK: - Hex color helper

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self = Color(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
