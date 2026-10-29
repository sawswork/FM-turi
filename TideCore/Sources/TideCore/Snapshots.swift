import Foundation

/// 風・気圧・気温（WeatherKit 由来）。
public struct WeatherSnapshot: Hashable, Codable, Sendable {
    /// 風速 m/s
    public var windSpeed: Double
    /// 風向（度、北=0、風が吹いてくる方向）
    public var windDirection: Double
    /// 気圧 hPa
    public var pressure: Double
    /// 3時間の気圧変化 hPa（負=下降）
    public var pressureTrend3h: Double
    /// 気温 °C
    public var airTemperature: Double
    /// 観測／予報の対象時刻
    public var validAt: Date
    /// 取得した時刻
    public var fetchedAt: Date
    /// 気象警報・注意報の見出し（無ければ空）
    public var alerts: [String]

    public init(windSpeed: Double, windDirection: Double, pressure: Double, pressureTrend3h: Double,
                airTemperature: Double, validAt: Date, fetchedAt: Date, alerts: [String] = []) {
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.pressure = pressure
        self.pressureTrend3h = pressureTrend3h
        self.airTemperature = airTemperature
        self.validAt = validAt
        self.fetchedAt = fetchedAt
        self.alerts = alerts
    }

    /// 16方位の略号（NE など）。
    public var compassLabel: String {
        Self.compassLabel(degrees: windDirection)
    }

    public static func compassLabel(degrees: Double) -> String {
        let labels = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let index = Int((positive / 22.5).rounded()) % 16
        return labels[index]
    }
}

/// 波高・周期・うねり・海水温（Open-Meteo Marine 由来）。
public struct MarineSnapshot: Hashable, Codable, Sendable {
    /// 波高 m
    public var waveHeight: Double
    /// 波の周期 s
    public var wavePeriod: Double
    /// うねりの高さ m
    public var swellHeight: Double
    /// うねりの向き（度）
    public var swellDirection: Double
    /// 海水温 °C
    public var seaSurfaceTemperature: Double
    public var validAt: Date
    public var fetchedAt: Date

    public init(waveHeight: Double, wavePeriod: Double, swellHeight: Double, swellDirection: Double,
                seaSurfaceTemperature: Double, validAt: Date, fetchedAt: Date) {
        self.waveHeight = waveHeight
        self.wavePeriod = wavePeriod
        self.swellHeight = swellHeight
        self.swellDirection = swellDirection
        self.seaSurfaceTemperature = seaSurfaceTemperature
        self.validAt = validAt
        self.fetchedAt = fetchedAt
    }
}
