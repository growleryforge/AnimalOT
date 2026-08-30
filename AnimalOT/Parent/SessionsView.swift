import SwiftUI
import SwiftData

// MARK: - Sessions (review what the iPad captured)
//
// Each GameSession a child played syncs here with its two automatic streams:
// the front-camera reaction clip and the in-app behavior data. The parent reviews
// RAW here, then adds MEANING (an interpretation). RAW on his device, MEANING on
// the parents' phone.

struct SessionsView: View {
    @Query(sort: \GameSession.startedAt, order: .reverse)
    private var sessions: [GameSession]
    @Query private var games: [Game]
    @Query private var moves: [MoveCard]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No play sessions yet",
                        systemImage: "play.rectangle",
                        description: Text("When he plays an animal game on the iPad, the session — his reaction and his choices — lands here.")
                    )
                } else {
                    List(sessions) { session in
                        NavigationLink {
                            SessionReviewView(session: session, game: game(for: session), move: move(for: session))
                        } label: {
                            SessionRow(session: session, game: game(for: session), move: move(for: session))
                        }
                    }
                }
            }
            .navigationTitle("Sessions")
        }
    }

    private func game(for session: GameSession) -> Game? {
        games.first { $0.id == session.gameId }
    }
    private func move(for session: GameSession) -> MoveCard? {
        moves.first { $0.id == session.gameId }
    }
}

struct SessionRow: View {
    let session: GameSession
    let game: Game?
    var move: MoveCard? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: 34))
            VStack(alignment: .leading, spacing: 4) {
                Text(game?.title ?? move?.name ?? "Animal game").font(.headline).lineLimit(1)
                Text(session.startedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Label("\(session.reactionMedia?.count ?? 0)", systemImage: "video")
                    Label("\(session.behaviorEvents?.count ?? 0)", systemImage: "hand.tap")
                    Label("\(session.observations?.count ?? 0)", systemImage: "note.text")
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var emoji: String {
        if let move { return move.emoji }
        guard let game else { return "🐾" }
        switch AnimalKind.forGame(game) {
        case .lion: return "🦁"; case .donkey: return "🫏"; case .raccoon: return "🦝"; case .pig: return "🐷"
        }
    }
}

struct SessionReviewView: View {
    let session: GameSession
    let game: Game?
    var move: MoveCard? = nil

    @State private var showingEditor = false

    var body: some View {
        Form {
            Section("Reaction (from his iPad)") {
                let media = session.reactionMedia ?? []
                if media.isEmpty {
                    Text("No reaction clip. Capture may be off — turn it on in Settings.")
                        .foregroundStyle(.secondary).font(.callout)
                } else {
                    ForEach(media) { MediaPlayerCell(asset: $0) }
                }
            }

            Section("What he did (behavior data)") {
                let events = (session.behaviorEvents ?? []).sorted { $0.at < $1.at }
                if events.isEmpty {
                    Text("No behavior events logged.").foregroundStyle(.secondary).font(.callout)
                } else {
                    ForEach(events) { e in
                        HStack {
                            Image(systemName: icon(for: e.kind))
                            VStack(alignment: .leading) {
                                Text(label(for: e.kind)).font(.subheadline)
                                Text(e.value).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(e.at, format: .dateTime.hour().minute().second())
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            if let observations = session.observations, !observations.isEmpty {
                Section("Your interpretations") {
                    ForEach(observations) { obs in
                        Text(obs.observationDescription ?? obs.pattern)
                    }
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add your interpretation", systemImage: "plus.bubble")
                }
            }
        }
        .navigationTitle(game?.title ?? move?.name ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditor) {
            ObservationEditor(prefillGame: game, sessionToAttach: session)
        }
    }

    private func icon(for kind: BehaviorKind) -> String {
        switch kind {
        case .choice: return "hand.point.up.left"
        case .repeatAction: return "arrow.clockwise"
        case .avoid: return "arrow.uturn.left"
        case .complete: return "checkmark.circle"
        case .controlSet: return "slider.horizontal.3"
        case .duration: return "clock"
        }
    }

    private func label(for kind: BehaviorKind) -> String {
        switch kind {
        case .choice: return "Chose this game"
        case .repeatAction: return "Re-triggered the mischief"
        case .avoid: return "Bailed / avoided"
        case .complete: return "Completed"
        case .controlSet: return "Set a control"
        case .duration: return "Time on game (seconds)"
        }
    }
}

#Preview("Sessions") {
    SessionsView()
        .modelContainer(AppModelContainer.makePreview())
}
