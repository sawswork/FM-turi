import Foundation
import TideCore

/// 表示用の日時フォーマッタ（JST、ja_JP）。
@MainActor
enum TimeFormat {
    private static func make(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.timeZone = Tide736.timeZone
        f.dateFormat = format
        return f
    }

    /// "14:30"
    static let hourMinute = make("HH:mm")
    /// "10/30 金"
    static let monthDayWeekday = make("M/d E")
    /// "10/30 金 14:30"
    static let monthDayWeekdayTime = make("M/d E HH:mm")
    /// "10/30 14:30"
    static let monthDayTime = make("M/d HH:mm")

    static func hm(_ date: Date?) -> String {
        guard let date else { return "--:--" }
        return hourMinute.string(from: date)
    }
}
