import Foundation

/// 月齢と潮回り。
public enum MoonCalc {
    public static let synodicMonth = 29.530_588_853
    /// 基準の新月: 2000-01-06 18:14 UTC（JD 2451550.1）
    public static let referenceNewMoonJD = 2_451_550.1

    /// 月齢（0 ..< 29.53）。精度は ±0.5 日程度。
    public static func age(at date: Date) -> Double {
        let days = SunCalc.julianDay(date) - referenceNewMoonJD
        let r = days.truncatingRemainder(dividingBy: synodicMonth)
        return r < 0 ? r + synodicMonth : r
    }

    /// 輝面比 0...1。
    public static func illumination(age: Double) -> Double {
        (1 - cos(2 * .pi * age / synodicMonth)) / 2
    }

    /// 月齢 → 潮回り（一般的な区分表）。
    public static func tideType(age: Double) -> TideType {
        let day = Int(age.rounded(.down)) % 30
        switch day {
        case 0, 1, 2, 14, 15, 16, 17, 29: return .spring
        case 3, 4, 5, 6, 12, 13, 18, 19, 20, 21, 27, 28: return .middle
        case 7, 8, 9, 22, 23, 24: return .neap
        case 10, 25: return .long
        case 11, 26: return .young
        default: return .middle
        }
    }
}

/// 潮回り。
public enum TideType: String, Codable, Sendable, CaseIterable {
    case spring = "大潮"
    case middle = "中潮"
    case neap = "小潮"
    case long = "長潮"
    case young = "若潮"

    public var label: String { rawValue }

    /// tide736 の moon.title などの文字列から。
    public init?(label: String) {
        guard let match = Self.allCases.first(where: { label.contains($0.rawValue) }) else { return nil }
        self = match
    }
}
