import SwiftUI
import SwiftData

@main
struct AnimalOTApp: App {

    /// The shared, CloudKit-backed family store.
    let container: ModelContainer = AppModelContainer.makeShared()

    /// Local device identity. Decides the entire surface.
    @State private var provisioning = Provisioning()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(provisioning)
        }
        .modelContainer(container)
    }
}
