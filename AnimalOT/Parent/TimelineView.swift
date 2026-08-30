import SwiftUI
import SwiftData

// MARK: - Timeline (LOG pillar, parent side)
//
// Observations over time with media thumbnails, filterable. Tap to view. Seeded
// non-empty so this is live on first open.

struct TimelineView: View {
    @Query(sort: \SensoryObservation.timestamp, order: .reverse)
    private var observations: [SensoryObservation]

    @State private var systemFilter: SensorySystem?
    @State private var showingEditor = false

    private var filtered: [SensoryObservation] {
        guard let f = systemFilter else { return observations }
        return observations.filter { $0.system == f }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "No observations yet",
                        systemImage: "binoculars",
                        description: Text("Play an animal game on the iPad, or add what you saw here.")
                    )
                } else {
                    List {
                        ForEach(filtered) { obs in
                            NavigationLink {
                                ObservationDetailView(observation: obs)
                            } label: {
                                ObservationRow(observation: obs)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All systems") { systemFilter = nil }
                        Divider()
                        ForEach(SensorySystem.allCases) { sys in
                            Button(sys.label) { systemFilter = sys }
                        }
                    } label: {
                        Label(systemFilter?.label ?? "All", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingEditor) {
                ObservationEditor()
            }
        }
    }
}

struct ObservationRow: View {
    let observation: SensoryObservation

    var body: some View {
        HStack(spacing: 12) {
            MediaThumbnail(media: observation.media?.first)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let sys = observation.system {
                        Tag(text: sys.label, color: .blue)
                    }
                    if observation.control != .unknown {
                        Tag(text: observation.control.label,
                            color: observation.control == .controlMet ? .green : .orange)
                    }
                    if observation.isRegulating {
                        Tag(text: "regulating", color: .purple)
                    }
                }
                Text(observation.observationDescription ?? observation.pattern)
                    .font(.subheadline)
                    .lineLimit(2)
                Text(observation.timestamp, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct Tag: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
}

struct MediaThumbnail: View {
    let media: MediaAsset?
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
            if media != nil {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 54, height: 54)
    }
}

#Preview("Timeline") {
    TimelineView()
        .modelContainer(AppModelContainer.makePreview())
}
