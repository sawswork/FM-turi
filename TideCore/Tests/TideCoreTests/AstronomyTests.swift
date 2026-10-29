@testable import TideCore
import XCTest

final class AstronomyTests: XCTestCase {
    let tokyo = GeoPoint(latitude: 35.6762, longitude: 139.6503)
    let jst = TimeZone(identifier: "Asia/Tokyo")!

    private func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso)!
    }

    private func minutes(_ date: Date?, in tz: TimeZone) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let comps = cal.dateComponents([.hour, .minute], from: date!)
        return comps.hour! * 60 + comps.minute!
    }

    func testTokyoSummerSolstice() {
        let times = SunCalc.times(on: date("2024-06-21T12:00:00+09:00"), at: tokyo, timeZone: jst)
        XCTAssertEqual(minutes(times.sunrise, in: jst), 4 * 60 + 25, accuracy: 3)
        XCTAssertEqual(minutes(times.sunset, in: jst), 19 * 60 + 0, accuracy: 3)
    }

    func testTokyoWinterSolstice() {
        let times = SunCalc.times(on: date("2024-12-21T12:00:00+09:00"), at: tokyo, timeZone: jst)
        XCTAssertEqual(minutes(times.sunrise, in: jst), 6 * 60 + 47, accuracy: 3)
        XCTAssertEqual(minutes(times.sunset, in: jst), 16 * 60 + 32, accuracy: 3)
    }

    func testMoonAgeAtFullMoon() {
        // 2024-01-25 17:54 UTC 満月
        let age = MoonCalc.age(at: date("2024-01-25T17:54:00Z"))
        XCTAssertEqual(age, 14.77, accuracy: 0.7)
        XCTAssertGreaterThan(MoonCalc.illumination(age: age), 0.98)
    }

    func testMoonAgeAtNewMoon() {
        // 2024-01-11 11:57 UTC 新月
        let age = MoonCalc.age(at: date("2024-01-11T11:57:00Z"))
        XCTAssertTrue(age < 0.7 || age > 28.9, "age=\(age)")
    }

    func testTideTypeTable() {
        XCTAssertEqual(MoonCalc.tideType(age: 0.5), .spring)
        XCTAssertEqual(MoonCalc.tideType(age: 15.2), .spring)
        XCTAssertEqual(MoonCalc.tideType(age: 4.0), .middle)
        XCTAssertEqual(MoonCalc.tideType(age: 8.0), .neap)
        XCTAssertEqual(MoonCalc.tideType(age: 10.3), .long)
        XCTAssertEqual(MoonCalc.tideType(age: 11.9), .young)
        XCTAssertEqual(TideType(label: "大潮"), .spring)
        XCTAssertNil(TideType(label: "x"))
    }

    func testMockTideDay() async throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = jst
        let dayStart = cal.startOfDay(for: date("2026-10-30T14:30:00+09:00"))
        let point = GeoPoint(latitude: 35.1352, longitude: 139.6079)
        let days = try await MockTideProvider().tide(at: point, from: dayStart, days: 3, timeZone: jst)
        XCTAssertEqual(days.count, 3)
        let today = days[0]
        XCTAssertEqual(today.hourlyLevels.count, 24)
        XCTAssertEqual(today.highs.count, 2)
        XCTAssertEqual(today.lows.count, 2)
        XCTAssertEqual(minutes(today.highs.first?.time, in: jst), 8 * 60 + 40, accuracy: 12)
        XCTAssertNotNil(today.level(at: date("2026-10-30T14:30:00+09:00")))
        XCTAssertNil(today.level(at: date("2026-10-31T14:30:00+09:00")))
        XCTAssertNotNil(today.sunrise)
        XCTAssertEqual(days[1].dayStart, dayStart.addingTimeInterval(86_400))
    }
}
