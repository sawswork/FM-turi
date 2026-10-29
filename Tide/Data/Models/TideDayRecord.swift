import Foundation
import SwiftData
import TideCore

/// 潮汐1日分のキャッシュ。key = "港コード:yyyy-MM-dd"。予測値なので同一キーは再取得しない。
@Model
final class TideDayRecord {
    @Attribute(.unique) var key: String
    var stationCode: String
    var dayStart: Date
    var fetchedAt: Date
    var source: String
    /// TideDay を JSON で保持
    var payload: Data

    init(key: String, stationCode: String, day: TideDay) {
        self.key = key
        self.stationCode = stationCode
        self.dayStart = day.dayStart
        self.fetchedAt = day.fetchedAt
        self.source = day.source
        self.payload = (try? JSONEncoder().encode(day)) ?? Data()
    }

    var day: TideDay? {
        try? JSONDecoder().decode(TideDay.self, from: payload)
    }

    static func key(stationCode: String, dayStart: Date, timeZone: TimeZone) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let c = cal.dateComponents([.year, .month, .day], from: dayStart)
        return String(format: "%@:%04d-%02d-%02d", stationCode, c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
