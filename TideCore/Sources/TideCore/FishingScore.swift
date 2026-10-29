import Foundation

/// 釣れ率 v1（指示書 §4）: 潮25 + マズメ20 + 風15 + 気圧15 + 水温15 + 波10 = 100。
public enum FishingScore {
    public enum Key: String, Codable, Sendable, CaseIterable {
        case tide = "TIDE"
        case time = "TIME"
        case wind = "WIND"
        case pressure = "PRESS"
        case sst = "SST"
        case wave = "WAVE"

        public var max: Int {
            switch self {
            case .tide: 25
            case .time: 20
            case .wind: 15
            case .pressure: 15
            case .sst: 15
            case .wave: 10
            }
        }
    }

    /// 内訳の1行。
    public struct Component: Hashable, Codable, Sendable, Identifiable {
        public var key: Key
        public var points: Int
        /// 入力が無く 0 点になった
        public var missing: Bool

        public var id: Key { key }
        public var max: Int { key.max }
        /// Detail のバーは 25 点満点に対する割合（付録A A-3 6）。
        public var barFraction: Double { Double(points) / 25 }

        public init(key: Key, points: Int, missing: Bool = false) {
            self.key = key
            self.points = points
            self.missing = missing
        }
    }

    /// 要素ごとの配点（合計 100）。v1 は §4 の配点、v2 は釣果ログから学習（ScoreLearner）。
    public struct Weights: Hashable, Codable, Sendable {
        public var byKey: [Key: Double]
        public var learnedAt: Date?
        public var sampleCount: Int

        public init(byKey: [Key: Double], learnedAt: Date? = nil, sampleCount: Int = 0) {
            self.byKey = byKey
            self.learnedAt = learnedAt
            self.sampleCount = sampleCount
        }

        public static let v1 = Weights(byKey: Dictionary(uniqueKeysWithValues: Key.allCases.map { ($0, Double($0.max)) }))

        public func weight(_ key: Key) -> Double { byKey[key] ?? Double(key.max) }
        public var isV1: Bool { learnedAt == nil }
    }

    public struct Result: Hashable, Codable, Sendable {
        /// 0...100
        public var total: Int
        /// 点数の高い順
        public var components: [Component]

        public init(total: Int, components: [Component]) {
            self.total = total
            self.components = components
        }

        public func component(_ key: Key) -> Component {
            components.first { $0.key == key } ?? Component(key: key, points: 0, missing: true)
        }
    }

    /// 計算の入力。nil は「取得できていない」。
    public struct Input: Hashable, Sendable {
        /// 潮位の変化率 cm/h（符号は問わない）
        public var tideRateCmPerHour: Double?
        /// 最寄りのマズメ（日出・日没）までの分
        public var minutesToTwilight: Double?
        /// 風速 m/s
        public var windSpeed: Double?
        /// 3時間の気圧変化 hPa（負=下降）
        public var pressureTrend3h: Double?
        /// 海水温 °C
        public var seaSurfaceTemperature: Double?
        /// 対象魚種の適水温帯
        public var band: TemperatureBand?
        /// 波高 m
        public var waveHeight: Double?

        public init(tideRateCmPerHour: Double? = nil, minutesToTwilight: Double? = nil, windSpeed: Double? = nil,
                    pressureTrend3h: Double? = nil, seaSurfaceTemperature: Double? = nil,
                    band: TemperatureBand? = nil, waveHeight: Double? = nil) {
            self.tideRateCmPerHour = tideRateCmPerHour
            self.minutesToTwilight = minutesToTwilight
            self.windSpeed = windSpeed
            self.pressureTrend3h = pressureTrend3h
            self.seaSurfaceTemperature = seaSurfaceTemperature
            self.band = band
            self.waveHeight = waveHeight
        }
    }

    // MARK: - 係数（v1）

    /// この変化率以上で潮の動き満点
    public static let fullTideRate = 30.0
    /// この分数以上でマズメ 0 点
    public static let twilightZeroMinutes = 180.0
    /// この風速以上で風 0 点
    public static let windZeroSpeed = 10.0
    /// 気圧: -3 hPa/3h 以下で満点、+3 以上で 0
    public static let pressureSpan = 3.0
    /// 帯外: 端から何 °C で 0 点
    public static let temperatureFalloff = 4.0
    /// この波高以上で波 0 点
    public static let waveZeroHeight = 2.0

    // MARK: - 計算

    public static func compute(_ input: Input, weights: Weights = .v1) -> Result {
        var components: [Component] = [
            tidePoints(rate: input.tideRateCmPerHour),
            timePoints(minutes: input.minutesToTwilight),
            windPoints(speed: input.windSpeed),
            pressurePoints(trend: input.pressureTrend3h),
            sstPoints(temperature: input.seaSurfaceTemperature, band: input.band),
            wavePoints(height: input.waveHeight)
        ]
        if !weights.isV1 {
            components = components.map { component in
                let scaled = Double(component.points) * weights.weight(component.key) / Double(component.key.max)
                return Component(key: component.key, points: Int(scaled.rounded()), missing: component.missing)
            }
        }
        components.sort { $0.points == $1.points ? $0.key.max > $1.key.max : $0.points > $1.points }
        let total = min(100, max(0, components.reduce(0) { $0 + $1.points }))
        return Result(total: total, components: components)
    }

    /// v1 の要素点数（Key.allCases の順）。釣果の記録に保存する。
    public static func rawPoints(_ input: Input) -> [Int] {
        let result = compute(input)
        return Key.allCases.map { result.component($0).points }
    }

    static func tidePoints(rate: Double?) -> Component {
        guard let rate else { return Component(key: .tide, points: 0, missing: true) }
        let fraction = min(abs(rate) / fullTideRate, 1)
        return Component(key: .tide, points: Int((Double(Key.tide.max) * fraction).rounded()))
    }

    static func timePoints(minutes: Double?) -> Component {
        guard let minutes else { return Component(key: .time, points: 0, missing: true) }
        let fraction = max(0, 1 - abs(minutes) / twilightZeroMinutes)
        return Component(key: .time, points: Int((Double(Key.time.max) * fraction).rounded()))
    }

    static func windPoints(speed: Double?) -> Component {
        guard let speed else { return Component(key: .wind, points: 0, missing: true) }
        let fraction = max(0, 1 - max(speed, 0) / windZeroSpeed)
        return Component(key: .wind, points: Int((Double(Key.wind.max) * fraction).rounded()))
    }

    static func pressurePoints(trend: Double?) -> Component {
        guard let trend else { return Component(key: .pressure, points: 0, missing: true) }
        // -3 → 1.0, 0 → 0.5, +3 → 0
        let fraction = min(max((pressureSpan - trend) / (2 * pressureSpan), 0), 1)
        return Component(key: .pressure, points: Int((Double(Key.pressure.max) * fraction).rounded()))
    }

    /// 帯の中心で15、端で7、帯外は距離に応じて0へ（付録B）。
    static func sstPoints(temperature: Double?, band: TemperatureBand?) -> Component {
        guard let temperature, let band else { return Component(key: .sst, points: 0, missing: true) }
        let distance = abs(temperature - band.center)
        let points: Double
        if band.halfWidth <= 0 {
            points = distance == 0 ? 15 : 0
        } else if distance <= band.halfWidth {
            points = 15 - 8 * (distance / band.halfWidth)
        } else {
            let outside = distance - band.halfWidth
            points = max(0, 7 * (1 - outside / temperatureFalloff))
        }
        return Component(key: .sst, points: Int(points.rounded()))
    }

    static func wavePoints(height: Double?) -> Component {
        guard let height else { return Component(key: .wave, points: 0, missing: true) }
        let fraction = max(0, 1 - max(height, 0) / waveZeroHeight)
        return Component(key: .wave, points: Int((Double(Key.wave.max) * fraction).rounded()))
    }

    // MARK: - 入力の組み立て

    /// 潮汐・気象・海況から、時刻 `date` の入力を作る。
    public static func input(at date: Date, tide: TideDay?, weather: WeatherSnapshot?, marine: MarineSnapshot?,
                             band: TemperatureBand?) -> Input {
        var input = Input()
        if let tide {
            if let now = tide.level(at: date), let later = tide.level(at: date.addingTimeInterval(1800)) {
                input.tideRateCmPerHour = (later - now) * 2
            } else if let earlier = tide.level(at: date.addingTimeInterval(-1800)), let now = tide.level(at: date) {
                input.tideRateCmPerHour = (now - earlier) * 2
            }
            let twilights = [tide.sunrise, tide.sunset].compactMap { $0 }
            if let nearest = twilights.map({ abs($0.timeIntervalSince(date)) / 60 }).min() {
                input.minutesToTwilight = nearest
            }
        }
        if let weather {
            input.windSpeed = weather.windSpeed
            input.pressureTrend3h = weather.pressureTrend3h
        }
        if let marine {
            input.seaSurfaceTemperature = marine.seaSurfaceTemperature
            input.waveHeight = marine.waveHeight
        }
        input.band = band
        return input
    }

    /// 1日 24 時間分（毎正時）の釣れ率。気象は当日の値で一定、海況は時系列があればその時刻の値。
    public static func hourlyTotals(day: TideDay, weather: WeatherSnapshot?, marineSeries: [MarineSnapshot],
                                    band: TemperatureBand?, weights: Weights = .v1) -> [Int] {
        (0..<24).map { hour in
            let date = day.dayStart.addingTimeInterval(TimeInterval(hour) * 3600)
            let marine = marineSeries.min { abs($0.validAt.timeIntervalSince(date)) < abs($1.validAt.timeIntervalSince(date)) }
            return compute(input(at: date, tide: day, weather: weather, marine: marine, band: band), weights: weights).total
        }
    }
}
