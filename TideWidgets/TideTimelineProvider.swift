import Foundation
import TideCore
import WidgetKit

struct TideEntry: TimelineEntry, Sendable {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// アプリが書き出した WidgetSnapshot を読み、毎正時にエントリを切り替える。
struct TideTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TideEntry {
        TideEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TideEntry) -> Void) {
        completion(TideEntry(date: Date(), snapshot: WidgetBridge.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TideEntry>) -> Void) {
        let snapshot = WidgetBridge.load() ?? .placeholder
        let now = Date()
        var entries = [TideEntry(date: now, snapshot: snapshot)]
        let next = CacheKey.bucketStart(now).addingTimeInterval(3600)
        for hour in 0..<6 {
            entries.append(TideEntry(date: next.addingTimeInterval(TimeInterval(hour) * 3600), snapshot: snapshot))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
