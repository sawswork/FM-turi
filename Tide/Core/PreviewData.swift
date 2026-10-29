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
        return container
    }()

    static let location = LocationService()

    static let conditions = ConditionsStore(context: container.mainContext,
                                            weatherProvider: MockWeatherProvider(),
                                            marineProvider: MockMarineProvider())
}

extension View {
    /// プレビューに必要な環境をまとめて付ける。
    @MainActor
    func previewEnvironment() -> some View {
        self
            .modelContainer(PreviewData.container)
            .environment(PreviewData.location)
            .environment(PreviewData.conditions)
            .preferredColorScheme(.dark)
    }
}
