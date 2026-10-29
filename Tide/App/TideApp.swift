import SwiftData
import SwiftUI

@main
struct TideApp: App {
    @State private var location: LocationService
    @State private var conditions: ConditionsStore
    private let container: ModelContainer

    init() {
        let container = AppContainer.shared
        self.container = container
        _location = State(initialValue: LocationService())
        _conditions = State(initialValue: ConditionsStore.live(context: container.mainContext))
        SeedData.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
        .environment(location)
        .environment(conditions)
    }
}
