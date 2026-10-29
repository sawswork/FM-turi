import XCTest
@testable import TideCore

final class DeepLinkTests: XCTestCase {
    func testCatchHostParses() throws {
        let url = try XCTUnwrap(URL(string: "tide://catch"))
        XCTAssertEqual(DeepLink(url: url), .catchScreen)
    }

    func testCatchPathParses() throws {
        let url = try XCTUnwrap(URL(string: "tide:///catch"))
        XCTAssertEqual(DeepLink(url: url), .catchScreen)
    }

    func testUnknownSchemeIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "https://catch"))
        XCTAssertNil(DeepLink(url: url))
    }

    func testUnknownTargetIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "tide://settings"))
        XCTAssertNil(DeepLink(url: url))
    }

    func testRoundTrip() {
        XCTAssertEqual(DeepLink(url: DeepLink.catchScreen.url), .catchScreen)
    }
}
