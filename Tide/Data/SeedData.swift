import Foundation
import OSLog
import SwiftData

/// 初回起動時の投入データ（ADR-0003）。
enum SeedData {
    private static let logger = Logger(subsystem: "jp.tide.app", category: "Seed")

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        var spotDescriptor = FetchDescriptor<Spot>()
        spotDescriptor.fetchLimit = 1
        if ((try? context.fetch(spotDescriptor)) ?? []).isEmpty {
            for spot in Spot.seedSpots() {
                context.insert(spot)
            }
        }
        var tackleDescriptor = FetchDescriptor<TackleItem>()
        tackleDescriptor.fetchLimit = 1
        if ((try? context.fetch(tackleDescriptor)) ?? []).isEmpty {
            for item in TackleItem.seedItems() {
                context.insert(item)
            }
        }
        do {
            try context.save()
        } catch {
            logger.error("初期データの保存に失敗: \(error.localizedDescription, privacy: .public)")
        }
    }
}
