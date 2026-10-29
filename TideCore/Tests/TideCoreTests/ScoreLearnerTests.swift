@testable import TideCore
import XCTest

final class ScoreLearnerTests: XCTestCase {
    func testV1WeightsUnchangedWithFewSamples() {
        let weights = ScoreLearner.learn(catchPoints: [[25, 20, 15, 15, 15, 10]])
        XCTAssertTrue(weights.isV1)
        XCTAssertEqual(weights.weight(.tide), 25)
    }

    func testLearnsHigherWeightForFeatureConcentratedInCatches() {
        // 釣果は潮の動きが常に満点、他は中程度 → TIDE の重みが上がる
        let catches = (0..<40).map { _ in [25, 10, 8, 7, 8, 5] }
        let weights = ScoreLearner.learn(catchPoints: catches)
        XCTAssertFalse(weights.isV1)
        XCTAssertEqual(weights.sampleCount, 40)
        XCTAssertGreaterThan(weights.weight(.tide), 25)
        let total = FishingScore.Key.allCases.reduce(0.0) { $0 + weights.weight($1) }
        XCTAssertEqual(total, 100, accuracy: 0.001)
    }

    func testWeightsFromZeroCoefficientsEqualV1() {
        let weights = ScoreLearner.weights(fromCoefficients: [0, 0, 0, 0, 0, 0])
        for key in FishingScore.Key.allCases {
            XCTAssertEqual(weights.weight(key), Double(key.max), accuracy: 1e-9)
        }
    }

    func testComputeWithWeightsKeepsBreakdown() {
        var weights = ScoreLearner.weights(fromCoefficients: [0.7, 0, 0, 0, 0, -0.7])
        weights.learnedAt = Date()
        let input = FishingScore.Input(tideRateCmPerHour: 30, minutesToTwilight: 0, windSpeed: 0, pressureTrend3h: -3,
                                       seaSurfaceTemperature: 17, band: TemperatureBand(low: 12, high: 22), waveHeight: 0)
        let v1 = FishingScore.compute(input)
        let v2 = FishingScore.compute(input, weights: weights)
        XCTAssertEqual(v1.total, 100)
        XCTAssertEqual(v2.components.count, 6)
        XCTAssertGreaterThan(v2.component(.tide).points, v1.component(.tide).points)
        XCTAssertLessThan(v2.component(.wave).points, v1.component(.wave).points)
        XCTAssertEqual(v2.total, 100, accuracy: 1)
        XCTAssertEqual(FishingScore.rawPoints(input), [25, 20, 15, 15, 15, 10])
    }

    func testSeededGeneratorIsDeterministic() {
        let a = ScoreLearner.negatives(count: 3, seed: 42)
        let b = ScoreLearner.negatives(count: 3, seed: 42)
        XCTAssertEqual(a, b)
        XCTAssertTrue(a.allSatisfy { $0.features.allSatisfy { (0...1).contains($0) } })
    }
}
