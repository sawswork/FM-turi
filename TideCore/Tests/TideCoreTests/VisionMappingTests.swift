@testable import TideCore
import XCTest

final class VisionMappingTests: XCTestCase {
    func testRockfishMapsToKasagoFirst() {
        let candidates = VisionMapping.candidates(from: [
            VisionMapping.Observation(identifier: "rockfish", confidence: 0.8),
            VisionMapping.Observation(identifier: "fish", confidence: 0.9)
        ])
        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].species.id, "kasago")
        XCTAssertGreaterThan(candidates[0].confidence, candidates[1].confidence)
        XCTAssertTrue(candidates.allSatisfy { (0...1).contains($0.confidence) })
    }

    func testGrouperMapsToHata() {
        let candidates = VisionMapping.candidates(from: [VisionMapping.Observation(identifier: "grouper", confidence: 0.6)])
        XCTAssertEqual(candidates[0].species.id, "kijihata")
        XCTAssertEqual(Set(candidates.map(\.species.id)).count, 3, "候補は重複しない")
    }

    func testNoMatchGivesDefaults() {
        let candidates = VisionMapping.candidates(from: [VisionMapping.Observation(identifier: "dog", confidence: 0.9)])
        XCTAssertEqual(candidates.map(\.species.id), ["kasago", "mebaru", "hata_other"])
        XCTAssertTrue(candidates.allSatisfy { $0.confidence == 0 })
    }

    func testLowConfidenceIgnored() {
        let candidates = VisionMapping.candidates(from: [VisionMapping.Observation(identifier: "flounder", confidence: 0.005)])
        XCTAssertEqual(candidates.map(\.species.id), ["kasago", "mebaru", "hata_other"])
    }
}
