@testable import TideCore
import XCTest

final class SizeEstimateTests: XCTestCase {
    func testCoinConversion() throws {
        // 硬貨 26.5mm が 100px → 0.265 mm/px。魚 1434px → 38.0cm
        let reference = try XCTUnwrap(SizeEstimate.coinReference(boxWidth: 0.1, boxHeight: 0.1, imageWidth: 1000, imageHeight: 1000))
        XCTAssertEqual(reference.pixelLength, 100)
        XCTAssertEqual(try XCTUnwrap(SizeEstimate.lengthCm(fishPixelLength: 1434, reference: reference)), 38.0, accuracy: 0.05)
    }

    func testNonSquareCoinBoxRejected() {
        XCTAssertNil(SizeEstimate.coinReference(boxWidth: 0.2, boxHeight: 0.1, imageWidth: 1000, imageHeight: 1000))
    }

    func testOutOfRangeIsNil() {
        let reference = SizeEstimate.Reference(kind: .ruler, pixelLength: 100, realLengthMm: 100)
        XCTAssertNil(SizeEstimate.lengthCm(fishPixelLength: 10, reference: reference), "1cm は小さすぎる")
        XCTAssertNil(SizeEstimate.lengthCm(fishPixelLength: 30_000, reference: reference), "300cm は大きすぎる")
        XCTAssertNil(SizeEstimate.lengthCm(fishPixelLength: 0, reference: reference))
    }

    func testLidarReference() throws {
        // 0.5m 先、焦点距離 1500px → 1px = 0.333mm。魚 1200px → 40.0cm
        let reference = try XCTUnwrap(SizeEstimate.lidarReference(distanceMeters: 0.5, focalLengthPx: 1500))
        XCTAssertEqual(try XCTUnwrap(SizeEstimate.lengthCm(fishPixelLength: 1200, reference: reference)), 40.0, accuracy: 0.05)
        XCTAssertNil(SizeEstimate.lidarReference(distanceMeters: 0, focalLengthPx: 1500))
    }
}
