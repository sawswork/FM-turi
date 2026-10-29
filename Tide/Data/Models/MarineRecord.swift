import Foundation
import SwiftData
import TideCore

/// Open-Meteo Marine の取得値のキャッシュ（1時間ごとに1行）。
@Model
final class MarineRecord {
    @Attribute(.unique) var key: String
    var latitude: Double
    var longitude: Double
    var validAt: Date
    var fetchedAt: Date
    var waveHeight: Double
    var wavePeriod: Double
    var swellHeight: Double
    var swellDirection: Double
    var seaSurfaceTemperature: Double
    var source: String

    init(key: String, point: GeoPoint, snapshot: MarineSnapshot, source: String) {
        self.key = key
        self.latitude = point.latitude
        self.longitude = point.longitude
        self.validAt = snapshot.validAt
        self.fetchedAt = snapshot.fetchedAt
        self.waveHeight = snapshot.waveHeight
        self.wavePeriod = snapshot.wavePeriod
        self.swellHeight = snapshot.swellHeight
        self.swellDirection = snapshot.swellDirection
        self.seaSurfaceTemperature = snapshot.seaSurfaceTemperature
        self.source = source
    }

    var snapshot: MarineSnapshot {
        MarineSnapshot(waveHeight: waveHeight, wavePeriod: wavePeriod, swellHeight: swellHeight,
                       swellDirection: swellDirection, seaSurfaceTemperature: seaSurfaceTemperature,
                       validAt: validAt, fetchedAt: fetchedAt)
    }
}
