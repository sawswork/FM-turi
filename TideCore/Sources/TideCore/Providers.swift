import Foundation

/// 風・気圧・気温の取得元。本番は WeatherKit、CI/シミュレータは固定値モック。
public protocol WeatherProvider: Sendable {
    /// `date` を含む時間帯の値を返す。
    func weather(at point: GeoPoint, for date: Date) async throws -> WeatherSnapshot
}

/// 波・海水温の取得元。本番は Open-Meteo Marine、CI/シミュレータは固定値モック。
public protocol MarineProvider: Sendable {
    /// `date` の前後を含む時間ごとの値（取得できる範囲すべて）。
    func marine(at point: GeoPoint, around date: Date) async throws -> [MarineSnapshot]
}

/// 固定値モック。値は付録A A-3 の例（WIND 4.2 m/s NE / PRESS 1009 ↓3 / AIR 16.8 / WAVE 0.6 m 7s / SST 19.2）。
public struct MockWeatherProvider: WeatherProvider {
    public var now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = { Date() }) {
        self.now = now
    }

    public func weather(at point: GeoPoint, for date: Date) async throws -> WeatherSnapshot {
        WeatherSnapshot(windSpeed: 4.2, windDirection: 45, pressure: 1009, pressureTrend3h: -3,
                        airTemperature: 16.8, validAt: CacheKey.bucketStart(date), fetchedAt: now())
    }
}

public struct MockMarineProvider: MarineProvider {
    public var now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = { Date() }) {
        self.now = now
    }

    public func marine(at point: GeoPoint, around date: Date) async throws -> [MarineSnapshot] {
        let start = CacheKey.bucketStart(date).addingTimeInterval(-24 * 3600)
        let fetched = now()
        return (0..<72).map { hour in
            MarineSnapshot(waveHeight: 0.6, wavePeriod: 7, swellHeight: 0.4, swellDirection: 160,
                           seaSurfaceTemperature: 19.2,
                           validAt: start.addingTimeInterval(TimeInterval(hour) * 3600),
                           fetchedAt: fetched)
        }
    }
}
