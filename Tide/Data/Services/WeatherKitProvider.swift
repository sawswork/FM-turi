import CoreLocation
import Foundation
import TideCore
import WeatherKit

/// WeatherKit 実装。Capability 未設定（L16 まで）だと throw するので呼び出し側がモックへ退避する。
struct WeatherKitProvider: WeatherProvider {
    func weather(at point: GeoPoint, for date: Date) async throws -> WeatherSnapshot {
        let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let start = CacheKey.bucketStart(date).addingTimeInterval(-3 * 3600)
        let end = CacheKey.bucketStart(date).addingTimeInterval(24 * 3600)
        let (current, hourly) = try await WeatherService.shared.weather(
            for: location,
            including: .current, .hourly(startDate: start, endDate: end)
        )
        let bucket = CacheKey.bucketStart(date)
        let hours = hourly.forecast
        let atNow = hours.first { CacheKey.bucketStart($0.date) == bucket }
        let before3h = hours.first { CacheKey.bucketStart($0.date) == bucket.addingTimeInterval(-3 * 3600) }
        let pressureNow = atNow?.pressure.converted(to: .hectopascals).value
            ?? current.pressure.converted(to: .hectopascals).value
        let trend = before3h.map { pressureNow - $0.pressure.converted(to: .hectopascals).value } ?? 0
        return WeatherSnapshot(
            windSpeed: (atNow?.wind.speed ?? current.wind.speed).converted(to: .metersPerSecond).value,
            windDirection: (atNow?.wind.direction ?? current.wind.direction).converted(to: .degrees).value,
            pressure: pressureNow,
            pressureTrend3h: trend,
            airTemperature: (atNow?.temperature ?? current.temperature).converted(to: .celsius).value,
            validAt: bucket,
            fetchedAt: Date()
        )
    }
}
