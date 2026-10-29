import Foundation

/// 「同一地点・同一時刻の再取得をしない」ためのキー。
/// 地点は 0.01° に丸め、時刻は UTC の1時間バケットにする。
public enum CacheKey {
    public static let secondsPerBucket: TimeInterval = 3600

    /// 時刻のバケット番号（UTC 1時間単位）。
    public static func hourBucket(_ date: Date) -> Int {
        Int((date.timeIntervalSince1970 / secondsPerBucket).rounded(.down))
    }

    /// バケットの開始時刻。
    public static func bucketStart(_ date: Date) -> Date {
        Date(timeIntervalSince1970: TimeInterval(hourBucket(date)) * secondsPerBucket)
    }

    /// 例: "35.14,139.62,h497935"
    public static func make(point: GeoPoint, date: Date) -> String {
        let p = point.rounded
        return String(format: "%.2f,%.2f,h%d", p.latitude, p.longitude, hourBucket(date))
    }

    /// キャッシュが無いときだけ取得する。
    public static func needsFetch(cachedExists: Bool) -> Bool {
        !cachedExists
    }
}
