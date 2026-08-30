import SwiftUI
import SwiftData

// MARK: - Parent app (full surface — review, timeline, insights)
//
// Lives ONLY on parent devices. Holds the MEANING: review of iPad-captured
// footage + behavior data, the timeline, control-flip insights, and settings
// including the child-capture consent control.

struct ParentRootView: View {
    var body: some View {
        TabView {
            TimelineView()
                .tabItem { Label("Timeline", systemImage: "list.bullet.rectangle") }

            SessionsView()
                .tabItem { Label("Sessions", systemImage: "play.rectangle") }

            InsightsView()
                .tabItem { Label("Improve", systemImage: "lightbulb") }

            ParentSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

#Preview("Parent app") {
    ParentRootView()
        .environment(Provisioning())
        .modelContainer(AppModelContainer.makePreview())
}
