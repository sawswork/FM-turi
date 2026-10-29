import Foundation
import OSLog
import SwiftData

/// SwiftData コンテナ。App Group（group.jp.tide.app）上に置き、ウィジェットと共有する（L11）。
enum AppContainer {
    static let appGroupID = "group.jp.tide.app"
    static var schema: Schema {
        Schema([Spot.self, WeatherRecord.self, MarineRecord.self, TideDayRecord.self, CatchRecord.self, TackleItem.self,
                TideStationConstants.self])
    }
    private static let logger = Logger(subsystem: "jp.tide.app", category: "AppContainer")

    @MainActor
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: [configuration(inMemory: false)])
        } catch {
            logger.error("永続ストアを開けないためメモリ上で動作: \(error.localizedDescription, privacy: .public)")
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: [configuration(inMemory: true)])
        }
    }()

    /// プレビュー・テスト用。
    @MainActor
    static func makeInMemory() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: [configuration(inMemory: true)])
    }

    private static func configuration(inMemory: Bool) -> ModelConfiguration {
        if inMemory {
            return ModelConfiguration(isStoredInMemoryOnly: true)
        }
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return ModelConfiguration(url: groupURL.appendingPathComponent("Tide.store"))
        }
        return ModelConfiguration()
    }
}
