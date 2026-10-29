import Foundation

/// 釣れ率 v2: 自分の釣果ログから各要素の重みを学び直す（指示書 §4）。
/// 正例 = 釣果時の6要素（0...1 に正規化）、負例 = 一様乱数。ロジスティック回帰の係数 β から
/// 重み w_i = 100 · m_i·exp(β_i) / Σ m_j·exp(β_j)（m = v1 の配点）を作る。β=0 なら v1 と同じ。
public enum ScoreLearner {
    /// 学習に必要な最少釣果数
    public static let minimumSamples = 10
    /// exp(β) のクランプ（重みが極端にならないように）
    public static let gainRange = 0.5...2.0

    public struct Sample: Hashable, Sendable {
        /// Key.allCases の順で 0...1
        public var features: [Double]
        public var label: Bool

        public init(features: [Double], label: Bool) {
            self.features = features
            self.label = label
        }
    }

    /// 釣果の要素点数 → 0...1 の特徴量。
    public static func features(points: [Int]) -> [Double] {
        zip(points, FishingScore.Key.allCases).map { point, key in
            min(max(Double(point) / Double(key.max), 0), 1)
        }
    }

    /// 乱数で負例を作る（再現性のため seed 固定）。
    public static func negatives(count: Int, seed: UInt64 = 7) -> [Sample] {
        var generator = SeededGenerator(seed: seed)
        return (0..<count).map { _ in
            Sample(features: (0..<FishingScore.Key.allCases.count).map { _ in Double.random(in: 0...1, using: &generator) },
                   label: false)
        }
    }

    /// 勾配降下法のロジスティック回帰。返り値は切片を除く係数（特徴量の数だけ）。
    public static func logisticCoefficients(samples: [Sample], iterations: Int = 600, learningRate: Double = 0.5,
                                            l2: Double = 0.01) -> [Double] {
        guard let first = samples.first else { return [] }
        let dimension = first.features.count
        var beta = Array(repeating: 0.0, count: dimension)
        var intercept = 0.0
        let n = Double(samples.count)
        for _ in 0..<iterations {
            var gradBeta = Array(repeating: 0.0, count: dimension)
            var gradIntercept = 0.0
            for sample in samples {
                var z = intercept
                for i in 0..<dimension { z += beta[i] * sample.features[i] }
                let p = 1 / (1 + exp(-z))
                let error = p - (sample.label ? 1 : 0)
                for i in 0..<dimension { gradBeta[i] += error * sample.features[i] }
                gradIntercept += error
            }
            for i in 0..<dimension { beta[i] -= learningRate * (gradBeta[i] / n + l2 * beta[i]) }
            intercept -= learningRate * gradIntercept / n
        }
        return beta
    }

    /// 係数 → 重み（合計 100）。
    public static func weights(fromCoefficients beta: [Double]) -> FishingScore.Weights {
        let keys = FishingScore.Key.allCases
        guard beta.count == keys.count else { return .v1 }
        let gains = beta.map { min(max(exp($0), gainRange.lowerBound), gainRange.upperBound) }
        let raw = zip(keys, gains).map { Double($0.max) * $1 }
        let sum = raw.reduce(0, +)
        var byKey: [FishingScore.Key: Double] = [:]
        for (key, value) in zip(keys, raw) { byKey[key] = value / sum * 100 }
        return FishingScore.Weights(byKey: byKey)
    }

    /// 釣果の要素点数の列から重みを学ぶ。釣果が少なければ v1。
    public static func learn(catchPoints: [[Int]], now: Date = Date()) -> FishingScore.Weights {
        guard catchPoints.count >= minimumSamples else { return .v1 }
        let positives = catchPoints.map { Sample(features: features(points: $0), label: true) }
        let samples = positives + negatives(count: positives.count * 3)
        var weights = weights(fromCoefficients: logisticCoefficients(samples: samples))
        weights.learnedAt = now
        weights.sampleCount = catchPoints.count
        return weights
    }

    /// 再現性のある乱数（xorshift64*）。
    public struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        public init(seed: UInt64) {
            state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
        }

        public mutating func next() -> UInt64 {
            state ^= state >> 12
            state ^= state << 25
            state ^= state >> 27
            return state &* 0x2545_F491_4F6C_DD1D
        }
    }
}
