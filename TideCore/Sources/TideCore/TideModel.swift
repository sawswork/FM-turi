import Foundation

/// 満潮・干潮の1点。
public struct TideExtreme: Hashable, Codable, Sendable {
    public var time: Date
    public var heightCm: Double

    public init(time: Date, heightCm: Double) {
        self.time = time
        self.heightCm = heightCm
    }
}

/// 1日分の潮汐（現地の0時から）。
public struct TideDay: Hashable, Codable, Sendable {
    /// 現地時間の 0:00
    public var dayStart: Date
    /// `interval` ごとの潮位（cm）。index 0 が dayStart。
    public var levels: [Double]
    public var interval: TimeInterval
    public var highs: [TideExtreme]
    public var lows: [TideExtreme]
    public var sunrise: Date?
    public var sunset: Date?
    public var moonAge: Double
    public var tideType: TideType
    public var fetchedAt: Date
    /// "tide736" / "harmonic" / "mock"
    public var source: String

    public init(dayStart: Date, levels: [Double], interval: TimeInterval, highs: [TideExtreme], lows: [TideExtreme],
                sunrise: Date?, sunset: Date?, moonAge: Double, tideType: TideType, fetchedAt: Date, source: String) {
        self.dayStart = dayStart
        self.levels = levels
        self.interval = interval
        self.highs = highs
        self.lows = lows
        self.sunrise = sunrise
        self.sunset = sunset
        self.moonAge = moonAge
        self.tideType = tideType
        self.fetchedAt = fetchedAt
        self.source = source
    }

    /// 任意時刻の潮位（線形補間）。範囲外は nil。
    public func level(at date: Date) -> Double? {
        guard levels.count >= 2, interval > 0 else { return levels.first }
        let offset = date.timeIntervalSince(dayStart) / interval
        guard offset >= 0, offset <= Double(levels.count - 1) else { return nil }
        let index = Int(offset.rounded(.down))
        if index >= levels.count - 1 { return levels[levels.count - 1] }
        let fraction = offset - Double(index)
        return levels[index] + (levels[index + 1] - levels[index]) * fraction
    }

    /// 現時点の潮の向き（上げ=true、下げ=false）。1時間先との比較。
    public func isRising(at date: Date) -> Bool? {
        guard let now = level(at: date), let later = level(at: date.addingTimeInterval(3600)) else { return nil }
        return later >= now
    }

    /// 24 点（毎正時）の潮位。グラフ用。
    public var hourlyLevels: [Double] {
        (0..<24).compactMap { hour in level(at: dayStart.addingTimeInterval(TimeInterval(hour) * 3600)) }
    }
}

/// 潮汐の取得元。M1 は tide736、M3 で端末内計算に置換。
public protocol TideProvider: Sendable {
    /// `dayStart` から `days` 日分。
    func tide(at point: GeoPoint, from dayStart: Date, days: Int, timeZone: TimeZone) async throws -> [TideDay]
}

/// 固定値モック（半日周潮の正弦波。付録A の例: 満潮 08:40 / 20:55、干潮 02:18 / 14:50 に近い形）。
public struct MockTideProvider: TideProvider {
    public var now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = { Date() }) {
        self.now = now
    }

    public func tide(at point: GeoPoint, from dayStart: Date, days: Int, timeZone: TimeZone) async throws -> [TideDay] {
        let fetched = now()
        return (0..<days).map { dayIndex in
            let start = dayStart.addingTimeInterval(TimeInterval(dayIndex) * 86_400)
            return Self.synthesize(dayStart: start, point: point, timeZone: timeZone, fetchedAt: fetched)
        }
    }

    public static func synthesize(dayStart: Date, point: GeoPoint, timeZone: TimeZone, fetchedAt: Date) -> TideDay {
        let period = 12.42 * 3600
        let amplitude = 60.0
        let mean = 85.0
        // 2026-10-30 08:40 を満潮とする位相
        let referenceHigh = Date(timeIntervalSince1970: 1_793_403_600) // 2026-10-30T08:40+09:00
        func level(_ date: Date) -> Double {
            mean + amplitude * cos(2 * .pi * date.timeIntervalSince(referenceHigh) / period)
        }
        let interval: TimeInterval = 600
        let count = Int(86_400 / interval) + 1
        let levels = (0..<count).map { level(dayStart.addingTimeInterval(TimeInterval($0) * interval)) }
        var highs: [TideExtreme] = []
        var lows: [TideExtreme] = []
        for i in 1..<(count - 1) {
            let t = dayStart.addingTimeInterval(TimeInterval(i) * interval)
            if levels[i] > levels[i - 1], levels[i] >= levels[i + 1] { highs.append(TideExtreme(time: t, heightCm: levels[i])) }
            if levels[i] < levels[i - 1], levels[i] <= levels[i + 1] { lows.append(TideExtreme(time: t, heightCm: levels[i])) }
        }
        let sun = SunCalc.times(on: dayStart.addingTimeInterval(3600), at: point, timeZone: timeZone)
        let age = MoonCalc.age(at: dayStart.addingTimeInterval(12 * 3600))
        return TideDay(dayStart: dayStart, levels: levels, interval: interval, highs: highs, lows: lows,
                       sunrise: sun.sunrise, sunset: sun.sunset, moonAge: age, tideType: MoonCalc.tideType(age: age),
                       fetchedAt: fetchedAt, source: "mock")
    }
}
