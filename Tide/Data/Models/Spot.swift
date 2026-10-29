import Foundation
import SwiftData
import TideCore

/// 釣り場。登録済み（isRegistered）と候補（MKLocalSearch・tide736 由来、L9）を同じモデルで持つ。
@Model
final class Spot {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var isRegistered: Bool
    var createdAt: Date
    /// tide736 の港コード等。
    var tideStationCode: String?
    /// "seed" / "mapkit" / "tide736" / "user"
    var source: String
    /// 候補として検索した時刻（再検索の抑止に使う）
    var searchedAt: Date?

    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double,
         isRegistered: Bool, createdAt: Date = Date(), tideStationCode: String? = nil,
         source: String = "seed", searchedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isRegistered = isRegistered
        self.createdAt = createdAt
        self.tideStationCode = tideStationCode
        self.source = source
        self.searchedAt = searchedAt
    }

    var point: GeoPoint {
        GeoPoint(latitude: latitude, longitude: longitude)
    }
}

extension Spot {
    /// 付録A A-4 の登録済み4点（三浦半島）。初回起動時に投入する（ADR-0003）。
    static func seedSpots() -> [Spot] {
        [
            Spot(name: "城ヶ島 西側", latitude: 35.1352, longitude: 139.6079, isRegistered: true),
            Spot(name: "三崎港 北堤", latitude: 35.1428, longitude: 139.6222, isRegistered: true),
            Spot(name: "荒崎", latitude: 35.1897, longitude: 139.6046, isRegistered: true),
            Spot(name: "剱崎", latitude: 35.1362, longitude: 139.6776, isRegistered: true)
        ]
    }
}
