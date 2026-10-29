import Foundation

/// 日出・日没（NOAA の簡略アルゴリズム。精度 ±1〜2分）。
public enum SunCalc {
    public struct Times: Hashable, Sendable {
        public var sunrise: Date?
        public var sunset: Date?
        public var solarNoon: Date
    }

    /// `date` を含む `timeZone` の1日について計算する。
    public static func times(on date: Date, at point: GeoPoint, timeZone: TimeZone) -> Times {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dayStart = calendar.startOfDay(for: date)
        // UTC の 0 時を基準にした日付（分単位で足す）
        let utcDayStart = Date(timeIntervalSince1970: (dayStart.timeIntervalSince1970 / 86_400).rounded(.down) * 86_400)
        let localNoon = dayStart.addingTimeInterval(12 * 3600)
        let jd = julianDay(localNoon)
        let t = (jd - 2_451_545.0) / 36_525.0

        let l0 = normalize(280.46646 + t * (36_000.76983 + t * 0.000_303_2))
        let m = 357.52911 + t * (35_999.05029 - 0.000_153_7 * t)
        let e = 0.016_708_634 - t * (0.000_042_037 + 0.000_000_126_7 * t)
        let c = sinDeg(m) * (1.914_602 - t * (0.004_817 + 0.000_014 * t))
            + sinDeg(2 * m) * (0.019_993 - 0.000_101 * t)
            + sinDeg(3 * m) * 0.000_289
        let trueLong = l0 + c
        let omega = 125.04 - 1_934.136 * t
        let lambda = trueLong - 0.005_69 - 0.004_78 * sinDeg(omega)
        let epsilon0 = 23 + (26 + (21.448 - t * (46.815 + t * (0.000_59 - t * 0.001_813))) / 60) / 60
        let epsilon = epsilon0 + 0.002_56 * cosDeg(omega)
        let declination = asin(sinDeg(epsilon) * sinDeg(lambda)) * 180 / .pi
        let y = tanDeg(epsilon / 2) * tanDeg(epsilon / 2)
        let eot = 4 * (180 / .pi) * (
            y * sinDeg(2 * l0) - 2 * e * sinDeg(m) + 4 * e * y * sinDeg(m) * cosDeg(2 * l0)
                - 0.5 * y * y * sinDeg(4 * l0) - 1.25 * e * e * sinDeg(2 * m)
        )
        let noonMinutesUTC = 720 - 4 * point.longitude - eot
        let noon = utcDayStart.addingTimeInterval(noonMinutesUTC * 60)
        // 日付のずれ（UTC の日と現地の日）を補正: 現地の正午に最も近い候補を選ぶ
        let solarNoon = closest(to: localNoon, candidates: [noon.addingTimeInterval(-86_400), noon, noon.addingTimeInterval(86_400)])

        let cosHA = cosDeg(90.833) / (cosDeg(point.latitude) * cosDeg(declination)) - tanDeg(point.latitude) * tanDeg(declination)
        guard cosHA >= -1, cosHA <= 1 else {
            return Times(sunrise: nil, sunset: nil, solarNoon: solarNoon)
        }
        let hourAngle = acos(cosHA) * 180 / .pi
        return Times(sunrise: solarNoon.addingTimeInterval(-hourAngle * 4 * 60),
                     sunset: solarNoon.addingTimeInterval(hourAngle * 4 * 60),
                     solarNoon: solarNoon)
    }

    public static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400 + 2_440_587.5
    }

    private static func closest(to target: Date, candidates: [Date]) -> Date {
        candidates.min { abs($0.timeIntervalSince(target)) < abs($1.timeIntervalSince(target)) } ?? target
    }

    private static func normalize(_ degrees: Double) -> Double {
        let r = degrees.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    static func sinDeg(_ d: Double) -> Double { sin(d * .pi / 180) }
    static func cosDeg(_ d: Double) -> Double { cos(d * .pi / 180) }
    static func tanDeg(_ d: Double) -> Double { tan(d * .pi / 180) }
}
