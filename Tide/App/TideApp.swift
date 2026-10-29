import SwiftData
import SwiftUI

@main
struct TideApp: App {
    @State private var router = AppRouter()
    @State private var location: LocationService
    @State private var conditions: ConditionsStore
    @State private var tide: TideStore
    @State private var spots: SpotsStore
    private let container: ModelContainer

    init() {
        let container = AppContainer.shared
        self.container = container
        _location = State(initialValue: LocationService())
        _conditions = State(initialValue: ConditionsStore.live(context: container.mainContext))
        _tide = State(initialValue: TideStore.live(context: container.mainContext))
        _spots = State(initialValue: SpotsStore(context: container.mainContext))
        SeedData.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
        .environment(router)
        .environment(location)
        .environment(conditions)
        .environment(tide)
        .environment(spots)
    }
}
