import Foundation
import OSLog
import SwiftData
import TideCore

/// 学習用の書き出し（ml/data と同じ構成: <species_id>/<uuid>.jpg）を ZIP にする。
enum DataExport {
    private static let logger = Logger(subsystem: "jp.tide.app", category: "Export")

    @MainActor
    static func makeTrainingZip(context: ModelContext) -> URL? {
        let descriptor = FetchDescriptor<CatchRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("tide-training", isDirectory: true)
        try? FileManager.default.removeItem(at: root)
        let dataDir = root.appendingPathComponent("data", isDirectory: true)
        var copied = 0
        for record in records {
            guard let name = record.photoFileName else { continue }
            let source = PhotoStore.url(for: name)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            let dir = dataDir.appendingPathComponent(record.speciesID, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            do {
                try FileManager.default.copyItem(at: source, to: dir.appendingPathComponent(name))
                copied += 1
            } catch {
                logger.error("コピーに失敗: \(error.localizedDescription, privacy: .public)")
            }
        }
        guard copied > 0 else { return nil }
        return zip(directory: dataDir)
    }

    /// ディレクトリを ZIP に（NSFileCoordinator の forUploading）。
    static func zip(directory: URL) -> URL? {
        var result: URL?
        var coordinatorError: NSError?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: directory, options: .forUploading, error: &coordinatorError) { zipURL in
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent("tide-training-data.zip")
            try? FileManager.default.removeItem(at: destination)
            do {
                try FileManager.default.copyItem(at: zipURL, to: destination)
                result = destination
            } catch {
                logger.error("ZIP の作成に失敗: \(error.localizedDescription, privacy: .public)")
            }
        }
        return result
    }

    /// すべての記録・写真・キャッシュ・学習結果を消す（釣り場・在庫は初期値に戻す）。
    @MainActor
    static func deleteAll(context: ModelContext) {
        func deleteAll<T: PersistentModel>(_ type: T.Type) {
            let items = (try? context.fetch(FetchDescriptor<T>())) ?? []
            for item in items { context.delete(item) }
        }
        deleteAll(CatchRecord.self)
        deleteAll(WeatherRecord.self)
        deleteAll(MarineRecord.self)
        deleteAll(TideDayRecord.self)
        deleteAll(TideStationConstants.self)
        deleteAll(Spot.self)
        deleteAll(TackleItem.self)
        try? context.save()
        try? FileManager.default.removeItem(at: PhotoStore.directory)
        ScoreWeightsStore.reset()
        WidgetBridge.defaults.removeObject(forKey: WidgetBridge.key)
        SeedData.seedIfNeeded(context: context)
    }
}
