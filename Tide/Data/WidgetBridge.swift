import Foundation
import OSLog
import TideCore
import WidgetKit

/// アプリ→ウィジェットの受け渡し（App Group の UserDefaults）。
enum WidgetBridge {
    static let appGroupID = "group.jp.tide.app"
    static let key = "widget.snapshot.v1"
    private static let logger = Logger(subsystem: "jp.tide.app", category: "WidgetBridge")

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func save(_ snapshot: WidgetSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults.set(data, forKey: key)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            logger.error("ウィジェット用データの保存に失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
