@testable import TideCore
import XCTest

final class ExifTests: XCTestCase {
    func testDateParsing() throws {
        let date = try XCTUnwrap(Exif.date(from: "2026:10:30 14:30:12"))
        XCTAssertEqual(date, Date(timeIntervalSince1970: 1_793_338_212)) // 2026-10-30T14:30:12+09:00
        XCTAssertNil(Exif.date(from: nil))
        XCTAssertNil(Exif.date(from: "2026-10-30"))
        XCTAssertNil(Exif.date(from: ""))
    }

    func testCoordinate() {
        let point = Exif.coordinate(latitude: 35.1352, latitudeRef: "N", longitude: 139.6079, longitudeRef: "E")
        XCTAssertEqual(point, GeoPoint(latitude: 35.1352, longitude: 139.6079))
        let south = Exif.coordinate(latitude: 33.8, latitudeRef: "S", longitude: 151.2, longitudeRef: "W")
        XCTAssertEqual(south, GeoPoint(latitude: -33.8, longitude: -151.2))
        XCTAssertNil(Exif.coordinate(latitude: nil, latitudeRef: "N", longitude: 1, longitudeRef: "E"))
        XCTAssertNil(Exif.coordinate(latitude: 0, latitudeRef: "N", longitude: 0, longitudeRef: "E"))
    }

    func testScaledSize() {
        let landscape = Exif.scaledSize(width: 4032, height: 3024)
        XCTAssertEqual(landscape.width, 1024)
        XCTAssertEqual(landscape.height, 768)
        let portrait = Exif.scaledSize(width: 3024, height: 4032)
        XCTAssertEqual(portrait.height, 1024)
        let small = Exif.scaledSize(width: 800, height: 600)
        XCTAssertEqual(small.width, 800)
    }
}
