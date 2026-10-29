import Foundation
import OSLog
import SwiftData

/// 初回起動時の投入データ（ADR-0003）。
enum SeedData {
    private static let logger = Logger(subsystem: "jp.tide.app", category: "Seed")

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        var descriptor = FetchDescriptor<Spot>()
        descriptor.fetchLimit = 1
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        for spot in Spot.seedSpots() {
            context.insert(spot)
        }
        do {
            try context.save()
        } catch {
            logger.error("初期データの保存に失敗: \(error.localizedDescription, privacy: .public)")
        }
    }
}
