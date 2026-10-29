#if canImport(CreateML)
import CreateML
#endif
import CoreML
import Foundation
import OSLog
import SwiftData
import TideCore

/// 釣れ率 v2: 釣果ログ（各記録の v1 要素点数）から重みを学び直す（指示書 §4、ADR-0013）。
/// Create ML Tabular（MLLogisticRegressionClassifier）が使える環境ではそれで係数を出し、
/// 使えなければ TideCore.ScoreLearner（同じ定式化の自前ロジスティック回帰）。
enum ScoreV2Trainer {
    private static let logger = Logger(subsystem: "jp.tide.app", category: "ScoreV2")

    /// 釣果の要素点数を集めて学習し、保存する。釣果が少なければ v1 に戻す。
    @MainActor
    static func retrain(context: ModelContext, now: Date = Date()) async {
        let descriptor = FetchDescriptor<CatchRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        let points = records.map(\.componentPoints).filter { $0.count == FishingScore.Key.allCases.count }
        guard points.count >= ScoreLearner.minimumSamples else {
            ScoreWeightsStore.reset()
            return
        }
        let weights = await Task.detached(priority: .utility) { () -> FishingScore.Weights in
            learn(points: points, now: now)
        }.value
        ScoreWeightsStore.save(weights)
        logger.notice("釣れ率 v2 の重みを更新: \(points.count) 件")
    }

    static func learn(points: [[Int]], now: Date) -> FishingScore.Weights {
        #if canImport(CreateML)
        if let coefficients = createMLCoefficients(points: points) {
            var weights = ScoreLearner.weights(fromCoefficients: coefficients)
            weights.learnedAt = now
            weights.sampleCount = points.count
            return weights
        }
        #endif
        return ScoreLearner.learn(catchPoints: points, now: now)
    }

    #if canImport(CreateML)
    /// Create ML Tabular のロジスティック回帰。係数は単位ベクトルの予測確率から logit 差で復元する。
    private static func createMLCoefficients(points: [[Int]]) -> [Double]? {
        let keys = FishingScore.Key.allCases
        let positives = points.map { ScoreLearner.Sample(features: ScoreLearner.features(points: $0), label: true) }
        let samples = positives + ScoreLearner.negatives(count: positives.count * 3)
        var columns: [String: MLDataValueConvertible] = [:]
        for (index, key) in keys.enumerated() {
            columns[key.rawValue] = samples.map { $0.features[index] }
        }
        columns["label"] = samples.map { $0.label ? "catch" : "none" }
        do {
            let table = try MLDataTable(dictionary: columns)
            let classifier = try MLLogisticRegressionClassifier(trainingData: table, targetColumn: "label",
                                                                featureColumns: keys.map(\.rawValue))
            let model = classifier.model
            func probability(_ features: [Double]) throws -> Double {
                var dict: [String: Any] = [:]
                for (index, key) in keys.enumerated() { dict[key.rawValue] = features[index] }
                let output = try model.prediction(from: MLDictionaryFeatureProvider(dictionary: dict))
                let probabilities = output.featureValue(for: "labelProbability")?.dictionaryValue ?? [:]
                return probabilities["catch"]?.doubleValue ?? 0.5
            }
            func logit(_ p: Double) -> Double {
                let clamped = min(max(p, 1e-6), 1 - 1e-6)
                return log(clamped / (1 - clamped))
            }
            let base = logit(try probability(Array(repeating: 0, count: keys.count)))
            return try keys.indices.map { index in
                var unit = Array(repeating: 0.0, count: keys.count)
                unit[index] = 1
                return logit(try probability(unit)) - base
            }
        } catch {
            logger.notice("Create ML が使えないため自前の回帰を使用: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    #endif
}
