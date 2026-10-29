import Foundation

/// EXIF 由来の値の解釈（ImageIO からの読み出しはアプリ側）。
public enum Exif {
    /// "yyyy:MM:dd HH:mm:ss" → Date。EXIF にタイムゾーンは無いので `timeZone` で解釈する。
    public static func date(from text: String?, timeZone: TimeZone = Tide736.timeZone) -> Date? {
        guard let text else { return nil }
        let parts = text.split(whereSeparator: { $0 == ":" || $0 == " " }).compactMap { Int($0) }
        guard parts.count == 6 else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = DateComponents(year: parts[0], month: parts[1], day: parts[2],
                                   hour: parts[3], minute: parts[4], second: parts[5])
        return cal.date(from: comps)
    }

    /// GPS 辞書の値（正の数と N/S・E/W）→ 緯度経度。
    public static func coordinate(latitude: Double?, latitudeRef: String?,
                                  longitude: Double?, longitudeRef: String?) -> GeoPoint? {
        guard let latitude, let longitude else { return nil }
        let lat = (latitudeRef?.uppercased() == "S") ? -abs(latitude) : abs(latitude)
        let lon = (longitudeRef?.uppercased() == "W") ? -abs(longitude) : abs(longitude)
        guard (-90...90).contains(lat), (-180...180).contains(lon), lat != 0 || lon != 0 else { return nil }
        return GeoPoint(latitude: lat, longitude: lon)
    }

    /// 縮小後のサイズ（長辺 `maxLongEdge`、アスペクト維持、拡大はしない）。
    public static func scaledSize(width: Double, height: Double, maxLongEdge: Double = 1024) -> (width: Double, height: Double) {
        let longEdge = max(width, height)
        guard longEdge > maxLongEdge, longEdge > 0 else { return (width, height) }
        let scale = maxLongEdge / longEdge
        return ((width * scale).rounded(), (height * scale).rounded())
    }
}
