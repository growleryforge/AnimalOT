import SwiftUI
import SwiftData

// MARK: - Kid home (games only — no assessment surface, ever)
//
// To the child this is purely cool animal games. There is no score, no timeline,
// no settings he can fall into. Just: pick an animal, become it. Led by Lion Cub.

struct KidRootView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Game> { $0.isFirstSet == true },
           sort: \Game.displayOrder)
    private var firstSet: [Game]

    @Query(sort: \MoveCard.displayOrder) private var moves: [MoveCard]

    @State private var selectedGame: Game?
    @State private var selectedMove: MoveCard?
    @State private var bounce = false

    // One row: a flexible column per animal so all four sit side by side.
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 18), count: max(1, firstSet.count))
    }

    private let moveColumns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ZStack {
            // Warm, playful backdrop.
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.86, blue: 0.55),
                         Color(red: 1.0, green: 0.68, blue: 0.55),
                         Color(red: 0.78, green: 0.62, blue: 0.95)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 6) {
                    Text("Pick an animal")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                        .padding(.top, 36)
                    Text("Psst… they’re all a little bit naughty 😼")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.bottom, 14)

                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(Array(firstSet.enumerated()), id: \.element.id) { index, game in
                            AnimalCard(game: game, bounce: bounce, delay: Double(index) * 0.15) {
                                selectedGame = game
                            }
                        }
                    }
                    .padding(.horizontal, 28).padding(.top, 20)

                    if !moves.isEmpty {
                        moveSection
                    }
                }
                .padding(.bottom, 28)
            }
        }
        .onAppear { bounce = true }
        .fullScreenCover(item: $selectedGame) { game in
            AnimalGameView(game: game)
        }
        .fullScreenCover(item: $selectedMove) { move in
            MoveCardView(card: move)
        }
    }

    private var moveSection: some View {
        VStack(spacing: 6) {
            Text("💪 Animal Strength Club")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
                .padding(.top, 26)
            Text("Move like the animals!")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.95))
                .padding(.bottom, 10)

            LazyVGrid(columns: moveColumns, spacing: 16) {
                ForEach(moves) { move in
                    MoveMiniCard(move: move) { selectedMove = move }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

/// A compact, colorful move tile for the kid home.
struct MoveMiniCard: View {
    let move: MoveCard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(move.emoji).font(.system(size: 56))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
                Text(move.name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20).padding(.horizontal, 10)
            .background(
                LinearGradient(colors: [move.color, move.color.opacity(0.7)],
                               startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 24)
            )
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.5), lineWidth: 2))
            .shadow(color: move.color.opacity(0.5), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }
}

/// A big, friendly, fail-free tap target with its own personality.
struct AnimalCard: View {
    let game: Game
    var bounce: Bool = false
    var delay: Double = 0
    let action: () -> Void

    private var kind: AnimalKind { AnimalKind.forGame(game) }

    private var emoji: String {
        switch kind {
        case .lion:    return "🦁"
        case .donkey:  return "🫏"
        case .raccoon: return "🦝"
        case .pig:     return "🐷"
        }
    }

    private var palette: [Color] {
        switch kind {
        case .lion:    return [Color(red: 1.0, green: 0.80, blue: 0.35), Color(red: 0.96, green: 0.55, blue: 0.18)]
        case .donkey:  return [Color(red: 0.72, green: 0.74, blue: 0.72), Color(red: 0.50, green: 0.62, blue: 0.45)]
        case .raccoon: return [Color(red: 0.62, green: 0.55, blue: 0.85), Color(red: 0.40, green: 0.34, blue: 0.62)]
        case .pig:     return [Color(red: 1.0, green: 0.74, blue: 0.82), Color(red: 0.95, green: 0.52, blue: 0.62)]
        }
    }

    private var displayName: String {
        kind == .lion ? "Lion Cub" : game.animalTheme.capitalized
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 76))
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
                    .scaleEffect(bounce ? 1.0 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5)
                        .repeatForever(autoreverses: true).delay(delay), value: bounce)
                Text(displayName)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                Text(game.mischiefHook)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(colors: palette, startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 32)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(.white.opacity(0.55), lineWidth: 2)
            )
            .shadow(color: palette[1].opacity(0.5), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Kid home") {
    KidRootView()
        .modelContainer(AppModelContainer.makePreview())
}
