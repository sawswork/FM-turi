import Foundation
import SwiftData
import TideCore

/// WeatherKit の取得値のキャッシュ。key = CacheKey（地点0.01°＋時間バケット）。
@Model
final class WeatherRecord {
    @Attribute(.unique) var key: String
    var latitude: Double
    var longitude: Double
    var validAt: Date
    var fetchedAt: Date
    var windSpeed: Double
    var windDirection: Double
    var pressure: Double
    var pressureTrend3h: Double
    var airTemperature: Double
    var alerts: [String]
    /// "weatherkit" / "mock"
    var source: String

    init(key: String, point: GeoPoint, snapshot: WeatherSnapshot, source: String) {
        self.key = key
        self.latitude = point.latitude
        self.longitude = point.longitude
        self.validAt = snapshot.validAt
        self.fetchedAt = snapshot.fetchedAt
        self.windSpeed = snapshot.windSpeed
        self.windDirection = snapshot.windDirection
        self.pressure = snapshot.pressure
        self.pressureTrend3h = snapshot.pressureTrend3h
        self.airTemperature = snapshot.airTemperature
        self.alerts = snapshot.alerts
        self.source = source
    }

    var snapshot: WeatherSnapshot {
        WeatherSnapshot(windSpeed: windSpeed, windDirection: windDirection, pressure: pressure,
                        pressureTrend3h: pressureTrend3h, airTemperature: airTemperature,
                        validAt: validAt, fetchedAt: fetchedAt, alerts: alerts)
    }
}
