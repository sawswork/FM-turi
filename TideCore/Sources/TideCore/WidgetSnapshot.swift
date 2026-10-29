import Foundation

/// アプリがウィジェット用に App Group へ書き出す値（ウィジェットは SwiftData を読まずこれだけを使う）。
public struct WidgetSnapshot: Codable, Hashable, Sendable {
    public struct Meter: Codable, Hashable, Sendable {
        /// "wind" / "wave" / "drop" / "pressure"
        public var key: String
        public var fraction: Double
        /// "orange" / "green" / "white"
        public var color: String
        public var rotationDegrees: Double

        public init(key: String, fraction: Double, color: String, rotationDegrees: Double) {
            self.key = key
            self.fraction = fraction
            self.color = color
            self.rotationDegrees = rotationDegrees
        }
    }

    public struct Stock: Codable, Hashable, Sendable {
        public var label: String
        public var count: Int

        public init(label: String, count: Int) {
            self.label = label
            self.count = count
        }
    }

    public var spotName: String
    public var total: Int
    /// 今日の毎正時の釣れ率（24個）
    public var hourly: [Int]
    public var meters: [Meter]
    public var moonAge: Double
    public var tideTypeLabel: String
    public var isRising: Bool
    /// 今日の潮位（毎正時 24個、cm）
    public var tideLevels: [Double]
    public var sinkers: [Stock]
    public var hooks: [Stock]
    public var dayStart: Date
    public var generatedAt: Date

    public init(spotName: String, total: Int, hourly: [Int], meters: [Meter], moonAge: Double, tideTypeLabel: String,
                isRising: Bool, tideLevels: [Double], sinkers: [Stock], hooks: [Stock], dayStart: Date, generatedAt: Date) {
        self.spotName = spotName
        self.total = total
        self.hourly = hourly
        self.meters = meters
        self.moonAge = moonAge
        self.tideTypeLabel = tideTypeLabel
        self.isRising = isRising
        self.tideLevels = tideLevels
        self.sinkers = sinkers
        self.hooks = hooks
        self.dayStart = dayStart
        self.generatedAt = generatedAt
    }

    /// 仕様の例（プレビューと未取得時）。
    public static let placeholder = WidgetSnapshot(
        spotName: "城ヶ島 西側", total: 72,
        hourly: [30, 22, 18, 16, 20, 34, 58, 74, 66, 48, 38, 30, 26, 24, 30, 44, 62, 80, 72, 52, 38, 30, 26, 22],
        meters: [
            Meter(key: "wind", fraction: 0.60, color: "orange", rotationDegrees: 40),
            Meter(key: "wave", fraction: 0.22, color: "white", rotationDegrees: 0),
            Meter(key: "drop", fraction: 0.80, color: "green", rotationDegrees: 0),
            Meter(key: "pressure", fraction: 0.45, color: "green", rotationDegrees: 0)
        ],
        moonAge: 12.4, tideTypeLabel: "大潮", isRising: true,
        tideLevels: [100, 90, 70, 50, 46, 60, 90, 115, 128, 120, 100, 75, 55, 52, 65, 85, 100, 104, 100, 90, 80, 85, 95, 100],
        sinkers: [Stock(label: "5", count: 12), Stock(label: "7", count: 8), Stock(label: "10", count: 6),
                  Stock(label: "14", count: 4), Stock(label: "21", count: 2)],
        hooks: [Stock(label: "#2", count: 10), Stock(label: "#1", count: 14), Stock(label: "1/0", count: 9), Stock(label: "2/0", count: 5)],
        dayStart: Date(timeIntervalSince1970: 1_793_286_000), generatedAt: Date(timeIntervalSince1970: 1_793_338_200)
    )

    /// 時刻 `date` の釣れ率（毎正時の値を引く）。
    public func total(at date: Date, timeZone: TimeZone) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let hour = cal.component(.hour, from: date)
        guard hourly.indices.contains(hour) else { return total }
        return hourly[hour]
    }
}
