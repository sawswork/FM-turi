import Foundation

/// 緯度経度。キャッシュのキーには 0.01° に丸めた値を使う（約1km）。
public struct GeoPoint: Hashable, Codable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// 0.01° 単位に丸めた点。
    public var rounded: GeoPoint {
        GeoPoint(latitude: (latitude * 100).rounded() / 100,
                 longitude: (longitude * 100).rounded() / 100)
    }

    /// 2点間の概算距離（m）。haversine。
    public func distance(to other: GeoPoint) -> Double {
        let earthRadius = 6_371_000.0
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dLat = (other.latitude - latitude) * .pi / 180
        let dLon = (other.longitude - longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
