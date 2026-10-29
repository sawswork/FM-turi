import AppIntents
import Foundation
import SwiftData
import TideCore
import WidgetKit

/// ウィジェットの −/+。共有 SwiftData の在庫を直接更新し、スナップショットも書き換える（アプリを開かない）。
struct AdjustStockIntent: AppIntent {
    static let title: LocalizedStringResource = "在庫を変更"
    static let isDiscoverable = false

    @Parameter(title: "種類")
    var kind: String
    @Parameter(title: "サイズ")
    var label: String
    @Parameter(title: "増減")
    var delta: Int

    init() {
        kind = "sinker"
        label = ""
        delta = 0
    }

    init(kind: String, label: String, delta: Int) {
        self.kind = kind
        self.label = label
        self.delta = delta
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = AppContainer.shared.mainContext
        let key = "\(kind):\(label)"
        var descriptor = FetchDescriptor<TackleItem>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        if let item = (try? context.fetch(descriptor))?.first {
            item.stock = max(0, item.stock + delta)
            try? context.save()
        }
        StockSync.publish(context: context)
        return .result()
    }
}

/// 在庫のスナップショット更新（アプリの Tackle 画面とウィジェットの両方から呼ぶ）。
enum StockSync {
    @MainActor
    static func publish(context: ModelContext) {
        let descriptor = FetchDescriptor<TackleItem>(sortBy: [SortDescriptor(\.sortOrder)])
        let items = (try? context.fetch(descriptor)) ?? []
        guard var snapshot = WidgetBridge.load() else {
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        snapshot.sinkers = items.filter { $0.kind == .sinker }.map { WidgetSnapshot.Stock(label: $0.label, count: $0.stock) }
        snapshot.hooks = items.filter { $0.kind == .hook }.map { WidgetSnapshot.Stock(label: $0.label, count: $0.stock) }
        WidgetBridge.save(snapshot)
    }
}
