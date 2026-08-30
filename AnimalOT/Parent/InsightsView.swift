import SwiftUI
import SwiftData

// MARK: - Improve (insights powered by observations)
//
// On first open this is already live: the two seed observations trigger the
// loud-machine control-flip, and the unmapped quiet-vestibular gap surfaces as a
// Play-Next suggestion (Games V1/V2 isolate motion from sound).

struct InsightsView: View {
    @Query(sort: \SensoryObservation.timestamp, order: .reverse) private var observations: [SensoryObservation]
    @Query private var games: [Game]
    @Query private var children: [Child]

    private var childInterests: [String] {
        children.first(where: { $0.id == SeedData.childID })?.interests ?? []
    }

    private var flips: [ControlFlipInsight] {
        InsightEngine.controlFlips(observations: observations)
    }

    private var playNext: PlayNextSuggestion? {
        InsightEngine.playNext(observations: observations, games: games, childInterests: childInterests)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if flips.isEmpty && playNext == nil {
                        ContentUnavailableView(
                            "Insights build as you play",
                            systemImage: "lightbulb",
                            description: Text("Log a few moments and patterns will surface here.")
                        )
                        .padding(.top, 60)
                    }

                    ForEach(flips) { flip in
                        ControlFlipCard(flip: flip)
                    }

                    if let suggestion = playNext {
                        PlayNextCard(suggestion: suggestion)
                    }
                }
                .padding()
            }
            .navigationTitle("Improve")
        }
    }
}

struct ControlFlipCard: View {
    let flip: ControlFlipInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Control-flip", systemImage: "arrow.left.arrow.right.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)

            Text("Control flips his response to \(flip.inputDescription).")
                .font(.title3.weight(.bold))

            HStack(spacing: 12) {
                MiniStat(title: "When HE runs it", value: flip.whenInControl, color: .green)
                MiniStat(title: "When imposed", value: flip.whenImposed, color: .orange)
            }

            Divider()
            Label(flip.lever, systemImage: "key.fill")
                .font(.callout.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding()
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.green.opacity(0.25)))
    }
}

struct MiniStat: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PlayNextCard: View {
    let suggestion: PlayNextSuggestion
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Play next", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.indigo)
            Text(suggestion.reason)
                .font(.callout)
            ForEach(suggestion.games) { game in
                HStack {
                    Text("🎯")
                    VStack(alignment: .leading) {
                        Text(game.title).font(.subheadline.weight(.semibold))
                        Text(game.system.label).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.indigo.opacity(0.25)))
    }
}

#Preview("Improve") {
    InsightsView()
        .modelContainer(AppModelContainer.makePreview())
}
