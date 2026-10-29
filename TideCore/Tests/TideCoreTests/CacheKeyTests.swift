@testable import TideCore
import XCTest

final class CacheKeyTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_792_000_000) // 2026-10-14T...

    func testSamePointSameHourGivesSameKey() {
        let a = GeoPoint(latitude: 35.1351, longitude: 139.6149)
        let b = GeoPoint(latitude: 35.1389, longitude: 139.6201) // 0.01° 丸めで同じ
        let key1 = CacheKey.make(point: a, date: base)
        let key2 = CacheKey.make(point: b, date: base.addingTimeInterval(600))
        XCTAssertEqual(key1, key2)
        XCTAssertFalse(CacheKey.needsFetch(cachedExists: true))
    }

    func testDifferentHourGivesDifferentKey() {
        let p = GeoPoint(latitude: 35.135, longitude: 139.615)
        let start = CacheKey.bucketStart(base)
        let key1 = CacheKey.make(point: p, date: start)
        let key2 = CacheKey.make(point: p, date: start.addingTimeInterval(3600))
        XCTAssertNotEqual(key1, key2)
        XCTAssertTrue(CacheKey.needsFetch(cachedExists: false))
    }

    func testDifferentPointGivesDifferentKey() {
        let a = GeoPoint(latitude: 35.135, longitude: 139.615)
        let b = GeoPoint(latitude: 35.165, longitude: 139.615) // 約3km 北
        XCTAssertNotEqual(CacheKey.make(point: a, date: base), CacheKey.make(point: b, date: base))
    }

    func testBucketStartIsOnTheHour() {
        let start = CacheKey.bucketStart(base)
        XCTAssertEqual(Int(start.timeIntervalSince1970) % 3600, 0)
        XCTAssertLessThanOrEqual(start, base)
        XCTAssertGreaterThan(start.addingTimeInterval(3600), base)
    }

    func testKeyFormat() {
        let p = GeoPoint(latitude: 35.1349, longitude: 139.6151)
        let key = CacheKey.make(point: p, date: base)
        XCTAssertTrue(key.hasPrefix("35.13,139.62,h"), key)
    }

    func testDistance() {
        let a = GeoPoint(latitude: 35.135, longitude: 139.615)
        let b = GeoPoint(latitude: 35.144, longitude: 139.615) // 約1km
        XCTAssertEqual(a.distance(to: b), 1000, accuracy: 20)
    }
}
