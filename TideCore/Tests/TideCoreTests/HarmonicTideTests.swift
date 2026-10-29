@testable import TideCore
import XCTest

final class HarmonicTideTests: XCTestCase {
    /// 既知の定数から作った30日分の潮位を当てはめ、定数が復元できること。
    func testFitRecoversConstants() throws {
        let truth = HarmonicTide.Constants(
            meanLevelCm: 90,
            terms: [
                HarmonicTide.Term(name: "M2", amplitudeCm: 45, phaseDeg: 120),
                HarmonicTide.Term(name: "S2", amplitudeCm: 20, phaseDeg: 150),
                HarmonicTide.Term(name: "K2", amplitudeCm: 20 * 0.2723, phaseDeg: 150),
                HarmonicTide.Term(name: "N2", amplitudeCm: 9, phaseDeg: 100),
                HarmonicTide.Term(name: "K1", amplitudeCm: 25, phaseDeg: 200),
                HarmonicTide.Term(name: "P1", amplitudeCm: 25 * 0.3309, phaseDeg: 200),
                HarmonicTide.Term(name: "O1", amplitudeCm: 19, phaseDeg: 180),
                HarmonicTide.Term(name: "Q1", amplitudeCm: 4, phaseDeg: 170)
            ],
            fittedAt: Date(), sampleCount: 0, rmsErrorCm: 0)
        let start = Date(timeIntervalSince1970: 1_793_286_000) // 2026-10-30 00:00 JST
        let samples = (0..<(30 * 72)).map { index -> (date: Date, levelCm: Double) in
            let date = start.addingTimeInterval(TimeInterval(index) * 1200)
            return (date, HarmonicTide.level(at: date, constants: truth))
        }
        let fitted = try HarmonicTide.fit(samples: samples)
        XCTAssertEqual(fitted.meanLevelCm, 90, accuracy: 0.5)
        XCTAssertLessThan(fitted.rmsErrorCm, 0.5)
        for name in ["M2", "S2", "N2", "K1", "O1", "Q1", "K2", "P1"] {
            let expected = try XCTUnwrap(truth.term(name))
            let actual = try XCTUnwrap(fitted.term(name))
            XCTAssertEqual(actual.amplitudeCm, expected.amplitudeCm, accuracy: max(0.6, expected.amplitudeCm * 0.03), name)
            var phaseDiff = abs(actual.phaseDeg - expected.phaseDeg).truncatingRemainder(dividingBy: 360)
            if phaseDiff > 180 { phaseDiff = 360 - phaseDiff }
            XCTAssertLessThan(phaseDiff, 4, name)
        }
        XCTAssertEqual(fitted.terms.count, 8)
        // 当てはめ期間の外でも一致する
        let future = start.addingTimeInterval(60 * 86_400 + 5000)
        XCTAssertEqual(HarmonicTide.level(at: future, constants: fitted), HarmonicTide.level(at: future, constants: truth), accuracy: 1.5)
    }

    func testTooFewSamples() {
        let samples = (0..<20).map { (date: Date(timeIntervalSince1970: Double($0) * 1200), levelCm: 100.0) }
        XCTAssertThrowsError(try HarmonicTide.fit(samples: samples))
    }

    func testDayHasExtremesAndSun() {
        let constants = HarmonicTide.Constants(
            meanLevelCm: 90,
            terms: [HarmonicTide.Term(name: "M2", amplitudeCm: 50, phaseDeg: 0), HarmonicTide.Term(name: "K1", amplitudeCm: 20, phaseDeg: 0)],
            fittedAt: Date(), sampleCount: 1000, rmsErrorCm: 1)
        let jst = TimeZone(identifier: "Asia/Tokyo")!
        let day = HarmonicTide.day(starting: Date(timeIntervalSince1970: 1_793_286_000), constants: constants,
                                   point: GeoPoint(latitude: 35.1352, longitude: 139.6079), timeZone: jst)
        XCTAssertEqual(day.levels.count, 145)
        XCTAssertEqual(day.interval, 600)
        XCTAssertGreaterThanOrEqual(day.highs.count, 1)
        XCTAssertGreaterThanOrEqual(day.lows.count, 1)
        XCTAssertNotNil(day.sunrise)
        XCTAssertEqual(day.source, "harmonic")
        XCTAssertEqual(day.hourlyLevels.count, 24)
    }

    func testSolve() throws {
        let x = try HarmonicTide.solve([[2, 1], [1, 3]], [3, 5])
        XCTAssertEqual(x[0], 0.8, accuracy: 1e-9)
        XCTAssertEqual(x[1], 1.4, accuracy: 1e-9)
        XCTAssertThrowsError(try HarmonicTide.solve([[1, 2], [2, 4]], [1, 2]))
    }
}
