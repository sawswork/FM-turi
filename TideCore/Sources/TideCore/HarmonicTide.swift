import Foundation

/// 調和定数による潮汐の端末内計算（M3）。
/// 分潮: M2, S2, N2, K1, O1, Q1 を最小二乗で当て、K2 は S2 から、P1 は K1 から推定（標準の比）。合計8分潮。
public enum HarmonicTide {
    /// 分潮の角速度（度/時）。
    public struct Constituent: Hashable, Codable, Sendable {
        public var name: String
        public var speedDegPerHour: Double

        public init(name: String, speedDegPerHour: Double) {
            self.name = name
            self.speedDegPerHour = speedDegPerHour
        }
    }

    public static let m2 = Constituent(name: "M2", speedDegPerHour: 28.984_104_2)
    public static let s2 = Constituent(name: "S2", speedDegPerHour: 30.0)
    public static let n2 = Constituent(name: "N2", speedDegPerHour: 28.439_729_5)
    public static let k2 = Constituent(name: "K2", speedDegPerHour: 30.082_137_3)
    public static let k1 = Constituent(name: "K1", speedDegPerHour: 15.041_068_6)
    public static let o1 = Constituent(name: "O1", speedDegPerHour: 13.943_035_6)
    public static let p1 = Constituent(name: "P1", speedDegPerHour: 14.958_931_4)
    public static let q1 = Constituent(name: "Q1", speedDegPerHour: 13.398_660_9)

    /// 当てる分潮（自由）
    public static let fitted: [Constituent] = [m2, s2, n2, k1, o1, q1]
    /// 推定する分潮: (推定先, 元, 振幅比)
    public static let inferred: [(target: Constituent, from: Constituent, ratio: Double)] = [
        (k2, s2, 0.272_3), (p1, k1, 0.330_9)
    ]
    public static let allConstituents: [Constituent] = fitted + inferred.map(\.target)

    /// 基準時刻 2000-01-01 00:00 UTC
    public static let epoch = Date(timeIntervalSince1970: 946_684_800)

    /// 1分潮の振幅（cm）と位相（度、epoch 基準）。
    public struct Term: Hashable, Codable, Sendable {
        public var name: String
        public var amplitudeCm: Double
        public var phaseDeg: Double

        public init(name: String, amplitudeCm: Double, phaseDeg: Double) {
            self.name = name
            self.amplitudeCm = amplitudeCm
            self.phaseDeg = phaseDeg
        }
    }

    /// ある地点の調和定数。
    public struct Constants: Hashable, Codable, Sendable {
        public var meanLevelCm: Double
        public var terms: [Term]
        public var fittedAt: Date
        public var sampleCount: Int
        /// 当てはめの残差 RMS（cm）
        public var rmsErrorCm: Double

        public init(meanLevelCm: Double, terms: [Term], fittedAt: Date, sampleCount: Int, rmsErrorCm: Double) {
            self.meanLevelCm = meanLevelCm
            self.terms = terms
            self.fittedAt = fittedAt
            self.sampleCount = sampleCount
            self.rmsErrorCm = rmsErrorCm
        }

        public func term(_ name: String) -> Term? { terms.first { $0.name == name } }
    }

    public enum FitError: Error, Equatable {
        case tooFewSamples
        case singular
    }

    // MARK: - 予測

    static func hours(_ date: Date) -> Double {
        date.timeIntervalSince(epoch) / 3600
    }

    /// 潮位（cm）。
    public static func level(at date: Date, constants: Constants) -> Double {
        let t = hours(date)
        var sum = constants.meanLevelCm
        for term in constants.terms {
            guard let constituent = allConstituents.first(where: { $0.name == term.name }) else { continue }
            let angle = (constituent.speedDegPerHour * t - term.phaseDeg) * .pi / 180
            sum += term.amplitudeCm * cos(angle)
        }
        return sum
    }

    /// 1日分を `interval` 秒刻みで予測し、満潮・干潮と日出没・月齢も付けて TideDay にする。
    public static func day(starting dayStart: Date, constants: Constants, point: GeoPoint, timeZone: TimeZone,
                           interval: TimeInterval = 600, now: Date = Date()) -> TideDay {
        let count = Int(86_400 / interval) + 1
        let levels = (0..<count).map { level(at: dayStart.addingTimeInterval(TimeInterval($0) * interval), constants: constants) }
        var highs: [TideExtreme] = []
        var lows: [TideExtreme] = []
        for i in 1..<(count - 1) {
            let t = dayStart.addingTimeInterval(TimeInterval(i) * interval)
            if levels[i] > levels[i - 1], levels[i] >= levels[i + 1] { highs.append(TideExtreme(time: t, heightCm: levels[i])) }
            if levels[i] < levels[i - 1], levels[i] <= levels[i + 1] { lows.append(TideExtreme(time: t, heightCm: levels[i])) }
        }
        let sun = SunCalc.times(on: dayStart.addingTimeInterval(3600), at: point, timeZone: timeZone)
        let age = MoonCalc.age(at: dayStart.addingTimeInterval(12 * 3600))
        return TideDay(dayStart: dayStart, levels: levels, interval: interval, highs: highs, lows: lows,
                       sunrise: sun.sunrise, sunset: sun.sunset, moonAge: age, tideType: MoonCalc.tideType(age: age),
                       fetchedAt: now, source: "harmonic")
    }

    // MARK: - 当てはめ

    /// (時刻, 潮位cm) の列から調和定数を最小二乗で求める。最低 7 日分（20分刻みで約 500 点）を推奨。
    public static func fit(samples: [(date: Date, levelCm: Double)], now: Date = Date()) throws -> Constants {
        let unknowns = 1 + 2 * fitted.count
        guard samples.count >= unknowns * 10 else { throw FitError.tooFewSamples }
        // 設計行列の各行: [1, cos(ω1 t)+r cos(ωk t), sin(...), ...]
        func row(_ t: Double) -> [Double] {
            var r = [1.0]
            for constituent in fitted {
                var c = cos(constituent.speedDegPerHour * t * .pi / 180)
                var s = sin(constituent.speedDegPerHour * t * .pi / 180)
                for inference in inferred where inference.from == constituent {
                    c += inference.ratio * cos(inference.target.speedDegPerHour * t * .pi / 180)
                    s += inference.ratio * sin(inference.target.speedDegPerHour * t * .pi / 180)
                }
                r.append(c)
                r.append(s)
            }
            return r
        }
        var ata = Array(repeating: Array(repeating: 0.0, count: unknowns), count: unknowns)
        var atb = Array(repeating: 0.0, count: unknowns)
        for sample in samples {
            let r = row(hours(sample.date))
            for i in 0..<unknowns {
                atb[i] += r[i] * sample.levelCm
                for j in 0..<unknowns { ata[i][j] += r[i] * r[j] }
            }
        }
        let solution = try solve(ata, atb)
        var terms: [Term] = []
        for (index, constituent) in fitted.enumerated() {
            let a = solution[1 + 2 * index]
            let b = solution[2 + 2 * index]
            let amplitude = (a * a + b * b).squareRoot()
            let phase = atan2(b, a) * 180 / .pi
            terms.append(Term(name: constituent.name, amplitudeCm: amplitude, phaseDeg: phase))
            for inference in inferred where inference.from == constituent {
                terms.append(Term(name: inference.target.name, amplitudeCm: amplitude * inference.ratio, phaseDeg: phase))
            }
        }
        var constants = Constants(meanLevelCm: solution[0], terms: terms, fittedAt: now,
                                  sampleCount: samples.count, rmsErrorCm: 0)
        let residual = samples.reduce(0.0) { acc, sample in
            let diff = level(at: sample.date, constants: constants) - sample.levelCm
            return acc + diff * diff
        }
        constants.rmsErrorCm = (residual / Double(samples.count)).squareRoot()
        return constants
    }

    /// ガウスの消去法（部分ピボット）。
    static func solve(_ matrix: [[Double]], _ vector: [Double]) throws -> [Double] {
        let n = vector.count
        var a = matrix
        var b = vector
        for col in 0..<n {
            var pivot = col
            for r in (col + 1)..<n where abs(a[r][col]) > abs(a[pivot][col]) { pivot = r }
            guard abs(a[pivot][col]) > 1e-12 else { throw FitError.singular }
            if pivot != col {
                a.swapAt(pivot, col)
                b.swapAt(pivot, col)
            }
            for r in (col + 1)..<n {
                let factor = a[r][col] / a[col][col]
                if factor == 0 { continue }
                for c in col..<n { a[r][c] -= factor * a[col][c] }
                b[r] -= factor * b[col]
            }
        }
        var x = Array(repeating: 0.0, count: n)
        for r in stride(from: n - 1, through: 0, by: -1) {
            var sum = b[r]
            for c in (r + 1)..<n { sum -= a[r][c] * x[c] }
            x[r] = sum / a[r][r]
        }
        return x
    }
}
