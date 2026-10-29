import SwiftData
import SwiftUI
import TideCore

/// プレビュー用のメモリ内データ。
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        // swiftlint:disable:next force_try
        let container = try! AppContainer.makeInMemory()
        for spot in Spot.seedSpots() {
            container.mainContext.insert(spot)
        }
        for item in TackleItem.seedItems() {
            container.mainContext.insert(item)
        }
        return container
    }()

    static let router = AppRouter()
    static let location = LocationService()

    static let conditions = ConditionsStore(context: container.mainContext,
                                            weatherProvider: MockWeatherProvider(),
                                            marineProvider: MockMarineProvider())

    static let tide = TideStore(context: container.mainContext, provider: MockTideProvider())

    static let spots = SpotsStore(context: container.mainContext)
}

extension View {
    /// プレビューに必要な環境をまとめて付ける。
    @MainActor
    func previewEnvironment() -> some View {
        self
            .modelContainer(PreviewData.container)
            .environment(PreviewData.router)
            .environment(PreviewData.location)
            .environment(PreviewData.conditions)
            .environment(PreviewData.tide)
            .environment(PreviewData.spots)
            .preferredColorScheme(.dark)
    }
}
