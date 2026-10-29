@testable import TideCore
import XCTest

final class FishingScoreTests: XCTestCase {
    func testMaxAndMin() {
        let best = FishingScore.compute(FishingScore.Input(
            tideRateCmPerHour: 40, minutesToTwilight: 0, windSpeed: 0, pressureTrend3h: -4,
            seaSurfaceTemperature: 17, band: TemperatureBand(low: 12, high: 22), waveHeight: 0))
        XCTAssertEqual(best.total, 100)
        XCTAssertEqual(best.components.map(\.points), [25, 20, 15, 15, 15, 10])

        let worst = FishingScore.compute(FishingScore.Input(
            tideRateCmPerHour: 0, minutesToTwilight: 400, windSpeed: 15, pressureTrend3h: 5,
            seaSurfaceTemperature: 30, band: TemperatureBand(low: 12, high: 22), waveHeight: 3))
        XCTAssertEqual(worst.total, 0)
    }

    func testMissingInputsScoreZeroAndAreFlagged() {
        let result = FishingScore.compute(FishingScore.Input())
        XCTAssertEqual(result.total, 0)
        XCTAssertTrue(result.components.allSatisfy(\.missing))
        XCTAssertEqual(result.components.count, 6)
    }

    func testEachComponentMidpoints() {
        XCTAssertEqual(FishingScore.tidePoints(rate: 15).points, 13)   // 25 * 0.5 = 12.5 → 13
        XCTAssertEqual(FishingScore.tidePoints(rate: -30).points, 25)
        XCTAssertEqual(FishingScore.timePoints(minutes: 90).points, 10)
        XCTAssertEqual(FishingScore.timePoints(minutes: 200).points, 0)
        XCTAssertEqual(FishingScore.windPoints(speed: 4.2).points, 9)   // 15 * 0.58 = 8.7 → 9（付録A の例 +9）
        XCTAssertEqual(FishingScore.pressurePoints(trend: -3).points, 15)
        XCTAssertEqual(FishingScore.pressurePoints(trend: 0).points, 8)
        XCTAssertEqual(FishingScore.pressurePoints(trend: 3).points, 0)
        XCTAssertEqual(FishingScore.wavePoints(height: 0.6).points, 7)
        XCTAssertEqual(FishingScore.wavePoints(height: 2.5).points, 0)
    }

    func testTemperatureBandShape() {
        let band = TemperatureBand(low: 12, high: 22)
        XCTAssertEqual(FishingScore.sstPoints(temperature: 17, band: band).points, 15, "中心で15")
        XCTAssertEqual(FishingScore.sstPoints(temperature: 22, band: band).points, 7, "端で7")
        XCTAssertEqual(FishingScore.sstPoints(temperature: 12, band: band).points, 7, "端で7")
        XCTAssertEqual(FishingScore.sstPoints(temperature: 24, band: band).points, 4, "帯外は距離に応じて減る")
        XCTAssertEqual(FishingScore.sstPoints(temperature: 27, band: band).points, 0)
        XCTAssertTrue(FishingScore.sstPoints(temperature: 17, band: nil).missing)
    }

    func testComponentsSortedByPointsDescending() {
        let result = FishingScore.compute(FishingScore.Input(
            tideRateCmPerHour: 26, minutesToTwilight: 36, windSpeed: 4.2, pressureTrend3h: -1,
            seaSurfaceTemperature: 19.2, band: TemperatureBand(low: 12, high: 22), waveHeight: 1.4))
        let points = result.components.map(\.points)
        XCTAssertEqual(points, points.sorted(by: >))
        XCTAssertEqual(result.components.first?.key, .tide)
        XCTAssertEqual(result.total, points.reduce(0, +))
    }

    func testBarFractionIsOutOf25() {
        let component = FishingScore.Component(key: .tide, points: 22)
        XCTAssertEqual(component.barFraction, 0.88, accuracy: 0.0001)
    }

    func testInputFromSnapshots() async throws {
        let jst = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = jst
        let now = Date(timeIntervalSince1970: 1_793_338_200) // 2026-10-30T14:30+09:00
        let dayStart = cal.startOfDay(for: now)
        let point = GeoPoint(latitude: 35.1352, longitude: 139.6079)
        let day = try await MockTideProvider().tide(at: point, from: dayStart, days: 1, timeZone: jst)[0]
        let weather = try await MockWeatherProvider().weather(at: point, for: now)
        let marine = try await MockMarineProvider().marine(at: point, around: now)
        let input = FishingScore.input(at: now, tide: day, weather: weather, marine: marine.first,
                                       band: Species.defaultForScore.band)
        XCTAssertNotNil(input.tideRateCmPerHour)
        XCTAssertNotNil(input.minutesToTwilight)
        XCTAssertEqual(input.windSpeed, 4.2)
        XCTAssertEqual(input.pressureTrend3h, -3)
        XCTAssertEqual(input.seaSurfaceTemperature, 19.2)
        XCTAssertEqual(input.waveHeight, 0.6)
        let hourly = FishingScore.hourlyTotals(day: day, weather: weather, marineSeries: marine, band: input.band)
        XCTAssertEqual(hourly.count, 24)
        XCTAssertTrue(hourly.allSatisfy { (0...100).contains($0) })
    }

    func testSpeciesTable() {
        XCTAssertEqual(Species.all.count, 12)
        XCTAssertEqual(Species.find("mebaru")?.band, TemperatureBand(low: 10, high: 18))
        XCTAssertNil(Species.find("other")?.band)
        XCTAssertEqual(Species.defaultForScore.id, "kasago")
    }
}
