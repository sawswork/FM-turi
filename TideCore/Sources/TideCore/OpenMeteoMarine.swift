import Foundation

/// Open-Meteo Marine API（https://marine-api.open-meteo.com）のレスポンス解析。
public enum OpenMeteoMarine {
    public static let baseURL = URL(string: "https://marine-api.open-meteo.com/v1/marine")!
    public static let hourlyFields = [
        "wave_height", "wave_period", "swell_wave_height", "swell_wave_direction", "sea_surface_temperature"
    ]

    /// リクエスト URL。前日〜3日先を UTC で取得する。
    public static func requestURL(for point: GeoPoint, pastDays: Int = 1, forecastDays: Int = 3) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", point.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", point.longitude)),
            URLQueryItem(name: "hourly", value: hourlyFields.joined(separator: ",")),
            URLQueryItem(name: "timeformat", value: "unixtime"),
            URLQueryItem(name: "timezone", value: "UTC"),
            URLQueryItem(name: "past_days", value: String(pastDays)),
            URLQueryItem(name: "forecast_days", value: String(forecastDays))
        ]
        return components.url!
    }

    public struct Response: Decodable, Sendable {
        public struct Hourly: Decodable, Sendable {
            public var time: [Double]
            public var waveHeight: [Double?]
            public var wavePeriod: [Double?]
            public var swellWaveHeight: [Double?]
            public var swellWaveDirection: [Double?]
            public var seaSurfaceTemperature: [Double?]

            enum CodingKeys: String, CodingKey {
                case time
                case waveHeight = "wave_height"
                case wavePeriod = "wave_period"
                case swellWaveHeight = "swell_wave_height"
                case swellWaveDirection = "swell_wave_direction"
                case seaSurfaceTemperature = "sea_surface_temperature"
            }
        }

        public var hourly: Hourly
    }

    public enum ParseError: Error, Equatable {
        case empty
    }

    /// JSON → 時間ごとのスナップショット。欠損値（null）の時間は捨てる。
    public static func parse(_ data: Data, fetchedAt: Date) throws -> [MarineSnapshot] {
        let response = try JSONDecoder().decode(Response.self, from: data)
        let h = response.hourly
        var result: [MarineSnapshot] = []
        for (index, time) in h.time.enumerated() {
            guard index < h.waveHeight.count, let wave = h.waveHeight[index] else { continue }
            let period = index < h.wavePeriod.count ? (h.wavePeriod[index] ?? 0) : 0
            let swell = index < h.swellWaveHeight.count ? (h.swellWaveHeight[index] ?? 0) : 0
            let swellDir = index < h.swellWaveDirection.count ? (h.swellWaveDirection[index] ?? 0) : 0
            guard index < h.seaSurfaceTemperature.count, let sst = h.seaSurfaceTemperature[index] else { continue }
            result.append(MarineSnapshot(waveHeight: wave, wavePeriod: period, swellHeight: swell,
                                         swellDirection: swellDir, seaSurfaceTemperature: sst,
                                         validAt: Date(timeIntervalSince1970: time), fetchedAt: fetchedAt))
        }
        guard !result.isEmpty else { throw ParseError.empty }
        return result
    }
}
