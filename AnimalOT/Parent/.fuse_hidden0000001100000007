import SwiftUI
import SwiftData

// MARK: - Parent settings (consent + privacy live here)
//
// Child reaction capture is OFF until a parent turns it ON — explicit, revocable,
// clearly explained. In 1.x this syncs to the kid device; in 1.0 the same family
// iCloud + a parent toggling on the iPad during setup covers it. Surfaced here so
// the consent model is visible and honest from day one.

struct ParentSettingsView: View {
    @Environment(Provisioning.self) private var provisioning
    @State private var captureEnabled = CaptureConsent.isEnabled
    @Query private var children: [Child]

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    if let child = children.first(where: { $0.id == SeedData.childID }) {
                        LabeledContent("Name", value: child.displayName)
                        LabeledContent("Interests", value: child.interests.joined(separator: ", "))
                        LabeledContent("Flags", value: child.profileFlags.joined(separator: ", "))
                    }
                }

                Section {
                    Toggle("Record his reaction on the iPad", isOn: $captureEnabled)
                        .onChange(of: captureEnabled) { _, newValue in
                            CaptureConsent.isEnabled = newValue
                        }
                } header: {
                    Text("Reaction capture")
                } footer: {
                    Text("Off by default. When on, the iPad privately records his face and on-screen play during a game, so you can review it. Footage stays in your family iCloud only — never a third party, never an analytics service. You can pause it any time and delete any clip in one step.")
                }

                Section("Privacy") {
                    Label("Family iCloud only (CloudKit private DB)", systemImage: "lock.icloud")
                    Label("No third-party analytics or SDKs", systemImage: "hand.raised")
                    Label("Delete any clip in one step", systemImage: "trash")
                }

                Section("This device") {
                    LabeledContent("Role", value: provisioning.deviceType == .parent ? "Parent phone" : "—")
                    #if DEBUG
                    Button("Re-provision this device (debug)", role: .destructive) {
                        provisioning.resetForDebug()
                    }
                    #endif
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview("Settings") {
    ParentSettingsView()
        .environment(Provisioning())
        .modelContainer(AppModelContainer.makePreview())
}
